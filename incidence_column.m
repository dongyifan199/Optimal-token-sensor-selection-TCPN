function Ccol = incidence_column(Pre, Post, t)
    m = size(Pre,1);
    o = numel(Pre{1,t});

    Ccol = zeros(m,o);

    for p = 1:m
        Ccol(p,:) = Post{p,t} - Pre{p,t};
    end
end