
function [ Hologram, DiffractionEfficiency ] = function_Better_Holograms( SLM, Setup,ExportMe)

NCycles = Setup.Ncycles;

DepthVector = ExportMe.Depth;
Mask = ExportMe.Mask;
Subsampling =  ExportMe.Subsampling;
RandomizePhase =  ExportMe.RandomizePhase;
ExcludeCenter = ExportMe.ExcludeCenter;

LLY = SLM.Y*Subsampling;LLX = SLM.X*Subsampling;
PixelSize.X= (SLM.FocalFS*Setup.lambda/(SLM.pixelsizeX ))/LLX;
PixelSize.Y= (SLM.FocalFS*Setup.lambda/(SLM.pixelsizeY ))/LLY;
bX = floor(LLX/2-SLM.X/2)+1;
bY = floor(LLY/2-SLM.Y/2)+1;
eX = bX+SLM.X-1;
eY = bY+SLM.Y-1;


GaussianBase=imresize(SLM.GaussianBase, [LLY,LLX]);

%Initial construct :
if RandomizePhase == 1;     phase = 2*pi*rand(LLY,LLX); else;phase = zeros(LLY,LLX);end;
dZ = diff(DepthVector);
Holostart = Mask{1}.*exp(1i*phase);
for i = 1:numel(dZ)
Holostart = function_propagate(Holostart,Setup.lambda,-dZ(i),PixelSize.Y,PixelSize.X); 
Holostart = Holostart+Mask{i+1}.*exp(1i*phase);
end
Holostart = function_propagate(Holostart,Setup.lambda,DepthVector(end),PixelSize.Y,PixelSize.X);  
FourierPhaseMask = angle(fft2(fftshift(Holostart)));
Hologramtemp = GaussianBase.*(exp(1i*(fftshift(FourierPhaseMask))));

for jjj = 1:NCycles
[scores, DE ] = function_Evaluate_Holograms( Hologramtemp, SLM, Setup,ExportMe); 

DiffractionEfficiency.DE{jjj} = DE;
scores = scores / sum(scores);
DiffractionEfficiency.scores{jjj} = scores;
request = (ExportMe.GetpowerMultiplier/sum(ExportMe.GetpowerMultiplier));
DiffractionEfficiency.request{jjj} = request;
Adjustments = request./scores;
RealHologram = ifftshift(ifft2(ifftshift(Hologramtemp)));
RefocusImage = function_propagate(RealHologram,Setup.lambda,-DepthVector(1),PixelSize.Y,PixelSize.X);
%ggg= figure(4);imagesc(abs(RefocusImage));pause(1)
RefocusImage = function_Adjust_Amplitude(RefocusImage,Mask{1},Adjustments(1));
for i = 1:numel(dZ)
RefocusImage = function_propagate(RefocusImage,Setup.lambda,-dZ(i),PixelSize.Y,PixelSize.X); 
RefocusImage = function_Adjust_Amplitude(RefocusImage,Mask{i+1},Adjustments(i+1));
%imagesc(abs(RefocusImage));pause(1)
end
Holostart = function_propagate(RefocusImage,Setup.lambda,DepthVector(end),PixelSize.Y,PixelSize.X);  
FourierPhaseMask = angle(fft2(fftshift(Holostart)));
Hologramtemp = GaussianBase.*(exp(1i*(fftshift(FourierPhaseMask))));
end


Hologram = Hologramtemp(bY:eY,bX:eX);



%Now removing low order light by scrambling circle on SLM
if ExcludeCenter>0
    [LLLX,LLLY] = size(Hologram);
    cx=round(LLLX/2);cy=round(LLLY/2);ix=LLLX;iy=LLLY;r=ExcludeCenter;
    [x,y]=meshgrid(-(cx-1):(ix-cx),-(cy-1):(iy-cy));
    c_mask=((x.^2+y.^2)<=r^2);
    
    themaskcut = double(c_mask)';
    themaskkeep = 1-double(c_mask)';
    Hologram =  (themaskkeep.*Hologram)+(themaskcut.*exp(1i*2*pi*rand(LLLX,LLLY)));
else
end

%Now converting hologram complex format to real format
Hologram = uint8(SLM.Pixelmax*mod(angle(Hologram)/(2*pi),1));


end