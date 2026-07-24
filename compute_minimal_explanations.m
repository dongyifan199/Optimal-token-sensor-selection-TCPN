function explanations = compute_minimal_explanations( ...
    Pre, Post, M, t_explicit, TI, maxImplicitNodes)
% compute_minimal_explanations
% Faster drop-in implementation. The input/output and the definition of
% a minimal explanation are unchanged.

    [m, o] = size(M);
    n = size(Pre, 2);
    q = m * o;

    TI = TI(:).';

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

    if isempty(TI)
        if all(M(:) >= PreFlat(:, t_explicit))
            explanations = struct('MpreT', M, 'y', zeros(1, 0));
        else
            explanations = struct('MpreT', {}, 'y', {});
        end

        return;
    end

    [Mstates, Ystates, numStates] = implicit_closure_fast( ...
        M(:), PreFlat, DeltaFlat, TI, maxImplicitNodes);

    candidateIDs = find(all( ...
        Mstates(:, 1:numStates) >= PreFlat(:, t_explicit), 1));

    if isempty(candidateIDs)
        explanations = struct('MpreT', {}, 'y', {});
        return;
    end

    keep = minimal_count_vectors(Ystates(:, candidateIDs));
    candidateIDs = candidateIDs(keep);

    explanations = struct('MpreT', cell(1, numel(candidateIDs)), ...
                          'y', cell(1, numel(candidateIDs)));

    for k = 1:numel(candidateIDs)
        sid = candidateIDs(k);

        explanations(k).MpreT = reshape(Mstates(:, sid), m, o);
        explanations(k).y = Ystates(:, sid).';
    end
end

function [Mstates, Ystates, numStates] = implicit_closure_fast( ...
    M0vec, PreFlat, DeltaFlat, TI, maxImplicitNodes)

    q = numel(M0vec);
    nTI = numel(TI);

    capacity = 64;

    if isfinite(maxImplicitNodes)
        capacity = min(capacity, maxImplicitNodes);
    end

    capacity = max(capacity, 1);

    Mstates = zeros(q, capacity);
    Ystates = zeros(nTI, capacity);
    Mstates(:, 1) = M0vec;

    visited = containers.Map('KeyType', 'char', 'ValueType', 'double');
    visited(marking_key(reshape(M0vec, [], 1))) = 1;

    queue = 1;
    queueTail = 1;
    head = 1;
    numStates = 1;

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

                    ynew = ycur;
                    ynew(k) = ynew(k) + 1;
                    Ystates(:, numStates) = ynew;

                    visited(keyNew) = numStates;

                    queueTail = queueTail + 1;
                    queue(queueTail) = numStates;
                end
            end
        end
    end
end

function keep = minimal_count_vectors(Y)
    numCandidates = size(Y, 2);
    keep = true(1, numCandidates);

    for i = 1:numCandidates
        yi = Y(:, i);
        dominated = all(Y <= yi, 1) & any(Y < yi, 1);

        if any(dominated)
            keep(i) = false;
        end
    end
end
