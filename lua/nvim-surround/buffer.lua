local M = {}

--[============================================================================[
                             Line helper functions
--]============================================================================]

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

--[============================================================================[
                            Cursor helper functions
--]============================================================================]

--[[
Gets the position of the cursor, 1-indexed.
@return curpos The position of the cursor.
]]
M.get_curpos = function()
    local curpos = { vim.fn.getcurpos()[2], vim.fn.getcurpos()[3] }
    return curpos
end

--[============================================================================[
                             Mark helper functions
--]============================================================================]

--[[
Gets the row and column for a mark, 1-indexed, if it exists, returns nil otherwise.
@param mark The mark whose position will be returned.
@return The position of the mark.
]]
M.get_mark = function(mark)
    local position = vim.api.nvim_buf_get_mark(0, mark)
    if position[1] == 0 then
        return nil
    end
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
Deletes a mark from the buffer.
@param mark The mark to be deleted.
]]
M.del_mark = function(mark)
    vim.api.nvim_buf_del_mark(0, mark)
end

--[[
Moves operator marks to not be on whitespace characters.
@param mark The mark to potentially move.
]]
M.adjust_mark = function(mark)
    local pos = M.get_mark(mark)
    -- Do nothing if the mark doesn't exist
    if not pos then
        return
    end

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

--[============================================================================[
                        Buffer contents helper functions
--]============================================================================]

--[[
Deletes a given selection from the buffer.
@param selection The given selection.
]]
M.delete_selection = function(selection)
    local first_lnum, last_lnum = selection.first_pos[1], selection.last_pos[1]
    local first_col, last_col = selection.first_pos[2], selection.last_pos[2]
    local first_line = M.get_lines(first_lnum, first_lnum)[1]
    local last_line = M.get_lines(last_lnum, last_lnum)[1]
    local replacement = first_line:sub(1, first_col - 1) .. last_line:sub(last_col + 1, #last_line)
    M.set_lines(first_lnum, last_lnum, { replacement })
end

return M
