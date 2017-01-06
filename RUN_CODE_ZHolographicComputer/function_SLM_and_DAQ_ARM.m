function [] = function_SLM_and_DAQ_ARM(MySequence, SLM,holoRequest,handles)

%import locations
locations=SatsumaRigFile();

%get abort status
abort = handles.abort;

try clear('DAQ'); catch; end %clears DAQ if extant, otherwise doesnt err

%init session
Holodaq.Name = 'Dev1' ;
DAQ = daq.createSession('ni'); % initialize session
Fs=10000;
DAQ.Rate = Fs ; %samples per second
%Add Output Channels
DAQ.DurationInSeconds = 2/Fs;
addDigitalChannel(DAQ,Holodaq.Name,'port0/line0','InputOnly');
addDigitalChannel(DAQ,Holodaq.Name,'port0/line2','InputOnly');

TheSequence = holoRequest.Sequence;
cycleoption = holoRequest.cycleSequence;  %recycle sequence or hard wait for reset pulse
numberofsequences = numel(TheSequence);

holoID = 0;
sequenceID = 1;

Holomax = numel(MySequence);  %max holo ID

cycling = holoRequest.reload; %redundant with cycleoptions?

%open SLM SCREEN
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference','VisualDebugLevel', 0);
[w,rect]=Screen('OpenWindow',SLM.ScreenID,[0 0 0]);
ScreenFrames = zeros(1,Holomax);

%For each hologram in the sequence, use make texture to enter it into
%'ScreenFrame' and also show image of the cooresponding hologram
f = figure(2);
for i=1:Holomax;
    myholo = MySequence{i};                     
    img = [myholo myholo myholo];
    ScreenFrames(i)=Screen('MakeTexture',w,img);
    imagesc(myholo)
    pause(0.01)
end

disp('Holograms successfully loaded');
set(handles.statusText,'String','Holograms successfully loaded');  guidata(ListenerForHoloRequest,handles);

state = [0 0];  %first val is advance holo, second val is reset

figure(ListenerForHoloRequest) %make active holo


while abort == 0;

    %break if abort
    abort = get(handles.abortToggle,'Value');
    if abort == 1;
        %  break
        return
    end;

    %if handshake enabled, pause to enable abort
    if handles.DoHandshake == 1;
        pause(0.005)
    end
    
    %get single scan
    measure = inputSingleScan(DAQ);

    if measure == state; %if state is not changed, ignore all elseifs
    elseif  min(state-measure)>=0; 
        state = measure;  %change state to measure it
    else
        if measure == [1 0]
            disp('Advancing to next hologram')
            holoID = holoID+1;
            if holoID> length(TheSequence{sequenceID})
                if cycleoption == 1;
                    disp('Restarting this sequence')
                    holoID = 1;
                else
                    disp('You have reached the final step of that sequence and there are no more holograms, go to next sequence or fix your bug')
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
            disp('RESET SEQUENCE REQUESTED and first hologram will load')
        
        end
        
        
        state = measure;
        if holoID>0
            disp(strcat('Now displaying -- ',int2str(holoID)));
            %set(handles.currentROI,'String',strcat('Now displaying -- ',int2str(holoID)))
            
            Screen('DrawTexture', w,ScreenFrames(TheSequence{sequenceID}(holoID)));
            %inexplicable random error occured, changed holoID to cell to fix.  9/16/2016;
            %Screen('DrawTexture', w, ScreenFrames(TheSequence{sequenceID}{holoID}));
            
            Screen('Flip', w);
            
            
            if handles.DoHandshake == 1;
                
                currentHolo = holoID;%holoRequest.rois{1};
                
                if handles.writeROIsON
                    ROIsON = holoRequest.rois{holoID};
                else
                    ROIsON = holoRequest.rois{1};
                end
                
                set(handles.currentROI,'string',num2str(currentHolo));
                
                save([locations.HoloRequest_DAQ_PrintedHolo 'holo'],'currentHolo');
                save([locations.HoloRequest_DAQ_PrintedHolo 'holo'],'ROIsON','-append');
                
                disp('handshook')
                pause(0.005)
            end;
            
            
            
        end
    end
    
    if holoID== Holomax  && cycling==1
        holoID = 0;
        disp('You want to cycle through holograms, so we reset the sequence')
        
    end
end


try clear('DAQ'); catch; end
disp('Sequence display has been completed')
%set(handles.statusText,'String','Sequence display has been completed')
%set(handles.currentROI,'String',' ')
end