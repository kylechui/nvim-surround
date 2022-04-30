local M = {}

-- Gets the coordinates of the start and end of a given selection
M.get_selection = function(mode)
    -- Identify which marks are going to be used
    local mark1, mark2
    if mode == "v" or mode == "V" then
        mark1, mark2 = "<", ">" -- Marks for start and stop in visual mode
    else
        mark1, mark2 = "[", "]" -- Marks for start and stop in operator mode
        M.adjust_mark("[")
        M.adjust_mark("]")
    end
    -- Actually get the mark positions
    local start_mark = vim.api.nvim_buf_get_mark(0, mark1)
    local end_mark = vim.api.nvim_buf_get_mark(0, mark2)
    -- Adjust the mark positions so the rows and columns are 1-indexed
    local start_row, start_col = start_mark[1], start_mark[2] + 1
    local end_row, end_col = end_mark[1], end_mark[2] + 1
    return { start_row, start_col, end_row, end_col }
end

-- TODO: Write own functions to 1-index everything
M.adjust_mark = function(mark)
    local pos = vim.api.nvim_buf_get_mark(0, mark)
    pos[2] = pos[2] + 1
    local line = vim.api.nvim_buf_get_lines(0, pos[1] - 1, pos[1], false)[1]
    if mark == "[" then
        while line:sub(pos[2], pos[2]) == " " do
            pos[2] = pos[2] + 1
        end
    elseif mark == "]" then
        while line:sub(pos[2], pos[2]) == " " do
            pos[2] = pos[2] - 1
        end
    end
    vim.api.nvim_buf_set_mark(0, mark, pos[1], pos[2] - 1, {})
end

-- Inserts `to_insert` at index `pos` of `str`
M.insert_string = function(str, to_insert, pos)
    return str:sub(1, pos - 1) .. to_insert .. str:sub(pos, #str)
end

-- Deletes `to_remove` at index `pos` of `str`
M.delete_string = function(str, to_remove, pos)
    return str:sub(1, pos - 1) .. str:sub(pos + #to_remove, #str)
end

M.change_string = function(str, to_insert, to_replace, pos)
    return str:sub(1, pos - 1) .. to_insert .. str:sub(pos + #to_replace, #str)
end

return M
