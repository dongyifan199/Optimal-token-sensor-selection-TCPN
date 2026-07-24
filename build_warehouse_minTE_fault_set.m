function [VT, info] = build_warehouse_minTE_fault_set( ...
    m, o, N1, N2, N3, K1, K2, K3)
% BUILD_WAREHOUSE_MINTE_FAULT_SET
%
% This minimum-TE benchmark uses three single-color fault conditions:
%
% F1: M(p11,gamma1) >= K1
%     Ordinary-robot accumulation in the Waiting Buffer.
%
% F2: M(p11,gamma2) >= K2
%     Heavy-robot accumulation in the Waiting Buffer.
%
% F3: M(p12,gamma1) >= K3
%     Ordinary-robot congestion in the Return Zone.
%
% Each fault is described by exactly one C-GMEC. Thus, unlike the
% previous aggregate-threshold formulation, no union of multiple
% C-GMECs is required.

if K1 < 1 || K2 < 1 || K3 < 1
    error('K1, K2, and K3 must be positive integers.');
end

if K1 > N1
    error('K1 is too large. Fault 1 cannot occur.');
end

if K2 > N2
    error('K2 is too large. Fault 2 cannot occur.');
end

if K3 > N1
    error('K3 is too large. Fault 3 cannot occur.');
end

VT = struct('w', {}, 'd', {}, 'dprime', {});

% Fault 1: M(p11,gamma1) >= K1.
VT(1) = make_single_color_CGMEC(m, o, 11, 1, K1, N1);

% Fault 2: M(p11,gamma2) >= K2.
VT(2) = make_single_color_CGMEC(m, o, 11, 2, K2, N2);

% Fault 3: M(p12,gamma1) >= K3.
VT(3) = make_single_color_CGMEC(m, o, 12, 1, K3, N1);

info.NumFault1 = 1;
info.NumFault2 = 1;
info.NumFault3 = 1;

end

function vt = make_single_color_CGMEC( ...
    m, o, placeIndex, colorIndex, threshold, upperBound)
% Construct:
% threshold <= M(placeIndex,colorIndex) < upperBound+1.

vt.w = zeros(m, o);
vt.w(placeIndex, colorIndex) = 1;

vt.d = zeros(o, 1);
vt.dprime = ones(o, 1);

vt.d(colorIndex) = threshold;
vt.dprime(colorIndex) = upperBound + 1;

end
