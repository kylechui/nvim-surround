local buffer = require("nvim-surround.buffer")

local M = {}

M.is_quote = function(char)
    return char == "'" or char == '"' or char == "`"
end

-- Gets a selection based on the text-object for a given character, `a[char]`.
---@param char string The provided character.
---@return selection? @The selection that represents the text-object.
M.get_selection = function(char)
    -- Smart quotes feature; jump to the next quote if it is on the same line
    local curpos = buffer.get_curpos()
    if M.is_quote(char) and vim.fn.searchpos(char, "cnW")[1] == curpos[1] then
        vim.fn.cursor(vim.fn.searchpos(char, "cnW"))
    end

    buffer.set_operator_marks(char)
    -- Adjust the marks to reside on non-whitespace characters
    buffer.adjust_mark("[")
    buffer.adjust_mark("]")

    -- Get the row and column of the first and last characters of the selection
    local selection = {
        first_pos = buffer.get_mark("["),
        last_pos = buffer.get_mark("]"),
    }
    -- If a selection is found surrounding the cursor or after it, then return
    if selection.first_pos and selection.last_pos then
        -- Restore the cursor position
        buffer.set_curpos(curpos)
        return selection
    end

    -- Since no selection was found around/after the cursor, we look behind
    if char == "t" then -- Handle special case with lookbehind for HTML tags (search for `>` instead of `t`)
        vim.fn.searchpos(">", "bcW")
    elseif M.is_quote(char) then -- Handle special case with lookbehind for quote characters (stay in current line)
        if vim.fn.searchpos(char, "bncW")[1] == curpos[1] then
            vim.fn.searchpos(char, "bcW")
        end
    else -- General case, jump to the character
        vim.fn.searchpos(char, "bcW")
    end

    buffer.set_operator_marks(char)
    -- Adjust the marks to reside on non-whitespace characters
    buffer.adjust_mark("[")
    buffer.adjust_mark("]")

    -- Get the row and column of the first and last characters of the selection
    selection = {
        first_pos = buffer.get_mark("["),
        last_pos = buffer.get_mark("]"),
    }

    -- Restore the cursor position
    buffer.set_curpos(curpos)
    -- Return nil if either endpoint of the selection do not exist
    return selection.first_pos and selection.last_pos and selection
end

return M
