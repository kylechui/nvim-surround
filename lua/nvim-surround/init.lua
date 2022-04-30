local utils = require("nvim-surround.utils")

local M = {}

-- A table containing the set of tags associated with delimiter pairs
M._aliases = {
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

-- API: Surround a text object with delimiters
M.operator_surround = function()
    vim.go.operatorfunc = "v:lua.require'nvim-surround'._add_surround"
    vim.api.nvim_feedkeys("g@", "n", false)
end

-- API: Surround a visual selection with delimiters
M.visual_surround = function()
    vim.go.operatorfunc = "v:lua.require'nvim-surround'._add_surround"
    vim.api.nvim_feedkeys("g@", "n", false)
end

-- API: Delete a surrounding delimiter pair, if it exists
M.delete_surround = function()
    local char = M._get_char()
    if char == nil then
        return
    end

    if M._aliases[char] == nil then
        print("Invalid surrounding pair to delete!")
        return
    end
    vim.go.operatorfunc = "v:lua.require'nvim-surround'._delete_surround"
    vim.api.nvim_feedkeys("g@a" .. char, "n", false)
end

-- API: Delete a surrounding delimiter pair, if it exists
M.change_surround = function()
    local char = M._get_char()
    if char == nil then
        return
    end

    if M._aliases[char] == nil then
        print("Invalid surrounding pair to change!")
        return
    end
    vim.go.operatorfunc = "v:lua.require'nvim-surround'._change_surround"
    vim.api.nvim_feedkeys("g@a" .. char, "n", false)
end

M._get_char = function()
    local char_num = vim.fn.getchar()
    if char_num == 27 then
        return nil
    end
    return vim.fn.nr2char(char_num)
end

-- Gets a delimiter pair from the aliases table if it exists, otherwise returns
-- a table with the given character duplicated twice
M._get_delimiters = function()
    -- Get input from the user for what they would like to surround with
    -- Return nil if the user cancels the command
    local char = M._get_char()
    if char == nil then
        return nil
    end

    local delimiters = M._aliases[char]
    -- If the character is not bound to anything, duplicate it
    delimiters = delimiters or { char, char }
    return delimiters
end

-- Queries the user for a delimiter pair, and surrounds the given mark range
-- with that delimiter pair
M._add_surround = function()
    -- Get the associated delimiter pair to the user input
    local delimiters = M._get_delimiters()
    if delimiters == nil then
        return
    end
    -- Insert the delimiters around the given indices into the current line
    -- Note: Columns are 1-indexed
    local mode = vim.api.nvim_get_mode()["mode"]
    local positions = utils.get_selection(mode)
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
    local to_insert = M._get_delimiters()
    if to_insert == nil then
        return
    end
    lines[#lines] = utils.change_string(lines[#lines], to_insert[2], to_replace[2], positions[4])
    lines[1] = utils.change_string(lines[1], to_insert[1], to_replace[1], positions[2])
    -- Update the range of lines
    vim.api.nvim_buf_set_lines(0, positions[1] - 1, positions[3], false, lines)
end

return M
