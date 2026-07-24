function yes = verifier_edge_exists(Edges, source, a1, a2, target)
    yes = false;

    for k = 1:numel(Edges)
        if Edges(k).source == source && ...
           Edges(k).a1 == a1 && ...
           Edges(k).a2 == a2 && ...
           Edges(k).target == target
            yes = true;
            return;
        end
    end
end