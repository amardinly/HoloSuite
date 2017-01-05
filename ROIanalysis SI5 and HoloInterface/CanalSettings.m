function out = CanalSettings(item)
% Load default setting from settings file

switch item
    
    % Directory where raw images are stored
    case 'DataDirectory'
        load('CanalSettings', 'DataDirectory');
        if ~exist('DataDirectory', 'var') || ~isdir(DataDirectory)
            DataDirectory = cd;
        end
        out = DataDirectory;
        
    % Directory where raw experiment files are stored
    case 'ExperimentDirectory'
        load('CanalSettings', 'ExperimentDirectory');
        if ~exist('ExperimentDirectory', 'var') || ~isdir(ExperimentDirectory)
            ExperimentDirectory = cd;
        end
        out = ExperimentDirectory;
        
    % Directory where data is backed up to
    case 'StorageDirectory'
        load('CanalSettings', 'StorageDirectory');
        if ~exist('StorageDirectory', 'var') || ~isdir(StorageDirectory)
            StorageDirectory = cd;
        end
        out = StorageDirectory;
        
end