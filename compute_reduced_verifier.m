function RVA = compute_reduced_verifier(PV, A)
% compute_reduced_verifier
% Faster drop-in implementation of the same reduced-verifier construction.
% It uses cached PV arrays when they are available, but the formal output
% RVA is unchanged except for an optional internal cache.

    if isempty(A)
        A = false(size(PV.O_tau));
    end

    numV = PV.NumVertices;
    numE = PV.NumEdges;

    if ~isequal(size(A), size(PV.O_tau))
        error('A must have the same size as PV.O_tau.');
    end

    [Dflat, edgeSource, edgeTarget] = get_fast_pv_data(PV);

    selectedSensorIDs = find(A(:));

    if isempty(selectedSensorIDs)
        keep = true(1, numV);
    else
        keep = ~any(Dflat(selectedSensorIDs, :), 1);
    end

    if ~keep(PV.v0)
        error('The initial verifier vertex is removed. Please check D(v0).');
    end

    keepEdgeCandidate = keep(edgeSource) & keep(edgeTarget);

    % Reachability in the vertex-induced subgraph.
    reachable = false(1, numV);
    reachable(PV.v0) = true;

    candidateEdgeIDs = find(keepEdgeCandidate);

    if ~isempty(candidateEdgeIDs)
        adjacency = sparse( ...
            edgeSource(candidateEdgeIDs), ...
            edgeTarget(candidateEdgeIDs), ...
            1, numV, numV);

        queue = zeros(1, numV);
        queue(1) = PV.v0;
        queueTail = 1;
        head = 1;

        while head <= queueTail
            u = queue(head);
            head = head + 1;

            successors = find(adjacency(u, :));

            for k = 1:numel(successors)
                w = successors(k);

                if ~reachable(w)
                    reachable(w) = true;
                    queueTail = queueTail + 1;
                    queue(queueTail) = w;
                end
            end
        end
    end

    finalKeep = keep & reachable;
    keptOldVertices = find(finalKeep);

    oldToNew = zeros(1, numV);
    oldToNew(keptOldVertices) = 1:numel(keptOldVertices);

    if isempty(keptOldVertices)
        newVertices = struct([]);
    else
        newVertices = PV.Vertices(keptOldVertices);

        for i = 1:numel(keptOldVertices)
            newVertices(i).parentID = keptOldVertices(i);
        end
    end

    keptEdgeIDs = find(keepEdgeCandidate & ...
        finalKeep(edgeSource) & finalKeep(edgeTarget));

    if isempty(keptEdgeIDs)
        newEdges = struct([]);
        newEdgeSource = zeros(1, 0);
        newEdgeTarget = zeros(1, 0);
    else
        newEdges = PV.Edges(keptEdgeIDs);

        newEdgeSource = oldToNew(edgeSource(keptEdgeIDs));
        newEdgeTarget = oldToNew(edgeTarget(keptEdgeIDs));

        for i = 1:numel(keptEdgeIDs)
            newEdges(i).source = newEdgeSource(i);
            newEdges(i).target = newEdgeTarget(i);
            newEdges(i).parentID = keptEdgeIDs(i);
        end
    end

    RVA.Vertices = newVertices;
    RVA.Edges = newEdges;
    RVA.NumVertices = numel(newVertices);
    RVA.NumEdges = numel(newEdges);
    RVA.v0 = oldToNew(PV.v0);
    RVA.O_tau = PV.O_tau;
    RVA.A = A;

    % Optional internal cache used by find_ambiguous_witness.
    RVA.cache.edgeSource = newEdgeSource;
    RVA.cache.edgeTarget = newEdgeTarget;
end

function [Dflat, edgeSource, edgeTarget] = get_fast_pv_data(PV)
    if isfield(PV, 'cache') && ...
       isfield(PV.cache, 'Dflat') && ...
       isfield(PV.cache, 'edgeSource') && ...
       isfield(PV.cache, 'edgeTarget')

        Dflat = PV.cache.Dflat;
        edgeSource = PV.cache.edgeSource;
        edgeTarget = PV.cache.edgeTarget;
        return;
    end

    [m, o] = size(PV.O_tau);
    Dflat = false(m * o, PV.NumVertices);

    for v = 1:PV.NumVertices
        Dflat(:, v) = PV.Vertices(v).D(:);
    end

    edgeSource = zeros(1, PV.NumEdges);
    edgeTarget = zeros(1, PV.NumEdges);

    for e = 1:PV.NumEdges
        edgeSource(e) = PV.Edges(e).source;
        edgeTarget(e) = PV.Edges(e).target;
    end
end
