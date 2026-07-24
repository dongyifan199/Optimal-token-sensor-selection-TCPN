function print_parametric_verifier(PV, FCBRG, CBRG, placeNames, transNames)
% print_parametric_verifier
% Print vertices and edges of the parametric verifier, including D(v) and eta.

    fprintf('Verifier vertices:\n');

    for v = 1:PV.NumVertices
        V = PV.Vertices(v);

        fprintf('v%d = (x%d, x%d), ', v-1, V.x1-1, V.x2-1);
        fprintf('x%d=(Mb%d,%s), x%d=(Mb%d,%s), ', ...
            V.x1-1, V.mb1-1, V.flag1, ...
            V.x2-1, V.mb2-1, V.flag2);

        fprintf('D(v%d)=', v-1);
        print_sensor_set(V.D);
        fprintf('\n');
    end

    fprintf('\nVerifier edges:\n');

    for k = 1:PV.NumEdges
        e = PV.Edges(k);

        label1 = edge_label(e.a1, FCBRG, transNames);
        label2 = edge_label(e.a2, FCBRG, transNames);

        fprintf('v%d --(%s,%s), eta=(%d,%d)--> v%d\n', ...
            e.source-1, label1, label2, e.eta(1), e.eta(2), e.target-1);
    end
end

%% ============================================================
% Helper functions
% ============================================================

function label = edge_label(a, FCBRG, transNames)
    if a == 0
        label = 'epsilon';
        return;
    end

    e = FCBRG.Edges(a);

    src = get_edge_source(e);
    tgt = get_edge_target(e);
    t = get_edge_trans(e);

    if t >= 1 && t <= length(transNames)
        tname = transNames{t};
    else
        tname = sprintf('t%d', t);
    end

    label = sprintf('e%d:%s[x%d->x%d]', a-1, tname, src-1, tgt-1);
end

function print_sensor_set(D)
    [pList, cList] = find(D);

    if isempty(pList)
        fprintf('{}');
        return;
    end

    fprintf('{');
    for i = 1:length(pList)
        if i > 1
            fprintf(', ');
        end
        fprintf('(p_%d,gamma%d)', pList(i), cList(i));
    end
    fprintf('}');
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

function t = get_edge_trans(e)
    if isfield(e, 'trans')
        t = e.trans;
    elseif isfield(e, 'transition')
        t = e.transition;
    elseif isfield(e, 't')
        t = e.t;
    else
        error('Cannot find transition field in a fault-CBRG edge.');
    end
end