function [cellX] = str2CellArrayParser(x)
% converts string input to cell array of doubles
% with love from ian 7/9/2015

%really badly.  for instance [1:85] is output at as 1 2 3 4 5 6 7 85
%with frustration from alan 8/13/15

%%cleanup
x1 = x;
x1(strfind(x,',')) =' ';

while strcmp(x1(1),' ')
    x1=x1(2:end);
end
while strcmp(x1(end),' ')
    x1=x1(1:end-1);
end

a=strfind(x1,':');
for i= 1:length(a)
   b=strfind(x1,':');
   strt=str2num(x1(b(1)-1));
   stp=str2num(x1(b(1)+1));
   
   x1 = [x1(1:(b(1)-2)) num2str(strt:stp) x1((b(1)+2):end)];
end

a=strfind(x1,'[');
if isempty(a) %each item is one number
    [tok rem] = strtok(x1,' ');
    i =1;
    cellX{i} = str2double(tok);
    
    while ~isempty(rem)
        i=i+1;
        [tok rem] = strtok(rem,' ');
        cellX{i}= str2double(tok);
    end
else
    for i = 1:size(a,2);
        %insert space
        if a(i)>1 && ~strcmp(x1(a(i)-1),' ')
            x1 = [x1(1:a(i)-1) ' ' x1(a(i):end)];
            a(i:end)=a(i:end)+1;
        end
    end
    
    i=1;
    inSeq = 0; %flag if in seek
    rem = x1;
    while ~isempty(rem)
        [tok rem] =strtok(rem, ' ');
        if strcmp(tok(1),'[') && strcmp(tok(end),']')
            cellX{i}=str2double(tok(2:end-1));
            i=i+1; 
        elseif strcmp(tok(1),'[');
            cellseq=[];
            k=1;
            inSeq=1;
            cellseq(k)=str2double(tok(2:end));
        elseif strcmp(tok(end),']')
            k=k+1;
            cellseq(k)=str2double(tok(1:end-1));
            inSeq=0;
            cellX{i} = cellseq;
            i=i+1;
        elseif inSeq
            k=k+1;
            cellseq(k)=str2double(tok);
        else
            cellX{i}=str2double(tok);
            i=i+1; 
        end
        
    end
    
end

