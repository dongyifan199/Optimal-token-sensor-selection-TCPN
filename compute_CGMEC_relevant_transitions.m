function TVT = compute_CGMEC_relevant_transitions(Pre, Post, VT)
    [~,n] = size(Pre);
    TVT = [];

    for t = 1:n
        Ccol = incidence_column(Pre, Post, t);
        relevant = false;

        for s = 1:numel(VT)
            w = VT(s).w;
            delta = diag(w' * Ccol);

            if any(delta ~= 0)
                relevant = true;
                break;
            end
        end

        if relevant
            TVT(end+1) = t; %#ok<AGROW>
        end
    end
end