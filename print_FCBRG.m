function print_FCBRG(FCBRG, CBRG, placeNames, transNames)
    fprintf('Number of fault CBRG vertices: %d\n', FCBRG.NumNodes);
    fprintf('Number of fault CBRG edges: %d\n\n', FCBRG.NumEdges);

    fprintf('Fault CBRG vertices:\n');
    for i = 1:FCBRG.NumNodes
        basisID = FCBRG.X(i).basis;
        flag = FCBRG.X(i).flag;

        if flag
            flagStr = 'F';
        else
            flagStr = 'N';
        end

        fprintf('x%d = (Mb%d,%s), ', i-1, basisID-1, flagStr);
        print_marking_tuple(CBRG.Markings{basisID}, placeNames);
    end

    fprintf('\nFault CBRG edges:\n');
    for k = 1:FCBRG.NumEdges
        fprintf('x%d --%s--> x%d\n', ...
            FCBRG.Edges(k).source-1, ...
            transNames{FCBRG.Edges(k).transition}, ...
            FCBRG.Edges(k).target-1);
    end
end