function print_CBRG(CBRG, placeNames, transNames)
    fprintf('Number of basis markings: %d\n', CBRG.NumNodes);
    fprintf('Number of CBRG edges: %d\n\n', CBRG.NumEdges);

    fprintf('Basis markings:\n');
    for i = 1:CBRG.NumNodes
        fprintf('Mb%d = ', i-1);
        print_marking_tuple(CBRG.Markings{i}, placeNames);
    end

    fprintf('\nCBRG edges:\n');

    for k = 1:CBRG.NumEdges
        ystr = vector_to_string(CBRG.Edges(k).y);
        fprintf('Mb%d --%s, y=%s--> Mb%d\n', ...
            CBRG.Edges(k).source-1, ...
            transNames{CBRG.Edges(k).transition}, ...
            ystr, ...
            CBRG.Edges(k).target-1);
    end
end
