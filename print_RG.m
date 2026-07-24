function print_RG(RG, placeNames, colorNames, transNames)
    fprintf('Reachable markings:\n');
    for i = 1:RG.NumNodes
        fprintf('M%d:\n', i-1);
        print_marking(RG.Markings{i}, placeNames, colorNames);
    end

    fprintf('\nEdges:\n');
    for k = 1:RG.NumEdges
        fprintf('M%d --%s--> M%d\n', ...
            RG.Edges(k).source-1, ...
            transNames{RG.Edges(k).transition}, ...
            RG.Edges(k).target-1);
    end
end