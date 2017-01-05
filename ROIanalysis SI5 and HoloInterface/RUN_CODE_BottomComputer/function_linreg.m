function [slope,shift] = function_linreg(UX,UY,M)

[LX,LY] = size(M);


x = linspace(0,0,LX*LY);
y = linspace(0,0,LX*LY);
w = linspace(0,0,LX*LY);
for i = 1:LX,
    for j = 1:LY
x(i+(LX*(j-1))) = UX(i);
y(i+(LX*(j-1))) = UY(j);
w(i+(LX*(j-1))) = M(i,j);
    end
end

f=fittype('poly1');
options=fitoptions('poly1');
options.Weights=w;
fun=fit(x',y',f,options);
slope=fun.p1;
shift=fun.p2;


end