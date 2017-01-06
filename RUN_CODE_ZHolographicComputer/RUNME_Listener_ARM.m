function RUNME_Listener_ARM(handles);

locations = SatsumaRigFile(); %load all locations from Rig File

Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference','VisualDebugLevel', 0);

disp('Welcome to the Holostim Listener');
disp('Cpoyright A.M.Mardinly, I.A.Oldensmerg, N.C.Pegard 2015');
disp('Make sure SLM is on and you''re not being a moron some other way');
disp(' ');

%Export abort state from handles for ease of use
abort = handles.abort;

%load parameters
addpath('../');[ Setup, SLM, ~ ] = Load_Parameters(0); %Load SLM parameters
disp('Listener is activated');


%define instructions on what to do if we're loading a pre-saved sequence
if isfield(handles,'LoadedSequenceName') && handles.useLoad  
    
    disp('Sequence Loaded from file detected')
    set(handles.statusText,'String','Detected Loaded File');
    
    load([handles.LoadedPathName handles.LoadedSequenceName]) %Load SavedHolograms
    
    if ~exist('ROIdata')
        errordlg('Saved ROIdata not found')
        return
    elseif ~exist('holoRequest')
        errordlg('Saved holoRequest not found')
        return
    elseif ~exist('MySequence')
        errordlg('saved sequence no found!')
        return
    end;
    
    %save this holorequest and ROIdatafile
    save([locations.HoloRequest_DAQ 'holoRequest.mat'],'holoRequest')
    save([locations.HoloRequest_DAQ 'ROIdata.mat'],'ROIdata')
    
    %Tack Sequence onto HoloRequest
    holoRequest.Sequence{1}=1:length(MySequence);
    
    %parse holorequest and generate holograms
    function_SLM_and_DAQ_ARM(MySequence, SLM,holoRequest,handles);
    
    
