function D = compute_D_for_verifier_vertex(x1, x2, FCBRG, CBRG, O_tau)
% Compute the distinguishing-sensor set D(v).
%
% D(p,c)=true iff (p,gamma_c) belongs to O_tau and
% the two basis markings have different token counts at (p,c).

    basis1 = FCBRG.X(x1).basis;
    basis2 = FCBRG.X(x2).basis;

    M1 = CBRG.Markings{basis1};
    M2 = CBRG.Markings{basis2};

    D = O_tau & (M1 ~= M2);
end