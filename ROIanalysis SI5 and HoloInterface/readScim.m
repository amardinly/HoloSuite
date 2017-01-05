function [Images, Config] = readScim(TifFile, varargin)
% Loads 'Frames' of single .sbx file ('SbxFile'). Requires
% corresponding information file ('InfoFile').

Frames = 1:20; % indices of frames to load in 'Direct' mode, or 'all'
Channels = 1;
SaveDirect = false;

warning('off','MATLAB:imagesci:tiffmexutils:libtiffWarning');

%% Initialize Parameters
index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case {'Frames','frames'} % indices of frames to load in 'Direct' mode
                Frames = varargin{index+1};
                index = index + 2;
            case {'Channels','channels'}
                Channels = varargin{index+1};
                index = index + 2;
            case {'Depth','depths'}
                Depth = varargin{index+1};
                index = index + 2;    
            otherwise
                warning('Argument ''%s'' not recognized',varargin{index});
                index = index + 1;
        end
    catch
        warning('Argument %d not recognized',index);
        index = index + 1;
    end
end


if ~exist('TifFile', 'var') || isempty(TifFile)
    [TifFile,p] = uigetfile({'*.sbx'}, 'Choose scanbox file to load');
    if isnumeric(TifFile)
        Images = []; return
    end
    TifFile = fullfile(p,TifFile);
end

%% Load In Acquisition Information
Config = parseScimHeader(TifFile);

%% Load In Images

% Determine frames to load
if ischar(Frames) || (numel(Frames)==1 && Frames == inf)
    Frames = 1:Config.Frames;
elseif Frames(end) == inf
    Frames = [Frames(1:end-2),Frames(end-1):info.numFrames];
end

fprintf('Loading %d frames...', numel(Frames));
[~,Images] = scim_openTif(TifFile);%, 'frames', Frames, 'channels', Channels);



if Config.Depth == 1
    Images = permute(Images, [1,2,5,3,4]);
else
    Images = permute(Images, [1,2,4,3,5]);
end


%eval images
% for n = 1:5
%     for k = 1:100
%     image(Images(:,:,1,n,k));
%     pause(.1)
%     end
% end;



%% Save Images
fprintf('\tComplete\n');
if SaveDirect
    fprintf('\tSaving frames to mat file');
    savefn = [TifFile(1:end-4),'_EL.mat'];
    n=1;
    while exist(savefn,'file')
        savefn = [TifFile(1:end-4),sprintf('%d_EL.mat',n)];
        n = n + 1;
    end
    save(savefn, 'Images', 'info', '-v7.3');
end