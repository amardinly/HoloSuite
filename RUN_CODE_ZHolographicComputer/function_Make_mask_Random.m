function   [mask] =   function_Make_mask_Random(LLX,LLY,ROI,DiffSpotscount,Subsampling,SLM)

ROI(:,1) = LLX*ROI(:,1);
ROI(:,2) = LLY*ROI(:,2);
mask=zeros(Subsampling*SLM.Y, Subsampling*SLM.X);
[LN,~] = size(ROI);
points = zeros(DiffSpotscount+1,2);
u = linspace(0,1,LN);
UU = linspace(0,1,DiffSpotscount+1);
points(:,1) = spline(u,ROI(:,1),UU);
points(:,2) = spline(u,ROI(:,2),UU);
points = floor(points);

for i = 1:DiffSpotscount
mask(points(i,2),points(i,1)) = 1;
end



end

