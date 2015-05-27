function FD_TFG_HourlyInspection_Console(PathToImages, PlateBarcode, BackgroundIm)
% This is a simplified version of FD_TFG, only one plate is processed at at
% time to circumvent the endless possibility of differences that may arise
% from system to system.
% Inputs: 
%   PathToImages: Path to text file containing image file paths of a plate. 
%       Each image file path should be on a new line. 
%   OutputFileName: Path and filename to save output files. 
%       2 output files will be save and the following will be appended to
%       OutputFileName 
%           ..._TextonDist.mat
%               => Matlab file, cell variable named TextonFeatures.
%                  1: Filepaths, 2: Feature vectors, 3: Ranking scores
%                  4: Good/Empty/Faulty droplet, 5: Clear drop score, 
%                  6: Translation vector. 
%   BackgroundIm: Path to generated background image file. (Use the
%       included GenerateBackgroundIm.exe to generate these and supply the
%       filename of the saved file here).
%       If multiple files are required (different subwell for example), 
%       separate each filename with a comma and input them in the correct 
%       subwell order. 
%   fid: (optional) Path to log file. A text file will be created. 
%
% AUTHOR: Jia Tsing Ng (jiatsing.ng@dtc.ox.ac.uk). 
% Last modified 22 July 2014. 
% 



if nargin < 3 && strcmp(PathToImages, '-h')
    % show help message - clunky, oh well.
    HelpMessage = ['This is a simplified version of FD_TFG, only one plate is processed at at \n'...
                   'time to circumvent the endless possibility of differences that may arise \n'...
                   'from system to system. \n'...
                   'Inputs: \n'...
                   '  PathToImages: Path to text file containing image file paths of a plate. \n'...
                   '      Each image file path should be on a new line. \n'...
                   '  PlateBarcode: Output file will start with this name, saved in Data\\ \n'...
                   '        PlateBarcode.mat \n'...
                   '              => Matlab file, cell variable named TextonFeatures.\n'...
                   '                 1: Filepaths, 2: Feature vectors, 3: Ranking scores \n'...
                   '                 4: Good/Empty/Faulty droplet, 5: Clear drop score, \n'...
                   '                 6: Translation vector (wrt BackgroundIm). \n'...
                   '  BackgroundIm: Path to generated background image file. (Use the\n'...
                   '      included GenerateBackgroundIm.exe to generate these and supply the\n'...
                   '      filename of the saved file here).\n'...
                   '      If multiple files are required (different subwell for example), \n'...
                   '      separate each filename with a comma and input them in the correct \n'...
                   '      subwell order. \n'];
    fprintf('%s', HelpMessage);
    return;
    
elseif nargin ~= 3
    error('InputError:TooFewInputs', '3 arguments required');
end

% check and create directories if not already created.
if exist('Data', 'dir') ~= 7
    mkdir('Data'); % folder where all data files will be written to. 
end
if exist('LogFiles', 'dir') ~= 7
    mkdir('LogFiles');
