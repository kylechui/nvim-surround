local nvim_surround = require("nvim-surround")
local utils = require("nvim-surround.utils")

local M = {}

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
