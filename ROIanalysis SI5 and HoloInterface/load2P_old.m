function [Images, Config, loadObj] = load2P(DataFiles, varargin)
% Loads 'Frames' of single .sbx, .tif, or .imgs file. Requires
% corresponding information file ('InfoFile').

LoadType = 'Direct'; % 'MemMap' or 'Direct' or 'Buffered' 
Frames = inf; % indices of frames to load in 'Direct' mode, or 'all'
Channels = inf;
Double = false;
SaveToMat = false;

%% Initialize Parameters
if ~exist('DataFiles', 'var') || isempty(DataFiles)
    directory = CanalSettings('DataDirectory');
    [DataFiles,p] = uigetfile({'*.sbx;*.tif;*.imgs'}, 'Choose images file(s) to load', directory, 'MultiSelect', 'on');
    if isnumeric(DataFiles)
        Images = []; return
    elseif iscellstr(DataFiles)
        for index = 1:numel(DataFiles)
            DataFiles{index} = fullfile(p,DataFiles{index});
        end
    else
        DataFiles = {fullfile(p,DataFiles)};
    end
elseif ischar(DataFiles)
    DataFiles = {DataFiles};
elseif isstruct(DataFiles)
    loadObj = DataFiles;
end
nFiles = numel(DataFiles);

if ~exist('loadObj', 'var')
    % Initialize LoadObj
    loadObj.Filenames = DataFiles;
    loadObj.numFiles = nFiles;
    loadObj.filesLoaded = false(nFiles,1);
    loadObj.framesLoaded = cell(nFiles,1);
    loadObj.files = cell(nFiles,1);
else
    LoadType = loadObj.Type; % set load type based on loadObj
end

index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case isstruct(varargin{index})
                loadObj = varargin{index};
                index = index + 1;
            case {'Type','type'}
                LoadType = varargin{index+1};
                index = index + 2;
            case {'Frames','frames','Frame','frame'} % indices of frames to load in 'Direct' mode
                Frames = varargin{index+1};
                index = index + 2;
            case {'Channels', 'channels', 'Channel', 'channel'}
                Channels = varargin{index+1};
                index = index + 2;
            case {'Depths', 'depths'}
                Depths = varargin{index+1};
                index = index + 2;
            case {'Double', 'double'}
                Double = true;
                index = index + 1;
            otherwise
                warning('Argument ''%s'' not recognized',varargin{index});
                index = index + 1;
        end
    catch
        warning('Argument %d not recognized',index);
        index = index + 1;
    end
end

%% Update LoadObj
if ~iscell(Frames)
    Frames = {Frames};
    Frames = repmat(Frames, nFiles, 1);
end
loadObj.Type = LoadType;

