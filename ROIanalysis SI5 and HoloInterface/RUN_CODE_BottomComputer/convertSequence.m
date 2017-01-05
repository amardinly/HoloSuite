function [listOfPossibleHolos convertedSequence] = convertSequence(sequence);

[listOfPossibleHolos idx idx2] = uniquecell(sequence);


for n = 1:numel(idx2);
    convertedSequence{n,1}=idx2(n);
end;


% s=size(sequence);
% for rows=1:s(1);
%     for col=1:s(2);
%     test = sequence{rows,col};  
%     for n = 1:length(listOfPossibleHolos);
%         if numel(listOfPossibleHolos{n}) == numel(test);
%         if listOfPossibleHolos{n} == test;
%         display('true')
%         convertedSequence{rows,col}=n;
%         end;
%         end
%     end;
%     end;
% end;
% sequence = convertedSequence;

save('\\128.32.173.33\Imaging\STIM\Calibration SLM Computer\SEQUENCE_data.mat','sequence');
save('\\128.32.173.33\Imaging\STIM\Calibration SLM Computer\listOfPossibleHolos.mat','listOfPossibleHolos');