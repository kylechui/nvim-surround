local buffer = require("nvim-surround.buffer")

local M = {}

-- Converts a 1D index into the buffer to the corresponding 2D buffer position.
---@param index integer The index of the character in the string.
M.index_to_pos = function(index)
    local buffer_text = table.concat(buffer.get_lines(1, -1), "\n")
    local lnum = select(2, buffer_text:sub(1, index - 1):gsub("\n", "\n")) + 1
    if lnum == 1 then
        return { 1, index }
    end
    local col = index - #table.concat(buffer.get_lines(1, lnum - 1), "\n") - 1
    return { lnum, col }
end

-- Converts a 2D position in the buffer to the corresponding 1D string index.
---@param pos integer[] The position in the buffer.
M.pos_to_index = function(pos)
    if pos[1] == 1 then
        return pos[2]
    end
    return #table.concat(buffer.get_lines(1, pos[1] - 1), "\n") + pos[2] + 1
end

-- Finds a Lua pattern in the buffer.
---@param pattern string The pattern to search for.
---@param filter string The pattern to filter for.
M.find = function(pattern, filter)
    -- Get the current cursor position, buffer contents
    local curpos = buffer.get_curpos()
    local buffer_text = table.concat(buffer.get_lines(1, -1), "\n")
    -- Find which character the cursor is in the file
    local cursor_index = M.pos_to_index(curpos)
    -- Find the character positions of the pattern in the file (after the cursor)
    local a_first, a_last = buffer_text:find(pattern, cursor_index)
    -- Find the character positions of the pattern in the file (before/on the cursor)
    local b_first, b_last
    -- Linewise search for the pattern before/on the cursor
    for lnum = curpos[1], 1, -1 do
        -- Get the file contents from the first line to current line
        local cur_text = table.concat(buffer.get_lines(1, lnum - 1), "\n")
        -- Find the character positions of the pattern in the file (after the cursor)
        b_first, b_last = buffer_text:find(pattern, #cur_text + 1)
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
    local tmp = b_first
    while true do
        local t_first, t_last = buffer_text:find(pattern, tmp)
        if not t_first or t_first > cursor_index then
            break
        end
        if (b_last < cursor_index and b_last < t_last) or (b_last >= cursor_index and t_last >= cursor_index) then
            b_first, b_last = t_first, t_last
        end
        local len = #buffer_text:sub(b_first, b_last):match(filter)
        tmp = t_first + len
    end

    -- If the cursor is inside the range then return it
    if b_last >= cursor_index then
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

-- Finds the start and end indices for the given match groups, as close to the beginning and end as possible.
---@param start integer
M.get_selections = function(start, str, pattern)
    -- Get the surrounding pair itself
    local _, _, left_delimiter, first_index, right_delimiter, last_index = str:find(pattern)
    local left, right
    if type(left_delimiter) == "string" then
        left = {
            first_pos = M.index_to_pos(start + first_index - #left_delimiter - 1),
            last_pos = M.index_to_pos(start + first_index - 2),
        }
    end
    if type(right_delimiter) == "string" then
        right = {
            first_pos = M.index_to_pos(start + last_index - #right_delimiter - 1),
            last_pos = M.index_to_pos(start + last_index - 2),
        }
    end
    return {
        left = left,
        right = right,
    }
end

return M
