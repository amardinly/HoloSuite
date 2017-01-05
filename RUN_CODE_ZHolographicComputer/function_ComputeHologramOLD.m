function [ Hologram,Mask] = function_ComputeHologram( parametres, SLM, Setup)
%Here we define default parameters in case nothing is specified
GetROIList = {[0.560530576659609,0.500000000000000,0;0.559592818533721,0.510590239457498,0;0.556806058846460,0.520865980877410,0;0.552249568434543,0.530520327085120,0;0.546054414151201,0.539261884224848,0;0.538401453108724,0.546823094192926,0;0.529517802395829,0.552968893258136,0;0.519671417198286,0.557505257535189,0;0.509163455274516,0.560287073310182,0;0.498318595092789,0.561224489795918,0;0.487473734911061,0.560287073310182,0;0.476965772987292,0.557505257535189,0;0.467119387789748,0.552968893258136,0;0.458235737076853,0.546823094192926,0;0.450582776034376,0.539261884224848,0;0.444387621751035,0.530520327085120,0;0.439831131339117,0.520865980877410,0;0.437044371651856,0.510590239457498,0;0.436106613525968,0.500000000000000,0;0.437044371651856,0.489409760542502,0;0.439831131339117,0.479134019122590,0;0.444387621751035,0.469479672914879,0;0.450582776034376,0.460738115775152,0;0.458235737076853,0.453176905807074,0;0.467119387789748,0.447031106741864,0;0.476965772987292,0.442494742464811,0;0.487473734911061,0.439712926689818,0;0.498318595092789,0.438775510204082,0;0.509163455274516,0.439712926689818,0;0.519671417198286,0.442494742464811,0;0.529517802395829,0.447031106741864,0;0.538401453108724,0.453176905807073,0;0.546054414151201,0.460738115775152,0;0.552249568434543,0.469479672914879,0;0.556806058846460,0.479134019122590,0;0.559592818533721,0.489409760542502,0;0.560530576659609,0.500000000000000,0]};               %List of ROIS to target (0.5 is center, 0 is zero depth)
NCycles = 2;                                %Number of cycles for hologram Computation
OnlyCenterDotHologram = 0;                  %Options for CenterDot Hologram
RandomizePhase = 1;                         %Random phase mask in the computation method
Subsampling  = SLM.subsampling;             %Default Subsmampling as specified in load parameters file
ExcludeCenter =0;                           %Between 0 and 1, fraction of center pixels to block directly on SLM
ShrinkFactorList ={0};                      %Between 0 and 1, Reduction factor of ROI 0 is full size, 1 is shrinked
DonutFactorList ={0};                       %Between 0 and 1, closer to 1 is a Donut.
CentroidDiameter = {};                      %A circle, in units of SLM_SIZE
DiffSpotsList = {};                         %Number of diffraction limited spots per ROI
ApplyPattern = 0;                           %Apply a physical pattern to the mask
displaydetails = 1;                         %Turn to 1 to display details about holograms being compiled

%Assign available parameters if any
try GetROIList  =parametres.GetROIList; catch;end;
try NCycles  =parametres.NCycles; catch;end;
try RandomizePhase  = parametres.RandomizePhase; catch; end;
try OnlyCenterDotHologram  = parametres.OnlyCenterDotHologram; catch; end;
try Subsampling  = parametres.Subsampling; catch; end;
try ExcludeCenter  = parametres.ExcludeCenter; catch; end;
try ShrinkFactorList  = parametres.ShrinkFactorList; catch; end;
try DonutFactorList  = parametres.DonutFactorList; catch; end;
try CentroidDiameter = parametres.CentroidDiameter; catch; end;
try ApplyPattern  = parametres.ApplyPattern ; catch; end;
try DiffSpotsList  = parametres.DiffSpotsList ; catch; end;
try displaydetails  = parametres.displaydetails ; catch; end;
try u = parametres.nDLS; n = numel(GetROIList); for i = 1:n; DiffSpotsList{i} = u;  end; catch; end;





