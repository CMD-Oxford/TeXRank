function region = DroplITChanged(filename, bw)
% DroplIT Fast droplet segmentation script for crystallographers and other
% droplet enthousiasts,    
%                     By Pascal Vallotton, CSIRO, 13.08.2010
% No insurance whatsoever about whatsoever in whatsoever form is warranted
% if you decide to use this script.
% If you do so, please cite the following publication in
% your work, whether it uses this code in its integrality or only in part:
%                    Pascal Vallotton, Changming Sun, David Lovell, Vincent J. Fazio, Janet Newman,
% DroplIT, an improved Image Analysis Method for Droplet Identification 
% in High Throughput Crystallization Trials J. Appl. Cryst. 2010
%
% You will need to modify line 16 to point to your own image file on your  computer.
%
% Last modified by Jia Tsing Ng, 22 July 2014.
%   Modification now requires an input image (instead of filename) and binary
%   mask. Output is now a region mask of the droplet


% Creating sturcturing elements beforehand seems to speed things up a tiny bit. This is our collection
strelDisk3=strel('disk',3);strelDisk20=strel('disk',20);strelDisk10=strel('disk',10);strelDisk7=strel('disk',7);strelDisk2=strel('disk',2);
% Read image and resize it. You need to point to your own image for the
% script to work.
%a=imread('C:\Documents and Settings\val057\Image data\Janet Newman\MC100341\4\RMM3_01_328_ROBO_Test1_Clon1_MC_0000MC100341_004_100716_01_06_01_00_99_030_001_RDI.jpg');
a=filename;

a=sum(a,3);
b=imresize(a,0.15,'bilinear');bsav=b;%
% b=imresize(a,3) ;bsav=b;%
bw = imresize(bw,3);
%determine the center of droplet automatically using edge detection
% x = find(b~=0);
f=edge(imclose(b,strelDisk3),'zerocross');%
% figure; imshow(f);
%remove small garbage contours as it shifts the droplet center
% % % f=bwareaopen(f,40);
% Determine the outer well boundary using otsu thresholding
% % % level = graythresh(uint8(b));bw = im2bw(b/256,level);
% % % bw(1,:)=1;bw(end,:)=1;bw = imfill(bw,'holes');bwsav=1-bw;bw(:,1)=0;bw(:,end)=0;bw(1,:)=0;bw(end,:)=0;
% imshow(bw);
%secure a clearance zone where shadows may cause problems
bwsmall=imerode(bw,strelDisk3);%
% bwsmall = bw;
bw=imerode(bw,strelDisk3);
% imshow(bw);
%chip off the left and right well side, which are more ugly than the rest
%because of illumination issues
% % % [leftcornval,leftcornindx]=max(bw(round(size(bw,1)/2),:));
% % % [righornval,rightcornindx]=max(bw(round(size(bw,1)/2),end:-1:1));
% % % bw(:,1:(leftcornindx+20))=0;  bw(:,end:-1:(size(bw,2)-rightcornindx-10))=0;
%keep the edges within well only
f=bwsmall.*f;
%guard against empty edge condition
if sum(f(:))==0
    f(size(f,2)/2,size(f,1)/2)=1;
