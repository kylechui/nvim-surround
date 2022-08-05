local buffer = require("nvim-surround.buffer")
local config = require("nvim-surround.config")
local patterns = require("nvim-surround.patterns")

local M = {}

-- Do nothing.
M.NOOP = function() end

-- Splits an input string apart by newline characters.
---@param input string The input string.
---@return string[] @A table that contains the lines, split by the newline character.
M.split = function(input)
    local lines = {}
    for line in input:gmatch("([^\n]+)") do
        lines[#lines + 1] = line
    end
    return lines
end

-- Joins together the given lines, separated by the newline character.
---@param lines string[] The given lines.
---@return string @The concatenated lines, separated by newline characters.
M.join = function(lines)
    return table.concat(lines, "\n")
end

-- Gets a character input from the user.
---@return string? @The input character, or nil if a control character is pressed.
M.get_char = function()
    local ret_val, char_num = pcall(vim.fn.getchar)
    -- Return nil if error (e.g. <C-c>) or for control characters
    if not ret_val or char_num < 32 then
        return nil
    end
    local char = vim.fn.nr2char(char_num)
    return char
end

-- Returns the value that the input is aliased to, or the character if no alias exists.
---@param char string? The input character.
---@return string? @The aliased character if it exists, or the original if none exists.
M.get_alias = function(char)
    local aliases = config.get_opts().aliases
    if type(aliases[char]) == "string" then
        return aliases[char]
    end
    return char
end

-- Gets a delimiter pair for a user-inputted character.
---@param char string? The user-given character.
---@return string[][]? @A pair of delimiters for the given input, or nil if not applicable.
M.get_delimiters = function(char)
    char = M.get_alias(char)
    -- Return nil if the user cancels the command
    if not char then
        return nil
    end

    -- Get the function for adding the delimiters, if it exists
    local add = config.get_add(char)
    if add then
        return vim.deepcopy(add(char))
    end

    config.get_opts().surrounds.invalid_key_behavior.add(char)
end

-- Gets a selection that contains the left and right surrounding pair.
---@param char string A character representing what selection is to be found.
---@return selection? @The corresponding selection for the given character.
M.get_selection = function(char)
    if config.get_opts().surrounds[char] then
        return config.get_opts().surrounds[char].find(char)
    end
    return config.get_opts().surrounds.invalid_key_behavior.find(char)
end

-- Gets two selections for the left and right surrounding pair.
---@param char string? A character representing what kind of surrounding pair is to be selected.
---@param pattern string? A Lua pattern representing the wanted selections.
---@return selections? @A table containing the start and end positions of the delimiters.
M.get_selections = function(char, pattern)
    -- Get an input character from the user
    char = M.get_alias(char)
    if not char then
        return nil
    end

    -- Get the "parent selection" that contains the left and right surround.
    local selection = M.get_selection(char)
    if not selection then
        return nil
    end

    -- Narrow the "parent selection" down to the left and right surrounds.
    local selections
    if pattern then
        -- If the pattern exists, use pattern-based methods to narrow down the selection
        selections = patterns.get_selections(
            patterns.pos_to_index(selection.first_pos),
            M.join(buffer.get_text(selection)),
            pattern
        )
    else
        -- Get the corresponding delimiter pair for the character
        local delimiters = M.get_delimiters(char)
        if not delimiters then
            return nil
        end

        local open_first = selection.first_pos
        local close_last = selection.last_pos
        -- Use the length of the pair to find the proper selection boundaries
        local open_last = { open_first[1], open_first[2] + #delimiters[1][#delimiters[1]] - 1 }
        local close_first = { close_last[1], close_last[2] - #delimiters[2][#delimiters[2]] + 1 }

        selections = {
            left = {
                first_pos = open_first,
                last_pos = open_last,
            },
            right = {
                first_pos = close_first,
                last_pos = close_last,
            },
        }
    end
    return selections
end

-- Gets the nearest two selections for the left and right surrounding pair.
---@param char string? A character representing what kind of surrounding pair is to be selected.
---@param action "delete"|"change" A string representing what action is being performed.
---@return selections? @A table containing the start and end positions of the delimiters.
M.get_nearest_selections = function(char, action)
    char = M.get_alias(char)

    local chars = config.get_opts().aliases[char] or { char }
    local nearest_selections
    local curpos = buffer.get_curpos()
    -- Iterate through all possible selections for each aliased character, and find the closest pair
    for _, c in ipairs(chars) do
        local cur_selections = action == "change" and config.get_change(c).target(c) or config.get_delete(c)(c)
        if cur_selections then
            nearest_selections = nearest_selections or cur_selections
            if buffer.is_inside(curpos, nearest_selections) then
                -- Handle case where the cursor is inside the nearest selections
                if
                    buffer.is_inside(curpos, cur_selections)
                    and buffer.comes_before(nearest_selections.left.first_pos, cur_selections.left.first_pos)
                then
                    nearest_selections = cur_selections
                end
            elseif buffer.comes_before(curpos, nearest_selections.left.first_pos) then
                -- Handle case where the cursor comes before the nearest selections
                if
                    buffer.is_inside(curpos, cur_selections)
                    or buffer.comes_before(cur_selections.left.first_pos, nearest_selections.left.first_pos)
                then
                    nearest_selections = cur_selections
                end
            else
                -- Handle case where the cursor comes after the nearest selections
                if
                    buffer.is_inside(curpos, cur_selections)
                    or buffer.comes_before(nearest_selections.right.last_pos, cur_selections.right.last_pos)
                then
                    nearest_selections = cur_selections
                end
            end
        end
        -- Reset the cursor position
        buffer.set_curpos(curpos)
    end
    -- If a pair of selections is found, jump to the beginning of the left one
    if nearest_selections then
        buffer.set_curpos(nearest_selections.left.first_pos)
    end

    return nearest_selections
end

return M
