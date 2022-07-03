local buffer = require("nvim-surround.buffer")
local html = require("nvim-surround.html")
local strings = require("nvim-surround.strings")

local cr = vim.api.nvim_replace_termcodes("<CR>", true, false, true)

local M = {}

-- Do nothing.
M.NOOP = function() end

-- Custom feedkeys wrapper
M.feedkeys = function(string, flags)
    vim.api.nvim_feedkeys(string, flags, false)
end

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
Returns the value that the input is aliased to, or the character if no alias exists.
@param char The input character.
@return The aliased character if it exists, or the original if none exists.
]]
M.get_alias = function(char)
    if type(M.delimiters.aliases[char]) == "string" and #M.delimiters.aliases[char] == 1 then
        return M.delimiters.aliases[char]
    end
    return char
end

--[[
Gets a delimiter pair for a user-inputted character.
@return A pair of delimiters for the given input, or nil if not applicable.
]]
M.get_delimiters = function(char)
    char = M.get_alias(char)
    -- Get input from the user for what they would like to surround with
    -- Return nil if the user cancels the command
    local delimiters
    if not char then
        return nil
    end


    if M.is_HTML(char) then
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
M.get_selection = function(is_visual)
    -- Determine whether to use visual marks or operator marks
    local mark1, mark2
    if is_visual then
        mark1, mark2 = "<", ">"
    else
        mark1, mark2 = "[", "]"
        buffer.adjust_mark("[")
        buffer.adjust_mark("]")
    end

    -- Get the row and column of the first and last characters of the selection
    local first_position = buffer.get_mark(mark1)
    local last_position = buffer.get_mark(mark2)
    if not first_position or not last_position then
        return nil
    end
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
    char = M.get_alias(char)
    if not char then
        return nil
    end
    local open_first, open_last, close_first, close_last
    local curpos = buffer.get_curpos()

    -- Clear the [ and ] marks
    buffer.del_mark("[")
    buffer.del_mark("]")
    -- Set the [ and ] marks by calling an operatorfunc
    local cmd = ":set opfunc=v:lua.require('nvim-surround.utils').NOOP" .. cr .. "g@a" .. char
    M.feedkeys(cmd, "x")
    -- Clear the command line
    vim.cmd("echon")

    buffer.adjust_mark("[")
    buffer.adjust_mark("]")
    open_first = buffer.get_mark("[")
    close_last = buffer.get_mark("]")

    -- If the operatorfunc "fails", return no selection found
    if not open_first or not close_last then
        return nil
    end
    -- If the cursor is not contained within the selection, return no selection found
    local selection = {
        first_pos = open_first,
        last_pos = close_last,
    }
    if not M.inside_selection(curpos, selection) then
        vim.fn.cursor(curpos)
        return nil
    end

    if M.is_HTML(char) then
        -- Find the correct selection boundaries for HTML tags
        vim.fn.cursor(close_last)
        close_first = vim.fn.searchpos("<", "nbW")
        vim.fn.cursor(open_first)
        open_last = vim.fn.searchpos(">", "nW")
        if close_first == { 0, 0 } or open_last == { 0, 0 } then
            return nil
        end
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
    char = M.get_alias(char)
    -- If there are no tabular aliases, simply return the surrounding selection for that character
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
        if cur_pos then
            if not near_pos then
                nearest_selections = cur_selections
            else
                if near_pos[1] < cur_pos[1] or
                    (near_pos[1] == cur_pos[1] and near_pos[2] < cur_pos[2]) then
                    nearest_selections = cur_selections
                end
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

return M
