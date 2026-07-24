function hasAmbiguous = has_ambiguous_cycle(RVA)
% has_ambiguous_cycle
% Return true if the reduced verifier contains an ambiguous cycle.

    [hasAmbiguous, ~] = find_ambiguous_witness(RVA);
end