# Optimal-token-sensor-selection-TCPN

MATLAB implementation for optimal token-count sensor selection for marking diagnosability in tagged colored Petri nets.

## Description

This repository contains the MATLAB code for the paper:

**Optimal Token Sensor Selection for Diagnosability in Tagged Colored Petri Nets**

The code implements the construction of colored basis reachability graphs, fault colored basis reachability graphs, parametric verifiers, reduced verifiers, ambiguous witness detection, and the optimal sensor selection algorithm.

## Requirements

The code was tested with:

- MATLAB R2024b
- MATLAB version 24.2.0.2712019
- Windows 11
- Optimization Toolbox

The integer linear programming problems are solved using MATLAB's built-in solver `intlinprog`.

## How to run

Open MATLAB, set this repository as the current folder, and run:

```matlab
run_warehouse_robot_parametric_experiment
