function [AverageFrame, MaxProjection, MinProjection, Variance, Kurtosis] = computeProjections_workspace(Images, ExperimentFile, varargin)

computeAverage = true;
computeMax = true;
computeMin = true;
computeVar = true; % requires average
computeKur = false; % requires average and variance

saveOut = true;
loadPrevious = false;
MotionCorrect = false;

%% Initialize Parameters
index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case {'Avg','avg'}
                if numel(varargin{index+1}) == 1
                    computeAverage = varargin{index+1};
                else
                    computeAverage = true;
                    AverageFrame = varargin{index+1};
                end
                index = index + 2;
            case {'Max','max'}
                if numel(varargin{index+1}) == 1
                    computeAverage = varargin{index+1};
                else
                    computeAverage = true;
                    MaxProjection = varargin{index+1};
                end
                index = index + 2;
            case {'Min','min'}
                if numel(varargin{index+1}) == 1
                    computeAverage = varargin{index+1};
                else
                    computeAverage = true;
                    MinProjection = varargin{index+1};
                end
                index = index + 2;
            case {'Var','var'}
                if numel(varargin{index+1}) == 1
                    computeAverage = varargin{index+1};
                else
                    computeAverage = true;
                    Variance = varargin{index+1};
                end
                index = index + 2;
            case {'Kur','kur'}
                if numel(varargin{index+1}) == 1
                    computeAverage = varargin{index+1};
                else
                    computeAverage = true;
                    Kurtosis = varargin{index+1};
                end
                index = index + 2;
            case {'Save', 'save'}
                saveOut = true;
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


if saveOut || MotionCorrect || loadPrevious
    if ~exist('ExperimentFile','var') || isempty(ExperimentFile)
        directory = CanalSettings('ExperimentDirectory');
        [ExperimentFile, p] = uigetfile({'*.mat'},'Choose Experiment file',directory);
        if ~isnumeric(ExperimentFile)
            ExperimentFile = fullfile(p,ExperimentFile);
        end
    end
end

%% Determine # of frames to read in at a time

mem = memory;
sizeFrame = whos('Images');
sizeFrame = sizeFrame.bytes;
nFramesPerLoad = max(1, floor(0.1*mem.MaxPossibleArrayBytes/sizeFrame));

%% Determine # of frames in the file
fileConfig=Images.info; % = load2PConfig(ImageFile);
%fprintf('Computing projections of %d frames. Filename: %s\n', fileConfig.Frames, ImageFile{1});

%% Load Previous Values
if loadPrevious
    load(ExperimentFile, 'ImageFiles');
    if exist('ImageFiles', 'var')
        if isfield(ImageFiles, 'Average')
            computeAverage = false;
            AverageFrame = ImageFiles.Average;
        end
        if isfield(ImageFiles, 'Min')
            computeMin = false;
        end
        if isfield(ImageFiles, 'Max');
            computeMax = false;
        end
        if isfield(ImageFiles, 'Var');
            computeVar = false;
            Variance = ImageFiles.Var;
        end
        if isfield(ImageFiles, 'Kur');
            computeKur = false;
        end
    end
end

%% Motion correction
if MotionCorrect
    load(ExperimentFile, 'MCdata', '-mat');
    if ~exist('MCdata', 'var')
        MotionCorrect = false;
    end
end

%% Compute Average
dataConfig.size = Images.info.size;

if computeAverage || computeMax || computeMin
    if computeAverage && ~exist('AverageFrame', 'var')
        AverageFrame = zeros(dataConfig.size(1:end-1));
    end
    if computeMax && ~exist('MaxProjection', 'var')
        MaxProjection = zeros(dataConfig.size(1:end-1));
    end
    if computeMin && ~exist('MinProjection', 'var')
        MinProjection = inf(dataConfig.size(1:end-1));
    end
    framedim = numel(dataConfig.size); % assumes frames to be last dimension
    Frames = Images.frames;       % load2P(ImageFile, 'Type', 'Direct', 'Double'); %memmap
    
    nf=0;
    for n = 1:length(fileConfig)
        nf = nf+fileConfig(n).Frames;
    end;
    
    
     for f = 1:nFramesPerLoad:nf;
        lastframe = min(f+nFramesPerLoad-1, nf);
        Images = double(Frames(:,:,:,:,f:lastframe)); %memmap
