function [ B ] = function_2DCC( A, REFA, REFB )

%This function takes in argument matrixes of size n points in a matrix A size (2,n) 
%and converts them in a matrix B of the same size 

%By interpolating so that it matches how the reference points REFA turn into REFB
%REFA and REFB are coordinates X,Y of size 2,K, with K>=3


[a,b] = size(A);
B = zeros(a,b);
GetX = scatteredInterpolant(REFA(:,1),REFA(:,2),REFB(:,1),'linear');
GetY = scatteredInterpolant(REFA(:,1),REFA(:,2),REFB(:,2),'linear');

for iii = 1:a
AskPoint.X = A(iii,1);
AskPoint.Y = A(iii,2);
GetPoint.X = GetX(AskPoint.X,AskPoint.Y);
GetPoint.Y = GetY(AskPoint.X,AskPoint.Y);
B(iii,1) = GetPoint.X;
B(iii,2) = GetPoint.Y;
end
end

