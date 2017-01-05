clear all
close all
clc
%Make sure to commentout and activate the modifications
addpath('../');[ Setup, SLM, NiDaq ] = Load_Parameters(1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
parametres.NCycles = 1;
[filename, pathname] = uigetfile({'*.jpg'},'Pick A JPG file');
testname = 'test1';
 
 zeroZ = 65000;
 nframes =100;
 Z = linspace(-0,0,nframes);
 
 
 %Z=zeroZ;
 Z = Z+zeroZ;
 
f = imread(strcat(pathname,filename));
f = mean(f,3);
f = double(f);
f = f/max(max(f));
f = 1-f;
LLY = SLM.Y*SLM.subsampling;
LLX = SLM.X*SLM.subsampling;
f = imresize(f,[LLY,LLX]);
ReferenceImage = f;
PixelSize.X= (SLM.FocalFS*Setup.lambda/(SLM.pixelsizeX ))/LLX;
PixelSize.Y= (SLM.FocalFS*Setup.lambda/(SLM.pixelsizeY ))/LLY;
phase = 2*pi*rand(LLY,LLX);

[w,rect]=Screen('OpenWindow',SLM.ScreenID,[0 0 0]);
decision = 1;
commandwindow
 obj = videoinput('winvideo', 1);
counter = 1
 data = zeros(480,720,nframes);
 
for Zpick = Z 
for i = 1:parametres.NCycles
%First Defocus image
DefocusImage = function_propagate(ReferenceImage.*exp(1i*phase),Setup.lambda,Zpick,PixelSize.Y,PixelSize.X);
%Take FFT2 and keep angle
FourierPhaseMask = angle(fft2(fftshift(DefocusImage)));
%Compute Hologram
Hologram = (exp(1i*(fftshift(FourierPhaseMask))));
%Take Inverse FT
RealHologram = fftshift(ifft2(Hologram));
RefocusImage = function_propagate(RealHologram,Setup.lambda,-Zpick,PixelSize.Y,PixelSize.X);
%Update Phase
phase = angle(RefocusImage);
end    
    
bX = floor(LLX/2-SLM.X/2)+1;
bY = floor(LLY/2-SLM.Y/2)+1;
eX = bX+SLM.X-1;
eY = bY+SLM.Y-1;
%Scale down to SLM Size
Hologram = Hologram(bY:eY,bX:eX);
Hologram = uint8(SLM.Pixelmax*mod(angle(Hologram)/(2*pi),1));

%f = figure(1);
%pcolor(ReferenceImage);shading flat;title('Phase mask');axis image;



t = zeros(1,1);
 hhh = Hologram;
img = [hhh hhh hhh];
 t=Screen('MakeTexture',w,img);
Screen('DrawTexture', w, t);
Screen('Flip', w);
disp('Hologram ready and set on SLM')
pause(0.1)
commandwindow
frame = getsnapshot(obj);
data(:,:,counter) = sum(frame,3);
counter = counter+1
fff = figure(1)
image(frame)
pause(0.1)

end
Screen('Close',w)
clear('obj')

data = data-min(min(min(data)));
data = uint8(255*data/max(max(max(data))));

saveastiff(data,strcat(pathname,testname,'.tif'))
