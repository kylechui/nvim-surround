local M = {}

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

--[[
Sets the operator marks according to a given character.
@param char The given character.
]]
M.set_operator_marks = function(char)
    -- Clear the [ and ] marks
    M.del_mark("[")
    M.del_mark("]")
    -- Set the [ and ] marks by calling an operatorfunc
    vim.go.operatorfunc = "v:lua.require'nvim-surround.utils'.NOOP"
    vim.api.nvim_feedkeys("g@a" .. char, "x", false)
    -- Adjust the marks to not reside on whitespace
    M.adjust_mark("[")
    M.adjust_mark("]")
end

--[============================================================================[
                        Buffer contents helper functions
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

--[[
Inserts a set of lines into the buffer at a given position.
@param pos The position to be inserted at.
@param lines The lines to be inserted.
]]
M.insert_lines = function(pos, lines)
    local line = M.get_lines(pos[1], pos[1])[1]
    -- Make a copy of the lines to avoid modifying delimiters
    local lns = vim.deepcopy(lines)
    lns[1] = line:sub(1, pos[2] - 1) .. lns[1]
    lns[#lns] = lns[#lns] .. line:sub(pos[2])
    M.set_lines(pos[1], pos[1], lns)
end

--[[
Gets a selection of text from the buffer.
@param selection The selection of text to be retrieved.
@return lines The text from the buffer.
]]
M.get_selection = function(selection)
    local first_lnum, last_lnum = selection.first_pos[1], selection.last_pos[1]
    local first_col, last_col = selection.first_pos[2], selection.last_pos[2]
    local lines = M.get_lines(first_lnum, last_lnum)
    lines[#lines] = lines[#lines]:sub(1, last_col)
    lines[1] = lines[1]:sub(first_col)
    return lines
end

--[[
Returns whether a given position is contained within a given selection.
@param pos The position to be considered.
@param selection The selection to potentially contain the position.
@return A boolean indicating whether the position is contained in the selection.
]]
M.inside_selection = function(pos, selection)
    local first_pos, last_pos = selection.first_pos, selection.last_pos
    if pos[1] == first_pos[1] and pos[2] < first_pos[2] then
        return false
    elseif pos[1] == last_pos[1] and pos[2] > last_pos[2] then
        return false
    end
    return pos[1] >= first_pos[1] and pos[1] <= last_pos[1]
end

--[[
Returns whether a position comes before another in a buffer, true if the position.
@param pos1 The first position.
@param pos2 The second position.
@return A boolean indicating whether pos1 comes before pos2.
]]
M.comes_before = function(pos1, pos2)
    if pos1[1] < pos2[1] then
        return true
    end
    return pos1[1] == pos2[1] and pos1[2] <= pos2[2]
end

--[[
Deletes a given selection from the buffer.
@param selection The given selection.
]]
M.delete_selection = function(selection)
    local first_lnum, last_lnum = selection.first_pos[1], selection.last_pos[1]
    local first_col, last_col = selection.first_pos[2], selection.last_pos[2]
    local first_line = M.get_lines(first_lnum, first_lnum)[1]
    local last_line = M.get_lines(last_lnum, last_lnum)[1]
    local replacement = first_line:sub(1, first_col - 1) .. last_line:sub(last_col + 1)
    M.set_lines(first_lnum, last_lnum, { replacement })
end

--[[
Replaces a given selection with a set of lines.
@param selection The given selection.
@param lines The given lines to replace the selection.
]]
M.change_selection = function(selection, lines)
    local first_lnum, last_lnum = selection.first_pos[1], selection.last_pos[1]
    local first_col, last_col = selection.first_pos[2], selection.last_pos[2]
    local first_line = M.get_lines(first_lnum, first_lnum)[1]
    local last_line = M.get_lines(last_lnum, last_lnum)[1]
    -- Edge case where the selection is only one line
    if #lines == 1 then
        lines[1] = first_line:sub(1, first_col - 1) .. lines[1] .. first_line:sub(last_col + 1, #first_line)
    else
        lines[#lines] = last_line:sub(last_col + 1) .. lines[#lines]
        lines[1] = first_line:sub(1, first_col - 1) .. lines[1]
    end
    M.set_lines(first_lnum, last_lnum, lines)
end

--[============================================================================[
                        Highlight helper functions
--]============================================================================]

--[[
Highlights the text selected by an operator-mode text-object.
]]
M.highlight_range = function()
    M.adjust_mark("[")
    M.adjust_mark("]")
    local namespace = vim.api.nvim_create_namespace("NvimSurround")
    local first_pos, last_pos = M.get_mark("["), M.get_mark("]")
    if not first_pos or not last_pos then
        return
    end
    first_pos = { first_pos[1] - 1, first_pos[2] - 1 }
    last_pos = { last_pos[1] - 1, last_pos[2] - 1 }
    vim.highlight.range(
        0,
        namespace,
        "NvimSurroundHighlightTextObject",
        first_pos,
        last_pos,
        { inclusive = true }
    )
    -- Force the screen to highlight the text immediately
    vim.cmd("redraw")
end

--[[
Clears all nvim-surround highlights for the buffer.
]]
M.clear_highlights = function()
    local namespace = vim.api.nvim_create_namespace("NvimSurround")
    vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)
    -- Force the screen to clear the highlight immediately
    vim.cmd("redraw")
end

return M
