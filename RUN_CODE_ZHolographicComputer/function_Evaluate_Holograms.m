function [scores, diffefficiency ] = function_Evaluate_Holograms( Hologram, SLM, Setup,ExportMe)

[LLY,LLX] = size(ExportMe.Mask{1});
subsampling = LLY/SLM.Y;
bX = floor(LLX/2-SLM.X/2)+1;
bY = floor(LLY/2-SLM.Y/2)+1;
eX = bX+SLM.X-1;
eY = bY+SLM.Y-1;

Hologram = imresize(Hologram, subsampling, 'nearest' );

diffefficiency = 0;
DepthVector = ExportMe.Depth;
Mask = ExportMe.Mask;
Subsampling =  ExportMe.Subsampling;
RandomizePhase =  ExportMe.RandomizePhase;
ExcludeCenter = ExportMe.ExcludeCenter;

LLY = SLM.Y*Subsampling;LLX = SLM.X*Subsampling;
PixelSize.X= (SLM.FocalFS*Setup.lambda/(SLM.pixelsizeX ))/SLM.X;
PixelSize.Y= (SLM.FocalFS*Setup.lambda/(SLM.pixelsizeY ))/SLM.Y;
bX = floor(LLX/2-SLM.X/2)+1;
bY = floor(LLY/2-SLM.Y/2)+1;
eX = bX+SLM.X-1;
eY = bY+SLM.Y-1;

uu = angle(Hologram);
uu = SLM.Pixelmax*uu/(2*pi);
uu = 2*pi*double(floor(uu))/SLM.Pixelmax;
Hologram = abs(Hologram).*exp(1i*uu);

RealHologram = ifftshift(ifft2(ifftshift(Hologram)));
%disp(sum(sum(abs(Hologram.^2))));
%disp(sum(sum(abs(RealHologram.^2))));
scores = linspace(0,0,numel(DepthVector));

for j = 1:numel(DepthVector);
RefocusImage = function_propagate(RealHologram,Setup.lambda,-DepthVector(j),PixelSize.Y,PixelSize.X);
gatherarea = double(Mask{j}>0);
gatherarea = imgaussfilt(gatherarea, 2);
gatherarea = double(gatherarea>0);
gatherme = imresize(gatherarea, 1/subsampling );
gatherarea = zeros(LLY,LLX);
gatherarea(bY:eY,bX:eX)= gatherme;

%f = figure(1);
%subplot(2,2,1)
%imagesc(abs(RefocusImage.^2));
%subplot(2,2,2)
%imagesc(gatherarea);
%title(int2str(j));
%subplot(2,2,3)
%imagesc(abs(Hologram.^2));
%subplot(2,2,4)
%imagesc(angle(Hologram));
%pause(0.1);

% here add little bit of flexibility

uu = gatherarea.*abs(RefocusImage.^2);
uu = uu(:);
scores(j) = sum(uu(uu>0));
diffefficiency =  diffefficiency+sum(uu(uu>0)); % Sum of intensity that falls into masks aka power in area of interest
end

diffefficiency =diffefficiency/sum(abs(RealHologram(:).^2)); % divided by unit intensity
scores = scores/sum(abs(RealHologram(:).^2));

%disp(scores)
%disp(diffefficiency)


%gg = figure(6)
%plot(scores/sum(scores),'blue')
%hold on
%pause(0.1)

end

