%% run_CBRG_FCBRG_current_example.m
% Construct CBRG, Fault CBRG, and Parametric Verifier
% for the current TCPN example.
%
% Current settings:
% O_tau = {(p1,gamma1),(p5,gamma3),(p6,gamma1),(p6,gamma2),(p6,gamma3)}
%
% Fault C-GMEC:
% vt1: M(p6)(gamma3) = 1

clear; clc; close all;

%% ============================================================
%  1. Define the TCPN structure
% ============================================================

m = 6;      % places p1,...,p6
n = 6;      % transitions t1,...,t6
o = 3;      % colors gamma1,gamma2,gamma3

placeNames = {'p1','p2','p3','p4','p5','p6'};
transNames = {'t1','t2','t3','t4','t5','t6'};
colorNames = {'gamma1','gamma2','gamma3'};

Pre  = cell(m,n);
Post = cell(m,n);

for p = 1:m
    for t = 1:n
        Pre{p,t}  = zeros(1,o);
        Post{p,t} = zeros(1,o);
    end
end

% Color tuple order:
% [gamma1, gamma2, gamma3]

%% t1: p1 -- gamma1 --> t1 -- gamma1 --> p2
Pre{1,1}  = [1 0 0];
Post{2,1} = [1 0 0];

%% t2: p1 -- gamma2 --> t2 -- gamma2 --> p3
Pre{1,2}  = [0 1 0];
Post{3,2} = [0 1 0];

%% t3: p2 -- gamma1 --> t3 -- gamma1 --> p1
Pre{2,3}  = [1 0 0];
Post{1,3} = [1 0 0];

%% t4: p2 -- gamma1 --> t4, p3 -- gamma2 --> t4,
%      t4 -- gamma1+gamma2 --> p4
Pre{2,4}  = [1 0 0];
Pre{3,4}  = [0 1 0];
Post{4,4} = [1 1 0];

%% t5: p4 -- gamma1+gamma2 --> t5, p5 -- gamma3 --> t5,
%      t5 -- gamma1+gamma2 --> p4, t5 -- gamma1+gamma2+gamma3 --> p6
% p4 is a self-loop resource for t5.
Pre{4,5}  = [1 1 0];
Pre{5,5}  = [0 0 1];
Post{4,5} = [1 1 0];
Post{6,5} = [1 1 1];

%% t6: p6 -- gamma1+gamma2+gamma3 --> t6 -- gamma3 --> p5
Pre{6,6}  = [1 1 1];
Post{5,6} = [0 0 1];

%% Initial marking
M0 = zeros(m,o);
M0(1,:) = [2 1 0];    % p1 has two gamma1 and one gamma2
M0(5,:) = [0 0 1];    % p5 has one gamma3

%% ============================================================
%  2. Define O_tau
% ============================================================

O_tau = false(m,o);

O_tau(1,1) = true;    % (p1,gamma1)
O_tau(5,3) = true;    % (p5,gamma3)
O_tau(6,1) = true;    % (p6,gamma1)
O_tau(6,2) = true;    % (p6,gamma2)
O_tau(6,3) = true;    % (p6,gamma3)

%% ============================================================
%  3. Define C-GMEC VT
% ============================================================
% New fault specification:
% vt1: M(p6)(gamma3) = 1
%
% In the form:
% d <= diag(w^T * Mbar) < dprime
%
% We choose w(6,3)=1 and all other entries zero.
% Then diag(w^T*Mbar) = [0; 0; M(p6)(gamma3)].
%
% d      = [0;0;1]
% dprime = [1;1;2]
%
% Thus 1 <= M(p6)(gamma3) < 2, i.e., M(p6)(gamma3)=1.

VT = struct([]);

VT(1).w = zeros(m,o);
VT(1).w(6,3) = 1;

VT(1).d      = [0; 0; 1];
VT(1).dprime = [1; 1; 2];

