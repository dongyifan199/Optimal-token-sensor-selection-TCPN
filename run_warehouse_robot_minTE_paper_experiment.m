function results = run_warehouse_robot_minTE_paper_experiment()
% RUN_WAREHOUSE_ROBOT_PARAMETRIC_EXPERIMENT
%
% Parametric experiments for optimal token sensor selection in a
% warehouse robot tagged colored Petri net.
%
% Required existing functions:
%   compute_detectable_transitions.m
%   compute_CGMEC_relevant_transitions.m
%   compute_CBRG.m
%   compute_FCBRG.m
%   compute_parametric_verifier.m
%   compute_reduced_verifier.m
%   has_ambiguous_cycle.m
%   optimal_sensor_selection.m
%   build_warehouse_minTE_fault_set.m
%
% Fault definitions:
%   F1: M(p11,gamma1) >= K1
%   F2: M(p11,gamma2) >= K2
%   F3: M(p12,gamma1) >= K3
%
% The script writes:
%   warehouse_robot_paper_results.csv
%   warehouse_robot_paper_results.mat

clc;
close all;

fprintf('\n');
fprintf('====================================================\n');
fprintf('MINIMUM-TE warehouse robot experiment is running\n');
fprintf('Paper-oriented seven-case experiment is running\n');
fprintf('Expected |T_E| = 10 and |T_I| = 16\n');
fprintf('====================================================\n');

%% 1. Parametric cases
% Columns: [CaseID, N1, N2, N3, K1, K2, K3]
% N1 = number of ordinary transport robots (gamma1)
% N2 = number of heavy transport robots (gamma2)
% N3 = number of inspection robots (gamma3)
% K1 = ordinary-robot waiting-buffer threshold at p11
% K2 = heavy-robot waiting-buffer threshold at p11
% K3 = ordinary-robot return-zone threshold at p12
%
% Cases 1--4 vary N3.
% Cases 5--6 vary N1.
% Case 7 keeps the robot population of Case 6 and changes the thresholds.

caseData = [
    1, 1, 1, 1, 1, 1, 1;
    2, 1, 1, 2, 1, 1, 1;
    3, 1, 1, 3, 1, 1, 1;
    4, 1, 1, 4, 1, 1, 1;
    5, 2, 1, 1, 2, 1, 2;
    6, 3, 1, 1, 2, 1, 2;
    7, 3, 1, 1, 3, 1, 3
];

% Run all seven cases by default.
% For a quick test, use for example:
% selectedCaseRows = 1:3;
selectedCaseRows = 1:size(caseData, 1);

caseData = caseData(selectedCaseRows, :);

maxBasisNodes = 200000;
maxImplicitNodes = 200000;

% Full reachability graph generation is optional and can be expensive.
computeFullRG = false;
maxRGNodes = 200000;

%% 2. TCPN structure

m = 12;
n = 26;
o = 3;

transNames = arrayfun(@(k) sprintf('t%d', k), 1:n, ...
    'UniformOutput', false);

Pre = cell(m, n);
Post = cell(m, n);

for p = 1:m
    for t = 1:n
        Pre{p, t} = zeros(1, o);
        Post{p, t} = zeros(1, o);
    end
end

% gamma1 route:
% p1 -> p2 -> p3 -> p4 -> p6 -> p7 -> p12 -> p1
[Pre, Post] = add_single_color_move(Pre, Post,  1,  1,  2, 1);
[Pre, Post] = add_single_color_move(Pre, Post,  3,  2,  3, 1);
[Pre, Post] = add_single_color_move(Pre, Post,  5,  3,  4, 1);
[Pre, Post] = add_single_color_move(Pre, Post,  7,  4,  6, 1);
[Pre, Post] = add_single_color_move(Pre, Post,  9,  6,  7, 1);
[Pre, Post] = add_single_color_move(Pre, Post, 11,  7, 12, 1);
[Pre, Post] = add_single_color_move(Pre, Post, 13, 12,  1, 1);

% gamma2 route:
% p1 -> p2 -> p3 -> p5 -> p6 -> p7 -> p12 -> p1
[Pre, Post] = add_single_color_move(Pre, Post,  2,  1,  2, 2);
[Pre, Post] = add_single_color_move(Pre, Post,  4,  2,  3, 2);
[Pre, Post] = add_single_color_move(Pre, Post,  6,  3,  5, 2);
[Pre, Post] = add_single_color_move(Pre, Post,  8,  5,  6, 2);
[Pre, Post] = add_single_color_move(Pre, Post, 10,  6,  7, 2);
[Pre, Post] = add_single_color_move(Pre, Post, 12,  7, 12, 2);
[Pre, Post] = add_single_color_move(Pre, Post, 14, 12,  1, 2);

