clear all
close all
clc


%% Hologram Properties
NCycles = 2;
Objective = input('Enter the objective X number (4,10,16...) -->');
zoomlevel = input('Enter the scope Zoom level (1,2,3...) -->');
disp('--')
shrink = input('Enter ROI scaling factor from 0 to 1 (0 is full size ROI, 1 is a spot in the center)');
parametres.ShrinkFactorList = {shrink};
if shrink == 1; parameters.OnlyCenterDotHologram = 1; end
disp('--')
donut = input('Enter donut parameter from 0 to 1 (0 is for filled ROI, 1 is just the outer circle)');
parametres.DonutFactorList = {donut};
disp('--')
disp('Now you can exclude a disk in the center of the SLM to increase z resolution at the expense of power')
loworder = input('Enter the circle radius to exclude (in pixels 0...300), 0 means use full SLM');
parametres.ExcludeCenter = loworder;



addpath('../');[ Setup, SLM, NiDaq ] = Load_Parameters(0);
load(strcat(Setup.SLMFolder,'\ROIData.mat'));
load(strcat(Setup.CalibrationFolder,'\',int2str(Objective),'X_Objective_Zoom_',int2str(zoomlevel),'_XYZ_Calibration_Points.mat'));

NeuronData.StackSpacing = ImagesInfo.ZStepSize;
for zzz = 1:length(ROIdata.rois)
Zlevel.Slices(zzz)=ROIdata.rois(zzz).depth;
end;
Zlevel.Vector = NeuronData.StackSpacing*linspace(0,max(Zlevel.Slices)-1,max(Zlevel.Slices));
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
end







[w,rect]=Screen('OpenWindow',SLM.ScreenID,[0 0 0]);
decision = 1;
while decision == 1
commandwindow    
disp(strcat('Currently, you have selected ::',int2str(numel(NeuronData.ROI)),':: ROIs'));
disp('Indicate the neuron number or list (e.g.[1,4,5]) you would like to have on SLM from the current ROI database')    
h = input('Pick a number or enter a hologram list? ');
disp(strcat('SLM Max Pixel = ',int2str(SLM.Pixelmax)))    
disp('Delta X >0  makes hologram move down on camera, or right on 2P image')
disp('Delta Y >0  makes hologram move To the right on camera, or up on 2P image')    
disp('Z Positive makes hologram closer to objective, 0 is 2p imaging focal distance')
DeltaX =  input('Pick DeltaX in microns ');
DeltaY =  input('Pick DeltaY in microns ');
DeltaZ =  input('Pick DeltaZ in microns ');
%SLM.Pixelmax = input('New SLM Max Pixel Value');


for iii = 1:numel(h)
ROI = NeuronData.ROI{h(iii)};
ZPlane = NeuronData. EllipseZplane{h(iii)};
NewROI= ROI; 
NewROI(:,1) = ROI(:,1)+DeltaX ;
NewROI(:,2) = ROI(:,2)+DeltaY ;
NewROI(:,3) = ROI(:,3)+DeltaZ ;
NewZplane = ZPlane+floor(DeltaZ/NeuronData.StackSpacing);
GETROI{iii}  = function_3DCofC( NewROI',XYZ_Points )';
end
%Addparameters here
parametres.GetROIList = GETROI;
   
 [ Hologram,Mask] = function_ComputeHologram( parametres, SLM, Setup  );


f = figure(1);
subplot(1,2,1);pcolor(double(Hologram));shading flat;title('Phase mask');axis image;
maskref = Mask{1}-Mask{1}; for jjji = 1:numel(Mask); maskref = max(maskref,Mask{jjji}); end;
subplot(1,2,2); pcolor(double(maskref));shading flat;title('Targeted ROIs');axis image;


t = zeros(1,1);
 hhh = Hologram;
img = [hhh hhh hhh];
 t=Screen('MakeTexture',w,img);
Screen('DrawTexture', w, t);
Screen('Flip', w);
disp('Hologram ready and set on SLM')
disp(strcat('DeltaX = ',num2str(DeltaX)));
disp(strcat('DeltaY = ',num2str(DeltaY)));
disp(strcat('DeltaZ  = ',num2str(DeltaZ)));

commandwindow
pause(0.1)
20

decision = input('type 1 to move hologram to different position, 0 to exit ');
end
Screen('Close',w)





break;



