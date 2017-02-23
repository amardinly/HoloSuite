function [scores, diffefficiency ] = function_Evaluate_Holograms( Hologram, SLM, Setup,ExportMe)

diffefficiency = 0;
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

RealHologram = ifftshift(ifft2(ifftshift(Hologram)));

scores = linspace(0,0,numel(DepthVector));

for j = 1:numel(DepthVector);
RefocusImage = function_propagate(RealHologram,Setup.lambda,-DepthVector(j),PixelSize.Y,PixelSize.X);
%f = figure(1);
%subplot(1,2,1)
%imagesc(abs(RefocusImage.^2));
%subplot(1,2,2)
%imagesc(Mask{j});
%title(int2str(j));
%pause(0.1);

uu = double(Mask{j}>0).*abs(RefocusImage.^2);
uu = uu(:);
scores(j) = mean(uu(uu>0));
diffefficiency =  diffefficiency+sum(uu(uu>0)); % Sum of intensity that falls into masks aka power in area of interest
end

[LLA,LLB] = size(RealHologram);

diffefficiency =diffefficiency; % divided by unit intensity

end

