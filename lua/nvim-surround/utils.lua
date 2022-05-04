local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

-- A table containing the set of tags associated with delimiter pairs
M._aliases = {
    -- As for now, the aliases are only one character long, although I might
    -- allow for them to go beyond that in the future
    ["'"] = { "'", "'" },
    ['"'] = { '"', '"' },
    ["`"] = { "`", "`" },
    ["b"] = { "(", ")" },
    ["("] = { "( ", " )" },
    [")"] = { "(", ")" },
    ["B"] = { "{", "}" },
    ["{"] = { "{ ", " }" },
    ["}"] = { "{", "}" },
    ["a"] = { "<", ">" },
    ["<"] = { "<", ">" }, -- TODO: Try implementing surrounds with HTML tags?
    [">"] = { "<", ">" },
    ["["] = { "[ ", " ]" },
    ["]"] = { "[", "]" },
}

--[[
Returns if a character is a valid key into the aliases table.
@param char The character to be checked.
@return Whether or not it is in the aliases table.
]]
M._is_valid_alias = function(char)
    return M._aliases[char] ~= nil
end

--[[
Gets a character input from the user.
@return The input character, or nil if a control character is pressed.
]]
M._get_char = function()
    local char_num = vim.fn.getchar()
    -- Return nil for control characters
    if char_num < 32 then
        return nil
    end
    local char = vim.fn.nr2char(char_num)
    return char
end

--[[
Gets a delimiter pair for a user-inputted character.
@return A pair of delimiters for the given input, or nil if not applicable.
]]
M._get_delimiters = function(char)
    -- Get input from the user for what they would like to surround with
    -- Return nil if the user cancels the command
    local delimiters
    -- Set the delimiters based on cases
    if char == nil then
        return nil
    elseif char == "<" then
        -- Get an HTML tag as input
        vim.ui.input({
            prompt = "Enter an HTML tag: ",
            default = "<",
        }, function(input)
            local tag = input:match("^<?(%w+)>?$")
            if not tag then
                return nil
            end
            delimiters = { "<" .. tag .. ">", "</" .. tag .. ">" }
        end)
    else
        delimiters = M._aliases[char]
    end
    -- If the character is not bound to anything, duplicate it
    return delimiters or { char, char }
end


--[[
Gets the row and column for a mark, 1-indexed.
@param mark The mark whose position will be returned.
@return The position of the mark.
]]
M._get_mark = function(mark)
    local position = vim.api.nvim_buf_get_mark(0, mark)
    position[2] = position[2] + 1
    return position
end

--[[
Gets a set of lines from the buffer, inclusive and 1-indexed.
@param start The starting line.
@param stop The final line.
@return A table consisting of the lines from the buffer.
]]
M._get_lines = function(start, stop)
    return vim.api.nvim_buf_get_lines(0, start - 1, stop, false)
end

--[[
Replaces some lines in the buffer, inclusive and 1-indexed.
@param start The starting line.
@param stop The final line.
@param lines The set of lines to replace the lines in the buffer.
]]
M._set_lines = function(start, stop, lines)
    vim.api.nvim_buf_set_lines(0, start - 1, stop, false, lines)
end

--[[
Gets the coordinates of the start and end of a given selection.
@param mode The current mode that the user is in.
@return A table containing the start and end positions of the marks.
]]
M.get_selection = function()
    -- Get the current cursor mode
    local mode = vim.api.nvim_get_mode()["mode"]
    -- Determine whether to use visual marks or operator marks
    local mark1, mark2
    if mode == "v" or mode == "V" then
        mark1, mark2 = "<", ">"
    else
        mark1, mark2 = "[", "]"
        -- Adjust the start and end marks for weird situations where certain
        -- actions like va" result in surrounding whitespace being selected
        M.adjust_mark("[")
        M.adjust_mark("]")
    end

    -- Get the row and column of the marks
    local start_position = M._get_mark(mark1)
    local end_position = M._get_mark(mark2)
    return {
        start_position[1],
        start_position[2],
        end_position[1],
        end_position[2],
    }
end

--[[
Moves operator marks to not be on whitespace characters.
@param mark The mark to potentially move.
]]
M.adjust_mark = function(mark)
    local pos = M._get_mark(mark)
    local line = vim.api.nvim_buf_get_lines(0, pos[1] - 1, pos[1], false)[1]
    if mark == "[" then
        while line:sub(pos[2], pos[2]) == " " do
            pos[2] = pos[2] + 1
        end
    elseif mark == "]" then
        while line:sub(pos[2], pos[2]) == " " do
            pos[2] = pos[2] - 1
        end
    end
    vim.api.nvim_buf_set_mark(0, mark, pos[1], pos[2] - 1, {})
end

--[[
Inserts a string at an index of another string.
@param str The original string.
@param to_insert The string to be inserted.
@param start The index at which the string will be inserted.
@return The modified string.
]]
M.insert_string = function(str, to_insert, start)
    return str:sub(1, start - 1) .. to_insert .. str:sub(start, #str)
end

--[[
Deletes a substring at an index of another string.
@param str The original string.
@param start The index at which the deletion starts.
@param stop The index at which the deletion stops (inclusive).
@return The modified string.
]]
M.delete_string = function(str, start, stop)
    return str:sub(1, start - 1) .. str:sub(stop + 1, #str)
end

--[[
Replaces a substring with a string, within another string.
@param str The original string.
@param to_insert The substring to be inserted.
@param start The index at which the replacement starts.
@param stop The index at which the replacement stops (inclusive).
@return The modified string.
]]
M.replace_string = function(str, to_insert, start, stop)
    return str:sub(1, start - 1) .. to_insert .. str:sub(stop + 1, #str)
end

M._get_tag_range = function()
    local node = ts_utils.get_node_at_cursor()
    while node and node:type() ~= "element" do
        node = node:parent()
    end
    if not node then
        return nil
    end

    local positions = { -1, -1, -1, -1, -1, -1, -1, -1, }
    for child in node:iter_children() do
        if child:type() == "start_tag" then
            positions[1], positions[2], positions[3], positions[4] = child:range()
        elseif child:type() == "end_tag" then
            positions[5], positions[6], positions[7], positions[8] = child:range()
        end
    end

    positions[1] = positions[1] + 1
    positions[2] = positions[2] + 1
    positions[3] = positions[3] + 1
    positions[5] = positions[5] + 1
    positions[6] = positions[6] + 1
    positions[7] = positions[7] + 1
    return positions
end

return M
