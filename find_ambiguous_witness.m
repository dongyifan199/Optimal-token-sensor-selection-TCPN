function [hasAmbiguous, W] = find_ambiguous_witness(RVA)
% find_ambiguous_witness
% Faster drop-in implementation. It preserves the same criterion:
% a confused cycle is ambiguous only if the faulty component makes at
% least one real move on that cycle.

    hasAmbiguous = false;
    W = [];

    if RVA.NumVertices == 0
        return;
    end

    numV = RVA.NumVertices;
    numE = RVA.NumEdges;

    isConfused = false(1, numV);

    for v = 1:numV
        isConfused(v) = ~strcmp( ...
            RVA.Vertices(v).flag1, RVA.Vertices(v).flag2);
    end

    confusedVertices = find(isConfused);

    if isempty(confusedVertices) || numE == 0
        return;
    end

    [edgeSource, edgeTarget] = get_rva_edge_arrays(RVA);

    confusedEdgeIDs = find( ...
        isConfused(edgeSource) & isConfused(edgeTarget));

    if isempty(confusedEdgeIDs)
        return;
    end

    Gconf = digraph( ...
        edgeSource(confusedEdgeIDs), ...
        edgeTarget(confusedEdgeIDs), [], numV);

    comp = conncomp(Gconf, 'Type', 'strong');
    compIDs = unique(comp(confusedVertices));

    outgoing = build_outgoing_edge_lists(edgeSource, numV);

    for cidx = 1:numel(compIDs)
        cid = compIDs(cidx);
        nodes = find((comp == cid) & isConfused);

        if isempty(nodes)
            continue;
        end

        if numel(nodes) >= 2
            isCyclic = true;
        else
            u = nodes(1);
            isCyclic = any( ...
                edgeSource(confusedEdgeIDs) == u & ...
                edgeTarget(confusedEdgeIDs) == u);
        end

        if ~isCyclic
            continue;
        end

        v0c = nodes(1);
        flag1 = RVA.Vertices(v0c).flag1;
        flag2 = RVA.Vertices(v0c).flag2;

        if strcmp(flag1, 'F') && strcmp(flag2, 'N')
            faultySide = 1;
        elseif strcmp(flag1, 'N') && strcmp(flag2, 'F')
            faultySide = 2;
        else
            continue;
        end

        inCurrentSCC = false(1, numV);
        inCurrentSCC(nodes) = true;

        progressEdgeID = [];

        for kk = 1:numel(confusedEdgeIDs)
            eid = confusedEdgeIDs(kk);

            if inCurrentSCC(edgeSource(eid)) && ...
               inCurrentSCC(edgeTarget(eid)) && ...
               RVA.Edges(eid).eta(faultySide) == 1

                progressEdgeID = eid;
                break;
            end
        end

        if isempty(progressEdgeID)
            continue;
        end

        eProg = RVA.Edges(progressEdgeID);
        u = eProg.source;
        v = eProg.target;

        if u == v
            cycleVertices = [u, u];
            cycleEdges = progressEdgeID;
        else
            [pathVU, pathEdgeVU] = shortest_path_with_edge_ids_fast( ...
                RVA, v, u, nodes, outgoing);

            if isempty(pathVU)
                continue;
            end

            cycleVertices = [u, pathVU];
            cycleEdges = [progressEdgeID, pathEdgeVU];
        end

        [pathInit, pathEdgeInit] = shortest_path_with_edge_ids_fast( ...
            RVA, RVA.v0, u, 1:numV, outgoing);

        if isempty(pathInit)
            continue;
        end

        W.path.vertices = pathInit;
        W.path.edges = pathEdgeInit;

        W.cycle.vertices = cycleVertices;
        W.cycle.edges = cycleEdges;

        Vset = unique([pathInit, cycleVertices]);
        W.V = Vset;

        B = false(size(RVA.O_tau));

        for ii = 1:numel(Vset)
            B = B | RVA.Vertices(Vset(ii)).D;
        end

        W.B = B;

        hasAmbiguous = true;
        return;
    end
end

function [edgeSource, edgeTarget] = get_rva_edge_arrays(RVA)
    if isfield(RVA, 'cache') && ...
       isfield(RVA.cache, 'edgeSource') && ...
       isfield(RVA.cache, 'edgeTarget')

        edgeSource = RVA.cache.edgeSource;
        edgeTarget = RVA.cache.edgeTarget;
        return;
    end

    edgeSource = zeros(1, RVA.NumEdges);
    edgeTarget = zeros(1, RVA.NumEdges);

    for e = 1:RVA.NumEdges
        edgeSource(e) = RVA.Edges(e).source;
        edgeTarget(e) = RVA.Edges(e).target;
    end
end

function Out = build_outgoing_edge_lists(edgeSource, numVertices)
    Out = cell(1, numVertices);

    if isempty(edgeSource)
        return;
    end

    counts = accumarray(edgeSource(:), 1, [numVertices, 1]).';
    positions = ones(1, numVertices);

    for v = 1:numVertices
        if counts(v) > 0
            Out{v} = zeros(1, counts(v));
        end
    end

    for e = 1:numel(edgeSource)
        s = edgeSource(e);
        Out{s}(positions(s)) = e;
        positions(s) = positions(s) + 1;
    end
end

function [pathVertices, pathEdges] = shortest_path_with_edge_ids_fast( ...
    RVA, source, target, allowedNodes, outgoing)

    allowed = false(1, RVA.NumVertices);
    allowed(allowedNodes) = true;

    if ~allowed(source) || ~allowed(target)
        pathVertices = [];
        pathEdges = [];
        return;
    end

    visited = false(1, RVA.NumVertices);
    predNode = zeros(1, RVA.NumVertices);
    predEdge = zeros(1, RVA.NumVertices);

    queue = zeros(1, RVA.NumVertices);
    queue(1) = source;
    queueTail = 1;
    head = 1;
    visited(source) = true;

    while head <= queueTail
        u = queue(head);
        head = head + 1;

        if u == target
            break;
        end

        outgoingEdges = outgoing{u};

        for k = 1:numel(outgoingEdges)
            eid = outgoingEdges(k);
            w = RVA.Edges(eid).target;

            if allowed(w) && ~visited(w)
                visited(w) = true;
                predNode(w) = u;
                predEdge(w) = eid;

                queueTail = queueTail + 1;
                queue(queueTail) = w;
            end
        end
    end

    if ~visited(target)
        pathVertices = [];
        pathEdges = [];
        return;
    end

    lengthPath = 1;
    cur = target;

    while cur ~= source
        lengthPath = lengthPath + 1;
        cur = predNode(cur);
    end

    pathVertices = zeros(1, lengthPath);
    pathEdges = zeros(1, lengthPath - 1);

    cur = target;
    pathVertices(lengthPath) = target;

    for pos = lengthPath - 1:-1:1
        pathEdges(pos) = predEdge(cur);
        cur = predNode(cur);
        pathVertices(pos) = cur;
    end
end
