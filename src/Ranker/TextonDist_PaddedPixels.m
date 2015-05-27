function [distribution TextIm] = TextonDist_PaddedPixels(Im, Filter, Reference, ShowIm)
% [distribution TextIm] = TextonDist_PaddedPixels(Im, Filter, Reference, ShowIm)
% Calculate texton distribution for a given image.
% Input: Im - image to calculate (everything but the droplet should be
%           masked)
%        Filter - MR8 filter. Use makeRFSfilters (by Varma and Zisserman).
%        Reference - Texton dictionary 
%        ShowIm - 1 to show artificial colouring of images (by texton
%           labels) or 0
% Output: distribution - Texton distribution (feature vector for ranking)
%         TextIm - Artificial colour image.
%
% AUTHOR: Jia Tsing Ng (jiatsing.ng@dtc.ox.ac.uk)
% Last modified: 22 July 2014.



if nargin<4
    ShowIm = 0;
end


% define structural elements for morphological transforms
se10 = strel('disk', 10); % half of filter size 12.5 ->13 dilate ring further by 3 pixels.
se3 = strel('disk',3);
se16 = strel('disk', 16); %10 + 3 + 3 (total size of ring)

% Crop off redundant space. Get min rectangle that contains droplet
stats = regionprops(logical(Im), 'basic');
area = [stats.Area];
% only consider largest area
[~, id] = max(area);
% Centroid = stats(id).Centroid;
box = round(stats(id).BoundingBox);
imCropped = Im(box(2):box(2)+box(4), box(1):box(1)+box(3));
bwCropped = logical(imCropped);

% % % % for formulatrix only ----------------------------------------------------
% % % % Cut off some extra pixels because segmentation with blurred image will
% % % % not be so accurate. 
% % % bwCropped(1,:) = 0; bwCropped(end,:) = 0; bwCropped(:,1) = 0; bwCropped(:,end) = 0;
% % % bwCropped = imerode(bwCropped, se10);
% % % imCropped = imCropped .* bwCropped;
% % % darkMask = imCropped > 30;
% % % darkMask = imopen(darkMask, se10);
% % % darkMask = imfill(darkMask, 'holes');
% % % bwCropped = bwCropped | darkMask;
% % % imCropped = imCropped .* bwCropped;

% ----------------------------------------------------------------------

if ShowIm
    imCroppedOri = imCropped; %keep copy for view
end

% Check for liquid film
if max(imCropped(bwCropped))-min(imCropped(bwCropped)) < 50 %std(imCropped(bwCropped)) < 12 % or max-min < 50
    % if it's a liquid film, give it feature vec == 0.
    distribution = zeros(1,size(Reference,1));
    TextIm = zeros(size(imCropped));

else
    % --------------------------------------------------------------------
    % gamma correction
    [m n] = size(imCropped); imfft = fftshift(fft2(imCropped,m,n));
    imLP = ifft2(imfft .* fspecial('gaussian', size(imfft), 3));
    gammaVals = abs(imLP)/max(max(imLP));
    imCroppedNew = abs(255*(imCropped/255) .^ (abs(gammaVals)));  % Previous version: abs(gammaVals)+1: Don't know the reason !!!
  
    imCropped = imCroppedNew;
  
    clear imCroppedNew;
    
    % ---------------------------------------------------------------------
    % droplet boundary extension 
    imCroppedBig = zeros(size(imCropped)+52);
    imCroppedBig(27:26+size(imCropped,1), 27:26+size(imCropped,2)) = imCropped;
    bwCropped = logical(imCroppedBig);
    bwDilate = imdilate(bwCropped, se10);
    bwRing = xor(bwDilate, bwCropped);
    bwRing = imdilate(bwRing, se3);
    % remove the outer ring of bwcropped
    bwCropped = imerode(bwCropped, se3);
   
     % Pad pixels
    R = max(size(imCroppedBig));
    maxR = ceil(R/2);
    imP = ImToPolar(imCroppedBig,0,1,maxR,360);
    for i = 1:360
        zeroIdx = find(imP(:,i)==0,1);
        try
            aveToReplace = median(imP(zeroIdx-10:zeroIdx-3,i)); %use median to avoid outliers
            padMax = min(zeroIdx+13, maxR);
            imP(zeroIdx-5:padMax, i) = aveToReplace;
        catch 
            % ignore. no pads. 
%             aveToReplace = 0;
        end

    end
    imR = PolarToIm(imP,0,1,ceil(R/2), ceil(R/2));
    imR = imresize(imR, size(imCroppedBig), 'nearest');
    
    imCroppedBig(bwRing) = imR(bwRing); % pad pixels in ring from imR
    imCropped = imCroppedBig;
    bwtemp = logical(imCropped); % ROI to take at the end - erode all padded pixels + eat-in pixels
    bwROI = imerode(bwtemp, se16);
    
    % --------------------------------------------------------------------
    % Intensity normalisation 
    %normalise imCropped to mean = 0, std = 1
    %normalise all pixels in padded droplet with information only in droplet, do not consider added stuffs
    if std(imCropped(bwCropped)) < 15 % make std less than 1, or = x/20
        imCropped(bwtemp) = (imCropped(bwtemp)-mean(mean(imCropped(bwCropped))))/std(imCropped(bwCropped)) * (std(imCropped(bwCropped))/15);
    else
        imCropped(bwtemp) = (imCropped(bwtemp)-mean(mean(imCropped(bwCropped))))/std(imCropped(bwCropped));
    end
    clear bwtemp;

    %---------------------------------------------------------------------
    % Calculate filter response. 
    response = conv2FFT(Filter, imCropped);
    response = response .*repmat(bwCropped, [1,1,38]);
    %contrast normalise filter response as in Varma Zisserman
    L = sqrt(sum(response.^2,3));
    L = repmat(L,[1 1 38]);
    response = response.*log(1+L./0.03)./L;
    
    % --------------------------------------------------------------------
    % get maximum response for bar and edge filters, keep gaussian filters.
    MaxResponse = zeros([size(imCropped) 8]);
    for mr = 1:6
        MaxResponse(:,:,mr) = max(abs(response(:,:,(mr-1)*6+1:mr*6)),[],3);
    end
    MaxResponse(:,:,7:8) = (response(:,:,37:38));
    
    dataMat = reshape(MaxResponse, numel(imCropped),8);
    dataMat = dataMat(bwROI(:),:); % Only taking responses of pixels NOT in the ring
    distances = pdist2(dataMat, Reference);

    % --------------------------------------------------------------------
    % Find closest match
    [~, I] = min(distances, [], 2);
    distribution = hist(I,1:size(Reference,1));

    
    
   
    % just for showing.
    TextIm = double(bwROI);
    TextIm(bwROI(:)) = I;
    TextIm = TextIm(27:end-26, 27:end-26);
    if ShowIm

        figure(1);
        subplot(2,2,1);imagesc(TextIm, [1 max(TextIm(:))]); axis equal; axis tight; axis off; colormap jet;
        subplot(2,2,2); hist(I,1:size(Reference,1));
        subplot(2,2,3); imagesc(imCroppedOri); axis equal; axis tight; axis off; 
    end
    
end