else  %if we are generating a new sequence
    
    
    %search for ROI data
    disp('Now looking for ROI DATA file');
    set(handles.statusText,'String','Listener Active, looking for ROIData.mat')
    
    roidatafound = 0;
    %run loops unless ROIData file appears or we have an abort
    while (roidatafound == 0) && (abort == 0);
        %get abort status
        abort = get(handles.abortToggle,'Value');
        
        %if abort, return
        if abort;
            return
        end;
        
        
        if exist(strcat(Setup.HoloRequestFolder,'\ROIdata.mat'), 'file') == 2; %if file detected
            disp('ROI DATA file found,loading')
            set(handles.statusText,'String','Found ROI data - loading')
            roidatafound = 1;
        else
            pause(1)
        end
    end
    
    %load ROI data
    load(strcat(Setup.HoloRequestFolder,'\ROIdata.mat'));
    clear 'roidatafound'
    disp('ROI DATA file succesfully loaded');
    disp(' ');
    disp('Listener is now active, waiting for Holo Request')
    
    set(handles.statusText,'String','ROIdata loaded, waiting for HoloRequest')
    
    
    screenon = 0;
    sequenceholorequest = 0;
    
    %look for holorequest while there is no sequence and no abort
    while (sequenceholorequest == 0) && (abort == 0);
        
        abort = get(handles.abortToggle,'Value');
        if abort;
            return
            
        end;
        
        %if we find a holoRequest....
        if exist(strcat(Setup.HoloRequestFolder,'\HoloRequest.mat'), 'file') == 2
            pause(0.1)
            disp('Holo Request file found, loading')
            
            set(handles.statusText,'String','Found HoloRequest file, loading')
            
            set(handles.listening,'Value',0) %stop listening!
            
            guidata(ListenerForHoloRequest,handles)  
            
            
            %load HoloRequest and Calibration Points
            load(strcat(Setup.HoloRequestFolder,'\HoloRequest.mat'));
            disp(strcat('Zoom level = ',int2str(holoRequest.zoom)));
            load(strcat(Setup.CalibrationFolder,'\',int2str(holoRequest.objective),'X_Objective_Zoom_',int2str(holoRequest.zoom),'_XYZ_Calibration_Points.mat'));
            disp('Holo Request file successfully loaded')
            set(handles.statusText,'String','HoloRequest file loaded')
            
            %Delete holorequest so next one can be detected
            delete(strcat(Setup.HoloRequestFolder,'\HoloRequest.mat'));
           
            guidata(ListenerForHoloRequest,handles)
            clear('parametres');
            
           
            %What is this for  - ARM
            if isfield(holoRequest,'powerMultiplier');
            parametres.powerMultiplier = holoRequest.powerMultiplier;
            end
            
            
            %reload ROIdata file if requested
            if holoRequest.reload == 1; load(strcat(Setup.HoloRequestFolder,'\ROIdata.mat')); disp('ROI Data File updated as requested');end;
            
            %if we're defining sequence by exluding rois:
            if holoRequest.excludeROIs == 1;
                ROICount = numel(ROIdata.rois);
                for i = 1:numel(holoRequest.rois);
                    holoRequest.rois{i} = setxor(holoRequest.rois{i},1:ROICount);
                end;
            end;
                        
            %Parse hologram type (center dot or disc,edge,etc).
            if strcmp(holoRequest.hologram_config, 'DLS');
            
                disp('You have rquested diffraction limited holograms');
                disp('For 3D-SHOT, this will manifest as a 20 um disc');
                
                parametres.OnlyCenterDotHologram = 1;
                parametres.nDLS = 1;  
                
                %ARM - commented out obsolete code where we try targeting 1
                %ROI with many DLS
                %try
                %    parametres.nDLS = holoRequest.nDLS;
                %catch
                %    parametres.nDLS = 1;  
                %end
                
                % ARM - obsolete thing that never worked -img segementation
                % ...good idea
%                 try
%                     if strcmp(holoRequest.channel,'green')
%                         parametres.channel = 1;
%                     elseif strcmp(holoRequest.channel,'red')
%                         parametres.channel = 2;
%                     end;
%                 end
                
            elseif strcmp(holoRequest.hologram_config, 'filledCircle'); 
                disp('You have rquested Filled Cirlce holograms');
                parametres.OnlyCenterDotHologram = 0;
                disp('WARNING: NOT COMPATIBLE WITH 3DSHOT')
%             elseif strcmp(holoRequest.hologram_config, 'edge');  %obsolete - marked for deletion - ARM 
%                 disp('You have rquested Edge Only holograms');  
%                 parametres.ShrinkFactorList = {0};
%                 parametres.DonutFactorList = {0.9};
%             elseif strcmp(holoRequest.hologram_config, 'custom');  %obsolete - marked for deletions
%                 disp('You have requested Custom holograms');
%                 parametres.ShrinkFactorList = {holoRequest.shrinking_factor};
%                 parametres.DonutFactorList = {holoRequest.donut_factor};
%                 if holoRequest.centroid_diameter == 0;
%                     disp('You want something shaped like the ROI');
%                 else
%                     disp(strcat('You want a sphere of radius  -- ',int2str(holoRequest.centroid_diameter))); parametres.CentroidDiameter = {holoRequest.centroid_diameter};
%                 end;
            else disp('Something is wrong with your request - unknown error - code 666');
                set(handles.statusText,'String','Bullshit something is wrong with your request')
                guidata(ListenerForHoloRequest,handles)
            end
            
            
            
            % obsolete - marked for deletion arm
%             try
%                 if holoRequest.excludeCenter == 1;
%                     parametres.ExcludeCenter = holoRequest.excludeRadius;
%                 else
%                     parametres.ExcludeCenter = 0;
%                 end;
%             end;
            
            if holoRequest.grid == 0 && holoRequest.xyz_map == 0 && numel(holoRequest.rois) <= 1 && strcmp(holoRequest.hologram_config, 'paramaterSpace') == 0; %Case: single hologram only
            %case: no grid, no map, only 1 ROI requested, parameter space
            %map not requested - this code handles a holorequest containing
            %a request for only 1 hologram, not a sequence
                
                disp('You have requested a single hologram'); 
                disp('The ROIs to be displayed are :')
                
                %set(handles.statusText,'String',strcat('Single Holo requested: ROIs requested are ',num2str(holoRequest.rois{1})));
                
                guidata(ListenerForHoloRequest,handles) %these are necessary to update text on gui..do we need this?
                
                if numel(holoRequest.rois) == 0; disp('All ROIS'); else  disp(holoRequest.rois{1}); end;
                
                disp('Now compiling hologram')
                set(handles.statusText,'String','Now compiling hologram')
                
                guidata(ListenerForHoloRequest,handles) %these are necessary to update text on gui..do we need this?
                
                % turn on SLM Screen
                if screenon == 0;
                    screenon = 1;
                    [w,rect]=Screen('OpenWindow',SLM.ScreenID,[0 0 0]); 
                end;
                
                ROICount = numel(ROIdata.rois);  %not necessary
                
                %this if/else statement is already handled in the
                %conditional above - the else should never be called! - ARM
                if numel(holoRequest.rois) == 1;
                    PickROIS = holoRequest.rois{1}; 
                else
                    PickROIS = 1:length(ROIdata.rois);
                end;
                
                [ Hologram, Mask ] = function_compileHologram( parametres, SLM, Setup,XYZ_Points,ImagesInfo,ROIdata,PickROIS,holoRequest );
              
                               
                f = figure(1);
                subplot(2,1,1);
                pcolor(double(Hologram)); shading flat; title('Phase mask'); 
                maskref = Mask{1}-Mask{1}; 
                for jjji = 1:numel(Mask);
                    maskref = max(maskref,Mask{jjji}); 
                end;
                axis image;
                subplot(2,1,2); 
                pcolor(double(maskref)); shading flat; title('Targeted ROIs'); axis image;
                t = zeros(1,1); hhh = Hologram; img = [hhh hhh hhh]; 
                t=Screen('MakeTexture',w,img); 
                Screen('DrawTexture', w, t); 
                Screen('Flip', w);
                disp('Hologram is now on the SLM');disp('--');disp('--');
                set(handles.statusText,'String','Hologram is now on the SLM')
                
                
                if handles.DoHandshake == 1;  %if handshake enabled...
                    currentHolo = holoRequest.rois{1};
                    ROIsON = holoRequest.rois{1};
                    set(handles.currentROI,'string',num2str(currentHolo));
                    save([locations.HoloRequest_DAQ_PrintedHolo 'holo'],'currentHolo');
                    save([locations.HoloRequest_DAQ_PrintedHolo 'holo'],'ROIsON','-append');
                    disp('handshook')
                    pause(0.005)
                end;
                
                
                guidata(ListenerForHoloRequest,handles)
                disp('Listener is active WAITING FOR NEW INSTRUCTIONS');
                set(handles.statusText,'String','Listener is active WAITING FOR NEW INSTRUCTIONS')
                set(handles.listening,'Value',1)
                figure(ListenerForHoloRequest)
            else
                clc
                sequenceholorequest = 1;
            end
        else
            pause(1) %this is just to wait and go back to listening
        end
    end
    
    %clc
    %Kill this line later
    %holoRequest.reload = input('enter 1 to recycle holograms, 0 otherwise')
    
    disp('You have selected a sequence of multiple holograms.');
    set(handles.statusText,'String','You have selected a sequence of multiple holograms - listening OFF')
    set(handles.listening,'Value',0)
    guidata(ListenerForHoloRequest,handles)
    disp('LISTENER IS NOW TURNED OFF');
    NXYZ = [holoRequest.points.x,holoRequest.points.y,holoRequest.points.z]; NX = NXYZ(1); NY = NXYZ(2); NZ = NXYZ(3);
    LXYZ = [holoRequest.spacing.x,holoRequest.spacing.y,holoRequest.spacing.z]; LX = LXYZ(1); LY = LXYZ(2); LZ = LXYZ(3); clear 'LXYZ';
    if screenon == 0; screenon = 1; [w,rect]=Screen('OpenWindow',SLM.ScreenID,[0 0 0]); end;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    % Done until here, screen is turned on correctly at this point...
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    foundcrap = 0;
    if strcmp(holoRequest.hologram_config, 'paramaterSpace');
        disp('You want to generate a sequence though the preselected parameters in the CustomHologram.xls file')
        thevalues = csvread(strcat(Setup.CalibrationFolder,'\CustomHologram.csv')); [LN,LP] = size(thevalues); disp(strcat('You have requested --',int2str(LN),' - Holograms'));
        MySequence = {};
        holoRequest.Sequence = {};
        for iiij = 1:LN
            disp(strcat('Now compiling hologram --',int2str(iiij),'-- Gof --',int2str(LN)));
            set(handles.statusText,'String','Compiling Hologram')
            guidata(ListenerForHoloRequest,handles)
            clear 'parametres';
            PickROIS = holoRequest.rois{1}; %In parameters space, we just pick the first hologram in the list
            if strcmp(holoRequest.hologram_config, 'DLS'); disp('You have rquested diffraction limited holograms');
                
                parametres.OnlyCenterDotHologram = 1;
                parametres.nDLS = holoRequest.nDLS;
                
                if strcmp(holoRequest.channel,'green')
                    parametres.channel = 1;
                elseif strcmp(holoRequest.channel,'red')
                    parametres.channel = 2;
                end;
                
                
            end;
            
            
            
            if thevalues(iiij,2) == 1;  parametres.OnlyCenterDotHologram = 1; else parametres.OnlyCenterDotHologram = 0; end;
            parametres.ShrinkFactorList = {thevalues(iiij,3)};
            parametres.DonutFactorList = {thevalues(iiij,4)};
            holoRequest.zoffset = thevalues(iiij,5);
            if thevalues(iiij,6) == 0 ;  parametres.ExcludeCenter = 0; else parametres.ExcludeCenter = thevalues(iiij,6); end;
            if thevalues(iiij,7) == 0 ;  parametres.nDLS = 0; else parametres.nDLS = thevalues(iiij,7); end;
            
            [ Hologram, Mask ] = function_compileHologram( parametres, SLM, Setup,XYZ_Points,ImagesInfo,ROIdata,PickROIS,holoRequest );
            save(['Hologram_' num2str(iiij)],'Hologram');
            pause(5)
            MySequence{iiij} = Hologram;
            MySequenceMask{iiij} = Mask;
        end
        holoRequest.Sequence{1} = 1:LN;
        
    elseif numel(holoRequest.rois)>1 && holoRequest.grid == 0 && holoRequest.xyz_map == 0
        disp('You want to display a particular sequence in a loop'); disp('Here is the sequence, pulse by pulse');
        for iii = 1:numel(holoRequest.rois); disp(holoRequest.rois{iii});end;
        MySequence = {};
        handles.writeROIsON =1;
        for iiij = 1:numel(holoRequest.rois)
            PickROIS = holoRequest.rois{iiij};
            [ Hologram, Mask ] = function_compileHologram( parametres, SLM, Setup,XYZ_Points,ImagesInfo,ROIdata,PickROIS,holoRequest );
            display(strcat('now computing #',int2str(iiij)));
            MySequence{iiij} = Hologram;
            MySequenceMask{iiij} = Mask;
            
        end
        
        
        
    elseif holoRequest.grid == 1 && holoRequest.xyz_map == 0 && numel(holoRequest.rois)<=1;
        disp('You have requested a rectangular grid')
        MySequence = {};
        if holoRequest.randomizelist == 1; TheList =  holoRequest.RandGridPosition; else  TheList =  holoRequest.GridPosition; end; [~,LN] = size(TheList);
        disp(strcat('We will be computing -- ',int2str(LN),'-- holograms'));
        thatone = holoRequest;
        holoRequest.Sequence = {};
        for iiij = 1:LN
            disp(strcat('Now compiling hologram --',int2str(iiij),'-- of --',int2str(LN)));
            PickROIS = holoRequest.rois{1};
            thatone.xoffset = holoRequest.xoffset + TheList(1,iiij);
            thatone.yoffset = holoRequest.yoffset + TheList(2,iiij);
            thatone.zoffset = holoRequest.zoffset + TheList(3,iiij);
            [ Hologram, Mask ] = function_compileHologram( parametres, SLM, Setup,XYZ_Points,ImagesInfo,ROIdata,PickROIS,thatone );
            MySequence{iiij} = Hologram;MySequenceMask{iiij} = Mask;
        end
        holoRequest.Sequence{1} = 1:LN;
        
    elseif holoRequest.xyz_map == 1 && holoRequest.grid == 0 && numel(holoRequest.rois)<=1;
        disp('You have requested an XYZ_Map')
        MySequence = {};
        if holoRequest.randomizelist == 1; TheList =  holoRequest.RandXYZMapPosition; else  TheList =  holoRequest.XYZMapPosition; end;  [~,LN] = size(TheList);
        disp(strcat('We will be computing -- ',int2str(LN),'-- holograms'));
        thatone = holoRequest;
        holoRequest.Sequence = {};
        for iiij = 1:LN
            disp(strcat('Now compiling hologram --',int2str(iiij),'-- of --',int2str(LN)));
            PickROIS = holoRequest.rois{1};
            thatone.xoffset = holoRequest.xoffset + TheList(1,iiij);
            thatone.yoffset = holoRequest.yoffset + TheList(2,iiij);
            thatone.zoffset = holoRequest.zoffset + TheList(3,iiij);
            [ Hologram, Mask ] = function_compileHologram( parametres, SLM, Setup,XYZ_Points,ImagesInfo,ROIdata,PickROIS,thatone );
            MySequence{iiij} = Hologram;MySequenceMask{iiij} = Mask;
            
        end
        holoRequest.Sequence{1} = 1:LN;
        
        
        
    else
        foundcrap = 1;
        clc;disp('You have requested a sequence but there I cant figure out what type');disp('I quit, next time send me a valid holoRequest file')
        set(handles.statusText,'String','error - sequence type not determined.  Go bother Nico')
        guidata(ListenerForHoloRequest,handles)
    end
    
    
    clc
    if screenon== 1; screenon=0;Screen('CloseAll'); end
    disp('Holograms have been compiled, we are preparing slm and loading holograms');
    set(handles.statusText,'String','Holograms have been compiled, we are preparing slm and loading holograms')
    guidata(ListenerForHoloRequest,handles)
    
    if handles.save
        disp('saving holograms before loading on slm')
        set(handles.statusText,'String','Saving Sequence')
        if ~strcmp(handles.currentDir(length(handles.currentDir)),'\')
            handles.currentDir=strcat(handles.currentDir,'\');
        end;
        
        if isempty(handles.saveName)
            errordlg('please enter a name for your holo sequence')
            str = input('File Name:','s');
            handles.saveName = str;
        end;
        
        
        
        %check for existing save name and get input for overwrrite or append?
        save([handles.currentDir handles.saveName],'MySequence');
        save([handles.currentDir handles.saveName],'ROIdata','-append');
        save([handles.currentDir handles.saveName],'holoRequest','-append');
        disp('saved')
    end
    
    function_SLM_and_DAQ_ARM(MySequence, SLM,holoRequest,handles);
    
    
    
end;
