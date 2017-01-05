function [header, config] = createImgsHeader(config, varargin)


%% Set Version Defaults
version = 1;
delimeter = ';';
config.version = version;
config.AlignmentType = 0;


%% Check input arguments & overwrite any input fields or create new ones
narginchk(1, inf);
for index = 1:2:length(varargin)
    config.(varargin{index}) = varargin{index + 1};
end


%% Update fields dependent on other fields
config.size = sizeDimensions(config); % size dependent on ordering and length of each dimension


%% Build Header String
header = sprintf('%s', delimeter);
fn = fieldnames(config);
data = struct2cell(config);
for index = 1:length(fn)
    if isnumeric(data{index})
        data{index} = mat2str(data{index});
    end
    if ~iscell(data{index})
        header = [header, sprintf('%s=%s%s', fn{index}, data{index}, delimeter)];
    end
end