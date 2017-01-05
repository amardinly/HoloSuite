function [ ROI ] = function_circle( cx,cy,r,N )
ROI = zeros(3,N);

Angle=2*pi*linspace(0,1,N);
ROI(1,:) = cx+r*cos(Angle);
ROI(2,:) = cy+r*sin(Angle);



end

