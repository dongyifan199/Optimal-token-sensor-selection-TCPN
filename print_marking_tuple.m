function print_marking_tuple(M, placeNames)
    terms = {};

    for p = 1:size(M,1)
        if any(M(p,:) ~= 0)
            tupleStr = sprintf('%d,', M(p,:));
            tupleStr = tupleStr(1:end-1);

            pname = format_place_name(placeNames{p});
            termStr = sprintf('(%s)%s', tupleStr, pname);

            terms{end+1} = termStr; %#ok<AGROW>
        end
    end

    if isempty(terms)
        fprintf('0\n');
    else
        fprintf('%s\n', strjoin(terms, ' + '));
    end
end