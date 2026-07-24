function FCBRG = compute_FCBRG(CBRG, VT)
% compute_FCBRG
% Faster drop-in implementation. It constructs exactly the same fault
% CBRG, but precomputes outgoing CBRG edges and marking fault status.

    numBasis = CBRG.NumNodes;
    numCBEdges = CBRG.NumEdges;

    if numCBEdges == 0
        sourceList = zeros(1, 0);
        targetList = zeros(1, 0);
        transitionList = zeros(1, 0);
    else
        sourceList = [CBRG.Edges.source];
        targetList = [CBRG.Edges.target];
        transitionList = [CBRG.Edges.transition];
    end

    Out = build_outgoing_edge_lists(sourceList, numBasis);

    % A basis marking has a fixed instantaneous fault status. Compute it
    % once rather than once per FCBRG edge traversal.
    basisFault = false(1, numBasis);

    for b = 1:numBasis
        basisFault(b) = is_faulty_marking(CBRG.Markings{b}, VT);
    end

    X = struct('basis', {}, 'flag', {});
    EF = struct('source', {}, 'transition', {}, 'target', {});

    % The key is 2*basisID + flag. It is injective for basisID >= 1.
    visited = containers.Map('KeyType', 'uint64', 'ValueType', 'double');

    X(1).basis = 1;
    X(1).flag = basisFault(1);

    visited(make_fvertex_key(1, basisFault(1))) = 1;

    queue = 1;
    queueTail = 1;
    head = 1;

    while head <= queueTail
        xid = queue(head);
        head = head + 1;

        basisID = X(xid).basis;
        currentFlag = X(xid).flag;

        outgoing = Out{basisID};

        for pos = 1:numel(outgoing)
            edgeID = outgoing(pos);

            targetBasis = targetList(edgeID);
            nextFlag = currentFlag || basisFault(targetBasis);

            keyNext = make_fvertex_key(targetBasis, nextFlag);

            if ~isKey(visited, keyNext)
                newXID = numel(X) + 1;
                X(newXID).basis = targetBasis;
                X(newXID).flag = nextFlag;
                visited(keyNext) = newXID;

                queueTail = queueTail + 1;
                queue(queueTail) = newXID;
            else
                newXID = visited(keyNext);
            end

            ef.source = xid;
            ef.transition = transitionList(edgeID);
            ef.target = newXID;

            EF(end + 1) = ef; %#ok<AGROW>
        end
    end

    FCBRG.X = X;
    FCBRG.Edges = EF;
    FCBRG.x0 = 1;
    FCBRG.NumNodes = numel(X);
    FCBRG.NumEdges = numel(EF);
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

function key = make_fvertex_key(basisID, flag)
    key = uint64(2 * basisID + double(flag));
end
