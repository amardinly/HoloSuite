
if strmatch(handles.color,'green')==1
      TwoPhotonImage=handles.TwoPhotonImageGreen;
elseif strmatch(handles.color,'red')==1;
      TwoPhotonImage=handles.TwoPhotonImageRed;
end;


if handles.log==1
TwoPhotonImage = log(TwoPhotonImage);
end;

%f = figure()
hold off
f=pcolor(TwoPhotonImage(:,:,handles.Zplane));
xlabel('x pixels')
ylabel('y pixels')
shading flat
axis image
colormap gray(256)

%plot ellipses
[LX,LY] = size(TwoPhotonImage);
hold on
for n=1:handles.i-1;
    
    Ellipse=handles.Ellipse{n};
    %[LP,dd] = size(handles.Experiment.ROI{n});
    %Center = mean(Ellipse);
    %EstimateCenter =  Center*handles.setup.SetupAlignment.Transformation +(handles.setup.SetupAlignment.translation);
    text(max(Ellipse(:,1)),max(Ellipse(:,2)),num2str(n),'Color',[0,1,0],'FontSize',16);
   % ROI=handles.Experiment.ROI{n};
    plot(Ellipse(:,1),Ellipse(:,2),'r');
    
end;
%end plot ellipse