% gamma3 inspection route:
% p8 -> p9 -> p3 -> p6 -> p8
[Pre, Post] = add_single_color_move(Pre, Post, 15, 8, 9, 3);
[Pre, Post] = add_single_color_move(Pre, Post, 16, 9, 3, 3);
[Pre, Post] = add_single_color_move(Pre, Post, 17, 3, 6, 3);
[Pre, Post] = add_single_color_move(Pre, Post, 18, 6, 8, 3);

% gamma1 waiting-buffer route:
% p3 -> p11 -> p3
[Pre, Post] = add_single_color_move(Pre, Post, 19, 3, 11, 1);
[Pre, Post] = add_single_color_move(Pre, Post, 20, 11, 3, 1);

% gamma2 waiting-buffer route:
% p3 -> p11 -> p3
[Pre, Post] = add_single_color_move(Pre, Post, 21, 3, 11, 2);
[Pre, Post] = add_single_color_move(Pre, Post, 22, 11, 3, 2);

% gamma2 maintenance route:
% p6 -> p10 -> p1
[Pre, Post] = add_single_color_move(Pre, Post, 23, 6, 10, 2);
[Pre, Post] = add_single_color_move(Pre, Post, 24, 10, 1, 2);

% gamma2 routing-fault route:
% p3 -> p4 -> p6
[Pre, Post] = add_single_color_move(Pre, Post, 25, 3, 4, 2);
[Pre, Post] = add_single_color_move(Pre, Post, 26, 4, 6, 2);

%% 3. Available sensors and costs

O_tau = false(m, o);
sensorCost = zeros(m, o);

% This is the smallest sensor arrangement that breaks all five
% transition-disjoint cycles of the fixed warehouse TCPN without
% introducing any additional detectable transition.
%
% The resulting detectable-transition set is:
% T_d = {t11,t12,t13,t14,t15,t18,t19,t20,t21,t22}.

% Return Zone p12: cuts the gamma1 and gamma2 main transport cycles
O_tau(12, 1) = true; sensorCost(12, 1) = 3;
O_tau(12, 2) = true; sensorCost(12, 2) = 3;

% Waiting Buffer p11: cuts the two buffer cycles
O_tau(11, 1) = true; sensorCost(11, 1) = 2;
O_tau(11, 2) = true; sensorCost(11, 2) = 2;

% Charging Station p8: cuts the inspection-robot cycle
O_tau(8, 3) = true; sensorCost(8, 3) = 2;

fprintf('Selected candidate sensors: %s\n', sensor_set_to_string(O_tau));
fprintf('Expected T_d = {t11,t12,t13,t14,t15,t18,t19,t20,t21,t22}.\n');
fprintf('Expected T_VT = {t11,t13,t19,t20,t21,t22}.\n');
fprintf('Expected T_E = {t11,t12,t13,t14,t15,t18,t19,t20,t21,t22}.\n\n');

%% 4. Result storage

numCases = size(caseData, 1);

CaseID = caseData(:, 1);
N1List = caseData(:, 2);
N2List = caseData(:, 3);
N3List = caseData(:, 4);
K1List = caseData(:, 5);
K2List = caseData(:, 6);
K3List = caseData(:, 7);

NumCGMEC = nan(numCases, 1);
RGNodes = nan(numCases, 1);
CBRGNodes = nan(numCases, 1);
FCBRGNodes = nan(numCases, 1);
PVVertices = nan(numCases, 1);
PVEdges = nan(numCases, 1);
EmptySetHasAmbiguousCycle = nan(numCases, 1);
Iterations = nan(numCases, 1);
OptimalCost = nan(numCases, 1);
BuildTime = nan(numCases, 1);
OptimizationTime = nan(numCases, 1);
TotalTime = nan(numCases, 1);

RGStatus = strings(numCases, 1);
Status = strings(numCases, 1);
OptimalSensors = strings(numCases, 1);
ErrorMessage = strings(numCases, 1);

%% 5. Run cases

