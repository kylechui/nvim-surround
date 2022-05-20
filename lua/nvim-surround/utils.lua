local buffer = require("nvim-surround.buffer")

local M = {}

-- A table containing the set of tags associated with delimiter pairs
M.delimiters = {
    pairs = {
        ["b"] = { "(", ")" },
        ["("] = { "( ", " )" },
        [")"] = { "(", ")" },
        ["B"] = { "{", "}" },
        ["{"] = { "{ ", " }" },
        ["}"] = { "{", "}" },
        ["a"] = { "<", ">" },
        ["<"] = { "<", ">" },
        [">"] = { "<", ">" },
        ["["] = { "[ ", " ]" },
        ["]"] = { "[", "]" },
    },
    separators = {
        ["'"] = { "'", "'" },
        ['"'] = { '"', '"' },
        ["`"] = { "`", "`" },
    },
}

--[[
Returns if a character is a valid key into the aliases table.
@param char The character to be checked.
@return Whether or not it is in the aliases table.
]]
M.is_valid_alias = function(char)
    return M.delimiters.pairs[char] or M.delimiters.separators[char]
end

--[[
Gets a character input from the user.
@return The input character, or nil if a control character is pressed.
]]
M.get_char = function()
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
M.get_delimiters = function(char)
    -- Get input from the user for what they would like to surround with
    -- Return nil if the user cancels the command
    local delimiters
    -- Set the delimiters based on cases
    if char == nil then
        return nil
    elseif char == "<" or char == "t" then
        -- Get an HTML tag as input
        vim.ui.input({
            prompt = "Enter an HTML tag: ",
        }, function(input)
            local tag = input:match("^%w+")
            local attributes = input:match(" +(.+)$")
            if not tag then
                return nil
            end

            if not attributes then
                delimiters = {
                    "<" .. tag .. ">",
                    "</" .. tag .. ">",
                }
            else
                delimiters = {
                    "<" .. tag .. " " .. attributes .. ">",
                    "</" .. tag .. ">",
                }
            end
        end)
    else
        delimiters = M.delimiters.pairs[char] or M.delimiters.separators[char]
    end
    -- If the character is not bound to anything, duplicate it
    return delimiters or { char, char }
end

--[[
Gets the coordinates of the start and end of a given selection.
@return A table containing the start and end of the selection.
]]
M.get_selection = function()
    -- Get the current cursor mode
    local mode = vim.fn.mode()
    -- Determine whether to use visual marks or operator marks
    local mark1, mark2
    if mode == "v" or mode == "V" then
        mark1, mark2 = "<", ">"
    else
        mark1, mark2 = "[", "]"
        -- Adjust the start and end marks for weird situations where certain
        -- actions like va" result in surrounding whitespace being selected
        buffer.adjust_mark("[")
        buffer.adjust_mark("]")
    end

    -- Get the row and column of the first and last characters of the selection
    local first_position = buffer.get_mark(mark1)
    local last_position = buffer.get_mark(mark2)
    return {
        first_pos = {
            first_position[1],
            first_position[2],
        },
        last_pos = {
            last_position[1],
            last_position[2],
        },
    }
end

--[[
Gets two selections for the left and right surrounding pair.
@return A table containing the start and end positions of the marks.
]]
M.get_surrounding_selections = function(char)
    local delimiters = M.get_delimiters(char)
    if not delimiters then
        return nil
    end

    buffer.adjust_mark("[")
    buffer.adjust_mark("]")
    local open_first = buffer.get_mark("[")
    local close_first = buffer.get_mark("]")

    local open_last = { open_first[1], open_first[2] + #delimiters[1] - 1 }
    local close_last = { close_first[1], close_first[2] + #delimiters[2] - 1 }

    local selections = {
        left = {
            first_pos = open_first,
            last_pos = open_last,
        },
        right = {
            first_pos = close_first,
            last_pos = close_last,
        },
    }
    return selections
end

return M
