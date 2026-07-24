function s = vector_to_string(v)
    if isempty(v)
        s = '[]';
        return;
    end

    tmp = sprintf('%d,', v);
    tmp = tmp(1:end-1);
    s = ['[' tmp ']'];
end