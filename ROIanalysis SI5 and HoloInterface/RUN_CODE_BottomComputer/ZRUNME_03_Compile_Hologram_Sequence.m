clear all
close all
clc

ExperimentName = 'ExperimentEBis';
OnlyCenterDotHologram = 0; %1 for only centerdot hologram, 0 otherwise
Hologram.NCycles = 2;
parametres.OnlyCenterDotHologram = 0;

addpath('../');
[ Setup, SLM, NiDaq ] = Load_Parameters(0);
Objective = input('Enter the objective X number (4,10,16...) -->');
ZoomLevel = input('Enter the scope Zoom level (1,2,3...) -->');
load(strcat(Setup.CalibrationFolder,'\',int2str(Objective),'X_Objective_Calibration_LaserPower.mat'));
load(strcat(Setup.SLMFolder,'\ROIData.mat'));
load(strcat(Setup.CalibrationFolder,'\',int2str(Objective),'X_Objective_Zoom_',int2str(ZoomLevel ),'_XYZ_Calibration_Points.mat'));


% edited by Alan 6/29/15
if isfield(ImagesInfo,'ZStepSize') == 1;
NeuronData.StackSpacing = ImagesInfo.ZStepSize;
elseif isfield(ImagesInfo,'ZStepSize') == 0;
NeuronData.StackSpacing = 0;
display('Warning - no Zstep info - all images assumed to be in same plane')
end;

for zzz = 1:length(ROIdata.rois)
Zlevel.Slices(zzz)=ROIdata.rois(zzz).depth;
end;

Zlevel.Vector = NeuronData.StackSpacing*linspace(0,max(Zlevel.Slices)-1,max(Zlevel.Slices))

ROICount = numel(ROIdata.rois);
for i = 1:ROICount
    h = ROIdata.rois(i).vertices;
    [LA LB] = size(h);
    z = ROIdata.rois(i).depth;
    Zvalue = Zlevel.Vector(z)*ones(1,LA)';
    h = [h Zvalue];
    NeuronData.ROI{i} = h;
    NeuronData.EllipseZplane{i} = [z];
end

LLX = ImagesInfo.size(1);
LLY = ImagesInfo.size(2);


for j = 1:length(NeuronData.ROI)
AskPointList = NeuronData.ROI{j};
%Here we resize the alignement marks in case resolution has changed so the
%roi is scaled on the same scale as the calibration was done for
AskPointList(:,1) = AskPointList(:,1)*Setup.GalvoPX/LLX;
AskPointList(:,2) = AskPointList(:,2)*Setup.GalvoPY/LLY;
NeuronData.ROI{j} = AskPointList;
NeuronData.GETROI{j}  = function_3DCofC( AskPointList',XYZ_Points )';
end


 load(strcat(Setup.SLMFolder,'\listOfPossibleHolos.mat'));
[d, NumberOfStepsInSequence] = size( listOfPossibleHolos);

for i = 1:NumberOfStepsInSequence;
     disp(strcat('Now computing step #', int2str(i)))
Indices =  listOfPossibleHolos{i};
%Indices=Indices{1};
LH = length(Indices);
mymasks = {};
Z = {};
h = {}';
for vvvv = 1:numel(Indices)
h{vvvv} = NeuronData.GETROI{Indices(vvvv)};    
end

parametres.GetROIList = h;

[ Hologram,Mask] = function_ComputeHologram( parametres, SLM, Setup  );
Sequence.Hologram{i} = Hologram;

f = figure(1);
subplot(1,2,1)
pcolor(double(Hologram))
colormap gray
shading flat
pause(0.001)

subplot(1,2,2)
pcolor(double(Mask{1}))
colormap gray
shading flat
pause(0.001)

%saveas(f,strcat('phaseMask_',num2str(i),'.jpeg'))

end


CurrentSequence.ROI = NeuronData.ROI;

CurrentSequence.Hologram = Sequence.Hologram;
save(strcat(Setup.CalibrationFolder,'\CurrentSequence.mat'), 'CurrentSequence');
save(strcat(Setup.SLMFolder,'\CurrentSequence.mat'), 'CurrentSequence');


