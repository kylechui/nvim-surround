---@type table<string, filetype_spec>
local specs = {
    lua = require("nvim-surround.filetypes.lua"),
    python = require("nvim-surround.filetypes.python"),
}

return specs
