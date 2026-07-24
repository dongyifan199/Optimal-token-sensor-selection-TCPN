%% Example TCPN in Fig. X
% Places:      p1, p2, p3, p4, p5, p6
% Transitions: t1, t2, t3, t4, t5, t6
% Colors:
%   gamma_1 = blue circle
%   gamma_2 = blue square
%   gamma_3 = blue triangle

clear; clc; close all;

%% Dimensions
m = 6;      % number of places
n = 6;      % number of transitions
o = 3;      % number of colors

placeNames = {'p1','p2','p3','p4','p5','p6'};
transNames = {'t1','t2','t3','t4','t5','t6'};
colorNames = {'circle','square','triangle'};

%% Initialize Pre and Post
Pre  = cell(m,n);
Post = cell(m,n);

for p = 1:m
    for t = 1:n
        Pre{p,t}  = zeros(1,o);
        Post{p,t} = zeros(1,o);
    end
end

%% ------------------------------------------------------------
% Transition t1
% p1 -- circle --> t1 -- circle --> p2
% ------------------------------------------------------------
Pre{1,1}  = [1 0 0];
Post{2,1} = [1 0 0];

%% ------------------------------------------------------------
% Transition t2
% p1 -- square --> t2 -- square --> p3
% ------------------------------------------------------------
Pre{1,2}  = [0 1 0];
Post{3,2} = [0 1 0];

%% ------------------------------------------------------------
% Transition t3
% p2 -- circle --> t3 -- circle --> p2
% This is a self-loop on p2 for circle tokens.
% ------------------------------------------------------------
Pre{2,3}  = [1 0 0];
Post{1,3} = [1 0 0];

%% ------------------------------------------------------------
% Transition t4
% p2 -- circle --> t4
% p3 -- square --> t4
% t4 -- circle + square --> p4
% ------------------------------------------------------------
Pre{2,4}  = [1 0 0];
Pre{3,4}  = [0 1 0];
Post{4,4} = [1 1 0];

%% ------------------------------------------------------------
% Transition t5
% p4 -- circle + square --> t5
% p5 -- triangle --> t5
% t5 -- circle + square --> p4
% t5 -- circle + square + triangle --> p6
%
% Here p4 is modeled as a self-loop resource of t5.
% ------------------------------------------------------------
Pre{4,5}  = [1 1 0];
Pre{5,5}  = [0 0 1];

Post{4,5} = [1 1 0];
Post{6,5} = [1 1 1];

%% ------------------------------------------------------------
% Transition t6
% p6 -- circle + square + triangle --> t6
% t6 -- triangle --> p5
% ------------------------------------------------------------
Pre{6,6}  = [1 1 1];
Post{5,6} = [0 0 1];

%% Initial marking M0
% p1 has two circle tokens and one square token.
% p5 has one triangle token.
M0 = zeros(m,o);

M0(1,:) = [2 1 0];
M0(5,:) = [0 0 1];

%% Compute reachability graph
maxNodes = 10000;

RG = compute_TCPN_reachability(Pre, Post, M0, maxNodes);

fprintf('Number of reachable markings: %d\n', RG.NumNodes);
fprintf('Number of edges: %d\n\n', RG.NumEdges);

%% Print reachable markings and edges
print_RG(RG, placeNames, colorNames, transNames);

