function [] = function_SLM_and_DAQ(MySequence, SLM,holoRequest)
try clear('DAQ'); catch; end
Holodaq.Name = 'Dev1' ;
%daq.getDevices 
DAQ = daq.createSession('ni'); % initialize session
Fs=10000;
DAQ.Rate = Fs ;
%Add Output Channels
DAQ.DurationInSeconds = 2/Fs;
addDigitalChannel(DAQ,Holodaq.Name,'port0/line0','InputOnly');
addDigitalChannel(DAQ,Holodaq.Name,'port0/line2','InputOnly');

TheSequence = holoRequest.Sequence;
cycleoption = holoRequest.cycleSequence;
numberofsequences = numel(TheSequence);
holoID = 0;
sequenceID = 1;

Holomax = numel(MySequence);
cycling = holoRequest.reload;
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference','VisualDebugLevel', 0);
[w,rect]=Screen('OpenWindow',SLM.ScreenID,[0 0 0]);
ScreenFrames = zeros(1,Holomax);
for i=1:Holomax;
myholo = MySequence{i};
img = [myholo myholo myholo];
 ScreenFrames(i)=Screen('MakeTexture',w,img);
end
disp('Holograms successfully loaded');
state = [0 0];

while 1== 1
    
measure = inputSingleScan(DAQ);
if measure == state;
elseif  min(state-measure)>=0;
    state = measure;
else 
    if measure == [1 0]
        %disp('Advancing to next hologram')
        holoID = holoID+1;
        if holoID> length(TheSequence{sequenceID})
            if cycleoption == 1;
             %   disp('Restarting this sequence')
                holoID = 1;
            else
             %   disp('You have reached the final step of that sequence and there are no more holograms, go to next sequence or fix your bug')
                holoID = holoID-1;   
            end         
        end
                   
    elseif measure == [0,1]; 
          holoID = 0;
          sequenceID = mod(sequenceID+1,numberofsequences)+1;
          disp('NEXT SEQUENCE REQUESTED, waiting for pulse to load first hologram')
          if sequenceID == 1;
              disp('This is a reset')
          end
    elseif measure == [1,1]; 
            holoID = 1;
            sequenceID = mod(sequenceID+1,numberofsequences)+1;
            %disp('RESET SEQUENCE REQUESTED and first hologram will load')          
    end
    state = measure;
    if holoID>0
        disp(strcat('Now displaying -- ',int2str(holoID)));
        Screen('DrawTexture', w, ScreenFrames(TheSequence{sequenceID}(holoID)));
        Screen('Flip', w);
    end
end

if holoID== Holomax  && cycling==1
    holoID = 0;
%disp('You want to cycle through holograms so we reset the sequence')
    
end
end


try clear('DAQ'); catch; end
disp('Sequence display has been completed')

end