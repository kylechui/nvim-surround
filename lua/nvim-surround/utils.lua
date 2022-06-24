local buffer = require("nvim-surround.buffer")
local strings = require("nvim-surround.strings")

local cr = vim.api.nvim_replace_termcodes("<CR>", true, false, true)

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
        ["<"] = { "< ", " >" },
        [">"] = { "<", ">" },
        ["["] = { "[ ", " ]" },
        ["]"] = { "[", "]" },
        ["r"] = { "[", "]" },
    },
    separators = {
        ["'"] = { "'", "'" },
        ['"'] = { '"', '"' },
        ["`"] = { "`", "`" },
    },
    HTML = {
        ["t"] = true,
    },
    aliases = {
        ["q"] = { '"', "'", "`" },
    },
}

--[[
Returns if a character is a valid key into the aliases table.
@param char The character to be checked.
@return Whether or not it is in the aliases table.
]]
M.is_valid = function(char)
    local delim = M.delimiters
    return delim.pairs[char] or delim.separators[char] or delim.HTML[char] or delim.aliases[char]
end

--[[
Returns if a character is a valid HTML tag alias.
@param char The character to be checked.
@return Whether or not it is an alias for HTML tags.
]]
M.is_HTML = function(char)
    return M.delimiters.HTML[char]
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
    elseif M.is_HTML(char) then
        delimiters = M.get_HTML_pair()
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
@param A character representing what kind of surrounding pair is to be selected
@return A table containing the start and end positions of the delimiters.
]]
M.get_surrounding_selections = function(char)
    local open_first, open_last, close_first, close_last
    local cmd = ":set opfunc=v:lua.require('nvim-surround'.utils).NOOP" .. cr .. "g@a" .. char
    vim.api.nvim_feedkeys(cmd, "x", false)

    buffer.adjust_mark("[")
    buffer.adjust_mark("]")
    open_first = buffer.get_mark("[")
    close_last = buffer.get_mark("]")

    if M.is_HTML(char) then
        vim.fn.cursor(close_last)
        close_first = vim.fn.searchpos("<", "nbW")
        vim.fn.cursor(open_first)
        open_last = vim.fn.searchpos(">", "nW")
    else
        local delimiters = M.get_delimiters(char)
        if not delimiters then
            return nil
        end
        delimiters[1] = strings.trim_whitespace(delimiters[1])
        delimiters[2] = strings.trim_whitespace(delimiters[2])

        open_last = { open_first[1], open_first[2] + #delimiters[1] - 1 }
        close_first = { close_last[1], close_last[2] - #delimiters[2] + 1 }
    end

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

M.get_nearest_selections = function(char)
    if not M.delimiters.aliases[char] then
        return M.get_surrounding_selections(char)
    end

    local aliases = M.delimiters.aliases[char]
    local nearest_selections
    for _, c in ipairs(aliases) do
        local curpos = buffer.get_curpos()

        local cur_selections = M.get_surrounding_selections(c)
        local near_pos = nearest_selections and nearest_selections.left.first_pos
        local cur_pos = cur_selections and cur_selections.left.first_pos
        if not near_pos then
            nearest_selections = cur_selections
        elseif near_pos and cur_pos then
            if near_pos[1] < cur_pos[1] or
                (near_pos[1] == cur_pos[1] and near_pos[2] < cur_pos[2]) then
                nearest_selections = cur_selections
            end
        end

        vim.fn.cursor(curpos)
    end

    return nearest_selections
end

--[[
Adjust the selection boundaries to only select the HTML tag type.
@param The coordinates of the open and closing HTML tags.
@return The coordinates of the HTML tag.
]]
M.adjust_HTML_selections = function(selections)
    local open, close = selections.left, selections.right
    close.first_pos[2] = close.first_pos[2] + 2
    close.last_pos[2] = close.last_pos[2] - 1
    open.first_pos[2] = open.first_pos[2] + 1
    open.last_pos[2] = open.first_pos[2] + close.last_pos[2] - close.first_pos[2]
    return {
        left = {
            first_pos = open.first_pos,
            last_pos = open.last_pos,
        },
        right = {
            first_pos = close.first_pos,
            last_pos = close.last_pos,
        },
    }
end

--[[
Returns a HTML open/closing pair.
@param Whether or not to include the angle brackets.
@return The HTML tag pair.
]]
M.get_HTML_pair = function(omit_brackets)
    local pair
    vim.ui.input({
        prompt = "Enter an HTML tag: ",
    }, function(input)
        local tag = input:match("^%w+")
        local attributes = input:match(" +(.+)$")
        if not tag then
            return nil
        end

        local open = attributes and tag .. " " .. attributes or tag
        local close = tag

        if not omit_brackets then
            open = "<" .. open .. ">"
            close = "</" .. close .. ">"
        end
        pair = { open, close }
    end)

    return pair
end

return M
