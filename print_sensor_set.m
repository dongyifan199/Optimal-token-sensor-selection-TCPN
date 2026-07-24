function print_sensor_set(D, placeNames)
% Print D = {(p,gamma_c) | D(p,c)=true}.

    [m,o] = size(D);
    terms = {};

    for p = 1:m
        for c = 1:o
            if D(p,c)
                terms{end+1} = sprintf('(%s,gamma%d)', format_place_name(placeNames{p}), c); %#ok<AGROW>
            end
        end
    end

    if isempty(terms)
        fprintf('{}');
    else
        fprintf('{%s}', strjoin(terms, ', '));
    end
end