function Mnext = fire_transition(M, Pre, Post, t)
% Fire transition t at marking M.

    m = size(M,1);
    Mnext = M;

    for p = 1:m
        Mnext(p,:) = Mnext(p,:) - Pre{p,t} + Post{p,t};
    end

    if any(Mnext(:) < 0)
        error('Negative marking generated.');
    end
end