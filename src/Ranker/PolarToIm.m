function imR = PolarToIm (imP, rMin, rMax, Mr, Nr)
% POLARTOIM converts polar image to rectangular image. 
%
% V0.1 16 Dec, 2007 (Created) Prakash Manandhar, pmanandhar@umassd.edu
%
% This is the inverse of ImToPolar. imP is the polar image with M rows and
% N columns of data (double data between 0 and 1). M is the number of
% samples along the radius from rMin to rMax (which are between 0 and 1 and
% rMax > rMin). Mr and Nr are the number of pixels in the rectangular
% domain. The center of the image is assumed to be the origin for the polar
% co-ordinates, and half the width of the image corresponds to r = 1.
% Bilinear interpolation is performed for points not in the imP image and
% points not between rMin and rMax are rendered as zero. The output is a Mr
% x Nr grayscale image (with double values between 0.0 and 1.0).

% Modified by Jia Tsing Ng (jiatsing.ng@dtc.ox.ac.uk), 7 Oct 2013
% Vectorizing all parts of the function, reduced run-time from 0.34s to
% 0.006s. Also changed the bilinear interpolation equations - see wikipedia
% 56.67 fold increase


imR = zeros(Mr, Nr);
Om = (Mr+1)/2; % co-ordinates of the center of the image
On = (Nr+1)/2;
sx = (Mr-1)/2; % scale factors
sy = (Nr-1)/2;

[M N] = size(imP);

delR = (rMax - rMin)/(M-1);
delT = 2*pi/N;

% % My codes
[xi yi] = meshgrid(1:Mr, 1:Nr);
x = (xi - Om)/sx;
y = (yi - On)/sx;
r = sqrt(x.*x + y.*y);

rInRange = r >= rMin & r <= rMax;
t = atan2(y,x);
t(t<0) = t(t<0) + 2*pi;

imR = interpolate(imP, r, t, rMin, rMax, M, N, delR, delT, rInRange);

% % Original code
% for xi = 1:Mr
% for yi = 1:Nr
%     x = (xi - Om)/sx;
%     y = (yi - On)/sx;
%     r = sqrt(x*x + y*y);
%     if r >= rMin & r <= rMax
%        t = atan2(y, x);
%        if t < 0
%            t = t + 2*pi;
%        end
%        imR (xi, yi) = interpolate (imP, r, t, rMin, rMax, M, N, delR, delT);
%     end
% end
% end

function v = interpolate (imP, r, t, rMin, rMax, M, N, delR, delT, rInRange)
    
    ri = 1 + (r - rMin)/delR;
    ti = 1 + t/delT;
    rf = floor(ri);
    rc = ceil(ri);
    tf = floor(ti);
    tc = ceil(ti);
% %Original codes:    
%     if tc > N
%         tc = tf;
%     end
    
    % my codes
    tc(tc>N) = tf(tc>N);
    rc(rc>M) = rf(rc>M);
    v = zeros(size(tc));
    
    AllEq = rf == rc & tc == tf & rInRange;
    v(AllEq) = imP(sub2ind(size(imP), rc(AllEq), tc(AllEq)));
    REq = rf == rc & tf ~= tc & rInRange;
    v(REq) = imP(sub2ind(size(imP),rf(REq), tf(REq))) + (ti(REq) - tf(REq)).*(imP(sub2ind(size(imP),rf(REq), tc(REq))) - imP(sub2ind(size(imP),rf(REq), tf(REq))));
    TEq = tf == tc & rf ~= rc & rInRange;
    v(TEq) = imP(sub2ind(size(imP),rf(TEq), tf(TEq))) + (ri(TEq) - rf(TEq)).*(imP(sub2ind(size(imP),rc(TEq), tf(TEq))) - imP(sub2ind(size(imP),rf(TEq), tf(TEq))));
    
    
    NotEq = rf ~= rc & tf ~= tc & rInRange;
    %bilinear interpolation
    % Q21      Q22   (ceils)
    %    (x,y)
    % Q11      Q12   (floors)
   
    Q11 = imP(sub2ind(size(imP), rf(NotEq), tf(NotEq)));
    Q21 = imP(sub2ind(size(imP), rf(NotEq), tc(NotEq)));
    Q12 = imP(sub2ind(size(imP), rc(NotEq), tf(NotEq)));
    Q22 = imP(sub2ind(size(imP), rc(NotEq), tc(NotEq)));
    
    %weights: taking the opposite squares
    w11 = (rc-ri).*(tc-ti); w11 = w11(NotEq);
    w21 = (ri-rf).*(tc-ti); w21 = w21(NotEq);
    w12 = (rc-ri).*(ti-tf); w12 = w12(NotEq);
    w22 = (ri-rf).*(ti-tf); w22 = w22(NotEq);
    
%     denominator = (rc-rf).*(tc-tf); denominator = 1/denominator(NotEq);
    
    v(NotEq) = (Q11.*w11 + Q21.*w21 + Q12.*w12 + Q22.*w22);% .* denominator';
    v = v';
    
% % % Original Code:
%     if rf == rc & tc == tf
%         v = imP (rc, tc);
%     elseif rf == rc
%         v = imP (rf, tf) + (ti - tf)*(imP (rf, tc) - imP (rf, tf));
%     elseif tf == tc
%         v = imP (rf, tf) + (ri - rf)*(imP (rc, tf) - imP (rf, tf));
%     else
%        A = [ rf tf rf*tf 1
%              rf tc rf*tc 1
%              rc tf rc*tf 1
%              rc tc rc*tc 1 ];
%        z = [ imP(rf, tf)
%              imP(rf, tc)
%              imP(rc, tf)
%              imP(rc, tc) ];
%        a = A\double(z);
%        w = [ri ti ri*ti 1];
%        v = w*a;
%     end
