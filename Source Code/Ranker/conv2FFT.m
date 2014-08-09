function g = conv2FFT(h, f)

% g = conv2FFT(h, f)
%
% DESC:
% computes the 2D convolution via FFT
%
% AUTHOR
% Marco Zuliani - zuliani@ece.ucsb.edu
%
% VERSION:
% 1.0.0
%
% INPUT:
% h                 = convolution kernel
% f                 = input signal
%
% OUTPUT:
% g                 = output signal
%
% HISTORY
% 1.0.0             ??/??/07 Initial version
%
% Last modified by Jia Tsing Ng, 23 May 2013 for 3D input and 3D filter
% Original code available from http://vision.ece.ucsb.edu/~zuliani/Code/Matlab/conv2FFT.html
% 



sh = size(h);
sh3 = sh(3);
sh = sh(1:2);
sf = size(f);
g = zeros([sf sh3]);
% zero pad the input signals
fm = zeros(sf+2*(sh-1), class(f));
o = sh-1;
fm( o(1)+(1:size(f,1)), o(2)+(1:size(f,2)) ) = f;



% compute the convolution in frequency
F = fft2(fm);
h_zp = zeros(size(fm), class(h));
o2 = floor(1.5*sh)-1;
for i = 1:sh3
    h_zp(1:size(h,1), 1:size(h,2)) = h(:,:,i);
    H = fft2(h_zp);
    Y = F.*H;
    % back to spatial domain
    temp = real( ifft2(Y) );
    % remove padding
    g(:,:,i) = temp( o2(1)+(1:size(f,1)), o2(2)+(1:size(f,2)) );
end



return