switch LoadType

    
%% Load Direct
    %Determine dimensions of output for preallocation
    case 'Direct'
        % Load in acquisition information
        Headers = load2PConfig(DataFiles);
        
        % Determine Dimensions
        if numel(unique([Headers(:).Height])) ~= 1 || numel(unique([Headers(:).Width])) ~= 1 || numel(unique([Headers(:).Depth])) ~= 1
            error('Data need to be the same size...');
        end
        Height = Headers(1).Height;
        Width = Headers(1).Width;
        Depth = Headers(1).Depth;
        if strcmp(Headers(1).type,'sbx') && Headers(1).header{1}.scanbox_version == 1
            Width = 796;
        end
        
        % Determine number of frames to load from each file
        % single input => load same frames from each file
        numFrames = zeros(nFiles, 1);
        for index = 1:nFiles
            if (ischar(Frames{index}) && strcmp(Frames{index}, 'all')) || (numel(Frames{index})==1 && Frames{index} == inf) % load all frames from each file
                numFrames(index) = Headers(index).Frames;
            elseif Frames{index}(end) == inf
                numFrames(index) = numel([Frames{index}(1:end-2),Frames{index}(end-1):Headers(index).Frames]);
            else
                numFrames(index) = numel(Frames{index});
            end
        end
        
        % Determine Channels to Load (FILES ALL MUST HAVE DESIRED CHANNEL OR WILL
        % ERROR)
        if ischar(Channels) || (numel(Channels)==1 && Channels == inf)
            Channels = 1:Headers(1).Channels;
        elseif Channels(end) == inf
            Channels = [Channels(1:end-2),Channels(end-1):Headers(1).Channels];
        end
        
        % Load Images
        Images = zeros(Height, Width, Depth, numel(Channels), sum(numFrames), 'uint16');
        startFrame = cumsum([1;numFrames(1:end-1)]);
        ext = cell(nFiles, 1);
        for index = 1:nFiles
            [~,~,ext{index}] = fileparts(DataFiles{index});
            switch ext{index}
                case '.sbx'
                    Images(:,:,:,:,startFrame(index):startFrame(index)+numFrames(index)-1)...
                        = readSbx(DataFiles{index}, [], 'Type', 'Direct', 'Frames', Frames{index}, 'Channels', Channels);
                case '.tif'
                    Images(:,:,:,:,startFrame(index):startFrame(index)+numFrames(index)-1)...
                        = readScim(DataFiles{index}, 'Frames', Frames{index}, 'Channels', Channels);
                case '.imgs'
                    Images(:,:,:,:,startFrame(index):startFrame(index)+numFrames(index)-1)...
                        = readImgs(DataFiles{index}, 'Type', 'Direct', 'Frames', Frames{index}, 'Channels', Channels);
            end
            loadObj.filesLoaded(index) = true;
            loadObj.framesLoaded(index) = Frames(index);
        end
        
        if Double && ~isa(Images, 'double')
            Images = double(Images);
        end
        
%% Load MemMap
    case 'MemMap'
        if nFiles > 1
            warning('Cannot load more than one file with MemMap. Loading first file...');
            nFiles = 1;
        end
        Headers = load2PConfig(DataFiles{1});
        [~,~,ext] = fileparts(DataFiles{1});
        switch ext
            case '.sbx'
                loadObj.files{1} = readSbx(DataFiles{1}, [], 'Type', LoadType, 'Frames', Frames{1}, 'Channels', Channels);
                Images = loadObj.files{1}.Data.Frames;
            case '.tif'
                errordlg('Tif files do not allow for MemMap loading...');
            case '.imgs'
                loadObj.files{1} = readImgs(DataFiles{1}, 'Type', LoadType, 'Frames', Frames{1}, 'Channels', Channels);
                Images = loadObj.files{1}.Data.Frames;
        end
        loadObj.filesLoaded(1) = true;
        loadObj.framesLoaded(1) = Frames(1);
end

%% Parse Acquisition Information
if nFiles == 1
    Config = Headers;
else
    Config.header = {Headers};
    config.Processing = {};
    config.info = [];
    config.MotionCorrected = {Headers(:).MotionCorrected};
    config.FrameRate = mode([Headers(:).FrameRate]); % current default
    config.ZoomFactor = [Headers(:).ZoomFactor]; % current default
    config.ZStepSize = [Headers(:).ZStepSize]; % current default
    config.Precision = {Headers(:).Precision}; % default
    config.Colors = [];
end

% Update dimensions
[Config.Height, Config.Width, Config.Depth, Config.Channels, Config.Frames] = size(Images);
Config.DimensionOrder = {'Height', 'Width', 'Depth', 'Channels', 'Frames'};
Config.size = [Config.Height, Config.Width, Config.Depth, Config.Channels, Config.Frames];


%% Save Images
if SaveToMat
    [p,f,~] = fileparts(DataFiles{index});
    SaveFile = fullfile(p, [f,'.mat']); % automatically create filename to save to
    if exist('SaveFile', 'file') % if file previously exists, prompt for filename
        [SaveFile, p] = uiputfile({'.mat'}, 'Save images as:', p);
        SaveFile = fullfile(p,SaveFile);
    end
    [~,~,ext] = fileparts(SaveFile);
    switch ext
        case '.mat'
            save(SaveFile, 'Images', 'Config', 'numFrames', 'info', '-v7.3');
    end
end