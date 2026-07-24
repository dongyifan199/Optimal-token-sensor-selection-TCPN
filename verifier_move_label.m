function label = verifier_move_label(a, FCBRG, transNames)
% a is either 0 for epsilon or an index of FCBRG.Edges.

    if a == 0
        label = 'epsilon';
    else
        t = FCBRG.Edges(a).transition;
        src = FCBRG.Edges(a).source;
        tgt = FCBRG.Edges(a).target;

        label = sprintf('e%d:%s[x%d->x%d]', a-1, transNames{t}, src-1, tgt-1);
    end
end
