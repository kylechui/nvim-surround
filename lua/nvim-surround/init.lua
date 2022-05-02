local utils = require("nvim-surround.utils")

local M = {}

M.setup = function(opts)
    -- TODO: Implement setup function for user configuration
end

-- API: Surround a text object with delimiters
M.operator_surround = function()
    vim.go.operatorfunc = "v:lua.require'nvim-surround.modify_buffer'._add_surround"
    vim.api.nvim_feedkeys("g@", "n", false)
end

-- API: Surround a visual selection with delimiters
M.visual_surround = function()
    vim.go.operatorfunc = "v:lua.require'nvim-surround.modify_buffer'._add_surround"
    vim.api.nvim_feedkeys("g@", "n", false)
end

-- API: Delete a surrounding delimiter pair, if it exists
M.delete_surround = function()
    local char = utils._get_char()
    if char == nil then
        return
    end

    if not utils._is_valid_alias(char) then
        print("Invalid surrounding pair to delete!")
        return
    end

    vim.go.operatorfunc = "v:lua.require'nvim-surround.modify_buffer'._delete_surround"
    vim.api.nvim_feedkeys("g@a" .. char, "n", false)
end

-- API: Delete a surrounding delimiter pair, if it exists
M.change_surround = function()
    local char = utils._get_char()
    if char == nil then
        return
    end

    if not utils._is_valid_alias(char) then
        print("Invalid surrounding pair to change!")
        return
    end

    vim.go.operatorfunc = "v:lua.require'nvim-surround.modify_buffer'._change_surround"
    vim.api.nvim_feedkeys("g@a" .. char, "n", false)
end

return M
