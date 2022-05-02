local utils = require("nvim-surround.utils")

local M = {}

-- Queries the user for a delimiter pair, and surrounds the given mark range
-- with that delimiter pair
M._add_surround = function()
    -- Get the associated delimiter pair to the user input
    local delimiters = utils._get_delimiters()
    if delimiters == nil then
        return
    end
    -- Insert the delimiters around the given indices into the current line
    local positions = utils.get_selection()
    local lines = vim.api.nvim_buf_get_lines(0, positions[1] - 1, positions[3], false)
    -- Insert the right delimiter first so it doesn't mess up positioning for
    -- the left one
    -- TODO: Maybe use extmarks instead?
    -- Insert right delimiter on the last line
    local line = lines[#lines]
    lines[#lines] = utils.insert_string(line, delimiters[2], positions[4] + 1)
    -- Insert left delimiter on the first line
    line = lines[1]
    lines[1] = utils.insert_string(line, delimiters[1], positions[2])
    -- Update the buffer with the new lines
    vim.api.nvim_buf_set_lines(0, positions[1] - 1, positions[3], false, lines)
end

-- Deletes the surrounding delimiter
M._delete_surround = function()
    -- Get the start and end of the selection
    local positions = utils.get_selection()
    -- print(vim.inspect(positions))
    local lines = vim.api.nvim_buf_get_lines(0, positions[1] - 1, positions[3], false)
    -- Adjust the positions if they're on whitespace
    if lines[1]:sub(positions[2], positions[2]) == " " then
        positions[2] = positions[2] + 1
    end
    if lines[#lines]:sub(positions[4], positions[4]) == " " then
        positions[4] = positions[4] - 1
    end
    -- Remove the delimiting pair
    local to_delete = { "G", "G" } -- TODO: Make this work with multichar delimiters
    lines[#lines] = utils.delete_string(lines[#lines], to_delete[2], positions[4])
    lines[1] = utils.delete_string(lines[1], to_delete[1], positions[2])
    -- Update the range of lines
    vim.api.nvim_buf_set_lines(0, positions[1] - 1, positions[3], false, lines)
end

-- Changes the surrounding delimiter
M._change_surround = function()
    -- Get the start and end of the selection
    local positions = utils.get_selection()
    local lines = vim.api.nvim_buf_get_lines(0, positions[1] - 1, positions[3], false)
    -- Replace the delimiting pair
    local to_replace = { "G", "G" } -- TODO: Make this work with multichar delimiters
    local to_insert = utils._get_delimiters()
    if to_insert == nil then
        return
    end
    lines[#lines] = utils.change_string(lines[#lines], to_insert[2], to_replace[2], positions[4])
    lines[1] = utils.change_string(lines[1], to_insert[1], to_replace[1], positions[2])
    -- Update the range of lines
    vim.api.nvim_buf_set_lines(0, positions[1] - 1, positions[3], false, lines)
end

return M
