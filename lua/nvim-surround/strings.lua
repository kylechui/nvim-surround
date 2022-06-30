local M = {}

--[[
Inserts a string at an index of another string.
@param str The original string.
@param to_insert The string to be inserted.
@param start The index at which the string will be inserted.
@return The modified string.
]]
M.insert_string = function(str, to_insert, start)
    return str:sub(1, start - 1) .. to_insert .. str:sub(start, #str)
end

--[[
Deletes a substring at an index of another string.
@param str The original string.
@param start The index at which the deletion starts.
@param stop The index at which the deletion stops (inclusive).
@return The modified string.
]]
M.delete_string = function(str, start, stop)
    return str:sub(1, start - 1) .. str:sub(stop + 1, #str)
end

--[[
Replaces a substring with a string, within another string.
@param str The original string.
@param to_insert The substring to be inserted.
@param start The index at which the replacement starts.
@param stop The index at which the replacement stops (inclusive).
@return The modified string.
]]
M.replace_string = function(str, to_insert, start, stop)
    return str:sub(1, start - 1) .. to_insert .. str:sub(stop + 1, #str)
end

--[[
Removes leading and trailing whitespace from a string.
@param str The original string.
@return The trimmed string.
]]
M.trim_whitespace = function(str)
    return str:match("^%s*(.*)"):match("(.-)%s*$")
end

return M
