local buffer = require("nvim-surround.buffer")

local M = {}

-- Converts a 1D index into the buffer to the corresponding 2D buffer position.
---@param index integer The index of the character in the buffer.
M.index_to_pos = function(index)
    local buffer_text = table.concat(buffer.get_lines(1, -1), "\n")
    local lnum = select(2, buffer_text:sub(1, index - 1):gsub("\n", "\n")) + 1
    local col = index - #table.concat(buffer.get_lines(1, lnum - 1), "\n") - 1
    return { lnum, col }
end

-- Finds a Lua pattern in the buffer.
---@param pattern string The pattern to search for.
---@param filter string The pattern to filter for.
M.find = function(pattern, filter)
    -- Get the current cursor position, buffer contents
    local curpos = buffer.get_curpos()
    local buffer_text = table.concat(buffer.get_lines(1, -1), "\n")
    -- Find which character the cursor is in the file
    local cursor_index = #table.concat(buffer.get_lines(1, curpos[1] - 1), "\n") + curpos[2] + 1
    -- Find the character positions of the pattern in the file (after the cursor)
    local a_first, a_last = buffer_text:find(pattern, cursor_index)
    -- Find the character positions of the pattern in the file (before/on the cursor)
    local b_first, b_last
    -- Linewise search for the pattern before/on the cursor
    for lnum = curpos[1] - 1, 0, -1 do
        -- Get the file contents from the first to current line
        local cur_text = table.concat(buffer.get_lines(1, lnum), "\n")
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

return M
