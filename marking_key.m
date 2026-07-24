function key = marking_key(M)
% Convert a colored marking matrix into a unique string key.

    key = sprintf('%d,', M(:));
end