function [VT, info] = build_warehouse_fault_set_revised( ...
    m, o, N1, N2, N3, K1, K2)
% BUILD_WAREHOUSE_FAULT_SET
%
% Construct a collection of C-GMECs for the warehouse robot TCPN.
%
% F1: M(p4,gamma2) >= 1
% F2: M(p3,gamma1)+M(p3,gamma2) >= K1
% F3: M(p11,gamma1)+M(p11,gamma2) >= K2
%
% F2 and F3 are represented as unions of C-GMECs. Therefore,
% is_faulty_marking(M,VT) must return true when M satisfies
% at least one C-GMEC in VT.

if K1 < 1 || K2 < 1
    error('K1 and K2 must be positive integers.');
end

if K1 > N1 + N2
    error('K1 is too large. Fault 2 cannot occur.');
end

if K2 > N1 + N2
    error('K2 is too large. Fault 3 cannot occur.');
end

upperBounds = [N1, N2, N3];

VT = struct('w', {}, 'd', {}, 'dprime', {});

% Fault 1: heavy robot in Shelf Area A.
[VT, n1] = append_threshold_fault( ...
    VT, m, o, 4, [0, 1, 0], 1, upperBounds);

% Fault 2: transport-robot congestion at Central Intersection.
[VT, n2] = append_threshold_fault( ...
    VT, m, o, 3, [1, 1, 0], K1, upperBounds);

% Fault 3: overload at Waiting Buffer.
[VT, n3] = append_threshold_fault( ...
    VT, m, o, 11, [1, 1, 0], K2, upperBounds);

info.NumFault1 = n1;
info.NumFault2 = n2;
info.NumFault3 = n3;

end

function [VT, numAdded] = append_threshold_fault( ...
    VT, m, o, placeIndex, weights, threshold, upperBounds)
%
% For each componentwise-minimal q satisfying
% weights*q >= threshold, construct one C-GMEC.
%
% The union of all generated C-GMECs is exactly equivalent to
% the threshold condition over the bounded marking space.

Qmin = find_minimal_threshold_vectors(weights, threshold, upperBounds);

numAdded = size(Qmin, 1);

for k = 1:numAdded

    q = Qmin(k, :);

    w = zeros(m, o);
    d = zeros(o, 1);
    dprime = ones(o, 1);

    for c = 1:o
        if weights(c) > 0
            w(placeIndex, c) = weights(c);
            d(c) = weights(c) * q(c);
            dprime(c) = weights(c) * upperBounds(c) + 1;
        end
    end

    VT(end + 1).w = w;
    VT(end).d = d;
    VT(end).dprime = dprime;
end

end

function Qmin = find_minimal_threshold_vectors( ...
    weights, threshold, upperBounds)
%
% Find every componentwise-minimal integer vector q such that
% weights*q >= threshold and 0 <= q <= upperBounds.

q1 = 0:upperBounds(1);
q2 = 0:upperBounds(2);
q3 = 0:upperBounds(3);

[Q1, Q2, Q3] = ndgrid(q1, q2, q3);
Q = [Q1(:), Q2(:), Q3(:)];

Q = Q(Q * weights(:) >= threshold, :);

if isempty(Q)
    error('No marking satisfies the specified fault threshold.');
end

isMinimal = true(size(Q, 1), 1);

for i = 1:size(Q, 1)
    smallerOrEqual = all(Q <= Q(i, :), 2);
    strictlySmaller = any(Q < Q(i, :), 2);

    if any(smallerOrEqual & strictlySmaller)
        isMinimal(i) = false;
    end
end

Qmin = unique(Q(isMinimal, :), 'rows');

end
