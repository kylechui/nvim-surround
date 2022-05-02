local nvim_surround = require("nvim-surround")
local utils = require("nvim-surround.utils")

local M = {}

-- Queries the user for a delimiter pair, and surrounds the given mark range
-- with that delimiter pair
M._insert = function()
    -- Get a character input
    local char = utils._get_char()
    -- Insert the delimiters around the given indices into the current line
    local positions = utils.get_selection()
    nvim_surround.operator_surround(char, positions)
end

M._delete = function()
    -- Insert the delimiters around the given indices into the current line
    local positions = utils.get_selection()
    nvim_surround.delete_surround(positions)
end

return M
