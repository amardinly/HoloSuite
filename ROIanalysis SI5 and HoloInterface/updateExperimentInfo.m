function updateExperimentInfo(ExperimentFile)


%% Check input arguments
narginchk(0, 1);
if ~exist('ExperimentFile','var') || isempty(ExperimentFile)
    directory = CanalSettings('ExperimentDirectory');
    [ExperimentFile, p] = uigetfile({'*.mat'},'Choose Experiment file',directory);
    if isnumeric(ExperimentFile)
        return
    end
    ExperimentFile = fullfile(p,ExperimentFile);
end


%% Update info
vars = whos(matfile(ExperimentFile));
if ~strcmp('ID', {vars.name})
    [~,f,~] = fileparts(ExperimentFile);
    strings = strsplit(f, '_');
    ID = strings{1};
    Depth = strings{2};
    Tag = strings{3};
    Location = strcat(Tag(1),',',Tag(2),',',Depth);
    save(ExperimentFile, 'ID', 'Depth', 'Tag', 'Location', '-append');
    fprintf('File %s updated:ID=%s, Depth=%s, Tag=%s', ExperimentFile,ID,Depth,Tag);
end