%display what is going on
if displaydetails == 1
    disp(['Now compiling hologram'])
    disp(['Number of cycles = ' int2str(NCycles)]);
    disp(['Number of ROI in hologram = ' int2str(numel(GetROIList))]);
    if OnlyCenterDotHologram == 1 ; disp(['Request : Diffraction Limited Spot on each ROI']);
    elseif numel(DiffSpotsList)>0 ; disp(['Request : Diffraction limited spot(s) on edges of ROI']);
    else disp(['Request : Area_Hologram']);
    end
    if OnlyCenterDotHologram == 0;
        disp(['Details : Shrink, donut, or centroid apply, if any']);
    end
end



DepthVector = linspace(0,0,numel(GetROIList));
for i = 1:numel(GetROIList)
    DepthVector(i) = mean(GetROIList{i}(:,3));
end
[DepthVector,b] = sort(DepthVector);
NewROIList = {};
for i = 1:numel(GetROIList)
    NewROIList{i}= GetROIList{b(i)};
end
GetROIList = NewROIList;
%disp(strcat('Computing hologram :',information));
LLY = SLM.Y*Subsampling;LLX = SLM.X*Subsampling;
PixelSize.X= (SLM.FocalFS*Setup.lambda/(SLM.pixelsizeX ))/LLX;
PixelSize.Y= (SLM.FocalFS*Setup.lambda/(SLM.pixelsizeY ))/LLY;

for ii = 1:numel(GetROIList)
    ROI = GetROIList{ii};
    try ShrinkFactor = ShrinkFactorList{ii}; catch ShrinkFactor = ShrinkFactorList{1}; end
    try DonutFactor = DonutFactorList{ii}; catch DonutFactor = DonutFactorList{1}; end
    if numel(CentroidDiameter) == 0; else;
        try CentroidDiam = CentroidDiameter{ii}; catch  CentroidDiam = CentroidDiameter{1}; end;
    end
    
    [LN,~] = size(ROI);
    %Case of Only cente dot holgorams
    
    
    if LN ==1 || OnlyCenterDotHologram == 1;
        
        if LN == 1; center = ROI; else center = mean(ROI); end;
        Centers{ii} = center;
        TheMask = zeros(LLY,LLX);
        if center(2)<0 ||center(2)>1||center(1)<0 ||center(1)>1
            disp('(((WARNING Requested diffraction limited spot is out of physical range)))')
        else
            TheMask(round(LLY*center(2)),round(LLX*center(1)))=1;
        end
        Mask{ii} = TheMask;
        
        
%         if numel(DiffSpotsList)==1
%             Mask{ii} =   function_Make_mask_Random(LLX,LLY,ROI,DiffSpotsList{1},Subsampling,SLM);
%             disp('DLS on edge hologram')
%         elseif numel(DiffSpotsList)>1
%             Mask{ii} =   function_Make_mask_Random(LLX,LLY,ROI,DiffSpotsList{ii},Subsampling,SLM);
%             disp('DLS on edge hologram')
%         else
%             disp('Not a multiple DLS type hologram')
%         end
%         
        
        
        %Case of full Area holograms
    else
        center = mean(ROI);Centers{ii} = center;
        
        if numel(CentroidDiameter) == 0;
            for i = 1:LN;ROI(i,1:2) = ShrinkFactor*center(1:2)+(1-ShrinkFactor)*ROI(i,1:2);end;
        else;   theangle = linspace(0,2*pi,LN);
            for i = 1:LN;ROI(i,1) = center(1)+CentroidDiam*cos(theangle(i));ROI(i,2) = center(2)+CentroidDiam*sin(theangle(i));end;
        end
        
        InnerROI = ROI;
        if min(ROI(:,1))<0 ||min(ROI(:,2))<0||max(ROI(:,2))<0 ||max(ROI(:,1))>1
            disp('(((WARNING some points of the Requested ROI is out of physical range)))')
        end
        TheMask=poly2mask( LLX*ROI(:,1),LLY*(ROI(:,2)),Subsampling*SLM.Y, Subsampling*SLM.X);
        EdgeMask = 0;
        
        if DonutFactor>0;
            for i = 1:LN
                InnerROI(i,1:2) = (1-DonutFactor)*center(1:2)+(DonutFactor)*ROI(i,1:2);
            end
            InnerMask=poly2mask( LLX*InnerROI(:,1),LLY*(InnerROI(:,2)),Subsampling*SLM.Y, Subsampling*SLM.X);
            TheMask=TheMask-InnerMask;
        end
        
        
        Mask{ii}=TheMask;
        
    end
    
