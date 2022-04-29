local utils = require("nvim-surround.utils")

local M = {}

-- Differentiates operator surrounds from visual surrounds
M.mode = "operator"

-- A table containing the set of tags associated with delimiter pairs
M.aliases = {
    ["("] = { "( ", " )" },
    [")"] = { "(", ")" },
    ["a"] = { "<", ">" },
    ["<"] = { "<", ">" }, -- TODO: Try implementing surrounds with HTML tags?
    ["b"] = { "(", ")" },
    ["B"] = { "{", "}" },
    ["{"] = { "{ ", " }" },
    ["}"] = { "{", "}" },
    ["["] = { "[ ", " ]" },
    ["]"] = { "[", "]" },
}

M.setup = function(opts)
    -- TODO: Implement setup function for user configuration
end

M.get_delimiters = function()
    -- Get input from the user for what they would like to surround with
    local char = vim.fn.nr2char(vim.fn.getchar())
    local delimiters = M.aliases[char]
    -- If the character is not bound to anything, duplicate it
    if delimiters == nil then
        delimiters = { char, char }
    end
    return delimiters
end

M.do_surround = function()
    -- Get the associated delimiter pair to the user input
    local delimiters = M.get_delimiters()
    -- Insert the delimiters around the given indices into the current line
    -- Note: Columns are 1-indexed
    local positions = utils.get_selection(M.mode)
    local line = vim.api.nvim_get_current_line()
    -- JANK: Insert the right delimiter first so it doesn't mess up the
    -- positioning for the left one
    -- FIX: Use extmarks
    line = utils.insert_string(line, delimiters[2], positions[4] + 1)
    line = utils.insert_string(line, delimiters[1], positions[2])
    line = vim.api.nvim_set_current_line(line)
    --.go.operatorfunc = old_opfunc
end

M.operator_surround = function()
    M.mode = "operator"
    vim.go.operatorfunc = "v:lua.require'nvim-surround'.do_surround"
    vim.api.nvim_feedkeys("g@", "n", false)
end

-- Surround a visual selection with delimiters
M.visual_surround = function()
    M.mode = "visual"
    vim.go.operatorfunc = "v:lua.require'nvim-surround'.do_surround"
    vim.api.nvim_feedkeys("g@", "n", false)
end

return M
