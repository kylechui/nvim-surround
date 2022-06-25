local buffer = require("nvim-surround.buffer")
local html = require("nvim-surround.html")
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
        delimiters = html.get_tag(true)
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
M.get_selection = function(mode)
    -- Determine whether to use visual marks or operator marks
    local mark1, mark2
    if mode == "n" then
        mark1, mark2 = "[", "]"
        buffer.adjust_mark("[")
        buffer.adjust_mark("]")
    else
        mark1, mark2 = "<", ">"
    end

    -- Get the row and column of the first and last characters of the selection
    local first_position = buffer.get_mark(mark1)
    local last_position = buffer.get_mark(mark2)
    local selection = {
        first_pos = first_position,
        last_pos = last_position,
    }
    return selection
end

--[[
Gets two selections for the left and right surrounding pair.
@param A character representing what kind of surrounding pair is to be selected
@return A table containing the start and end positions of the delimiters.
]]
M.get_surrounding_selections = function(char)
    if not char then
        return nil
    end
    local open_first, open_last, close_first, close_last
    local curpos = buffer.get_curpos()

    -- Set the [ and ] marks by calling an operatorfunc
    local cmd = ":set opfunc=v:lua.require('nvim-surround'.utils).NOOP" .. cr .. "g@a" .. char
    vim.api.nvim_feedkeys(cmd, "x", false)

    buffer.adjust_mark("[")
    buffer.adjust_mark("]")
    open_first = buffer.get_mark("[")
    close_last = buffer.get_mark("]")
    -- If the operatorfunc "fails", return no selection found
    if open_first[1] == 1 and open_first[2] == 1 and close_last[1] == #buffer.get_lines(1, -1) and
        close_last[2] == 1 then
        return nil
    end
    -- If the cursor is not contained within the selection, return no selection found
    local selection = {
        first_pos = open_first,
        last_pos = close_last,
    }
    if not M.inside_selection(curpos, selection) then
        -- Reset cursor position
        vim.fn.cursor(curpos)
        return nil
    end

    if M.is_HTML(char) then
        -- Find the correct selection boundaries for HTML tags
        vim.fn.cursor(close_last)
        close_first = vim.fn.searchpos("<", "nbW")
        vim.fn.cursor(open_first)
        open_last = vim.fn.searchpos(">", "nW")
    else
        -- Get the corresponding delimiter pair for the character
        local delimiters = M.get_delimiters(char)
        if not delimiters then
            vim.fn.cursor(curpos)
            return nil
        end
        -- Use the length of the pair to find the proper selection boundaries
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
    vim.fn.cursor(curpos)
    return selections
end

M.get_nearest_selections = function(char)
    -- If there are no aliases, simply return the surrounding selection for that character
    if not M.delimiters.aliases[char] then
        return M.get_surrounding_selections(char)
    end

    local aliases = M.delimiters.aliases[char]
    local nearest_selections
    -- Iterate through all possible selections for each aliased character, and
    -- find the pair that is closest to the cursor position (that also still
    -- surrounds the cursor)
    for _, c in ipairs(aliases) do
        local cur_selections = M.get_surrounding_selections(c)
        local near_pos = nearest_selections and nearest_selections.left.first_pos
        local cur_pos = cur_selections and cur_selections.left.first_pos
        if not near_pos then
            nearest_selections = cur_selections
        elseif cur_pos then
            if near_pos[1] < cur_pos[1] or
                (near_pos[1] == cur_pos[1] and near_pos[2] < cur_pos[2]) then
                nearest_selections = cur_selections
            end
        end
    end

    return nearest_selections
end

--[[
Returns whether a given position is contained within a given selection.
@param pos The position to be considered.
@param selection The selection to potentially contain the position.
@return A boolean indicating whether the position is contained in the selection.
]]
M.inside_selection = function(pos, selection)
    local first_pos, last_pos = selection.first_pos, selection.last_pos
    if pos[1] == first_pos[1] and pos[2] < first_pos[2] then
        return false
    elseif pos[1] == last_pos[1] and pos[2] > last_pos[2] then
        return false
    end
    return pos[1] >= first_pos[1] and pos[1] <= last_pos[1]
end

--[[
Adjust the selection boundaries to only select the HTML tag type.
@param The coordinates of the open and closing HTML tags.
@return The coordinates of the HTML tag.
]]
M.adjust_HTML_selections = function(selections)
    if not selections then
        return nil
    end
    local open, close = selections.left, selections.right
    -- Move the boundaries to deselect the angle brackets and attributes
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

return M
