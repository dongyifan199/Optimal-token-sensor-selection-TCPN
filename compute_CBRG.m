function CBRG = compute_CBRG(Pre, Post, M0, TE, TI, maxBasisNodes, maxImplicitNodes)
% compute_CBRG
% Faster drop-in implementation of the same CBRG construction.
%
% Input and output are unchanged. The implementation differs only in
% efficiency: for each basis marking, the T_I closure is computed once
% and then reused for all transitions in T_E.

    [m, o] = size(M0);
    n = size(Pre, 2);
    q = m * o;

    if nargin < 7 || isempty(maxBasisNodes)
        maxBasisNodes = inf;
    end

    if nargin < 8 || isempty(maxImplicitNodes)
        maxImplicitNodes = inf;
    end

    TE = TE(:).';
    TI = TI(:).';

    % Flatten Pre and Post once. Column t corresponds to transition t.
    PreFlat = zeros(q, n);
    DeltaFlat = zeros(q, n);

    for t = 1:n
        preT = zeros(m, o);
        postT = zeros(m, o);

        for p = 1:m
            preT(p, :) = Pre{p, t};
            postT(p, :) = Post{p, t};
        end

        PreFlat(:, t) = preT(:);
        DeltaFlat(:, t) = postT(:) - preT(:);
    end

    Markings = {M0};
    Edges = struct('source', {}, 'transition', {}, 'target', {}, 'y', {});

    visited = containers.Map('KeyType', 'char', 'ValueType', 'double');
    visited(marking_key(M0)) = 1;

    edgeMap = containers.Map('KeyType', 'char', 'ValueType', 'logical');

    queue = 1;
    queueTail = 1;
    head = 1;

    while head <= queueTail
        sourceID = queue(head);
        head = head + 1;

        M = Markings{sourceID};
        Mvec = M(:);

        % The implicit closure is independent of the explicit transition.
        [implicitMarkings, implicitCounts, numImplicitStates] = ...
            implicit_closure_fast(Mvec, PreFlat, DeltaFlat, TI, ...
                                  maxImplicitNodes);

        for idx = 1:numel(TE)
            t = TE(idx);

            enabledStateIDs = find(all( ...
                implicitMarkings(:, 1:numImplicitStates) >= PreFlat(:, t), ...
                1));

            if isempty(enabledStateIDs)
                continue;
            end

            keepExplanation = minimal_count_vectors( ...
                implicitCounts(:, enabledStateIDs));

            explanationStateIDs = enabledStateIDs(keepExplanation);

            for k = 1:numel(explanationStateIDs)
                sid = explanationStateIDs(k);

                MpreVec = implicitMarkings(:, sid);
                y = implicitCounts(:, sid).';

                MnextVec = MpreVec + DeltaFlat(:, t);

                if any(MnextVec < 0)
                    error('Negative marking generated.');
                end

                Mnext = reshape(MnextVec, m, o);
                keyNext = marking_key(Mnext);

                if ~isKey(visited, keyNext)
                    newID = numel(Markings) + 1;

                    if newID > maxBasisNodes
                        error(['CBRG construction stopped: ', ...
                               'maxBasisNodes exceeded.']);
                    end

                    Markings{newID} = Mnext;
                    visited(keyNext) = newID;

                    queueTail = queueTail + 1;
                    queue(queueTail) = newID;
                else
                    newID = visited(keyNext);
                end

                eKey = make_edge_key(sourceID, t, newID, y);

                if ~isKey(edgeMap, eKey)
                    edgeMap(eKey) = true;

                    e.source = sourceID;
                    e.transition = t;
                    e.target = newID;
                    e.y = y;

                    Edges(end + 1) = e; %#ok<AGROW>
                end
            end
        end
    end

    CBRG.Markings = Markings;
    CBRG.Edges = Edges;
    CBRG.NumNodes = numel(Markings);
    CBRG.NumEdges = numel(Edges);
    CBRG.TE = TE;
    CBRG.TI = TI;
end

function [Mstates, Ystates, numStates] = implicit_closure_fast( ...
    M0vec, PreFlat, DeltaFlat, TI, maxImplicitNodes)
% Enumerate the same implicit markings as the original implementation.
% Each marking retains the firing-count vector from its first BFS visit.

    q = numel(M0vec);
    nTI = numel(TI);

    initialCapacity = 64;

    if isfinite(maxImplicitNodes)
        initialCapacity = min(initialCapacity, maxImplicitNodes);
    end

    initialCapacity = max(initialCapacity, 1);

    Mstates = zeros(q, initialCapacity);
    Ystates = zeros(nTI, initialCapacity);

    Mstates(:, 1) = M0vec;

    visited = containers.Map('KeyType', 'char', 'ValueType', 'double');
    visited(marking_key(reshape(M0vec, [], 1))) = 1;

    queue = 1;
    queueTail = 1;
    head = 1;
    numStates = 1;
    capacity = initialCapacity;

    while head <= queueTail
        sid = queue(head);
        head = head + 1;

        Mcur = Mstates(:, sid);
        ycur = Ystates(:, sid);

        for k = 1:nTI
            t = TI(k);

            if all(Mcur >= PreFlat(:, t))
                Mnew = Mcur + DeltaFlat(:, t);
                keyNew = marking_key(reshape(Mnew, [], 1));

                if ~isKey(visited, keyNew)
                    numStates = numStates + 1;

                    if numStates > maxImplicitNodes
                        error(['Implicit exploration stopped: ', ...
                               'maxImplicitNodes exceeded. Check whether ', ...
                               'T_I-induced subnet is acyclic.']);
                    end

                    if numStates > capacity
                        newCapacity = max(2 * capacity, capacity + 1);

                        if isfinite(maxImplicitNodes)
                            newCapacity = min(newCapacity, maxImplicitNodes);
                        end

                        Mstates(:, newCapacity) = 0;

                        if nTI > 0
                            Ystates(:, newCapacity) = 0;
                        end

                        capacity = newCapacity;
                    end

                    Mstates(:, numStates) = Mnew;

                    if nTI > 0
                        ynew = ycur;
                        ynew(k) = ynew(k) + 1;
                        Ystates(:, numStates) = ynew;
                    end

                    visited(keyNew) = numStates;

                    queueTail = queueTail + 1;
                    queue(queueTail) = numStates;
                end
            end
        end
    end
end

function keep = minimal_count_vectors(Y)
% Return the same Pareto-minimal count vectors as the original nested
% loop. Columns of Y are candidate explanation vectors.

    numCandidates = size(Y, 2);
    keep = true(1, numCandidates);

    if numCandidates <= 1
        return;
    end

    for i = 1:numCandidates
        yi = Y(:, i);
        dominated = all(Y <= yi, 1) & any(Y < yi, 1);

        if any(dominated)
            keep(i) = false;
        end
    end
end

function key = make_edge_key(sourceID, transition, targetID, y)
    key = sprintf('%d|%d|%d|%s', ...
        sourceID, transition, targetID, sprintf('%d,', y));
end
