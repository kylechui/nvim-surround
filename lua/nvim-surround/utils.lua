local buffer = require("nvim-surround.buffer")
local config = require("nvim-surround.config")
local html = require("nvim-surround.html")

local M = {}

-- Do nothing.
M.NOOP = function() end

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
    local delimiters = config.get_opts().delimiters
    if type(delimiters.aliases[char]) == "string" and #delimiters.aliases[char] == 1 then
        return delimiters.aliases[char]
    end
    return char
end

-- Gets a delimiter pair for a user-inputted character.
---@param char string? The user-given character.
---@param args? { bufnr: integer, selection: selection, text: string[] }
---@return delimiters @A pair of delimiters for the given input, or nil if not applicable.
M.get_delimiters = function(char, args)
    char = M.get_alias(char)
    -- Return nil if the user cancels the command
    if not char then
        return nil
    end

    local delimiters
    if html.get_type(char) then
        delimiters = html.get_tag(true)
    else
        delimiters = config.get_opts().delimiters.pairs[char]
            or config.get_opts().delimiters.separators[char]
            or config.get_opts().delimiters.invalid_key_behavior(char)
    end
    if not delimiters then
        return nil
    end

    -- Evaluate the function if necessary
    if type(delimiters) == "function" then
        delimiters = delimiters(args)
    end
    if type(delimiters) ~= "table" then
        return nil
    end

    -- Wrap the delimiters in a table if necessary
    delimiters[1] = type(delimiters[1]) == "string" and { delimiters[1] } or delimiters[1]
    delimiters[2] = type(delimiters[2]) == "string" and { delimiters[2] } or delimiters[2]
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
---@return selections? @A table containing the start and end positions of the delimiters.
M.get_surrounding_selections = function(char)
    char = M.get_alias(char)
    if not char then
        return nil
    end
    local open_first, open_last, close_first, close_last
    local curpos = buffer.get_curpos()
    -- Use the correct quotes to surround the arguments for setting the marks
    local args
    if html.get_type(char) then
        args = "'t'"
    elseif char == "'" then
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

    if html.get_type(char) then
        -- Find the correct selection boundaries for HTML tags
        buffer.set_curpos(close_last)
        close_first = vim.fn.searchpos("<", "nbW")
        buffer.set_curpos(open_first)
        open_last = vim.fn.searchpos(">", "nW")
        if close_first == { 0, 0 } or open_last == { 0, 0 } then
            return nil
        end
    else
        -- Get the corresponding delimiter pair for the character
        local delimiters = M.get_delimiters(char)
        if not delimiters then
            return nil
        end
        -- Use the length of the pair to find the proper selection boundaries
        local open_line = buffer.get_lines(open_first[1], open_first[1])[1]
        local close_line = buffer.get_lines(close_last[1], close_last[1])[1]
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

-- Gets the nearest two selections for the left and right surrounding pair.
---@param char string? A character representing what kind of surrounding pair is to be selected.
---@return selections? @A table containing the start and end positions of the delimiters.
M.get_nearest_selections = function(char)
    char = M.get_alias(char)

    local delimiters = config.get_opts().delimiters
    local chars = delimiters.aliases[char] and delimiters.aliases[char] or { char }
    local nearest_selections
    local curpos = buffer.get_curpos()
    -- Iterate through all possible selections for each aliased character, and
    -- find the pair that is closest to the cursor position (that also still
    -- surrounds the cursor)
    for _, c in ipairs(chars) do
        -- If the character is a separator and the next separator is on the same line, jump to it
        if config.get_opts().delimiters.separators[c] and vim.fn.searchpos(c, "cnW")[1] == curpos[1] then
            vim.fn.searchpos(c, "cW")
        end
        local cur_selections = M.get_surrounding_selections(c)
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
