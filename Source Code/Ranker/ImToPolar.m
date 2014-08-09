function imP = ImToPolar (imR, rMin, rMax, M, N)
% IMTOPOLAR converts rectangular image to polar form. The output image is 
% an MxN image with M points along the r axis and N points along the theta
% axis. The origin of the image is assumed to be at the center of the given
% image. The image is assumed to be grayscale.
% Bilinear interpolation is used to interpolate between points not exactly
% in the image.
%
% rMin and rMax should be between 0 and 1 and rMin < rMax. r = 0 is the
% center of the image and r = 1 is half the width or height of the image.
%
% V0.1 7 Dec 2007 (Created), Prakash Manandhar pmanandhar@umassd.edu


% Modified by Jia Tsing Ng (jiatsing.ng@dtc.ox.ac.uk), 7 Oct 2013
% Vectorizing all parts of the function, reduced run-time from ~0.95s to
% 0.012s. Also changed the bilinear interpolation equations - see wikipedia
% 80 fold increase

[Mr Nr] = size(imR); % size of rectangular image
Om = (Mr+1)/2; % co-ordinates of the center of the image
On = (Nr+1)/2;
sx = (Mr-1)/2; % scale factors
sy = (Nr-1)/2;

% imP  = zeros(M,  N);

delR = (rMax - rMin)/(M-1);
delT = 2*pi/N;

% % % Orignal code
% % loop in radius and 
% % tic;
% for ri = 1:M
% for ti = 1:N
%     r = rMin + (ri - 1)*delR;
%     t = (ti - 1)*delT;
%     x = r*cos(t);
%     y = r*sin(t);
%     xR = x*sx + Om;  
%     yR = y*sy + On; 
%     imP (ri, ti) = interpolate (imR, xR, yR);
% end
% end
% % toc;

[ri ti] = meshgrid(1:M, 1:N);
r = rMin + (ri-1)*delR;
t = (ti-1)*delT;
x = r.*cos(t);
y = r.*sin(t);
xR = sx*x + Om;
yR = sy*y + On;

imP  = interpolate (imR, xR, yR);



function v = interpolate (imR, xR, yR)
    xf = floor(xR);
    xc = ceil(xR);
    yf = floor(yR);
    yc = ceil(yR);
    
      % My codes
    v = zeros(size(xR));
    
    AllEq = xf == xc & yc == yf;
    v(AllEq) =imR(sub2ind(size(imR), xc(AllEq), yc(AllEq)));
    XEq = xf == xc & yf ~= yc;
    v(XEq) = imR(sub2ind(size(imR),xf(XEq), yf(XEq))) + (yR(XEq) - yf(XEq)).*(imR(sub2ind(size(imR),xf(XEq), yc(XEq))) - imR(sub2ind(size(imR),xf(XEq), yf(XEq))));
    YEq = yf == yc & xf ~= xc;
    v(YEq) = imR(sub2ind(size(imR),xf(YEq), yf(YEq))) + (xR(YEq) - xf(YEq)).*(imR(sub2ind(size(imR),xc(YEq), yf(YEq))) - imR(sub2ind(size(imR),xf(YEq), yf(YEq))));
    
    NotEq = xf ~= xc & yf ~= yc;
    %bilinear interpolation
    % Q21      Q22   (ceils)
    %    (x,y)
    % Q11      Q12   (floors)
   
    Q11 = imR(sub2ind(size(imR), xf(NotEq), yf(NotEq)));
    Q21 = imR(sub2ind(size(imR), xf(NotEq), yc(NotEq)));
    Q12 = imR(sub2ind(size(imR), xc(NotEq), yf(NotEq)));
    Q22 = imR(sub2ind(size(imR), xc(NotEq), yc(NotEq)));
    
    %weights: taking the opposite squares
    w11 = (xc-xR).*(yc-yR); w11 = w11(NotEq);
    w21 = (xR-xf).*(yc-yR); w21 = w21(NotEq);
    w12 = (xc-xR).*(yR-yf); w12 = w12(NotEq);
    w22 = (xR-xf).*(yR-yf); w22 = w22(NotEq);
    
%     denominator = (xc-xf).*(yc-yf); denominator = 1/denominator(NotEq);
    
    v(NotEq) = (Q11.*w11 + Q21.*w21 + Q12.*w12 + Q22.*w22);% .* denominator';
    v = v';
    
    
% % Original code
%     if xf == xc && yc == yf
%         v = imR (xc, yc);
%     elseif xf == xc
%         v = imR (xf, yf) + (yR - yf)*(imR (xf, yc) - imR (xf, yf));
%     elseif yf == yc
%         v = imR (xf, yf) + (xR - xf)*(imR (xc, yf) - imR (xf, yf));
%     else
%        A = [ xf yf xf*yf 1
%              xf yc xf*yc 1
%              xc yf xc*yf 1
%              xc yc xc*yc 1 ];
%        r = [ imR(xf, yf)
%              imR(xf, yc)
%              imR(xc, yf)
%              imR(xc, yc) ];
%        a = A\double(r);
%        w = [xR yR xR*yR 1];
%        v = w*a;
%     end
