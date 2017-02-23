function Image = function_Adjust_Amplitude(Image,Mask,k)
Maskme = double(Mask>0);
Keep = Image.*(1-Maskme);
Adjust = Image.*Maskme;
Adjust = Adjust*k;
Image = Keep+Adjust;
end