end
%crystals and debris attract the countour too much, supress them using
%closing but preserve the image intensity when the image behaves in
%subtle ways not preserved under closing e.g thin interrupted dark line
%assocaited with faint droptlet boundary
bx = imclose(b,strelDisk3);
bdifindx=find((bx-b)>30);
bcopydiff=zeros(size(b));bcopydiff(bdifindx)=1;bcopydiff=imdilate(bcopydiff,strelDisk3);
b(find(bcopydiff))= bx(find(bcopydiff));bx=b;
%find the centre of gravity of the droplet using edges
sumx=sum(f,1);sumy=sum(f,2);
sumtot=sum(sumx);
sumMomx=[1:size(sumx,2)].*sumx;global xPos;
xPos=sum(sumMomx)/sumtot;
sumMomy=[1:size(sumy,1)]'.*sumy;global yPos;
yPos=sum(sumMomy)/sumtot;%
%if there is only a large droplet on the side of well, you need to
%shift the centre of a bit by considering the intensity landscape
massd=bw.*bsav;massd=imclose(massd,strelDisk7)-massd;massd(massd<5)=0; 
sumx=sum(massd,1);sumy=sum(massd,2);
sumtot=sum(sumx);
sumMomx=[1:size(sumx,2)].*sumx;
xPosd=sum(sumMomx)/sumtot;
sumMomy=[1:size(sumy,1)]'.*sumy;
yPosd=sum(sumMomy)/sumtot;%
xPos=(xPos+xPosd)/2;yPos=(yPos+yPosd)/2;
%remove dark chuncks that would attract our contour
bxchunck=imclose(bx,strelDisk20)-bx;
bchuncklabel=bwlabeln(bwmorph(imclose(f,strelDisk2),'thin'));
bchuncklabelpros=regionprops(bchuncklabel,'ConvexArea');  %MADE CHANGES HERE-using convex area rather than filled area to accommodate incomplete edges
idx = find([bchuncklabelpros.ConvexArea] < 10000); %changed threshold for 3000 to 10000
BW2 = ismember(bchuncklabel, idx);bwchum=imfill(BW2,'holes');
bwchum=bwmorph(bwchum,'erode');

%remove clear chunks that would attract our contour
bxchunck=imopen(bx,strelDisk20)-bx;
tothre=max(bxchunck(:))-bxchunck;
tothre=(tothre/max(tothre(:)));
level = graythresh(tothre);
try
    BWs = im2bw(tothre,4*level);
catch
    BWs=zeros(size(b));
end
%calcutate radial gradient from centre position
bx=edgeGradient(bx,'canny',[],0.5).*bw;
if find(BWs)
    bx(imdilate(BWs>0,strelDisk3))=mean(bx(:));
end
%Trim intensity values over the dark chunks
if find(bwchum)
    bx(imdilate(bwchum>0,strelDisk3))=mean(bx(:));
end
%place a clear rim around the well boundary so that the tracing
%resolves to a large area if evidence for droplet is too weak.
bx((imdilate((1-bw),strelDisk2)-bw)==0)=quantile(bx(:),0.98);


%kill suspiciously strong edges that may attract the contour
qyp= quantile(bx(:),0.995);bx((bx>qyp))=qyp; 

