local nvim_surround = require("nvim-surround")
local utils = require("nvim-surround.utils")

local M = {}

M._insert = function()
    -- Get a character input and the positions of the selection
    local char = utils._get_char()
    local positions = utils.get_selection()
    -- Call the main insert function
    nvim_surround.insert_surround(char, positions)
end

M._delete = function()
    -- Get the positions of the selection and call the main delete function
    local positions = utils.get_selection()
    nvim_surround.delete_surround(positions)
end

M._change = function()
    -- Get the positions of the selection and call the main change function
    local positions = utils.get_selection()
    nvim_surround.change_surround(positions)
end

return M
