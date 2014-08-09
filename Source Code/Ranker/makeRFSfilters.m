function F=makeRFSfilters
% Returns the RFS filter bank of size 49x49x38 in F. The MR8, MR4 and
% MRS4 sets are all derived from this filter bank. To convolve an
% image I with the filter bank you can either use the matlab function
% conv2, i.e. responses(:,:,i)=conv2(I,F(:,:,i),'valid'), or use the
% Fourier transform.
%
% Code originally by Varma and Zisserman
% (http://www.robots.ox.ac.uk/~vgg/research/texclass/code/makeRFSfilters.m)
% Modified by Jia Tsing Ng (jiatsing.ng@dtx.ox.ac.uk)
% Last modified 22 July 2014


  SUP=25;                 % Support of the largest filter (must be odd)
  SCALEX=[0.5,1,2];         % Sigma_{x} for the oriented filters
  SCALEGAUSS = 2.5;
  NORIENT=6;              % Number of orientations

  NROTINV=2;
  NBAR=length(SCALEX)*NORIENT;
  NEDGE=length(SCALEX)*NORIENT;
  NF=NBAR+NEDGE+NROTINV;
  F=zeros(SUP,SUP,NF);
  hsup=(SUP-1)/2;
  [x,y]=meshgrid([-hsup:hsup],[hsup:-1:-hsup]);
  orgpts=[x(:) y(:)]';

  count=1;
  for scale=1:length(SCALEX),
    for orient=0:NORIENT-1,
      angle=pi*orient/NORIENT;  % Not 2pi as filters have symmetry
      c=cos(angle);s=sin(angle);
      rotpts=[c -s;s c]*orgpts;
      F(:,:,count)=makefilter(SCALEX(scale),0,1,rotpts,SUP);
      F(:,:,count+NEDGE)=makefilter(SCALEX(scale),0,2,rotpts,SUP);
      count=count+1;
    end;
  end;  
  F(:,:,NBAR+NEDGE+1)=normalise(fspecial('gaussian',SUP,SCALEGAUSS ));
  F(:,:,NBAR+NEDGE+2)=normalise(fspecial('log',SUP,SCALEGAUSS ));
return

function f=makefilter(scale,phasex,phasey,pts,sup)
  gx=gauss1d(3*scale,0,pts(1,:),phasex);
  gy=gauss1d(scale,0,pts(2,:),phasey);
  f=normalise(reshape(gx.*gy,sup,sup));
return

function g=gauss1d(sigma,mean,x,ord)
% Function to compute gaussian derivatives of order 0 <= ord < 3
% evaluated at x.

  x=x-mean;num=x.*x;
  variance=sigma^2;
  denom=2*variance; 
  g=exp(-num/denom)/sqrt(pi*denom);
  switch ord,
    case 1, g=-g.*(x/variance);
    case 2, g=g.*((num-variance)/(variance^2));
  end;
return

function f=normalise(f), f=f-mean(f(:)); f=f/sum(abs(f(:))); return



% % % To plot filters in one figure: double scales and size to look
% % % pretty
% for i = 1:6
% subplot(4,12,i); imagesc(F(:,:,i)); axis equal; axis tight; axis off;
% end
% for i = 7:12
% subplot(4,12,i+6); imagesc(F(:,:,i)); axis equal; axis tight; axis off;
% end
% for i = 13:18
% subplot(4,12,i+12); imagesc(F(:,:,i)); axis equal; axis tight; axis off;
% end
% for i = 19:24
% subplot(4,12,i-12); imagesc(F(:,:,i)); axis equal; axis tight; axis off;
% end
% for i = 25:30
% subplot(4,12,i-6); imagesc(F(:,:,i)); axis equal; axis tight; axis off;
% end
% for i = 31:36
% subplot(4,12,i); imagesc(F(:,:,i)); axis equal; axis tight; axis off;
% end
% for i = 37:38
% subplot(4,12,i+5); imagesc(F(:,:,i)); axis equal; axis tight; axis off;
% end
% 
% for i = 1:6
% subplot(3,14,i); imagesc(F(:,:,i)); axis equal; axis tight; axis off;
% end
% for i = 7:12
% subplot(3,14,i+6+2); imagesc(F(:,:,i)); axis equal; axis tight; axis off;
% end
% for i = 13:18
% subplot(3,14,i+12+4); imagesc(F(:,:,i)); axis equal; axis tight; axis off;
% end
% for i = 19:24
% subplot(3,14,i-12); imagesc(F(:,:,i)); axis equal; axis tight; axis off;
% end
% for i = 25:30
% subplot(3,14,i-6+2); imagesc(F(:,:,i)); axis equal; axis tight; axis off;
% end
% for i = 31:36
% subplot(3,14,i+4); imagesc(F(:,:,i)); axis equal; axis tight; axis off;
% end
% for i = 37:38
% subplot(3,14,i-24); imagesc(F(:,:,i)); axis equal; axis tight; axis off;
% end
% 
% Use export_fig.