%% ============================================================
%  4. Compute T_d(O_tau), T_VT, T_E, and T_I
% ============================================================

Td  = compute_detectable_transitions(Pre, Post, O_tau);
TVT = compute_CGMEC_relevant_transitions(Pre, Post, VT);

TE = unique([Td TVT]);
TI = setdiff(1:n, TE);

fprintf('T_d(O_tau) = {%s}\n', join_transition_names(Td, transNames));
fprintf('T_VT       = {%s}\n', join_transition_names(TVT, transNames));
fprintf('T_E        = {%s}\n', join_transition_names(TE, transNames));
fprintf('T_I        = {%s}\n\n', join_transition_names(TI, transNames));

%% ============================================================
%  5. Construct the CBRG
% ============================================================

maxBasisNodes = 10000;
maxImplicitNodes = 10000;

CBRG = compute_CBRG(Pre, Post, M0, TE, TI, maxBasisNodes, maxImplicitNodes);

fprintf('\n================ CBRG ================\n');
print_CBRG(CBRG, placeNames, transNames);

%% ============================================================
%  6. Construct the Fault CBRG
% ============================================================

FCBRG = compute_FCBRG(CBRG, VT);

fprintf('\n================ Fault CBRG ================\n');
print_FCBRG(FCBRG, CBRG, placeNames, transNames);

%% ============================================================
%  7. Print faulty/nonfaulty status of basis markings
% ============================================================

fprintf('\n================ Fault Status of Basis Markings ================\n');
for i = 1:CBRG.NumNodes
    M = CBRG.Markings{i};
    if is_faulty_marking(M, VT)
        status = 'F';
    else
        status = 'N';
    end
    fprintf('Mb%d: %s, ', i-1, status);
    print_marking_tuple(M, placeNames);
end

%% ============================================================
%  8. Construct the Parametric Verifier
% ============================================================

PV = compute_parametric_verifier(FCBRG, CBRG, O_tau);

fprintf('\n================ Parametric Verifier ================\n');
print_parametric_verifier(PV, FCBRG, CBRG, placeNames, transNames);

%% ============================================================
%  9. Test reduced verifiers and ambiguous cycles
% ============================================================

A_empty = false(m,o);
RVA_empty = compute_reduced_verifier(PV, A_empty);
hasAmb_empty = has_ambiguous_cycle(RVA_empty);

fprintf('\nA = empty set: has ambiguous cycle = %d\n', hasAmb_empty);

A_p6g3 = false(m,o);
A_p6g3(6,3) = true;
RVA_p6g3 = compute_reduced_verifier(PV, A_p6g3);
hasAmb_p6g3 = has_ambiguous_cycle(RVA_p6g3);

fprintf('A = {(p6,gamma3)}: has ambiguous cycle = %d\n', hasAmb_p6g3);


%% ============================================================
%  10. Algorithm 2: optimal sensor selection
% ============================================================

sensorCost = zeros(m, o);

sensorCost(1,1) = 1;   % c(p1,gamma1)
sensorCost(5,3) = 2;   % c(p5,gamma3)
sensorCost(6,1) = 3;   % c(p6,gamma1)
sensorCost(6,2) = 3;   % c(p6,gamma2)
sensorCost(6,3) = 4;   % c(p6,gamma3)

fprintf('\n================ Algorithm 2 ================\n');

[Astar, result] = optimal_sensor_selection(PV, O_tau, sensorCost);

if strcmp(result.status, 'optimal')
    fprintf('\nFinal optimal sensor set:\n');

    [selectedPlaces, selectedColors] = find(Astar);

    for k = 1:numel(selectedPlaces)
        fprintf('  (p%d,gamma%d)\n', ...
            selectedPlaces(k), selectedColors(k));
    end

    fprintf('Minimum cost: %.6g\n', result.cost);
else
    fprintf('\nNo diagnosable sensor set exists.\n');
end