function outmat=HI3Parse(instr);




[S I]= regexp(instr,',','match');

k=1;
location=1;
outchar=[];
for j=1:length(I)+1;
    
    
   if j~= length(I)+1
   f=instr(location:I(j)-1);
   else
   f=instr(location:end);
   end
   
   f=strcat('[',f,'] ');
   outmat{k}=eval(f);

   if j~= length(I)+1
       location=I(j)+1;
   end
   k=k+1;
end
   
