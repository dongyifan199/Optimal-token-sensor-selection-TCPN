function yes = edge_exists(Edges, sourceID, transition, targetID, y)
% edge_exists
% Faster drop-in implementation with identical semantics.

    yes = false;

    if isempty(Edges)
        return;
    end

    sourceList = [Edges.source];
    transitionList = [Edges.transition];
    targetList = [Edges.target];

    candidates = find( ...
        sourceList == sourceID & ...
        transitionList == transition & ...
        targetList == targetID);

    for k = 1:numel(candidates)
        if isequal(Edges(candidates(k)).y, y)
            yes = true;
            return;
        end
    end
end
