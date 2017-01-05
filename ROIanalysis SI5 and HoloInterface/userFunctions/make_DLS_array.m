function handles = make_DLS_array(handles,points,um,dim,ROI)
vert=handles.ROIdata.rois(ROI).vertices;
natZ = handles.ROIdata.rois(ROI).Zlevel;


L=length(-round(points/2):um:round(points/2));

handles.ROIdata.rois(1:L)=handles.ROIdata.rois(ROI);



i=1;
for n=-round(points/2):um:round(points/2);

clear v;
if strcmp(dim,'x')
    v(:,1)=vert(:,1)+n;
    v(:,2)=vert(:,2);
    handles.ROIdata.rois(i).vertices=v;
    i = i + 1;
    
elseif strcmp(dim,'y')
    v(:,1)=vert(:,1);
    v(:,2)=vert(:,2)+n;
     handles.ROIdata.rois(i).vertices=v;
     i = i + 1;
    
    
elseif strcmp(dim,'z')
  
    handles.ROIdata.rois(i).Zlevel=natZ+n;
     i = i + 1;
    
else
    disp('select X Y or Z')
    return
end;



end
