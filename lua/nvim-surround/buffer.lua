local M = {}

--[[
Gets a set of lines from the buffer, inclusive and 1-indexed.
@param start The starting line.
@param stop The final line.
@return A table consisting of the lines from the buffer.
]]
M.get_lines = function(start, stop)
    return vim.api.nvim_buf_get_lines(0, start - 1, stop, false)
end

--[[
Replaces some lines in the buffer, inclusive and 1-indexed.
@param start The starting line.
@param stop The final line.
@param lines The set of lines to replace the lines in the buffer.
]]
M.set_lines = function(start, stop, lines)
    vim.api.nvim_buf_set_lines(0, start - 1, stop, false, lines)
end

--[[
Gets the row and column for a mark, 1-indexed.
@param mark The mark whose position will be returned.
@return The position of the mark.
]]
M.get_mark = function(mark)
    local position = vim.api.nvim_buf_get_mark(0, mark)
    position[2] = position[2] + 1
    return position
end

--[[
Sets the position of a mark, 1-indexed.
@param mark The mark whose position will be returned.
@param position The position that the mark should be set to
]]
M.set_mark = function(mark, position)
    vim.api.nvim_buf_set_mark(0, mark, position[1], position[2] - 1, {})
end

--[[
Moves operator marks to not be on whitespace characters.
@param mark The mark to potentially move.
]]
M.adjust_mark = function(mark)
    local pos = M.get_mark(mark)
    local line = M.get_lines(pos[1], pos[1])[1]
    if mark == "[" then
        while line:sub(pos[2], pos[2]) == " " do
            pos[2] = pos[2] + 1
        end
    elseif mark == "]" then
        while line:sub(pos[2], pos[2]) == " " do
            pos[2] = pos[2] - 1
        end
    end
    M.set_mark(mark, pos)
end

return M