%transform to polar coordinates
ThetaNum=360;
rhoMax=250; %rhoMax: radius in pixel of the transformed domain
thetac=repmat(linspace(0,2*pi,ThetaNum),rhoMax,1);
rhoc=repmat(linspace(1,rhoMax,rhoMax)',1,ThetaNum);
[X,Y] = pol2cart(thetac(:),rhoc(:));X=X+xPos;Y=Y+yPos;
X=reshape(X,rhoMax,ThetaNum);Y=reshape(Y,rhoMax,ThetaNum);
%interpolate values
[Xi,Yi] = meshgrid(1:size(f,2),1:size(f,1));
Z=bx;
ZI = interp2(Xi,Yi,Z,X,Y); 
ZIZerosIndx=find(or((abs(ZI))<0.001,not(isfinite(ZI))));Zzeros=zeros(size(ZI));Zzeros(ZIZerosIndx)=1;ZI(find(Zzeros))=0;
ZI(end,:)=0;
Zgrad=ZI;Zgrad=max(Zgrad(:))-Zgrad;
Zgrad=repmat(Zgrad,1,3);
%this is where you allow the slope of the shortest path to increase by a
%factor two in order to find accidents in the droplet contour
Zgrad= imresize(Zgrad,[size(Zgrad,1),size(Zgrad,2)*2],'nearest');
% Find shortest path now that you warmed up
%initialisation
parentI=zeros(size(Zgrad));%holds pointers to parents
distI=Zgrad;%distI holds best distance so far
weighFactDistInt=max(Zgrad(:));
wighPrefact=0.2; % this is 1-0.8 in the manuscript

%the following dynamic programming loop looks a bit ugly but the uglyness is what makes it fast
%under Matlab.

%first row gets special treatment
for h=2:size(Zgrad,2)
    for j=1
        distId=distI(j,h-1)+Zgrad(j,h)+wighPrefact*1*weighFactDistInt;
        distId1=min(distId,distI(j+1,h-1)+Zgrad(j,h)+wighPrefact*1.41*weighFactDistInt);
        distI(j,h)=distId1;
        if (distId1<distId)
            maxindx=3;
        else
            maxindx=2;
        end
        parentI(j,h)=maxindx;
    end
    
    %deal with all intermediate rows
    
    for j=2:size(Zgrad,1)-1
        distId=distI(j-1,h-1)+Zgrad(j,h)+wighPrefact*1.41*weighFactDistInt;
        distId1=min(distId,distI(j,h-1)+Zgrad(j,h)+wighPrefact*1*weighFactDistInt);
        distId3=min(distId1,distI(j+1,h-1)+Zgrad(j,h)+wighPrefact*1.41*weighFactDistInt);
        distI(j,h)=distId3;
        maxindx=1;
        if (distId3<distId1)
            maxindx=3;
        elseif (distId1<distId)
            maxindx=2;
        end
        parentI(j,h)=maxindx;
    end
    
    %deal with last row
          
    for j=size(Zgrad,1)
        distId=distI(j-1,h-1)+Zgrad(j,h)+wighPrefact*1.41*weighFactDistInt;
        distId1=min(distId,distI(j,h-1)+Zgrad(j,h)+wighPrefact*1*weighFactDistInt);
        distI(j,h)=distId1;
        if (distId1<distId)
            maxindx=1;
        else
            maxindx=2;
        end
        parentI(j,h)=maxindx;
    end
end

%identify path end in the last column
[dfsfd,parentnode]=min(distI(:,size(Zgrad,2)));
parentI(parentnode,size(Zgrad,2))=0;

%trace shortest path back from last column
for h=(size(Zgrad,2)-1):-1:1
    parentnode=min(max(1,parentnode+parentI(parentnode,h)-2),size(Zgrad,1));
    parentI(parentnode,h)=0; %mark the path with zeros
end
%trim Zgrad to original size
Zgrad=Zgrad(:,2*size(ZI,2)+1:4*size(ZI,2));parentI=parentI(:,2*size(ZI,2)+1:4*size(ZI,2));

%imshow((parentI==0)+Zgrad,[]);pause(0.02);%
Zgrad= imresize(Zgrad,[size(Zgrad,1),size(Zgrad,2)/2],'nearest');
parentI= imresize(parentI,[size(parentI,1),size(parentI,2)/2],'nearest');
%transform back to original domanin
indpath=find(((parentI>0))==0);
[rPath,thetaPath]=ind2sub(size(Zgrad),indpath);
xpath=rPath.*cosd(thetaPath);
ypath=rPath.*sind(thetaPath);
%imshow(imresize(a,0.15),[]);hold on;plot(xpath+xPos,ypath+yPos,'r.');hold off;
% Don't modify what's not broken. You should see a nice
% contour around your droplet.
towrite=logical(0.*f);%
inxsds=(round(ypath+yPos)>0)&(round(xpath+xPos)>0)&(round(xpath+xPos)<size(towrite,2))&(round(ypath+yPos)<size(towrite,1));
towrite(sub2ind(size(towrite),round(ypath(inxsds)+yPos),round(xpath(inxsds)+xPos)))=1;
%towrite=bwmorph(towrite,'bridge');
towrite=imdilate(towrite,strelDisk2);
% towrite=bwmorph(towrite,'skel',Inf);
towrite=bwmorph(towrite,'thin',Inf);

if sum(sum(towrite)) == 0
    %considered an empty/faulty well
    region = NaN;
else
    
    region = imclearborder(~towrite,4);
    %clear any potential noise
    region = imopen(region, strelDisk3);
    % check for possible broken contour - if so, return convex area instead
    if bwarea(region) < 3000
        area = regionprops(towrite, 'ConvexImage', 'BoundingBox');
        if size(area,1) == 1
            x_left = round(area.BoundingBox(2));
            y_left = round(area.BoundingBox(1));
            x_next = round(area.BoundingBox(2)+area.BoundingBox(4)-1);
            y_next = round(area.BoundingBox(1)+area.BoundingBox(3)-1);
            region(x_left:x_next, y_left:y_next) = area.ConvexImage;
        else
            region = NaN;
        end
    end
end
    
