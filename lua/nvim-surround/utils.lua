local buffer = require("nvim-surround.buffer")
local html = require("nvim-surround.html")
local strings = require("nvim-surround.strings")

local b = vim.b[0]

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
    local delim = b.buffer_opts.delimiters
    return delim.pairs[char] or delim.separators[char] or delim.HTML[char] or delim.aliases[char]
end

--[[
Returns if a character is a valid HTML tag alias.
@param char The character to be checked.
@return Whether or not it is an alias for HTML tags.
]]
M.is_HTML = function(char)
    return b.buffer_opts.delimiters.HTML[char]
end

--[[
Gets a character input from the user.
@return The input character, or nil if a control character is pressed.
]]
M.get_char = function()
    local ret_val, char_num = pcall(vim.fn.getchar)
    -- Return nil if error (e.g. <C-c>) or for control characters
    if not ret_val or char_num < 32 then
        return nil
    end
    local char = vim.fn.nr2char(char_num)
    return char
end

--[[
Gets a string input from the user.
@return The input string, or nil if the operation is cancelled.
]]
M.get_input = function(prompt)
    return string.format("%s", vim.fn.input({
        prompt = prompt,
        cancelreturn = nil,
    }))
end

--[[
Returns the value that the input is aliased to, or the character if no alias exists.
@param char The input character.
@return The aliased character if it exists, or the original if none exists.
]]
M.get_alias = function(char)
    if type(b.buffer_opts.delimiters.aliases[char]) == "string" and #b.buffer_opts.delimiters.aliases[char] == 1 then
        return b.buffer_opts.delimiters.aliases[char]
    end
    return char
end

--[[
Gets a delimiter pair for a user-inputted character.
@return A pair of delimiters for the given input, or nil if not applicable.
]]
M.get_delimiters = function(char)
    char = M.get_alias(char)
    -- Return nil if the user cancels the command
    if not char then
        return nil
    end

    local delimiters
    if M.is_HTML(char) then
        delimiters = html.get_tag(true)
    else
        -- If the character is not bound to anything, duplicate it
        delimiters = b.buffer_opts.delimiters.pairs[char] or b.buffer_opts.delimiters.separators[char] or { char, char }
    end

    -- Evaluate the function if necessary
    if type(delimiters) == "function" then
        delimiters = delimiters()
    end
    -- Wrap the delimiters in a table if necessary
    delimiters[1] = type(delimiters[1]) == "string" and { delimiters[1] } or delimiters[1]
    delimiters[2] = type(delimiters[2]) == "string" and { delimiters[2] } or delimiters[2]
    return { delimiters[1], delimiters[2] }
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
    -- Use the correct quotes to surround the arguments for setting the marks
    local args = char == "'" and [["'"]] or "'" .. char .. "'"
    vim.cmd("silent call v:lua.require'nvim-surround.buffer'.set_operator_marks(" .. args .. ")")
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
        local open_line = buffer.get_lines(open_first[1], open_first[1])[1]
        local close_line = buffer.get_lines(close_last[1], close_last[1])[1]
        open_last = { open_first[1], open_first[2] + #delimiters[1][1] - 1 }
        close_first = { close_last[1], close_last[2] - #delimiters[2][1] + 1 }
        -- Validate that the pair actually exists at the given selection
        if open_line:sub(open_first[2], open_last[2]) ~= delimiters[1][1] or
            close_line:sub(close_first[2], close_last[2]) ~= delimiters[2][1] then
            vim.fn.cursor(curpos)
            return nil
        end
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
    if not b.buffer_opts.delimiters.aliases[char] then
        return M.get_surrounding_selections(char)
    end

    local aliases = b.buffer_opts.delimiters.aliases[char]
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
