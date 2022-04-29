local M = {}

-- Gets the coordinates of the start and end of a given selection
M.get_selection = function(mode)
    -- Identify which marks are going to be used
    local mark1, mark2
    if mode == "visual" then
        mark1, mark2 = "<", ">" -- Marks for start and stop in visual mode
    else
        mark1, mark2 = "[", "]" -- Marks for start and stop in operator mode
    end
    -- Actually get the mark positions
    local start_mark = vim.api.nvim_buf_get_mark(0, mark1)
    local end_mark = vim.api.nvim_buf_get_mark(0, mark2)
    -- Adjust the mark positions so the rows and columns are 1-indexed
    local start_row, start_col = start_mark[1], start_mark[2] + 1
    local end_row, end_col = end_mark[1], end_mark[2] + 1
    return { start_row, start_col, end_row, end_col }
end

M.insert_string = function(original, to_insert, pos)
    return original:sub(1, pos - 1) .. to_insert .. original:sub(pos, #original)
end

return M
