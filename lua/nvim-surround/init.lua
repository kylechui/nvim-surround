local utils = require("nvim-surround.utils")

local M = {}

-- Differentiates operator surrounds from visual surrounds
M.mode = "operator"

-- A table containing the set of tags associated with delimiter pairs
M.aliases = {
    -- As for now, the aliases are only one character long, although I might
    -- allow for them to go beyond that in the future
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
    ["'"] = { "'", "'" },
    ['"'] = { '"', '"' },
    ["`"] = { "`", "`" },
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

-- Queries the user for a delimiter pair, and surrounds the given mark range
-- with that delimiter pair
M.add_surround = function()
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
    lines[#lines] = utils.insert_string(line, delimiters[2], positions[4] + 1)
    -- Insert left delimiter on the first line
    line = lines[1]
    lines[1] = utils.insert_string(line, delimiters[1], positions[2])
    -- Update the buffer with the new lines
    vim.api.nvim_buf_set_lines(0, positions[1] - 1, positions[3], false, lines)
end

-- Deletes the surrounding delimiter
M.del_surround = function()
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
    lines[#lines] = utils.delete_char(lines[#lines], positions[4])
    lines[1] = utils.delete_char(lines[1], positions[2])
    -- Update the range of lines
    vim.api.nvim_buf_set_lines(0, positions[1] - 1, positions[3], false, lines)
end

-- API call to delete a delimiter pair
M.delete_surround = function()
    vim.go.operatorfunc = "v:lua.require'nvim-surround'.del_surround"
    local char = vim.fn.nr2char(vim.fn.getchar())
    if M.aliases[char] == nil then
        print("Invalid surrounding pair to delete!")
        return
    end
    vim.api.nvim_feedkeys("g@a" .. char, "n", false)
end

-- Surround a text object with delimiters
M.operator_surround = function()
    M.mode = "operator"
    vim.go.operatorfunc = "v:lua.require'nvim-surround'.add_surround"
    vim.api.nvim_feedkeys("g@", "n", false)
end

-- Surround a visual selection with delimiters
M.visual_surround = function()
    M.mode = "visual"
    vim.go.operatorfunc = "v:lua.require'nvim-surround'.add_surround"
    vim.api.nvim_feedkeys("g@", "n", false)
end

return M
