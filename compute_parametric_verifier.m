function PV = compute_parametric_verifier(FCBRG, CBRG, O_tau)
% compute_parametric_verifier
% Faster drop-in implementation of the same reachable asynchronous-product
% construction. The definition and output fields of the parametric
% verifier are unchanged. PV.cache contains optional internal arrays used
% by compute_reduced_verifier for faster repeated Algorithm-2 iterations.

    numX = get_num_fcb_nodes(FCBRG);
    numEF = get_num_fcb_edges(FCBRG);

    [basisOfX, isFaultyX] = get_all_fcb_node_info(FCBRG, numX);

    if numEF == 0
        edgeSource = zeros(1, 0);
        edgeTarget = zeros(1, 0);
    else
        edgeSource = zeros(1, numEF);
        edgeTarget = zeros(1, numEF);

        for e = 1:numEF
            edgeSource(e) = get_edge_source(FCBRG.Edges(e));
            edgeTarget(e) = get_edge_target(FCBRG.Edges(e));
        end
    end

    Out = build_outgoing_edge_lists(edgeSource, numX);

    initialVertexCapacity = 256;
    initialEdgeCapacity = 1024;

    x1List = zeros(1, initialVertexCapacity);
    x2List = zeros(1, initialVertexCapacity);

    pvSource = zeros(1, initialEdgeCapacity);
    pvTarget = zeros(1, initialEdgeCapacity);
    pvA1 = zeros(1, initialEdgeCapacity);
    pvA2 = zeros(1, initialEdgeCapacity);
    pvEta1 = false(1, initialEdgeCapacity);
    pvEta2 = false(1, initialEdgeCapacity);

    numVertices = 1;
    numEdges = 0;
    vertexCapacity = initialVertexCapacity;
    edgeCapacity = initialEdgeCapacity;

    x1List(1) = 1;
    x2List(1) = 1;

    % Pair key: x1 + numX*(x2-1), which is injective.
    keyMap = containers.Map('KeyType', 'uint64', 'ValueType', 'double');
    keyMap(make_pair_key(1, 1, numX)) = 1;

    queue = 1;
    queueTail = 1;
    head = 1;

    while head <= queueTail
        vid = queue(head);
        head = head + 1;

        x1 = x1List(vid);
        x2 = x2List(vid);

        moves1 = [Out{x1}, 0];
        moves2 = [Out{x2}, 0];

        for idx1 = 1:numel(moves1)
            a1 = moves1(idx1);

            if a1 == 0
                x1p = x1;
            else
                x1p = edgeTarget(a1);
            end

            for idx2 = 1:numel(moves2)
                a2 = moves2(idx2);

                if a1 == 0 && a2 == 0
                    continue;
                end

                if a2 == 0
                    x2p = x2;
                else
                    x2p = edgeTarget(a2);
                end

                key = make_pair_key(x1p, x2p, numX);

                if isKey(keyMap, key)
                    vpid = keyMap(key);
                else
                    numVertices = numVertices + 1;

                    if numVertices > vertexCapacity
                        newCapacity = max(2 * vertexCapacity, ...
                                          vertexCapacity + 1);
                        x1List(newCapacity) = 0;
                        x2List(newCapacity) = 0;
                        vertexCapacity = newCapacity;
                    end

                    vpid = numVertices;
                    x1List(vpid) = x1p;
                    x2List(vpid) = x2p;
                    keyMap(key) = vpid;

                    queueTail = queueTail + 1;
                    queue(queueTail) = vpid;
                end

                numEdges = numEdges + 1;

                if numEdges > edgeCapacity
                    newCapacity = max(2 * edgeCapacity, edgeCapacity + 1);

                    pvSource(newCapacity) = 0;
                    pvTarget(newCapacity) = 0;
                    pvA1(newCapacity) = 0;
                    pvA2(newCapacity) = 0;
                    pvEta1(newCapacity) = false;
                    pvEta2(newCapacity) = false;

                    edgeCapacity = newCapacity;
                end

                pvSource(numEdges) = vid;
                pvTarget(numEdges) = vpid;
                pvA1(numEdges) = a1;
                pvA2(numEdges) = a2;
                pvEta1(numEdges) = (a1 ~= 0);
                pvEta2(numEdges) = (a2 ~= 0);
            end
        end
    end

    x1List = x1List(1:numVertices);
    x2List = x2List(1:numVertices);

    pvSource = pvSource(1:numEdges);
    pvTarget = pvTarget(1:numEdges);
    pvA1 = pvA1(1:numEdges);
    pvA2 = pvA2(1:numEdges);
    pvEta1 = pvEta1(1:numEdges);
    pvEta2 = pvEta2(1:numEdges);

    [m, o] = size(O_tau);
    numEntries = m * o;
    Dflat = false(numEntries, numVertices);

    Vertices = repmat(struct( ...
        'x1', 0, 'x2', 0, 'mb1', 0, 'mb2', 0, ...
        'flag1', 'N', 'flag2', 'N', 'D', false(m, o)), ...
        1, numVertices);

    for v = 1:numVertices
        x1 = x1List(v);
        x2 = x2List(v);

        mb1 = basisOfX(x1);
        mb2 = basisOfX(x2);

        D = (CBRG.Markings{mb1} ~= CBRG.Markings{mb2}) & O_tau;
        Dflat(:, v) = D(:);

        Vertices(v).x1 = x1;
        Vertices(v).x2 = x2;
        Vertices(v).mb1 = mb1;
        Vertices(v).mb2 = mb2;
        Vertices(v).flag1 = fault_flag_to_char(isFaultyX(x1));
        Vertices(v).flag2 = fault_flag_to_char(isFaultyX(x2));
        Vertices(v).D = D;
    end

    Edges = repmat(struct( ...
        'source', 0, 'target', 0, 'a1', 0, 'a2', 0, ...
        'eta', [false, false]), 1, numEdges);

    for e = 1:numEdges
        Edges(e).source = pvSource(e);
        Edges(e).target = pvTarget(e);
        Edges(e).a1 = pvA1(e);
        Edges(e).a2 = pvA2(e);
        Edges(e).eta = [pvEta1(e), pvEta2(e)];
    end

    PV.Vertices = Vertices;
    PV.Edges = Edges;
    PV.NumVertices = numVertices;
    PV.NumEdges = numEdges;
    PV.v0 = 1;
    PV.O_tau = O_tau;

    % Optional implementation cache. It does not change the formal PV.
    PV.cache.edgeSource = pvSource;
    PV.cache.edgeTarget = pvTarget;
    PV.cache.Dflat = Dflat;
