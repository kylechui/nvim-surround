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
    local lines = vim.api.nvim_buf_get_lines(0, positions[1] - 1, positions[3], false)
    -- Insert the right delimiter first so it doesn't mess up positioning for
    -- the left one
    -- TODO: Maybe use extmarks instead?
    -- Insert right delimiter on the last line
    local line = lines[#lines]
    line = utils.insert_string(line, delimiters[2], positions[4] + 1)
    lines[#lines] = line
    -- Insert left delimiter on the first line
    line = lines[1]
    line = utils.insert_string(line, delimiters[1], positions[2])
    lines[1] = line
    -- Update the buffer with the new lines
    vim.api.nvim_buf_set_lines(0, positions[1] - 1, positions[3], false, lines)
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
