function rect = plotBoundingBox(optotuneDepths,zoom)

% returns rect- a m x n matrix where m is the number of optotune depths
% asked for, and n is 4 element bounding of a rectangel where for a given
% optotune depth N % rect(n,1) = minX, rect(n,2) = minY, rect(n,3)= maxX,
% and rect(n,4) = maxY;

%path to interpolant will have to be zoom dependent...default if not
%specified will load zoom 1.5

%% Check Input Args and make full path to interpolant
if any(optotuneDepths>50) || any(optotuneDepths<0)
    errordlg('Specifiy optotune depth between 0 and 50, you hampster faced butt')
    return;
end

if nargin==1;
    %defaults = load zoom 1.5
    fullPathToInterpolant='Z:\holography\Calibration Parameters\20X_Objective_Zoom_15_XYZ_Calibration_PointsOPTOTUNE.mat';
    
elseif nargin==2
    
    %change 1.5 to 15, etc
    if mod(zoom,1)>0;
        zoom=zoom*10;
    end
    
    fullPathToInterpolant=['Z:\holography\Calibration Parameters\20X_Objective_Zoom_' num2str(zoom) '_XYZ_Calibration_PointsOPTOTUNE.mat'];
   
else
    errordlg('too many input arguments, asshole');
    return;
    
end
%% Load Interpolation points (XYZ)
load(fullPathToInterpolant)

% XYZ_Calibration.RX = 0.75;
% XYZ_Calibration.RY = 0.75;
% XYZ_Calibration.CX = 0.54; 
% XYZ_Calibration.CY = .45;
% 
% XYZ_Calibration.BZ = -60000; %-40000; %Range in depth for testing purposes (This is the natural SLM coordinates)
% XYZ_Calibration.EZ = 60000; % 40000; %Range in depth for testing purposes (This is the natural SLM coordinates)
% 

% Code Based On Nicos idea that doesnt work 
% % SLMminX=min(XYZ_Points.GET.X);
% % SLMmaxX=max(XYZ_Points.GET.X);
% % SLMminY=min(XYZ_Points.GET.Y);
% % SLMmaxY=max(XYZ_Points.GET.Y);
% % 
% % for j=1:numel(optotuneDepths)
% % SLMPOINT=function_3DCofC([256 256 optotuneDepths(j)]',XYZ_Points);  %takes location in Real Units and Returns SLM units
% % SLMZlevel(j)=SLMPOINT(3);
% % end
% % 
% % 
% % ReversePoints.ASK=XYZ_Points.GET;
% % ReversePoints.GET=XYZ_Points.ASK;
% % 
% % for j = 1:numel(optotuneDepths)
% % 
% %     A=round(function_3DCofC([SLMminX SLMminY SLMZlevel(j)]',ReversePoints,5));  %takes location in Real Units and Returns SLM units
% %     rect(j,1:2)=A(1:2);
% %     
% %     A=round(function_3DCofC([SLMmaxX SLMmaxY SLMZlevel(j)]',ReversePoints,5));  %takes location in Real Units and Returns SLM units
% %     rect(j,3:4)=A(1:2); 
% % end

%code based on Alan's stupid Idea that does work

U=[XYZ_Points.ASK.X XYZ_Points.ASK.Y XYZ_Points.ASK.Z];
UniqZ=unique(U(:,3));
for j = 1:numel(UniqZ);
   thesePoints=U(find(U(:,3)==UniqZ(j)),1:2);
   r(j,:)=[min(thesePoints(:,1)) min(thesePoints(:,2)) max(thesePoints(:,1)) max(thesePoints(:,2))];
end

for j = 1:numel(optotuneDepths)
   [sorted indx]= sort(abs(UniqZ-optotuneDepths(j)));
    
   if optotuneDepths(j)>2;
     A=1./r(indx(1),:);

     B=1./r(indx(2),:);
     
     
     %take inverse weighted average of neighboring planes above and below,
     %the higher weight going to the closer plane
     rect(j,:)=  1./  (mean([A*sorted(1); B*sorted(2)]) /  mean([sorted(1) sorted(2)]));
     
     
       
   else
       
       rect(j,:)=r(indx(1),:);
       
   end

 


end


rect(:,3:4)=rect(:,3:4)-rect(:,1:2);


%Cdoe based on a REALLY stupid Alan idea that DOES Work

% %for j=1:numel(optotuneDepths)
%     currentX=0;
%     currentY=0;
%     SLMPOINT=[0 0 0];
%     
%     while SLMPOINT(1)<SLMminX
%         
%         SLMPOINT=function_3DCofC([currentX currentY optotuneDepths(j)]',XYZ_Points);  %takes location in Real Units and Returns SLM units
%         currentX=currentX+1;
%         
%     end
%     
%     rect(j,1)=currentX;
%     
%     
%     currentY=0;
%     SLMPOINT=[0 0 0];
%     
%     while SLMPOINT(2)<SLMminY
%         
%         SLMPOINT=function_3DCofC([rect(1) currentY optotuneDepths(j)]',XYZ_Points);  %takes location in Real Units and Returns SLM units
%         %currentX=currentX+1;
%         currentY=currentY+1;
%         
%     end
%     
%     
%     rect(j,2)=currentY;
%     
%     
%     
%     
%     currentX=512;
%     currentY=512;
%     SLMPOINT=[1 1 1];
%     while SLMPOINT(1)>SLMmaxX
%         
%         SLMPOINT=function_3DCofC([currentX currentY optotuneDepths(j)]',XYZ_Points);  %takes location in Real Units and Returns SLM units
%         currentX=currentX-1;
%         
%     end
%     
%     rect(j,3)=currentX;
%     
%     
%     
%     currentY=512;
%     SLMPOINT=[1 1 1];
%     while SLMPOINT(2)>SLMmaxY
%         
%         SLMPOINT=function_3DCofC([currentX currentY optotuneDepths(j)]',XYZ_Points);  %takes location in Real Units and Returns SLM units
%         currentY=currentY-1;
%         
%     end
%     
%     rect(j,4)=currentY;
%     
%     
% end
% 