%         Images = load2P(ImageFile, 'Type', 'Direct', 'Frames', f:lastframe, 'Double'); %direct
        if MotionCorrect
            Images = applyMotionCorrection(Images, MCdata, f:lastframe);
        end
        if computeAverage
            AverageFrame = AverageFrame + sum(Images, framedim)/nf;
        end
        if computeMax
            MaxProjection = max(cat(framedim, MaxProjection, Images), [], framedim);
        end
        if computeMin
            MinProjection = min(cat(framedim, MinProjection, Images), [], framedim);
        end
        if nFramesPerLoad >= nf
            if computeVar
                meanSubtracted = bsxfun(@minus, Images, AverageFrame);
                Variance = mean(meanSubtracted.^2, framedim);
            end
            if computeKur
                Kurtosis = mean(bsxfun(@rdivide, meanSubtracted, sqrt(Variance)).^4, framedim) - 3;
            end
        end
        fprintf('\tFinished frames %d through %d\n', f, lastframe);
    end
end

% Can't load all images at once => compute variance and kurtosis
% Variance calculation requires knowing the mean
if nFramesPerLoad < nf && computeVar
    fprintf('Computing Variance...\n');
    if ~exist('Variance', 'var')
        Variance = zeros(dataConfig.size(1:end-1));
    end
    for f = 1:nFramesPerLoad:nf;
        lastframe = min(f+nFramesPerLoad-1, nf);
        Images = double(Frames(:,:,:,:,f:lastframe)); %memmap
%         Images = load2P(ImageFile, 'Type', 'Direct', 'Frames', f:lastframe, 'Double'); %direct
        if MotionCorrect
            Images = applyMotionCorrection(Images, MCdata, f:lastframe);
        end
        Variance = Variance + sum(bsxfun(@minus, Images, AverageFrame).^2, framedim)/nf; %var = 1/T*sum((x_t-x_avg)^2)
        fprintf('\tVariance: Finished frames %d through %d\n', f, lastframe);
    end
end
% Kurtosis calculation requires knowing the mean and variance
if nFramesPerLoad < nf && computeKur
    fprintf('Computing Kurtosis...\n');
    if ~exist('Kurtosis', 'var')
        Kurtosis = zeros(dataConfig.size(1:end-1));
    end
    for f = 1:nFramesPerLoad:fileConfig.Frames;
        lastframe = min(f+nFramesPerLoad-1, fileConfig.Frames);
        Images = double(Frames(:,:,:,:,f:lastframe)); %memmap
%         Images = load2P(ImageFile, 'Type', 'Direct', 'Frames', f:lastframe, 'Double'); %direct
        if MotionCorrect
            Images = applyMotionCorrection(Images, MCdata, f:lastframe);
        end
        Kurtosis = Kurtosis + sum(bsxfun(@rdivide, bsxfun(@minus, Images, AverageFrame), sqrt(Variance)).^4, framedim)/fileConfig.Frames - 3; %kur = 1/T*sum(((x_t-x_avg)/x_var)^4)
        fprintf('\tKurtosis: Finished frames %d through %d\n', f, lastframe);
    end
end

%% Save to file
if saveOut && exist('ExperimentFile', 'var') && ischar(ExperimentFile)
    % Append to file
    %     load(ExperimentFile, 'ImageFiles', '-mat');
    %     if ~exist('ImageFiles', 'var')
    index = 1;
    %     else
    %         if any(strcmp({ImageFiles(:).filename}, ImgsFile));
    %             index = find(strcmp({ImageFiles(:).filename}, ImgsFile)); % replace
    %         else
    %             index = numel(ImageFiles + 1); % add to end
    %         end
    %     end
    %ImageFiles(index).filename = ImageFiles;
    if computeAverage
        ImageFiles(index).Average = AverageFrame;
    end
    if computeMax
        ImageFiles(index).Max = MaxProjection;
    end
    if computeMin
        ImageFiles(index).Min = MinProjection;
    end
    if computeVar
        ImageFiles(index).Var = Variance;
    end
    if computeKur
        ImageFiles(index).Kur = Kurtosis;
    end
    save(ExperimentFile, 'ImageFiles', '-append');
    fprintf('Saved projections to: %s\n', ExperimentFile);
end