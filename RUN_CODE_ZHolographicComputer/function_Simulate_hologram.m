function [ Stack,info] = function_Simulate_hologram( varargin )
disp('3D Hologram simulation -> Now running')
%Format  function_Simulate_hologram( Hologram, Simulation*, Prop ** )
if numel(varargin) == 1
    Hologram = varargin{1};
    
    Simulation.XYresolution = 1;                      %Micrometers            desired imaging resolution for 3D stack reconstruction
    Simulation.DepthVec = linspace(-200,200,100);       %Vector micrometers     Depth levels requested for the reconstruction
    Simulation.XYRange =512;                          %Microns :              size of the Obeservation window
    Simulation.optionsave = 0;                        %0 1 2                  Set to 0 for nothing, 1 for saving stacks, 2 for saving stacks and rotating views
    Simulation.angles = linspace(0,90,100);           %vector of degrees :    angular range for rotating views
    Simulation.Name = '';                             %string                 Filename to save stack and rotating views
    disp('Warning : No simulation properties, we use DEFAULT')
    
    Prop.pixelsize = 20;                %Micrometers            Pixel size of the slm
    Prop.wavelength = 1.032;            %Micrometers            Focal length of the lens directly afther the SLM
    Prop.focalSLM = 200000;             %Micrometers            Focal length of the lens directly afther the SLM
    Prop.focalTubeLens = 200000;        %Micrometers            Focal length of the lens directly afther the SLM
    Prop.focalObjective = 10000;        %Micrometers            Focal length of the lens directly afther the SLM
    disp('Warning : No setup properties, we use DEFAULT')
elseif numel(varargin) == 2
    Hologram = varargin{1};
    Simulation = varargin{2};
    
    Prop.pixelsize = 20;                %Micrometers            Pixel size of the slm
    Prop.wavelength = 1.032;            %Micrometers            Focal length of the lens directly afther the SLM
    Prop.focalSLM = 200000;             %Micrometers            Focal length of the lens directly afther the SLM
    Prop.focalTubeLens = 200000;        %Micrometers            Focal length of the lens directly afther the SLM
    Prop.focalObjective = 10000;        %Micrometers            Focal length of the lens directly afther the SLM
    disp('Warning : No setup properties, we use DEFAULT')
    
else
    Hologram = varargin{1};
    Simulation = varargin{2};
    Prop = varargin{3};
end

RangeX = Prop.focalSLM*Prop.wavelength/(Prop.pixelsize);
disp(strcat('Holographic xy-span :',int2str(floor(RangeX*Prop.focalObjective/Prop.focalTubeLens)),' micrometers '))

[LX,LY] = size(Hologram);

Simulation.subsampling = (Prop.focalSLM*Prop.wavelength/(Prop.pixelsize))*(Prop.focalObjective/Prop.focalTubeLens)*1/(Simulation.XYresolution*LX);
info.paddingratio = Simulation.subsampling;

SubsampledHologram = zeros(floor(LX*Simulation.subsampling),floor(LY*Simulation.subsampling));
if Simulation.subsampling>1
HX = floor((LX*Simulation.subsampling-LX)/2)+1;
HY = floor((LY*Simulation.subsampling-LY)/2)+1;
SubsampledHologram(HX:HX+LX-1,HY:HY+LY-1) = Hologram;
info.SubsampledHologram = SubsampledHologram;
else
info.SubsampledHologram = Hologram;
SubsampledHologram = Hologram;   
end
[LX,LY] = size(SubsampledHologram);
UX = linspace(-RangeX/2,RangeX/2,LX); UY = linspace(-RangeX/2,RangeX/2,LY);

TransformedField = ifftshift(fft2(fftshift(SubsampledHologram)));
% UX UY are the corresponding true coordinates in microns at the SLM scale.

MUX = UX*Prop.focalObjective/Prop.focalTubeLens; MUY = UY*Prop.focalObjective/Prop.focalTubeLens;
% MUX MUY are the corresponding true coordinates in microns Under the microscope objective.

%Now crop the image to the desired window size to reduce image volume
if UX(1)> -Simulation.XYRange || UY(1)> -Simulation.XYRange
    disp('Unable to Restrict the observation window XYRange too big');
end
keepx = abs(MUX)<Simulation.XYRange; keepy =  abs(MUY)<Simulation.XYRange;
MUX = MUX(keepx); MUY = MUY(keepy);
psX = MUX(2)-MUX(1); psY = MUY(2)-MUY(1);
TransformedField = TransformedField(keepx,keepy);

disp('Digital refocusing -> Begins');
LZ = numel(Simulation.DepthVec);
[LLX,LLY] = size(TransformedField);
Stack = zeros(LLX,LLY,LZ);
for i =1:LZ
    [RefocusField] = function_propagate(TransformedField,Prop.wavelength,Simulation.DepthVec(i),psX,psY);
    Stack(:,:,i) = (RefocusField);
end
disp('Digital refocusing -> Completed');

if  Simulation.optionsave >=1
    disp('Digital refocusing -> Stacks Saved')
    savedata = (abs(Stack).^2);
    savedata = 255*savedata/max(savedata(:));
    savedata = uint8(savedata);
    saveastiff(savedata, strcat(Simulation.Name,'_1_Photon.tif'));
    savedata = (abs(Stack).^4);
    savedata = 255*savedata/max(savedata(:));
    savedata = uint8(savedata);
    saveastiff(savedata, strcat(Simulation.Name,'_2_Photon.tif'));
end

if  Simulation.optionsave ==2
    disp('Rotating stack projection -> Begins')
    LLP = 0;Projdata = {};
     NS = floor(numel(Simulation.angles));
    for ii = 1:NS
        aangle = Simulation.angles(ii) ;
        B = imrotate(squeeze(abs(Stack(:,:,i))),aangle);
        LP = numel(max(B'));
        Projection = zeros(LP,LZ);
        for i = 1:LZ
            B = imrotate(squeeze(abs(Stack(:,:,i))),aangle);
            Projection(:,i) = max(B');
        end
        Projdata{ii} = Projection;
        LLP = max(LLP,LP);
    end
    
    RotatingStack = zeros(LLP,LZ,numel(Simulation.angles));
   
    for ii = 1:NS
        frame = zeros(LLP,LZ);
        UU = Projdata{ii};
        [LP,LZ] = size(UU);
        beg = floor((LLP-LP)/2+1);
        frame(beg:beg+LP-1,:) =  UU;
        RotatingStack(:,:,ii) = frame;
    end
    disp('Rotating stack projection -> Completed')
    savedata = (RotatingStack.^2);
    savedata = 255*savedata/max(savedata(:));
    savedata = uint8(savedata);
    saveastiff(savedata, strcat(Simulation.Name,'Rotating_1_Photon.tif'));
    savedata = (RotatingStack.^4);
    savedata = 255*savedata/max(savedata(:));
    savedata = uint8(savedata);
    saveastiff(savedata, strcat(Simulation.Name,'Rotating_2_Photon.tif'));
    info.URX = psX*linspace(1,LLP,LLP);
    info.URZ = Simulation.DepthVec;
    info.RotatingStack = RotatingStack;
     disp('Rotating stack projection -> Stacks Saved')
     
end
info.UX = MUX;
info.UY = MUY;
info.UZ = Simulation.DepthVec;

disp('3D Hologram simulation -> My job is done !')
end

