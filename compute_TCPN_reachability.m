function RG = compute_TCPN_reachability(Pre, Post, M0, maxNodes)
% compute_TCPN_reachability
% Compute the reachability graph of a Tagged/Colored Petri Net.
%
% INPUT:
%   Pre      : m-by-n cell array, Pre{i,j} is a 1-by-o vector
%   Post     : m-by-n cell array, Post{i,j} is a 1-by-o vector
%   M0       : m-by-o matrix, initial colored marking
%   maxNodes : maximum number of reachable markings allowed
%
% OUTPUT:
%   RG.Markings : cell array of reachable markings
%   RG.Edges    : struct array with fields: source, transition, target
%   RG.NumNodes : number of reachable markings
%   RG.NumEdges : number of edges

    if nargin < 4
        maxNodes = 100000;
    end

    [m, n] = size(Pre);
    [m0_rows, o] = size(M0);

    if m0_rows ~= m
        error('The number of rows of M0 must be equal to the number of places.');
    end

    % Check dimensions of Pre and Post
    for i = 1:m
        for j = 1:n
            if numel(Pre{i,j}) ~= o || numel(Post{i,j}) ~= o
                error('Each Pre{i,j} and Post{i,j} must be a 1-by-o vector.');
            end
            Pre{i,j} = reshape(Pre{i,j}, 1, o);
            Post{i,j} = reshape(Post{i,j}, 1, o);
        end
    end

    % Initialization
    Markings = {};
    Edges = struct('source', {}, 'transition', {}, 'target', {});

    visited = containers.Map('KeyType', 'char', 'ValueType', 'double');

    key0 = marking_key(M0);
    Markings{1} = M0;
    visited(key0) = 1;

    queue = 1;
    head = 1;

    % BFS exploration
    while head <= length(queue)
        currentID = queue(head);
        head = head + 1;

        M = Markings{currentID};

        for t = 1:n
            if is_enabled(M, Pre, t)
                Mnext = fire_transition(M, Pre, Post, t);

                keyNext = marking_key(Mnext);

                if ~isKey(visited, keyNext)
                    newID = length(Markings) + 1;

                    if newID > maxNodes
                        error('Reachability exploration stopped: maxNodes exceeded. The net may be unbounded or too large.');
                    end

                    Markings{newID} = Mnext;
                    visited(keyNext) = newID;
                    queue(end+1) = newID;
                else
                    newID = visited(keyNext);
                end

                % Add edge
                e.source = currentID;
                e.transition = t;
                e.target = newID;
                Edges(end+1) = e;
            end
        end
    end

    RG.Markings = Markings;
    RG.Edges = Edges;
    RG.NumNodes = length(Markings);
    RG.NumEdges = length(Edges);
end