for r = 1:numCases

    caseID = caseData(r, 1);
    N1 = caseData(r, 2);
    N2 = caseData(r, 3);
    N3 = caseData(r, 4);
    K1 = caseData(r, 5);
    K2 = caseData(r, 6);
    K3 = caseData(r, 7);

    fprintf('\n============================================\n');
    fprintf('Warehouse Robot Experiment: Case %d\n', caseID);
    fprintf('N1=%d, N2=%d, N3=%d, K1=%d, K2=%d, K3=%d\n', ...
        N1, N2, N3, K1, K2, K3);
    fprintf('============================================\n');

    caseTimer = tic;

    try
        % Initial marking
        M0 = zeros(m, o);
        M0(1, :) = [N1, N2, 0];
        M0(8, :) = [0, 0, N3];

        % Fault C-GMEC collection
        [VT, faultInfo] = build_warehouse_minTE_fault_set( ...
            m, o, N1, N2, N3, K1, K2, K3);

        NumCGMEC(r) = numel(VT);

        fprintf('Fault 1 C-GMECs: %d\n', faultInfo.NumFault1);
        fprintf('Fault 2 C-GMECs: %d\n', faultInfo.NumFault2);
        fprintf('Fault 3 C-GMECs: %d\n', faultInfo.NumFault3);

        % Optional full reachability graph
        if computeFullRG
            [RGNodes(r), complete] = count_reachable_markings( ...
                M0, Pre, Post, maxRGNodes);

            if complete
                RGStatus(r) = "exact";
            else
                RGStatus(r) = "reached limit";
            end
        else
            RGStatus(r) = "not computed";
        end

        % CBRG, fault CBRG, and parametric verifier
        buildTimer = tic;

        Td = compute_detectable_transitions(Pre, Post, O_tau);
        TVT = compute_CGMEC_relevant_transitions(Pre, Post, VT);

        TE = unique([Td, TVT]);
        TI = setdiff(1:n, TE);

        fprintf('T_d(O_tau) = {%s}\n', ...
            join_transition_names_local(Td, transNames));
        fprintf('T_VT = {%s}\n', ...
            join_transition_names_local(TVT, transNames));
        fprintf('T_E = {%s}\n', ...
            join_transition_names_local(TE, transNames));
        fprintf('T_I = {%s}\n', ...
            join_transition_names_local(TI, transNames));

        CBRG = compute_CBRG( ...
            Pre, Post, M0, TE, TI, maxBasisNodes, maxImplicitNodes);

        FCBRG = compute_FCBRG(CBRG, VT);

        PV = compute_parametric_verifier(FCBRG, CBRG, O_tau);

        BuildTime(r) = toc(buildTimer);

        CBRGNodes(r) = get_structure_count( ...
            CBRG, {'NumNodes', 'NumVertices', 'Markings', 'Mb'});

        FCBRGNodes(r) = get_structure_count( ...
            FCBRG, {'NumNodes', 'NumVertices', 'Vertices', 'States', 'X'});

        PVVertices(r) = get_structure_count( ...
            PV, {'NumVertices', 'NumNodes', 'Vertices', 'V'});

        PVEdges(r) = get_structure_count( ...
            PV, {'NumEdges', 'NumArcs', 'Edges', 'E_V', 'E'});

        fprintf('CBRG nodes: %.0f\n', CBRGNodes(r));
        fprintf('Fault CBRG nodes: %.0f\n', FCBRGNodes(r));
        fprintf('Parametric verifier vertices: %.0f\n', PVVertices(r));
        fprintf('Parametric verifier edges: %.0f\n', PVEdges(r));

        % Test the empty sensor set
        Aempty = false(m, o);
        RVAempty = compute_reduced_verifier(PV, Aempty);

        EmptySetHasAmbiguousCycle(r) = ...
            has_ambiguous_cycle(RVAempty);

        fprintf('Empty sensor set has ambiguous cycle: %d\n', ...
            EmptySetHasAmbiguousCycle(r));

        % Algorithm 2
        optimizationTimer = tic;

        [Astar, result] = optimal_sensor_selection( ...
            PV, O_tau, sensorCost);

        OptimizationTime(r) = toc(optimizationTimer);

        if strcmp(result.status, 'optimal')
            Status(r) = "optimal";
            OptimalCost(r) = result.cost;
            OptimalSensors(r) = string(sensor_set_to_string(Astar));

            if isfield(result, 'history')
                Iterations(r) = numel(result.history);
            end

            fprintf('Optimal sensor set: %s\n', OptimalSensors(r));
            fprintf('Minimum cost: %.6g\n', OptimalCost(r));
        else
            Status(r) = "infeasible";
            OptimalSensors(r) = "{}";

            if isfield(result, 'history')
                Iterations(r) = numel(result.history);
            end

            fprintf('No diagnosable sensor set exists.\n');
        end

        TotalTime(r) = toc(caseTimer);

    catch ME
        Status(r) = "error";
        ErrorMessage(r) = string(ME.message);
        TotalTime(r) = toc(caseTimer);

        fprintf('\nCase %d failed.\n', caseID);
        fprintf('%s\n', ME.message);
    end
