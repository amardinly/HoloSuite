clear all
close all
clc
%Make sure to commentout and activate the modifications
addpath('../');[ Setup, SLM, NiDaq ] = Load_Parameters(0);
Objective = input('Enter the objective X number (4,10,16...) -->');
zoomlevel = input('Enter the scope Zoom level (1,2,3...) -->');

load(strcat(Setup.CalibrationFolder,'\',int2str(Objective),'X_Objective_Zoom_',int2str(zoomlevel),'_XYZ_Calibration_Points.mat'));

parametres.OnlyCenterDotHologram = 1;
parametres.NCycles = 1;

Xrange = 20;
Yrange = 20;
Zrange = 20;
LX = 20;
LY = 20;
LZ = 20;

XExpansion = linspace(-Xrange/2,Xrange/2,LX); 
YExpansion =  linspace(-Yrange/2,Yrange/2,LY); %This will replicate all ROIs in space
ZExpansion =   linspace(-Zrange/2,Zrange/2,LZ); 
SaveFile = 0; %Set value to 1, if you'd like to edit the ROIFile and effectively Multiply the active list of ROIs
ExpName = 'FOV2_Neuron1';


mypath = strcat(Setup.ResultsFolder,'\');
load(strcat(Setup.SLMFolder,'\ROIdata.mat'));

disp(strcat('Currently, you have selected ::',int2str(numel(ROIdata.rois)),':: ROIs'));
ID_Of_Neuron_To_Expand = input('Indicate the neuron ID of patched cell -->');

LX = length(XExpansion);LY = length(YExpansion);LZ = length(ZExpansion);

TheROI = ROIdata.rois(ID_Of_Neuron_To_Expand);
NeuronData.StackSpacing = ImagesInfo.ZStepSize;

Zlevel.Slices=TheROI.depth;
Zlevel.Vector = NeuronData.StackSpacing*linspace(0,max(Zlevel.Slices)-1,max(Zlevel.Slices));
h = ROIdata.rois(ID_Of_Neuron_To_Expand).vertices;
[LA LB] = size(h);
z = ROIdata.rois(ID_Of_Neuron_To_Expand).depth;
Zvalue = Zlevel.Vector(z)*ones(1,LA)';
h = [h Zvalue];
NeuronData.ROI{1} = h;
NeuronData.EllipseZplane{1} = [z];
LLX = ImagesInfo.size(1);
LLY = ImagesInfo.size(2);
AskPointList = NeuronData.ROI{1};
AskPointList(:,1) = AskPointList(:,1)*Setup.GalvoPX/LLX;
AskPointList(:,2) = AskPointList(:,2)*Setup.GalvoPY/LLY;
NeuronData.ROI{1} = AskPointList;
ROIPick = NeuronData.ROI{1};
totalholo = LX*LY*LZ;
counter = 0
tic
UX = randperm(LX);
UY = randperm(LY);
UZ = randperm(LZ);
LN = LX*LY*LZ;

for j = 1:LX
for jj = 1:LY 
for jjj = 1:LZ
    
    ttt = toc;
    tic
    counter = j+LX*(jj-1)+LX*LY*(jjj-1);
disp(strcat(int2str(counter),' -- of --' ,int2str(totalholo),', estimated time(s) = ',int2str(totalholo*ttt)));
ROI = ROIPick;
ROI(:,1) = ROI(:,1)+XExpansion(UX(j));
ROI(:,2) = ROI(:,2)+YExpansion(UY(jj));
ROI(:,3) = ROI(:,3)+ZExpansion(UZ(jjj));
CurrentSequence.XYZ_Position{counter} = [XExpansion(UX(j)) YExpansion(UY(jj)) ZExpansion(UZ(jjj))];
CurrentSequence.ROI = ROI;
GETROI  = function_3DCofC( ROI',XYZ_Points )';
%Addparameters here
parametres.GetROIList = {GETROI};
[ Hologram,Mask] = function_ComputeHologram( parametres, SLM, Setup  );
CurrentSequence.Hologram{counter} = Hologram;

end
end
end
toc

save(strcat(Setup.CalibrationFolder,'\3DGRID_CurrentSequence.mat'), 'CurrentSequence');
save(strcat(Setup.SLMFolder,'\3DGRID_CurrentSequence.mat'), 'CurrentSequence');

