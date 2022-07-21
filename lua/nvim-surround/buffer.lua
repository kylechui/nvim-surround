local config = require("nvim-surround.config")

local M = {}

--[============================================================================[
                            Cursor helper functions
--]============================================================================]

-- Gets the position of the cursor, 1-indexed.
---@return integer[] @The position of the cursor.
M.get_curpos = function()
    local curpos = vim.api.nvim_win_get_cursor(0)
    return { curpos[1], curpos[2] + 1 }
end

-- Sets the position of the cursor, 1-indexed.
---@param pos integer[] The given position.
M.set_curpos = function(pos)
    vim.api.nvim_win_set_cursor(0, { pos[1], pos[2] - 1 })
end

-- Move the cursor back to its original location post-action, if desired.
---@param pos integer[] The original position of the cursor.
M.reset_curpos = function(pos)
    if not config.get_opts().move_cursor then
        M.set_curpos(pos)
    end
end

--[============================================================================[
                             Mark helper functions
--]============================================================================]

-- Gets the row and column for a mark, 1-indexed, if it exists, returns nil otherwise.
---@param mark string The mark whose position will be returned.
---@return integer[]? @The position of the mark.
M.get_mark = function(mark)
    local position = vim.api.nvim_buf_get_mark(0, mark)
    if position[1] == 0 then
        return nil
    end
    return { position[1], position[2] + 1 }
end

-- Sets the position of a mark, 1-indexed.
---@param mark string The mark whose position will be returned.
---@param position integer[] The position that the mark should be set to.
M.set_mark = function(mark, position)
    vim.api.nvim_buf_set_mark(0, mark, position[1], position[2] - 1, {})
end

-- Deletes a mark from the buffer.
---@param mark string The mark to be deleted.
M.del_mark = function(mark)
    vim.api.nvim_buf_del_mark(0, mark)
end

-- Moves operator marks to not be on whitespace characters.
---@param mark string The mark to potentially move.
M.adjust_mark = function(mark)
    local pos = M.get_mark(mark)
    -- Do nothing if the mark doesn't exist
    if not pos then
        return
    end

    local line = M.get_line(pos[1])
    if mark == "[" then
        while line:sub(pos[2], pos[2]):match("%s") do
            pos[2] = pos[2] + 1
        end
    elseif mark == "]" then
        while line:sub(pos[2], pos[2]):match("%s") do
            pos[2] = pos[2] - 1
        end
    end
    M.set_mark(mark, pos)
end

-- Sets the operator marks according to a given character.
---@param char string The given character.
M.set_operator_marks = function(char)
    local curpos = M.get_curpos()
    -- Clear the [ and ] marks
    M.del_mark("[")
    M.del_mark("]")
    -- Set the [ and ] marks by calling an operatorfunc
    vim.go.operatorfunc = "v:lua.require'nvim-surround.utils'.NOOP"
    vim.cmd("normal! g@a" .. char)
    -- Adjust the marks to not reside on whitespace
    M.adjust_mark("[")
    M.adjust_mark("]")
    M.set_curpos(curpos)
end

--[============================================================================[
                        Buffer contents helper functions
--]============================================================================]

-- Gets a set of lines from the buffer, inclusive and 1-indexed.
---@param start integer The starting line.
---@param stop integer The final line.
---@return string[] @A table consisting of the lines from the buffer.
M.get_lines = function(start, stop)
    return vim.api.nvim_buf_get_lines(0, start - 1, stop, false)
end

-- Gets a line from the buffer, 1-indexed.
---@param line_num integer The number of the line to be retrieved.
---@return string @A string consisting of the line that was retrieved.
M.get_line = function(line_num)
    return M.get_lines(line_num, line_num)[1]
end

-- Formats a set of lines from the buffer, inclusive and 1-indexed.
---@param start integer The starting line.
---@param stop integer The final line.
M.format_lines = function(start, stop)
    local b = vim.bo
    -- Only format if a formatter is set up already
    if start <= stop and (b.equalprg ~= "" or b.indentexpr ~= "" or b.cindent or b.smartindent or b.lisp) then
        vim.cmd(string.format("silent normal! %dG=%dG", start, stop))
    end
end

-- Gets a selection of text from the buffer.
---@param selection selection The selection of text to be retrieved.
---@return string[]? @The text from the buffer.
M.get_text = function(selection)
    local first_pos, last_pos = selection.first_pos, selection.last_pos
    last_pos[2] = math.min(last_pos[2], #M.get_line(last_pos[1]))
    return vim.api.nvim_buf_get_text(0, first_pos[1] - 1, first_pos[2] - 1, last_pos[1] - 1, last_pos[2], {})
end

-- Returns whether a position comes before another in a buffer, true if the position.
---@param pos1 integer[] The first position.
---@param pos2 integer[] The second position.
---@return boolean @Whether or not pos1 comes before pos2.
M.comes_before = function(pos1, pos2)
    return pos1[1] < pos2[1] or pos1[1] == pos2[1] and pos1[2] <= pos2[2]
end

-- Adds some text into the buffer at a given position.
---@param pos integer[] The position to be inserted at.
---@param text string[] The text to be added.
M.insert_text = function(pos, text)
    vim.api.nvim_buf_set_text(0, pos[1] - 1, pos[2] - 1, pos[1] - 1, pos[2] - 1, text)
end

-- Deletes a given selection from the buffer.
---@param selection selection The given selection.
M.delete_selection = function(selection)
    local first_pos, last_pos = selection.first_pos, selection.last_pos
    vim.api.nvim_buf_set_text(0, first_pos[1] - 1, first_pos[2] - 1, last_pos[1] - 1, last_pos[2], {})
end

-- Replaces a given selection with a set of lines.
---@param selection selection The given selection.
---@param text string[] The given text to replace the selection.
M.change_selection = function(selection, text)
    local first_pos, last_pos = selection.first_pos, selection.last_pos
    vim.api.nvim_buf_set_text(0, first_pos[1] - 1, first_pos[2] - 1, last_pos[1] - 1, last_pos[2], text)
end

--[============================================================================[
                        Highlight helper functions
--]============================================================================]

-- Highlights a given selection.
---@param selection selection? The selection to be highlighted.
M.highlight_selection = function(selection)
    if not selection then
        return
    end
    local namespace = vim.api.nvim_create_namespace("NvimSurround")
    local first_pos, last_pos = selection.first_pos, selection.last_pos
    vim.highlight.range(
        0,
        namespace,
        "NvimSurroundHighlightTextObject",
        { first_pos[1] - 1, first_pos[2] - 1 },
        { last_pos[1] - 1, last_pos[2] - 1 },
        { inclusive = true }
    )
    -- Force the screen to highlight the text immediately
    vim.cmd("redraw")
end

-- Clears all nvim-surround highlights for the buffer.
M.clear_highlights = function()
    local namespace = vim.api.nvim_create_namespace("NvimSurround")
    vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)
    -- Force the screen to clear the highlight immediately
    vim.cmd("redraw")
end

return M
