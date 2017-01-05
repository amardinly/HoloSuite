clear all
close all
clc

%%Before running the code please adjust the properties in this section :
Hologram_DiskRadius = 5 ; %Unit is - 2Photon microscope pixels - 512 would be for the ful window (At selected zoom level);
%Set disk radius to 0 for diffraction limited hologram


Xrange = 200;    %Unit is - 2Photon microscope pixels - 512 would be for the ful window (At selected zoom level)
Yrange = 200;    %Unit is - 2Photon microscope pixels - 512 would be for the ful window (At selected zoom level)
Zrange = 20;    %In Microns
LX = 5;        %Number of datapoints
LY = 5;        %Number of datapoints
LZ = 2;        %Number of datapoints

%The number of holograms that will be compiled is LX*LY*LZ 
%The center of the grid pattern will be located at the center of the 


%Make sure to commentout and activate the modifications
addpath('../');[ Setup, SLM, NiDaq ] = Load_Parameters(0);
Objective = input('Enter the objective X number (4,10,16...) -->');
zoomlevel = input('Enter the scope Zoom level (1,2,3...) -->');
TwoPhotonImage_Size = 512;
load(strcat(Setup.CalibrationFolder,'\',int2str(Objective),'X_Objective_Zoom_',int2str(zoomlevel),'_XYZ_Calibration_Points.mat'));


if Hologram_DiskRadius == 0
    parametres.OnlyCenterDotHologram = 1;
else
    parametres.OnlyCenterDotHologram = 0;
end


parametres.NCycles = 2;

XExpansion = linspace(-Xrange/2,Xrange/2,LX); 
YExpansion =  linspace(-Yrange/2,Yrange/2,LY); %This will replicate all ROIs in space
ZExpansion =   linspace(-Zrange/2,Zrange/2,LZ); 


ROIPick = function_circle(TwoPhotonImage_Size/2,TwoPhotonImage_Size/2,Hologram_DiskRadius,30)';
UX = randperm(LX);
UY = randperm(LY);
UZ = randperm(LZ);
LN = LX*LY*LZ;
CurrentSequence.XYZ_Position = zeros(3,LN);

for j = 1:LX
for jj = 1:LY 
for jjj = 1:LZ
    
    counter = j+LX*(jj-1)+LX*LY*(jjj-1);
disp(strcat(int2str(counter),' -- of --' ,int2str(LN),', estimated time(s) = '));
ROI = ROIPick;
ROI(:,1) = ROI(:,1)+XExpansion(UX(j));
ROI(:,2) = ROI(:,2)+YExpansion(UY(jj));
ROI(:,3) = ROI(:,3)+ZExpansion(UZ(jjj));
CurrentSequence.XYZ_Position(:,counter) = [XExpansion(UX(j)) YExpansion(UY(jj)) ZExpansion(UZ(jjj))];
CurrentSequence.XYZ_Positionindex(:,counter) = [(UX(j)) (UY(jj)) (UZ(jjj))];
CurrentSequence.ROI = ROI;
GETROI  = function_3DCofC( ROI',XYZ_Points )';
%Addparameters here
parametres.GetROIList = {GETROI};
[ Hologram,Mask] = function_ComputeHologram( parametres, SLM, Setup  );
CurrentSequence.Hologram{counter} = Hologram;

end
end
end

save(strcat(Setup.CalibrationFolder,'\3DGRID_CurrentSequence.mat'), 'CurrentSequence');
save(strcat(Setup.SLMFolder,'\3DGRID_CurrentSequence.mat'), 'CurrentSequence');

