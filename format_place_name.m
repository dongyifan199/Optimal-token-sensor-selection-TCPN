function pname = format_place_name(rawName)
    if numel(rawName) >= 2 && rawName(1) == 'p'
        pname = ['p_' rawName(2:end)];
    else
        pname = rawName;
    end
end