end
LogFileName = [datestr(now, 'yyyymmdd_HHMM') '.txt'];
fid = fopen(['LogFiles\' LogFileName], 'w');

fprintf('Writing logfile: LogFiles\\%s', LogFileName)
fprintf(fid, 'Loading files and background images...\n');
fprintf('Loading files and background images...\n');


% load and initialize some variables. 
load('MatFiles/bGradOnly_DropM.mat');% bGradOnly_DropM - Random Forest classifier for fault detection
load('MatFiles/bEmptyOrFaulty.mat'); % bEmptyOrFaulty - 2nd layer of Random Forest classifier - Empty drop or faulty drop.
load('TextonDictionaryForRanker.mat'); % variable name: UpdatedTextons
load('MatFiles/bRanking.mat'); %variable name: b.
load('MatFiles/bClearDropID.mat'); %variable name: bClearDropID

se = strel('disk', 3);
se2 = strel('disk',5);
histGradBinCentre = linspace(0,5,50);
TextonFeatures = cell(1,6);
F = makeRFSfilters; % MR8 filter bank. 

% Load and process background images, create mask. 
BackgroundImPaths = regexp(BackgroundIm, ',', 'split');
% remove trailing white spaces 
BackgroundImPaths = strtrim(BackgroundImPaths);
ImAveAll = cell(length(BackgroundImPaths),1); ImBWAll = ImAveAll;
for i = 1:length(BackgroundImPaths)
    try 
        load(BackgroundImPaths{i});
        ImAveAll{i} = BackgroundIm{1};
        ImBWAll{i} = BackgroundIm{2};
    catch err
        fprintf('Error loading background image: %s (%s).\n', BackgroundImPaths{i}, err.message);
        return;
    end
end
NumSubwells = length(ImAveAll);
TranslateVectors = zeros(NumSubwells,3);

% read text file containing file paths.
fFilePaths = fopen(PathToImages, 'r');
files = textscan(fFilePaths, '%s', 'delimiter', '\n');
files = files{1};
fclose(fFilePaths);

% initialise more variables
FD_Features = zeros(length(files), 54);
DropletMorph = zeros(length(files),6);
FeatureVec = NaN(length(files), size(UpdatedTextons,1));
Centroids = zeros(NumSubwells,2);

fftw('planner', 'patient');

TranslateFlag = 0; % Translation vector still not found


fprintf(fid, 'Calculating features...\n');
fprintf('Calculating features...\n');


imThumbnailAll = uint8(zeros([1056 1584 3])); % write and create thumbnailer
for FileNum = 1:length(files)
    try
        fprintf(fid, 'Subwell %d:', FileNum);
        fprintf('Subwell %d:', FileNum);

        tic;
        im = imread(files{FileNum});
        if NumSubwells == 3
            %store to thumbnail
            imThumbnail = uint8(imresize(im, [66 88]));
            imThumbnail = permute(imThumbnail, [2 1 3]);
            col = mod(FileNum, 24); if col==0 col=24; end
            imThumbnailAll(floor((FileNum-1)/24)*88+1:(floor((FileNum-1)/24)+1)*88, (col-1)*66+1:col*66,:) = imThumbnail;
            clear imThumnail col;
        end
        
        im = double(imadjust(rgb2gray(im)));
        if mod(FileNum, NumSubwells)
            bwSmall = ImBWAll{mod(FileNum, NumSubwells)};
            imAveSmall = ImAveAll{mod(FileNum, NumSubwells)};
        else
            bwSmall = ImBWAll{end};
            imAveSmall = ImAveAll{end};
        end
        
        % ---------------------------------------------------------------
        % Fault detection:  
        %   Image registration
        %   Calculate features from normalised image. 
        
        %image registration at low resolution
        imSmall = imresize(im, [96 128]);
        %Also get downsizing factor which will be used for centroid
        %translation for ECHO
        DownsizeFactorX = size(im,1)/96;
        DownsizeFactorY = size(im,2)/128;
        
        % only find translation vectors for 1 set of subwells, use the
        % corresponding vectors for the rest. Save time! 
        if FileNum > NumSubwells 
            t = TranslateVectors(mod(FileNum,NumSubwells)+1,:); %add 1 for easy indexing. 
        else
            if mean(mean(im))<111  %Very dark droplets - will screw up registration. Forget it!
                t(1) = 0; t(2) = 0; t(3) = 1;
            else
                f = @(t) sqrt(sum(sum((translate_image(imAveSmall, t) - imSmall).^2)));
                if TranslateFlag==0
                    t = [-5 3 1];
                end
                [t,~,TranslateFlag] = fminsearch(f, [t(1) t(2) t(3)]);
                TranslateVectors(mod(FileNum,NumSubwells)+1,:) = t;
            end
        end
        
        
        bwT = translate_image(bwSmall, t);
        bwTer = imerode(bwT,se); %take away boundary pixels
        bwTer(1,:) = 0; bwTer(end,:) = 0;
        bwTer(:,1) = 0; bwTer(:,end) = 0;
        
        % calculate centroid
        if FileNum < NumSubwells+1
            temp = regionprops(imresize(bwTer, size(im), 'nearest'), 'Centroid');
            Centroids(FileNum,:) = temp.Centroid;
        end
        
        MaskedIm = bwTer .* imSmall;
        idx = logical(MaskedIm);
        
        %normalise
        MaskedIm(idx) = (MaskedIm(idx) - mean(MaskedIm(idx))) / std(MaskedIm(idx));
        
        
        % Gradient Features 
        [fx fy] = gradient(MaskedIm);
        gradIm = imerode(bwT, se2) .* (abs(fx) + abs(fy)); %Remove high gradients due to edge of well/mask
        gradIm(1:2,:) = 0; gradIm(end-1:end,:) = 0;
        idxGradient = logical(gradIm);
        aveGrad = mean(gradIm(idxGradient));
        stdevGrad = std(gradIm(idxGradient));
        skewGrad = skewness(gradIm(idxGradient));
        kurtGrad = kurtosis(gradIm(idxGradient));
        DistributionGrad = hist(gradIm(idxGradient),histGradBinCentre);
        DistributionGrad = DistributionGrad / sum(DistributionGrad);
        
        
        FD_Features(FileNum,:) = [aveGrad stdevGrad skewGrad kurtGrad DistributionGrad];

        % --------------------------------------------------------------------------
        % Droplet Segmentation
        DropletRegion = DroplITChanged(im, bwTer);
        if sum(DropletRegion(:)) > 5000 && sum(DropletRegion(:)) < 50000
            %roughly the right size of droplet - determined empirically
            reg = imresize(im, [480 640]).* imresize(DropletRegion, [480 640]);
            % Calculate some droplet morphology features for fault
            % detection
            temp = regionprops(DropletRegion, {'Area','Centroid', 'Eccentricity', 'MajorAxisLength','MinorAxisLength'});
            DropletMorph(FileNum,:) = [temp.Area, temp.Centroid, temp.MajorAxisLength, temp.MinorAxisLength, temp.Eccentricity];
        else
            %probably wrong segmentation. Try again with smaller ROI
            DropletRegion = DroplITChanged(im, imerode(bwTer,se2));
            if sum(DropletRegion(:)) > 4000 && sum(DropletRegion(:)) < 50000  % if wrong segmentation, ignore again.
                reg = imresize(im, [480 640]).* imresize(DropletRegion, [480 640]);
                temp = regionprops(DropletRegion, {'Area','Centroid', 'Eccentricity', 'MajorAxisLength','MinorAxisLength'});
                DropletMorph(FileNum,:) = [temp.Area, temp.Centroid, temp.MajorAxisLength, temp.MinorAxisLength, temp.Eccentricity];
            else
                reg = NaN;
                DropletMorph(FileNum,:) = [0 0 0 0 0 0];
            end
        end
        
        if isnan(reg)
            % if no region was detected - bad droplet segmentation
            FeatureVec(FileNum,:) = NaN(1,size(UpdatedTextons,1));
        else
            FeatureVec(FileNum,:) = TextonDist_PaddedPixels(reg, F, UpdatedTextons,0);
        end
        
        fprintf(fid,'Time: %.4f\n', toc);
        fprintf('Time: %.4f\n', toc);

        
    catch err
        Message = sprintf('Calculation error at Subwell %d, Error:%s \n', FileNum, err.message);
        fprintf(fid, '%s\n', Message);
        fprintf('%s\n', Message);
        TextonFeatures{1} = files;
        TextonFeatures{2} = FeatureVec;
    end
end
TextonFeatures{1} = files;
TextonFeatures{2} = FeatureVec;
save(['Data\' PlateBarcode '.mat'], 'TextonFeatures');


clear im nOriReduced FeaturesContrast FeaturesGrad im*

try
    % ------------------------------------------------------------------------
    % Fault detection prediction.
    % 0 = good drop, 1 = empty drop, 2 = faulty
    % drop
    % New Replacement: Predict with Grad+DropletMorph
    EmptyWell = predict(bGradOnly_DropM, [FD_Features DropletMorph]);
    EmptyWell = str2num(cell2mat(EmptyWell));
    EmptyWell(logical(EmptyWell)) = EmptyWell(logical(EmptyWell))+1;
    nanIdx = isnan(FeatureVec(:,1));
    EmptyWell(nanIdx) = 2;
    % 2nd layer.
    FaultyIdx = EmptyWell > 0;
    if sum(FaultyIdx) > 0
        EmptyOrFaulty = predict(bEmptyOrFaulty, [FD_Features(FaultyIdx,:) DropletMorph(FaultyIdx,:)]);
        EmptyOrFaulty = str2num(cell2mat(EmptyOrFaulty));
        EmptyWell(FaultyIdx) = EmptyOrFaulty;
    end
    clear FD_Features DropletMorph;
    TextonFeatures{4} = EmptyWell;
    
    
    % -----------------------------------------------------------------------
    % Ranking calculation
    XNorm =  FeatureVec ./ repmat(nansum(FeatureVec,2), 1,size(FeatureVec,2));
    
    Faulty = EmptyWell > 1;
    nanidx = isnan(FeatureVec(:,1)) | Faulty ; %nan or faulty
    
    RankScores = zeros(size(XNorm,1),1);
    [~, Scores] = predict(b, XNorm(~nanidx,:));
    RankScores(~nanidx) = Scores(:,2);
    TextonFeatures{3} = RankScores;
    
    % --------------------------------------------------------------------
    % Clear Drop Prediction 
    ClearScores = zeros(size(XNorm,1),1);
    [~, Scores] = predict(bClearDropID, XNorm(~nanidx,:));
    ClearScores(~nanidx) = Scores(:,2);
    TextonFeatures{5} = ClearScores;
    
    
    % --------------------------------------------------------------------
    % Save translation vectors just in case (for ECHO use)
    TranslateVectors = TranslateVectors([2:NumSubwells 1], :);
    TextonFeatures{6} = [TranslateVectors(:,1:2).*repmat([DownsizeFactorX DownsizeFactorY], NumSubwells, 1) ...
        Centroids ...
        TranslateVectors(:,3)]; %scaling vector.

    save(['Data\' PlateBarcode '.mat'], 'TextonFeatures');
    
    % --------------------------------------------------------------------
    % Write CSV file: rows = image
    % cols: |image filename| RankingScore | Faulty Class | Clear Score |
    fCSV = fopen(['Data\' PlateBarcode '_Scores.csv'], 'w');
    for i = 1:length(files)
        fprintf(fCSV, '%s,%.4f,%d,%.4f\n', files{i},RankScores(i),EmptyWell(i),ClearScores(i));
    end
    fclose(fCSV);
    
    % --------------------------------------------------------------------
    % Save thumbnail - use the same format as - only for 3 subwells
    if NumSubwells == 3
        imThumbnailAll(:,:,1) = flipud(imThumbnailAll(:,:,1));
        imThumbnailAll(:,:,2) = flipud(imThumbnailAll(:,:,2));
        imThumbnailAll(:,:,3) = flipud(imThumbnailAll(:,:,3));
        
        Rows = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'};
        Green = uint8([55 220 80]);
        for i = 1:8
            imThumbnailAll(:,i*198-2:i*198,1) = 55;
            imThumbnailAll(:,i*198-2:i*198,2) = 220;
            imThumbnailAll(:,i*198-2:i*198,3) = 80;
            textInserter = vision.TextInserter(Rows{i}, 'Color', Green, 'FontSize', 20, 'Location', [(i-1)*198+1, 1030]);
            imThumbnailAll = step(textInserter,imThumbnailAll);
        end
        for i = 1:12
            textInserter = vision.TextInserter(num2str(i), 'Color', Green, 'FontSize', 20, 'Location', [1, (12-i)*88+1]);
            imThumbnailAll = step(textInserter,imThumbnailAll);
        end
        imwrite(imThumbnailAll, ['Data\' PlateBarcode '_thumb.jpg'], 'jpg');
    end
    

catch err
    Message = sprintf('Error at Prediction stage. %s: ', err.message);
    %         EmailMe('Error - Fault Detection Error', Message);

    fprintf(fid, '%s\n', Message);
    fprintf('%s\n', Message);

    save(['Data\' PlateBarcode '.mat'], 'TextonFeatures');
end


fclose(fid);





