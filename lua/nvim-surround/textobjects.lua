local buffer = require("nvim-surround.buffer")

local M = {}

M.get_selection = function(textobject)
    buffer.set_operator_marks(textobject)
    -- Determine whether to use visual marks or operator marks
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

M.get_selections = function() end

return M
