local buffer = require("nvim-surround.buffer")

local M = {}

-- Gets a selection based on the text-object for a given character, `a[char]`.
---@param char string The provided character.
---@return selection? @The selection that represents the text-object.
M.get_selection = function(char)
    buffer.set_operator_marks(char)
    -- Adjust the marks to reside on non-whitespace characters
    buffer.adjust_mark("[")
    buffer.adjust_mark("]")

    -- Get the row and column of the first and last characters of the selection
    local first_position = buffer.get_mark("[")
    local last_position = buffer.get_mark("]")
    if not first_position or not last_position then
        return nil
    end

    local selection = {
        first_pos = first_position,
        last_pos = last_position,
    }
    return selection
end

return M
