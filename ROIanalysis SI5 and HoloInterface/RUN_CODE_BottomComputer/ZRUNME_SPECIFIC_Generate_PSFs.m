clear all
close all
clc
%Make sure to commentout and activate the modifications
addpath('../');[ Setup, SLM, NiDaq ] = Load_Parameters(1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



[w,rect]=Screen('OpenWindow',SLM.ScreenID,[0 0 0]);
decision = 1;
parametres.NCycles = 3;
commandwindow
while decision == 1
parametres.OnlyCenterDotHologram = input('type 1 for diffraction limited spot, or 0 for ROIS ->>>');
parameters.ROIradius = input('enter the roi radius fom 0 to 0.5 in window scale ->>>');
donut = input('enter a number from 0 (full roi) to 1 (just circle) for DONUT factor ->>>');
parametres.DonutFactorList = {donut};
parametres.ExcludeCenter = input('enter radius in pixels for the area to exclude on SLM cneter ->>>');

t = 0:pi/60:2*pi;
R0 =parameters.ROIradius; x0 = 0.5; y0 = 0.5;
xi = R0*cos(t)+x0;
yi = R0*sin(t)+y0;
ROI = [xi; yi; yi-yi];
parametres.GetROIList = {ROI'};  
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
pause(0.1)

decision = input('type 1 to move hologram to different position, 0 to exit ');
end
Screen('Close',w)


