function [ Interpolated ] = function_3DCofC( varargin )
%%%% Edited for smart interpolatio nwith optotune data in OPTION 4.
%%%% default option is now 4


 AskPointList = varargin{1};
 XYZ_Points = varargin{2}; 
 if nargin==3
 option = varargin{3};
 else
     option = 4;
 end
 
%%%% New smart method
if option == 1;
MGET = [XYZ_Points.GET.X,XYZ_Points.GET.Y,XYZ_Points.GET.Z];
MASK = [XYZ_Points.ASK.X,XYZ_Points.ASK.Y,XYZ_Points.ASK.Z];
[a,b] = sort(XYZ_Points.GET.Z);
MGET = MGET(b,:);
MASK = MASK(b,:);

LN = numel(a); 
levels = linspace(0,0,LN);counter = 1;
getlevel = linspace(0,0,LN);getlevel(1) = a(1);
asklevel = linspace(0,0,LN);asklevel(1) = MASK(1,3);
for i = 1:LN
if a(i)>getlevel(counter);
counter = counter+1;
getlevel(counter)= MGET(i,3);
asklevel(counter)= MASK(i,3);
end
levels(i) = counter;
end
getlevel = getlevel(1:counter); 
asklevel = asklevel(1:counter); 

M = zeros(2,3,counter);
for j = 1:counter
LGET = MGET(levels == j,:);
LASK = MASK(levels == j,:);
LASK(:,3) = 1;
LGET = LGET(:,1:2);
M(:,:,j) = LGET'*pinv(LASK');
end

[~,b] = size(AskPointList);
Interpolated = zeros(3,b);

MM = zeros(2,2,3);
for i = 1:2
    for j = 1:3
    MM(:,i,j) = squeeze(M(i,j,:))'/[asklevel; getlevel-getlevel+1];     
    end
end


MZ = getlevel/[asklevel; getlevel-getlevel+1];
for j = 1:b
 Interpolated(3,j) =MZ(1)*AskPointList(3,j)+MZ(2);
 Mat = squeeze(MM(1,:,:))*AskPointList(3,j)+squeeze(MM(2,:,:));
 AskPointList(3,j) = 1;
 u = Mat*AskPointList(:,j);
 Interpolated(1,j) = u(1);
 Interpolated(2,j) = u(2);
end




%Interpolated = M*AskPointList;
end




%Stupid method, does not work well with Z
if option == 2;
MGET = [XYZ_Points.GET.X,XYZ_Points.GET.Y,XYZ_Points.GET.Z];
MASK = [XYZ_Points.ASK.X,XYZ_Points.ASK.Y,XYZ_Points.ASK.Z];

MASK(:,4) = 1;
M = MGET'*pinv(MASK');
AskPointList(4,:) = 1;
Interpolated = M*AskPointList;
end

%Interpolation method, does not work well ourtside of calibration window
if option == 3
ASK = XYZ_Points.ASK; % is the list in 2P Coordinates
GET = XYZ_Points.GET; % Is the list of holo coordinates
[a,b] = size(AskPointList);
Interpolated = zeros(a,b);
GetX = scatteredInterpolant(ASK.X(:),ASK.Y(:),ASK.Z(:),GET.X(:),'linear','linear');
GetY = scatteredInterpolant(ASK.X(:),ASK.Y(:),ASK.Z(:),GET.Y(:),'linear','linear');
GetZ = scatteredInterpolant(ASK.X(:),ASK.Y(:),ASK.Z(:),GET.Z(:),'linear','linear');
for iii = 1:b
AskPoint.X = AskPointList(1,iii);AskPoint.Y = AskPointList(2,iii);AskPoint.Z = AskPointList(3,iii);
GetPoint.X = GetX(AskPoint.X,AskPoint.Y,AskPoint.Z);GetPoint.Y = GetY(AskPoint.X,AskPoint.Y,AskPoint.Z);GetPoint.Z = GetZ(AskPoint.X,AskPoint.Y,AskPoint.Z);
Interpolated(1,iii) = GetPoint.X;Interpolated(2,iii) = GetPoint.Y;Interpolated(3,iii) = GetPoint.Z;
end
end


if option == 4


Conversion.polyZ = polyfit(XYZ_Points.ASK.Z,XYZ_Points.GET.Z,4);
y1 = polyval(Conversion.polyZ,XYZ_Points.ASK.Z);
LN = numel(XYZ_Points.ASK.X);
LP = 6;
Pdim = 4;
Conversion.PX = zeros(Pdim+1,LP);
Conversion.PY = zeros(Pdim+1,LP);
GX = linspace(0,0,LP);
GY = linspace(0,0,LP);
AX = linspace(0,0,LP);
AY = linspace(0,0,LP);
for j = 1:LP;  
Picks = j:LP:LN;
VX = XYZ_Points.ASK.X(Picks);
VY = XYZ_Points.ASK.Y(Picks);
VZ = XYZ_Points.ASK.Z(Picks);
GX(j) = mean(XYZ_Points.GET.X(Picks));
GY(j) = mean(XYZ_Points.GET.Y(Picks));
Conversion.PX(:,j) = polyfit(VZ,VX,Pdim)';
Conversion.PY(:,j) = polyfit(VZ,VY,Pdim)';
end

[~,b] = size(AskPointList);
Interpolated = zeros(3,b);
for kk = 1:b
ZASKPOINT = AskPointList(3,kk);
XASKPOINT = AskPointList(1,kk);
YASKPOINT = AskPointList(2,kk);

Interpolated(3,kk) = polyval(Conversion.polyZ,ZASKPOINT);
AX = linspace(0,0,LP);
AY = linspace(0,0,LP);
for j = 1:LP; 
AX(j) = polyval(Conversion.PX(:,j),ZASKPOINT);  
AY(j) = polyval(Conversion.PY(:,j),ZASKPOINT);  
end
[d,Z,TF] = procrustes([GX; GY]',[AX ;AY]');
RefXY = TF.b*[AX ;AY]'*TF.T + TF.c;
GetXY = TF.b*[XASKPOINT;YASKPOINT]'*TF.T + TF.c(1,:);

Interpolated(1,kk) = GetXY(:,1);
Interpolated(2,kk) = GetXY(:,2);

end


end





end

