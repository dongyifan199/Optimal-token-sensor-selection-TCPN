function print_marking(M, placeNames, colorNames)
% Print a colored marking in tuple form, e.g.,
% M0 = (2,1,0)p_1 + (0,0,1)p_5

    terms = {};

    for p = 1:size(M,1)
        if any(M(p,:) ~= 0)
            tupleStr = sprintf('%d,', M(p,:));
            tupleStr = tupleStr(1:end-1);  % remove the last comma

            % Use p_1 style
            termStr = sprintf('(%s)%s', tupleStr, format_place_name(placeNames{p}));

            terms{end+1} = termStr; %#ok<AGROW>
        end
    end

    if isempty(terms)
        fprintf('0\n\n');
    else
        fprintf('%s\n\n', strjoin(terms, ' + '));
    end
end