end

%% 6. Export paper-oriented results
% Keep the full internal results for debugging, but return and export
% only the columns used in the manuscript table.

fullResults = table( ...
    CaseID, N1List, N2List, N3List, K1List, K2List, K3List, ...
    NumCGMEC, RGNodes, RGStatus, ...
    CBRGNodes, FCBRGNodes, PVVertices, PVEdges, ...
    EmptySetHasAmbiguousCycle, Iterations, OptimalCost, ...
    OptimalSensors, BuildTime, OptimizationTime, TotalTime, ...
    Status, ErrorMessage);

results = table( ...
    CaseID, N1List, N2List, N3List, K1List, K2List, K3List, ...
    CBRGNodes, FCBRGNodes, PVVertices, OptimalCost, TotalTime);

disp(' ');
disp('================ Paper-Oriented Results ================');
disp(results);

writetable(results, 'warehouse_robot_paper_results.csv');

save('warehouse_robot_paper_results.mat', ...
    'results', 'fullResults', 'caseData', 'O_tau', 'sensorCost');

fprintf('\nPaper-oriented results saved to:\n');
fprintf('  warehouse_robot_paper_results.csv\n');
fprintf('  warehouse_robot_paper_results.mat\n');

end

function [Pre, Post] = add_single_color_move( ...
    Pre, Post, transitionIndex, inputPlace, outputPlace, colorIndex)

vIn = Pre{inputPlace, transitionIndex};
vOut = Post{outputPlace, transitionIndex};

vIn(colorIndex) = 1;
vOut(colorIndex) = 1;

Pre{inputPlace, transitionIndex} = vIn;
Post{outputPlace, transitionIndex} = vOut;

end

function output = join_transition_names_local(indices, transNames)

if isempty(indices)
    output = '';
    return;
end

output = strjoin(transNames(indices), ', ');

end

function count = get_structure_count(S, candidateNames)

count = NaN;

for k = 1:numel(candidateNames)
    name = candidateNames{k};

    if isstruct(S) && isfield(S, name)
        value = S.(name);

        if isnumeric(value) && isscalar(value)
            count = double(value);
        else
            count = numel(value);
        end

        return;
    end
end

end

function text = sensor_set_to_string(A)

[places, colors] = find(A);

if isempty(places)
    text = '{}';
    return;
end

items = cell(1, numel(places));

for k = 1:numel(places)
    items{k} = sprintf('(p%d,gamma%d)', places(k), colors(k));
end

text = ['{', strjoin(items, ', '), '}'];

end

function [count, complete] = count_reachable_markings( ...
    M0, Pre, Post, maxNodes)

[m, n] = size(Pre);

queue = {M0};
head = 1;

visited = containers.Map('KeyType', 'char', 'ValueType', 'logical');
visited(marking_key(M0)) = true;

count = 1;
complete = true;

while head <= numel(queue)

    M = queue{head};
    head = head + 1;

    for t = 1:n
        enabled = true;

        for p = 1:m
            if any(M(p, :) < Pre{p, t})
                enabled = false;
                break;
            end
        end

        if ~enabled
            continue;
        end

        Mnext = M;

        for p = 1:m
            Mnext(p, :) = Mnext(p, :) - Pre{p, t} + Post{p, t};
        end

        key = marking_key(Mnext);

        if ~isKey(visited, key)
            if count >= maxNodes
                complete = false;
                return;
            end

            visited(key) = true;
            queue{end + 1} = Mnext;
            count = count + 1;
        end
    end
end

end

function key = marking_key(M)

key = sprintf('%d_', M(:));

end
