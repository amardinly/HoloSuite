function [ Hologram, Mask ] = function_compileHologram( parametres, SLM, Setup,XYZ_Points,ImagesInfo,ROIdata,PickROIS,holoRequest)


if isfield(ImagesInfo,'ZStepSize') == 1;
     NeuronData.StackSpacing = ImagesInfo.ZStepSize;
    if isnan(NeuronData.StackSpacing)
        NeuronData.StackSpacing=0;
    end
elseif isfield(ImagesInfo,'ZStepSize') == 0;
NeuronData.StackSpacing = 0;
%display('Warning - no Zstep info - all images assumed to be in same plane')
end;
for zzz = 1:length(ROIdata.rois)
Zlevel.Slices(zzz)=ROIdata.rois(zzz).depth;
end;
Zlevel.Vector=ImagesInfo.ZVector;
%Zlevel.Vector = NeuronData.StackSpacing*linspace(0,max(Zlevel.Slices)-1,max(Zlevel.Slices));

GETROI = {};
for iii = 1:numel(PickROIS)
hh = ROIdata.rois(PickROIS(iii)).vertices;
[LA LB] = size(hh);
z = ROIdata.rois(PickROIS(iii)).depth;
Zvalue = Zlevel.Vector(z)*ones(1,LA)';
NewROI= [hh Zvalue]; 
NewROI(:,1) = NewROI(:,1)+holoRequest.xoffset;
NewROI(:,2) = NewROI(:,2)+holoRequest.yoffset;
NewROI(:,3) = NewROI(:,3)+holoRequest.zoffset;
GETROI{iii}  = function_3DCofC( NewROI',XYZ_Points )';
end
parametres.GetROIList = GETROI;
[ Hologram,Mask] = function_ComputeHologram( parametres, SLM, Setup  );


end

