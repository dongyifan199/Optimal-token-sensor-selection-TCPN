function Td = compute_detectable_transitions(Pre, Post, O_tau)
    [m,n] = size(Pre);
    o = size(O_tau,2);
    Td = [];

    for t = 1:n
        Ccol = incidence_column(Pre, Post, t);
        detectable = false;

        for p = 1:m
            for c = 1:o
                if O_tau(p,c) && Ccol(p,c) ~= 0
                    detectable = true;
                    break;
                end
            end
            if detectable
                break;
            end
        end

        if detectable
            Td(end+1) = t; %#ok<AGROW>
        end
    end
end