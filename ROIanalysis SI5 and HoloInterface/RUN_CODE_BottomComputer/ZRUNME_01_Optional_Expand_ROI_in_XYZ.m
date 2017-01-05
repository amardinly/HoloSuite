clear all
close all
clc
%Make sure to commentout and activate the modifications

XExpansion = [0 -10 10 -20 20 -30 30 -40 40 -50 50]; 
YExpansion = [0 10 20 -10 -20]; %This will replicate all ROIs in space
ZExpansion =  [0 -10 10 -20 20 -30 30 -40 40 -50 50 -60 60 -70 70 -80 80 -90 90 -100 100]; 
SaveFile = 0; %Set value to 1, if you'd like to edit the ROIFile and effectively Multiply the active list of ROIs
ExpName = 'FOV2_Neuron1';

addpath('../');[ Setup, SLM, NiDaq ] = Load_Parameters(0);
mypath = strcat(Setup.ResultsFolder,'\');
load(strcat(Setup.SLMFolder,'\ROIdata.mat'));

disp(strcat('Currently, you have selected ::',int2str(numel(ROIdata.rois)),':: ROIs'));
ID_Of_Neuron_To_Expand = input('Indicate the neuron number to expand (1,2,3...) -->');
SaveFile = input('This operation is irreversible, save ? (Yes:1, NO:0) -->');

LX = length(XExpansion);LY = length(YExpansion);LZ = length(ZExpansion);
LN = LX+LY+LZ;
Stackspacinginmicrons = ImagesInfo.ZStepSize;
TheROI = ROIdata.rois(ID_Of_Neuron_To_Expand);
NeuronData.StackSpacing = ImagesInfo.ZStepSize;

Zlevel.Slices=TheROI.depth;
Zlevel.Vector = NeuronData.StackSpacing*linspace(0,max(Zlevel.Slices)-1,max(Zlevel.Slices))
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


ROIS = NeuronData.ROI{1};
ZPlanes = NeuronData.EllipseZplane{1};
LT = length(ROIS);

for j = 1:LX
    ROI = ROIS;
ROI(:,1) = ROIS(:,1)+XExpansion(j);
NewROI{j} = ROI; 
Zplane = ZPlanes;
NewZplane{j} = Zplane;
end

for j = 1:LY
ROI = ROIS;    
ROI(:,2) = ROIS(:,2)+YExpansion(j);
NewROI{LX+j} = ROI; 
Zplane = ZPlanes;
NewZplane{LX+j} = Zplane;
end

for j = 1:LZ
ROI = ROIS;    
ROI(:,3) = ROIS(:,3)+ZExpansion(j);
NewROI{LX+LY+j} = ROI; 
Zplane = ZPlanes;
Zplane = Zplane+floor(ZExpansion(j)/Stackspacinginmicrons);
NewZplane{LX+LY+j} = Zplane;
end

NeuronData.EllipseZplane = NewZplane;
NeuronData.ROI = NewROI;


for j = 1 : length(NeuronData.ROI)
f = figure(1);

h = NeuronData.ROI{j};
scatter3(h(:,1),h(:,2),h(:,3));
hold on
v = mean(h);
text(v(1),v(2),v(3),int2str(j)) ;
end
zlabel('Z, \mu m, SUTTER')
xlabel('X, galvo pixel')
xlabel('Y, galvo pixel')

title('ROI (True axis from 2P image)')

savefig(f,strcat(mypath,ExpName,'_ExpandedXYZNeuronFigure.fig'));
saveas(f,strcat(mypath,ExpName,'_ExpandedXYZNeuronFigure.jpg'));

ROIREF = ROIdata.rois(1);
ROIdata.rois = ROIdata.rois(linspace(1,1,numel(NeuronData.ROI)));
for i = 1:numel(NeuronData.ROI)
h = NeuronData.ROI{i};
ROIREF.vertices = h(:,1:2);
ROIREF.depth = NewZplane{1};
ROIdata.rois(i) = ROIREF;
end

ROIdata.expansioninfo = 'The points are in this order : first, the X expansion, then Y, then Z for a total of LX+LY+LZ ROI '
ROIdata.expansionalongX = XExpansion;
ROIdata.expansionalongY = YExpansion;
ROIdata.expansionalongZ = ZExpansion;

if SaveFile == 1
save(strcat(Setup.SLMFolder,'\ROIdata.mat'),'ImagesInfo','ROIdata');
else
end