end

function Out = build_outgoing_edge_lists(sourceList, numNodes)
    Out = cell(1, numNodes);

    if isempty(sourceList)
        return;
    end

    counts = accumarray(sourceList(:), 1, [numNodes, 1]).';
    positions = ones(1, numNodes);

    for i = 1:numNodes
        if counts(i) > 0
            Out{i} = zeros(1, counts(i));
        end
    end

    for edgeID = 1:numel(sourceList)
        s = sourceList(edgeID);
        Out{s}(positions(s)) = edgeID;
        positions(s) = positions(s) + 1;
    end
end

function key = make_pair_key(x1, x2, numX)
    key = uint64(x1) + uint64(numX) * uint64(x2 - 1);
end

function n = get_num_fcb_nodes(FCBRG)
    if isfield(FCBRG, 'NumNodes')
        n = FCBRG.NumNodes;
    elseif isfield(FCBRG, 'NumVertices')
        n = FCBRG.NumVertices;
    elseif isfield(FCBRG, 'Nodes')
        n = numel(FCBRG.Nodes);
    elseif isfield(FCBRG, 'Vertices')
        n = numel(FCBRG.Vertices);
    elseif isfield(FCBRG, 'X')
        n = numel(FCBRG.X);
    else
        error('Cannot determine the number of fault-CBRG vertices.');
    end
end

function n = get_num_fcb_edges(FCBRG)
    if isfield(FCBRG, 'NumEdges')
        n = FCBRG.NumEdges;
    elseif isfield(FCBRG, 'Edges')
        n = numel(FCBRG.Edges);
    else
        error('Cannot determine the number of fault-CBRG edges.');
    end
end

function [basisOfX, isFaultyX] = get_all_fcb_node_info(FCBRG, numX)
    basisOfX = zeros(1, numX);
    isFaultyX = false(1, numX);

    for x = 1:numX
        [basisOfX(x), flag] = get_fcb_node_info(FCBRG, x);
        isFaultyX(x) = strcmp(flag, 'F');
    end
end

function src = get_edge_source(e)
    if isfield(e, 'source')
        src = e.source;
    elseif isfield(e, 'src')
        src = e.src;
    elseif isfield(e, 'from')
        src = e.from;
    else
        error('Cannot find source field in an edge.');
    end
end

function tgt = get_edge_target(e)
    if isfield(e, 'target')
        tgt = e.target;
    elseif isfield(e, 'tgt')
        tgt = e.tgt;
    elseif isfield(e, 'to')
        tgt = e.to;
    else
        error('Cannot find target field in an edge.');
    end
end

function [mb, flag] = get_fcb_node_info(FCBRG, x)
    if isfield(FCBRG, 'Nodes')
        node = FCBRG.Nodes(x);
    elseif isfield(FCBRG, 'Vertices')
        node = FCBRG.Vertices(x);
    elseif isfield(FCBRG, 'X')
        node = FCBRG.X(x);
    else
        error('Cannot find fault-CBRG vertex information.');
    end

    if isfield(node, 'mb')
        mb = node.mb;
    elseif isfield(node, 'Mb')
        mb = node.Mb;
    elseif isfield(node, 'basis')
        mb = node.basis;
    elseif isfield(node, 'basisIndex')
        mb = node.basisIndex;
    elseif isfield(node, 'marking')
        mb = node.marking;
    elseif isfield(node, 'markingIndex')
        mb = node.markingIndex;
    elseif isfield(node, 'Mindex')
        mb = node.Mindex;
    else
        error('Cannot find basis marking index in fault-CBRG vertex.');
    end

    if isfield(node, 'flag')
        flag = normalize_flag(node.flag);
    elseif isfield(node, 'status')
        flag = normalize_flag(node.status);
    elseif isfield(node, 'label')
        flag = normalize_flag(node.label);
    elseif isfield(node, 'ell')
        flag = normalize_flag(node.ell);
    else
        error('Cannot find fault flag in fault-CBRG vertex.');
    end
end

function flag = normalize_flag(f)
    if ischar(f) || isstring(f)
        if strcmpi(char(f), 'F')
            flag = 'F';
        elseif strcmpi(char(f), 'N')
            flag = 'N';
        else
            error('Unknown fault flag.');
        end
    elseif isnumeric(f) || islogical(f)
        if f == 1
            flag = 'F';
        else
            flag = 'N';
        end
    else
        error('Unknown fault flag type.');
    end
end

function flag = fault_flag_to_char(isFaulty)
    if isFaulty
        flag = 'F';
    else
        flag = 'N';
    end
end
