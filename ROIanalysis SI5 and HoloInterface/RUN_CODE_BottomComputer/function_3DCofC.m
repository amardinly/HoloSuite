function [ GetPointList  ] = function_3DCOC( AskPointList, XYZ_Points )
%This converts a set of points in 2P reference, into a set of GET in 
ASK = XYZ_Points.ASK; % is the list in 2P Coordinates
GET = XYZ_Points.GET; % Is the list of holo coordinates
[a,b] = size(AskPointList);
GetPointList = zeros(a,b);
GetX = scatteredInterpolant(ASK.X(:),ASK.Y(:),ASK.Z(:),GET.X(:),'linear','linear');
GetY = scatteredInterpolant(ASK.X(:),ASK.Y(:),ASK.Z(:),GET.Y(:),'linear','linear');
GetZ = scatteredInterpolant(ASK.X(:),ASK.Y(:),ASK.Z(:),GET.Z(:),'linear','linear');

for iii = 1:b
AskPoint.X = AskPointList(1,iii);
AskPoint.Y = AskPointList(2,iii);
AskPoint.Z = AskPointList(3,iii);
GetPoint.X = GetX(AskPoint.X,AskPoint.Y,AskPoint.Z);
GetPoint.Y = GetY(AskPoint.X,AskPoint.Y,AskPoint.Z);
GetPoint.Z = GetZ(AskPoint.X,AskPoint.Y,AskPoint.Z);
GetPointList(1,iii) = GetPoint.X;
GetPointList(2,iii) = GetPoint.Y;
GetPointList(3,iii) = GetPoint.Z;
end
end

