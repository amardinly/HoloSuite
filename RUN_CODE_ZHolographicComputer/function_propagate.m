function [field2] = function_propagate(field1,lambda,z,psX,psY)
% propagate a field in z (digital focusing of a hologram)
% function [field2,H] = propagate(field1,lambda,z,ps,zpad)
% inputs: field1 - complex field at input plane
%         lambda - wavelength of light [m]
%         z - propagation distance (can be negative)
%         ps - pixel size [m]
%         zpad - size of propagation kernel desired
% outputs:field2 - propagated complex field
%         H - propagation kernel to check for aliasing
%
% Laura Waller, MIT, lwaller@alum.mit.edu

[m,n]=size(field1);
M=m;N=n;
[x,y]=meshgrid(-N/2+1:N/2, -M/2+1:M/2);
fx=x/(psX*M);     %width of CCD [m]
fy=y/(psY*N);     %height of CCD [m]
k=2*pi/lambda;

%H=exp(1i*k*z)*exp(-i*pi*lambda*z.*(x.^2+y.^2));
H=exp(-1i*pi*lambda*z.*(fx.^2+fy.^2));

aveborder=mean(mean([field1(1,:) field1(m,:) field1(:,1)' field1(:,n)']));
ff=ones(M,N)*aveborder; %pad by average border value to avoid sharp jumps
ff(1:m,1:n)=field1;
objFT=fftshift(fft2(ff));
field2=(ifft2(fftshift(objFT.*H)));
field2=field2(1:m,1:n);
