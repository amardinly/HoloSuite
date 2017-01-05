function Filename = checkFilename(Filename, autoincrement)

% Check input arguments
if ~exist('Filename', 'var') || isempty(Filename)
    [f,p] = uiputfile({'*.*'}, 'Save file as');
    if isnumeric(f)
        return
    end
    Filename = fullfile(p,f);
    return
end
if ~exist('autoincrement', 'var') || isempty(autoincrement)
    autoincrement = true;
end

%% Code
if exist(Filename,'file') % if file already exists, question whether to overwrite or delete
    if autoincrement
        index = 1;
        [fn, ext] = strtok(Filename, '.');
        while exist( strcat(fn, num2str(index), ext), 'file')
            index = index + 1;
        end
        Filename = strcat(fn, num2str(index), ext);
    else % prompt for filename to save to
        decision=questdlg(sprintf('%s already exists. Overwrite?',Filename),'Filename','Yes','No','Yes');
        switch decision
            case 'Yes'
                delete(Filename);
            case 'No'
                [~,~,ext]=fileparts(Filename);
                [f,p]=uiputfile(ext,'Save file to:',Filename);
                if isnumeric(f)
                    Filename = [];
                    return
                end
                Filename=[p,f];
                if exist(Filename, 'file') % user chose to overwrite the file
                    delete(Filename);
                end
            case ''
                Filename = [];
                return
        end
    end
end