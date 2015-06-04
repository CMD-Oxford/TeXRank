function translated = translate_image(im, t)
% translated = translate_image(im, t);
% im = image to translate.
% t = translation vector [t(1) t(2)]
%
% AUTHOR: Jia Tsing Ng (jiatsing.ng@dtx.ox.ac.uk)
% Last modified: 22 July 2014

T = maketform('affine', [t(3) 0; 0 t(3); t(1) t(2)]);
translated = double(imtransform(im, T, 'XData', [1 size(im,2)], 'YData', [1 size(im,1)], 'FillValues', 0));

