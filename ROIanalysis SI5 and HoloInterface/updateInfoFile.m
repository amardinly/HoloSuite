function [info, InfoFile] = updateInfoFile(SbxFile, InfoFile)


%% Check input arguments
narginchk(0,2);
if ~exist('SbxFile', 'var') || isempty(SbxFile)
    if exist('InfoFile', 'var') && ~isempty(InfoFile)
        SbxFile = sbxIdentifyFiles(InfoFile);
        SbxFile = SbxFile{1};
    else
        [f,p] = uigetfile({'*.sbx'}, 'Select ''sbx'' file to convert to ''imgs'' file:');
        if isnumeric(f)
            return
        end
        SbxFile = fullfile(p,f);
    end
end
if ~exist('InfoFile', 'var') || isempty(InfoFile)
    InfoFile = sbxIdentifyFiles(SbxFile);
    InfoFile = InfoFile{1};
end


%% Load in info
load(InfoFile, 'info'); %load in 'info' variable

%% Determine # of channels
if ~isfield(info, 'numChannels')
    switch info.channels
        case 1
            info.numChannels = 2;      % both PMT0 & 1
        case 2
            info.numChannels = 1;      % PMT 0
        case 3
            info.numChannels = 1;      % PMT 1
    end
end

%% Determine frame height
if ~isfield(info, 'Height')
    info.Height = info.recordsPerBuffer;
end

%% Determine frame width
if ~isfield(info, 'Width')
    if isfield(info,'scanbox_version') && info.scanbox_version >= 2
        S = sparseint; %(info.postTriggerSamples/4)
        info.Width = size(S, 2);
    else
        info.scanbox_version = 1;
        info.Width = info.postTriggerSamples;
    end
end

%% Determine # of frames
if ~isfield(info, 'numFrames')
    d = dir(SbxFile);
    info.numFrames =  d.bytes/(info.Height*info.Width*info.numChannels*2); % "2" b/c assumes uint16 encoding => 2 bytes per sample
end

%% Save info to file
% save(InfoFile, 'info'); % save updated info

