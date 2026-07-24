function faulty = is_faulty_marking(M, VT)
% is_faulty_marking
% Return true if M satisfies at least one C-GMEC in VT.
% This is algebraically identical to diag(w' * M), but avoids forming
% the full color-by-color product matrix.

    faulty = false;

    for s = 1:numel(VT)
        w = VT(s).w;
        d = VT(s).d(:);
        dprime = VT(s).dprime(:);

        val = sum(w .* M, 1).';

        if all(val >= d) && all(val < dprime)
            faulty = true;
            return;
        end
    end
end
