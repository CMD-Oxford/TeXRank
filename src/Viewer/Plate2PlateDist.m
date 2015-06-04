function [dist, Summary] = Plate2PlateDist(Plate1, Plate2, distType, Summarize)

if nargin <3
    distType = 'chi';
    Summarize = 0;
elseif nargin < 4
    Summarize = 0;
end

%Check if plates are the same
if size(Plate1,1)~=size(Plate2,1) && size(Plate1,2)~=size(Plate2,2)
    error('Plate2PlateDist:DifferentPlates', 'Plates are of different sizes.');
end

%Normalise histograms
DictLength = size(Plate1, 2);
Plate1 = Plate1 ./ repmat(sum(Plate1,2),1,DictLength);
Plate2 = Plate2 ./ repmat(sum(Plate2,2),1,DictLength);





if strcmp(distType, 'chi')
    temp = (Plate1 - Plate2).^2 ./ (abs(Plate1) + abs(Plate2));
    temp(isnan(temp)) = 0;
    dist = sqrt(sum(temp, 2));
 elseif strcmp(distType, 'euc')
    dist = sqrt(sum((Plate1 - Plate2).^2, 2));
elseif strcmp(distType, 'KLDiv')
    
    dKL = Plate1.* log(Plate1./Plate2);
    dKL = sum(dKL,2);
    
    d2 = Plate2 .* log(Plate2./Plate1);
    d2 = sum(d2,2);
    dist = mean([dKL d2],2);
elseif strcmp(distType, 'Hellinger')

    Plate1 = sqrt(Plate1); Plate2 = sqrt(Plate2);
    dist = (1/sqrt(2))*sqrt(sum((Plate1 - Plate2).^2,2));
    

end

if Summarize
    Summary.Sum = sum(dist);
    Summary.Average = nanmean(dist);
    Summary.StdDev = nanstd(dist);
    Summary.Skewness = skewness(dist);
    Summary.Kurt = kurtosis(dist);
end

