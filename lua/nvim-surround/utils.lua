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
---@return delimiters @A pair of delimiters for the given input, or nil if not applicable.
M.get_delimiters = function(char)
    char = M.get_alias(char)
    -- Return nil if the user cancels the command
    if not char then
        return nil
    end

    local delimiters = config.get_opts().delimiters[char].add() or config.get_opts().invalid_key_behavior(char)
    if not delimiters then
        return nil
    end

    return vim.deepcopy(delimiters)
end

-- Gets the coordinates of the start and end of a given selection.
---@return selection? @A table containing the start and end of the selection.
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

-- Gets two selections for the left and right surrounding pair.
---@param char string? A character representing what kind of surrounding pair is to be selected.
---@param pattern string? A Lua pattern representing the wanted selections.
---@return selections? @A table containing the start and end positions of the delimiters.
M.get_surrounding_selections = function(char, pattern)
    char = M.get_alias(char)
    if not char then
        return nil
    end

    if pattern then
        local selection = patterns.find(config.get_opts().delimiters[char].find, pattern)
        local selections = patterns.get_selections(
            patterns.pos_to_index(selection.first_pos),
            M.join(buffer.get_text(selection)),
            pattern
        )
        return selections
    else
        -- Get the corresponding delimiter pair for the character
        local delimiters = M.get_delimiters(char)
        if not delimiters then
            return nil
        end

        local open_first, open_last, close_first, close_last
        local curpos = buffer.get_curpos()
        -- Use the correct quotes to surround the arguments for setting the marks
        local args
        if char == "'" then
            args = [["'"]]
        else
            args = "'" .. char .. "'"
        end
        vim.cmd("silent call v:lua.require'nvim-surround.buffer'.set_operator_marks(" .. args .. ")")
        open_first = buffer.get_mark("[")
        close_last = buffer.get_mark("]")

        -- If the operatorfunc "fails", return no selection found
        if not open_first or not close_last then
            return nil
        end

        -- Use the length of the pair to find the proper selection boundaries
        local open_line = buffer.get_line(open_first[1])
        local close_line = buffer.get_line(close_last[1])
        open_last = { open_first[1], open_first[2] + #delimiters[1][1] - 1 }
        close_first = { close_last[1], close_last[2] - #delimiters[2][1] + 1 }
        -- Validate that the pair actually exists at the given selection
        if
            open_line:sub(open_first[2], open_last[2]) ~= delimiters[1][1]
            or close_line:sub(close_first[2], close_last[2]) ~= delimiters[2][1]
        then
            -- If not strictly there, trim the delimiters' whitespace and try again
            delimiters[1][1] = vim.trim(delimiters[1][1])
            delimiters[2][1] = vim.trim(delimiters[2][1])
            open_last = { open_first[1], open_first[2] + #delimiters[1][1] - 1 }
            close_first = { close_last[1], close_last[2] - #delimiters[2][1] + 1 }
            -- If still not found, return nil
            if
                open_line:sub(open_first[2], open_last[2]) ~= delimiters[1][1]
                or close_line:sub(close_first[2], close_last[2]) ~= delimiters[2][1]
            then
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
        buffer.set_curpos(curpos)
        return selections
    end
end

-- Gets the nearest two selections for the left and right surrounding pair.
---@param char string? A character representing what kind of surrounding pair is to be selected.
---@param pattern string? A Lua pattern representing the wanted selections.
---@return selections? @A table containing the start and end positions of the delimiters.
M.get_nearest_selections = function(char, pattern)
    char = M.get_alias(char)

    local opts = config.get_opts()
    local chars = opts.aliases[char] or { char }
    local nearest_selections
    local curpos = buffer.get_curpos()
    -- Iterate through all possible selections for each aliased character, and
    -- find the pair that is closest to the cursor position (that also still
    -- surrounds the cursor)
    for _, c in ipairs(chars) do
        local cur_selections = M.get_surrounding_selections(c, pattern)
        local n_first = nearest_selections and nearest_selections.left.first_pos
        local c_first = cur_selections and cur_selections.left.first_pos
        if c_first then
            if not n_first then
                nearest_selections = cur_selections
            else
                -- If the cursor is inside in the "nearest" selections, use the right-most selections
                if buffer.comes_before(c_first, curpos) then
                    if buffer.comes_before(curpos, n_first) or buffer.comes_before(n_first, c_first) then
                        nearest_selections = cur_selections
                    end
                else -- If the cursor precedes the "nearest" selections, use the left-most selections
                    if buffer.comes_before(curpos, n_first) and buffer.comes_before(c_first, n_first) then
                        nearest_selections = cur_selections
                    end
                end
            end
        end
        -- Reset the cursor position
        buffer.set_curpos(curpos)
    end
    -- If nothing is found, search backwards for the selections that end the latest
    if not nearest_selections then
        for _, c in ipairs(chars) do
            -- Jump to the previous instance of this delimiter
            vim.fn.searchpos(vim.trim(c), "bW")
            local cur_selections = M.get_surrounding_selections(c)
            local n_last = nearest_selections and nearest_selections.right.last_pos
            local c_last = cur_selections and cur_selections.right.last_pos
            if c_last then
                -- If the current selections is for a separator and not on the same line, ignore it
                if not (config.get_opts().delimiters.separators[c] and c_last[1] ~= curpos[1]) then
                    if not n_last then
                        nearest_selections = cur_selections
                    else
                        if buffer.comes_before(n_last, c_last) then
                            nearest_selections = cur_selections
                        end
                    end
                end
            end
            -- Reset the cursor position
            buffer.set_curpos(curpos)
        end
    end
    -- If a pair of selections is found, jump to the beginning of the left one
    if nearest_selections then
        buffer.set_curpos(nearest_selections.left.first_pos)
    end

    return nearest_selections
end

return M
