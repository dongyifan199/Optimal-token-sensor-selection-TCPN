function [Astar, result] = optimal_sensor_selection(PV, O_tau, sensorCost)
% optimal_sensor_selection
% Implementation of Algorithm 2:
% Computation of a Minimum-Cost Diagnosable Sensor Set.
%
% Inputs:
%   PV          : parametric verifier
%   O_tau       : m-by-o logical matrix of available sensors
%   sensorCost  : m-by-o matrix of nonnegative sensor costs
%
% Outputs:
%   Astar       : optimal selected sensor set; empty if infeasible
%   result      : structure containing status, witnesses, constraints,
%                 iteration history, and final cost
%
% Required external functions:
%   compute_reduced_verifier.m
%   find_ambiguous_witness.m
%
% The function find_ambiguous_witness must use the updated definition of
% ambiguous cycle: the faulty component must make at least one real move.

    [m, o] = size(O_tau);

    if ~isequal(size(sensorCost), [m, o])
        error('sensorCost must have the same size as O_tau.');
    end

    sensorIndices = find(O_tau);
    nSensors = numel(sensorIndices);

    if nSensors == 0
        error('The available sensor set O_tau is empty.');
    end

    costVector = sensorCost(sensorIndices);
    costVector = costVector(:);

    if any(costVector < 0)
        error('All available sensor costs must be nonnegative.');
    end

    intcon = 1:nSensors;
    lowerBound = zeros(nSensors, 1);
    upperBound = ones(nSensors, 1);

    options = optimoptions('intlinprog', 'Display', 'off');

    % Each row represents one witness constraint.
    constraintMatrix = zeros(0, nSensors);

    witnesses = {};
    history = struct('candidate', {}, 'cost', {}, ...
                     'hasAmbiguousCycle', {}, 'witness', {}, 'B', {});

    iteration = 0;
    Astar = [];

    while true
        iteration = iteration + 1;

        if isempty(constraintMatrix)
            Aineq = [];
            bineq = [];
        else
            % sum_{sensor in B(W)} x_sensor >= 1
            % is converted to -B(W)x <= -1.
            Aineq = -constraintMatrix;
            bineq = -ones(size(constraintMatrix, 1), 1);
        end

        [x, fval, exitflag] = intlinprog( ...
            costVector, intcon, Aineq, bineq, [], [], ...
            lowerBound, upperBound, options);

        if exitflag <= 0
            fprintf('\nAlgorithm 2 result: infeasible.\n');

            result.status = 'infeasible';
            result.Astar = [];
            result.cost = [];
            result.witnesses = witnesses;
            result.constraintMatrix = constraintMatrix;
            result.history = history;
            return;
        end

        A = false(m, o);
        A(sensorIndices) = x > 0.5;

        fprintf('\n========================================\n');
        fprintf('Algorithm 2 -- Iteration %d\n', iteration);
        fprintf('Candidate sensor set: %s\n', sensor_set_to_string(A));
        fprintf('Candidate cost: %.6g\n', fval);

        RVA = compute_reduced_verifier(PV, A);

        % This function returns:
        % hasAmbiguous = true/false
        % W            = ambiguous witness when true
        [hasAmbiguous, W] = find_ambiguous_witness(RVA);

        history(iteration).candidate = A;
        history(iteration).cost = fval;
        history(iteration).hasAmbiguousCycle = hasAmbiguous;

        if ~hasAmbiguous
            fprintf('No ambiguous cycle is found.\n');
            fprintf('Algorithm 2 result: optimal sensor set found.\n');

            Astar = A;

            history(iteration).witness = [];
            history(iteration).B = [];

            result.status = 'optimal';
            result.Astar = Astar;
            result.cost = fval;
            result.witnesses = witnesses;
            result.constraintMatrix = constraintMatrix;
            result.history = history;
            return;
        end

        B = witness_sensor_set(W, RVA, O_tau);

        history(iteration).witness = W;
        history(iteration).B = B;

        fprintf('An ambiguous witness is found.\n');
        fprintf('B(W) = %s\n', sensor_set_to_string(B));

        if ~any(B(sensorIndices))
            fprintf('No available sensor can distinguish this witness.\n');
            fprintf('Algorithm 2 result: infeasible.\n');

            result.status = 'infeasible';
            result.Astar = [];
            result.cost = [];
            result.witnesses = witnesses;
            result.constraintMatrix = constraintMatrix;
            result.history = history;
            return;
        end

        witnessRow = double(B(sensorIndices));
        witnessRow = witnessRow(:).';

        witnesses{end+1} = W;
        constraintMatrix = [constraintMatrix; witnessRow]; %#ok<AGROW>

        fprintf('A new witness constraint is added:\n');
        fprintf('sum_{(p,gamma) in B(W)} x_{p,gamma} >= 1\n');
    end
end

% ==============================================================
% Obtain B(W)
% ==============================================================

function B = witness_sensor_set(W, RVA, O_tau)
% Return B(W). Prefer W.B if it was created by
% find_ambiguous_witness; otherwise compute it using W.V.

    if isfield(W, 'B') && ~isempty(W.B)
        B = logical(W.B);
    elseif isfield(W, 'V') && ~isempty(W.V)
        B = false(size(O_tau));

        for k = 1:numel(W.V)
            v = W.V(k);
            B = B | logical(RVA.Vertices(v).D);
        end
    else
        error(['The ambiguous witness must contain either W.B or W.V. ', ...
               'Please check find_ambiguous_witness.m.']);
    end

    if ~isequal(size(B), size(O_tau))
        error('The dimension of B(W) is inconsistent with O_tau.');
    end
end

% ==============================================================
% Convert a sensor mask into printable text
% ==============================================================

function str = sensor_set_to_string(A)
    [places, colors] = find(A);

    if isempty(places)
        str = '{}';
        return;
    end

    items = cell(1, numel(places));

    for k = 1:numel(places)
        items{k} = sprintf('(p%d,gamma%d)', places(k), colors(k));
    end

    str = ['{', strjoin(items, ', '), '}'];
end