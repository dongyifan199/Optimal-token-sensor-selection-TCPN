function str = join_transition_names(Tset, transNames)
    if isempty(Tset)
        str = '';
        return;
    end

    names = cell(1,numel(Tset));
    for i = 1:numel(Tset)
        names{i} = transNames{Tset(i)};
    end
    str = strjoin(names, ', ');
end