local buffer = require("nvim-surround.buffer")

local M = {}

-- Converts a 1D index into the buffer to the corresponding 2D buffer position.
---@param index integer The index of the character in the string.
M.index_to_pos = function(index)
    local buffer_text = table.concat(buffer.get_lines(1, -1), "\n")
    -- Counts the number of newline characters, plus one for the final character before the current line
    local lnum = select(2, buffer_text:sub(1, index - 1):gsub("\n", "\n")) + 1
    -- Special case for first line, as there are no newline characters preceding it
    if lnum == 1 then
        return { 1, index }
    end
    local col = index - #table.concat(buffer.get_lines(1, lnum - 1), "\n") - 1
    return { lnum, col }
end

-- Converts a 2D position in the buffer to the corresponding 1D string index.
---@param pos integer[] The position in the buffer.
M.pos_to_index = function(pos)
    -- Special case for first line, as there are no newline characters preceding it
    if pos[1] == 1 then
        return pos[2]
    end
    return #table.concat(buffer.get_lines(1, pos[1] - 1), "\n") + pos[2] + 1
end

-- Returns a selection in the buffer based on a Lua pattern.
---@param find string The Lua pattern to find in the buffer.
M.get_selection = function(find)
    -- Get the current cursor position, buffer contents
    local curpos = buffer.get_curpos()
    local buffer_text = table.concat(buffer.get_lines(1, -1), "\n")
    -- Find which character the cursor is in the file
    local cursor_index = M.pos_to_index(curpos)
    -- Find the character positions of the pattern in the file (after/on the cursor)
    local a_first, a_last = buffer_text:find(find, cursor_index)
    -- Find the character positions of the pattern in the file (before the cursor)
    local b_first, b_last
    -- Linewise search for the pattern before/on the cursor
    for lnum = curpos[1], 1, -1 do
        -- Get the file contents from the first line to current line
        local cur_text = table.concat(buffer.get_lines(1, lnum - 1), "\n")
        -- Find the character positions of the pattern in the file (before the cursor)
        b_first, b_last = buffer_text:find(find, #cur_text + 1)
        if b_first and b_first < cursor_index then
            break
        end
    end
    -- If no match found, return the after one, if it exists
    if not b_first or not b_last then
        return a_first
            and a_last
            and {
                first_pos = M.index_to_pos(a_first),
                last_pos = M.index_to_pos(a_last),
            }
    end
    -- Adjust the selection character-wise
    local start_col, end_col = math.min(b_last, cursor_index), b_first
    b_first, b_last = nil, nil
    for index = start_col, end_col, -1 do
        vim.pretty_print(M.index_to_pos(index))
        local c_first, c_last = buffer_text:find(find, index)
        -- Validate if there is a current match
        if c_last then
            -- If no match yet or the current match is "better", use the current match
            if
                not (b_first and b_last) -- No match yet
                or (b_last == c_last) -- Extending current match
                or (cursor_index < b_first and c_first < b_first) -- Current is closer to cursor, after case
                or (b_last < cursor_index and b_last < c_last) -- Current is closer to cursor, before case
            then
                b_first, b_last = c_first, c_last
            end
        end
    end
    -- If the cursor is inside the range then return it
    if b_last and b_first and b_last >= cursor_index then
        return {
            first_pos = M.index_to_pos(b_first),
            last_pos = M.index_to_pos(b_last),
        }
    end
    -- Else if there's a range found after the cursor, return it
    if a_first and a_last then
        return {
            first_pos = M.index_to_pos(a_first),
            last_pos = M.index_to_pos(a_last),
        }
    end
    -- Otherwise return the range found before the cursor, if one exists
    if b_first and b_last then
        return {
            first_pos = M.index_to_pos(b_first),
            last_pos = M.index_to_pos(b_last),
        }
    end
end

-- Finds the start and end indices for the given match groups.
---@param offset integer The offset of the search string into the buffer.
---@param str string The given string to match against.
---@param pattern string The given Lua pattern to extract match groups from.
---@return selections @The selections for the left and right delimiters.
M.get_selections = function(offset, str, pattern)
    -- Get the surrounding pair, and the start/end indices
    local _, _, left_delimiter, first_index, right_delimiter, last_index = str:find(pattern)
    local left, right
    -- Validate that the match groups are non-empty, since empty match groups return indices
    if type(left_delimiter) == "string" then
        left = {
            first_pos = M.index_to_pos(offset + first_index - #left_delimiter - 1),
            last_pos = M.index_to_pos(offset + first_index - 2),
        }
    end
    if type(right_delimiter) == "string" then
        right = {
            first_pos = M.index_to_pos(offset + last_index - #right_delimiter - 1),
            last_pos = M.index_to_pos(offset + last_index - 2),
        }
    end
    return {
        left = left,
        right = right,
    }
end

return M
