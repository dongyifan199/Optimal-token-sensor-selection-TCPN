function enabled = is_enabled(M, Pre, t)
    m = size(M,1);
    enabled = true;

    for p = 1:m
        if any(M(p,:) < Pre{p,t})
            enabled = false;
            return;
        end
    end
end