end

%At this point, we have generated N masks, Mask{ii} organized in
%sorted DepthVector now we can merge them by depth
category = 1; zlevel = DepthVector(1);
ShortDepthVector(category) = zlevel; ShortMask{category} = Mask{1};
if numel(GetROIList)>=2
    for ii = 2:numel(GetROIList)
        if DepthVector(ii)>zlevel
            category = category+1;
            ShortMask{category} =  Mask{ii};
            ShortDepthVector(category) = DepthVector(ii);
            zlevel = DepthVector(ii);
        else
            ShortMask{category} = ShortMask{category}+ Mask{ii};
        end
    end
end

Mask = {};
DepthVector = ShortDepthVector;
Mask = ShortMask;
if displaydetails == 1; disp(strcat('We have extracted a solution in - ',int2str(numel(ShortDepthVector)),'- Masks')); end;


%%%%%%%%%%%%%%%%%%%%%%%%%%
%Here, secondary step-- Apply patterning ot the masks
if ApplyPattern == 1;
    %do apply patterns here
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%


if numel(Mask) == 1
    
    phase = 2*pi*RandomizePhase*rand(LLY,LLX);
    
    Z = DepthVector(1);
    for i = 1:NCycles
        %First Defocus image
        DefocusImage = function_propagate(Mask{1}.*exp(1i*phase),Setup.lambda,Z,PixelSize.Y,PixelSize.X);
        %Take FFT2 and keep angle
        FourierPhaseMask = angle(fft2(fftshift(DefocusImage)));
        %Compute Hologram
        Hologram = (exp(1i*(fftshift(FourierPhaseMask))));
        %Take Inverse FT
        RealHologram = fftshift(ifft2(Hologram));
        RefocusImage = function_propagate(RealHologram,Setup.lambda,-Z,PixelSize.Y,PixelSize.X);
        %Update Phase
        phase = angle(RefocusImage);
    end
    
    %Now Resize Hologram
    bX = floor(LLX/2-SLM.X/2)+1;
    bY = floor(LLY/2-SLM.Y/2)+1;
    eX = bX+SLM.X-1;
    eY = bY+SLM.Y-1;
    %Scale down to SLM Size
    Hologram = Hologram(bY:eY,bX:eX);
    DisplayMask = Mask{1};
else
    
    %%%%%%%%%%%%%%%%%%%%%%%%%
    %Now treat the case where hologram are of multiple locations
    for iiii = 1:numel(Mask)
        if RandomizePhase == 1
            phase = 2*pi*rand(LLY,LLX);
        else
            phase = zeros(LLY,LLX);
        end
        Z = DepthVector(iiii);
        for i = 1:NCycles
            %First Defocus image
            DefocusImage = function_propagate(Mask{iiii}.*exp(1i*phase),Setup.lambda,Z,PixelSize.Y,PixelSize.X);
            %Take FFT2 and keep angle
            FourierPhaseMask = angle(fft2(fftshift(DefocusImage)));
            %Compute Hologram
            Hologramtemp = (exp(1i*(fftshift(FourierPhaseMask))));
            %Take Inverse FT
            RealHologram = fftshift(ifft2(Hologramtemp));
            RefocusImage = function_propagate(RealHologram,Setup.lambda,-Z,PixelSize.Y,PixelSize.X);
            %Update Phase
            phase = angle(RefocusImage);
        end
        
        %Now Resize Hologram
        bX = floor(LLX/2-SLM.X/2)+1;
        bY = floor(LLY/2-SLM.Y/2)+1;
        eX = bX+SLM.X-1;
        eY = bY+SLM.Y-1;
        %Scale down to SLM Size
        Hologramtemp = Hologramtemp(bY:eY,bX:eX);
        TheHolos{iiii} = Hologramtemp;
    end
    Hologram = Hologramtemp-Hologramtemp;
    
    for iiii = 1:numel(Mask)
        Hologram = Hologram+ TheHolos{iiii};
    end
    %Come up with a better method !!
    %%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Display Mask is just the mask
    DisplayMask =  Mask{1};
    for j = 2:numel(Mask)
        DisplayMask = DisplayMask+Mask{j};
    end
end

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

