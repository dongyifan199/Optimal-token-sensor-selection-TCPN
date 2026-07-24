function Out = outgoing_fault_edges(FCBRG, x)
% Return indices of fault-CBRG edges leaving vertex x.

    Out = [];

    for k = 1:numel(FCBRG.Edges)
        if FCBRG.Edges(k).source == x
            Out(end+1) = k; %#ok<AGROW>
        end
    end
end