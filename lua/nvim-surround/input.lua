local M = {}

-- Replaces terminal keycodes in an input character.
---@param char string @The input character.
---@return string @The formatted character.
---@nodiscard
M.replace_termcodes = function(char)
    -- Do nothing to ASCII or UTF-8 characters
    if #char == 1 or char:byte() >= 0x80 then
        return char
    end
    -- Otherwise assume the string is a terminal keycode
    return vim.api.nvim_replace_termcodes(char, true, true, true)
end

-- Gets a character input from the user.
---@return string|nil @The input character, or nil if an escape character is pressed.
---@nodiscard
M.get_char = function()
    local ok, char = pcall(vim.fn.getcharstr)
    -- Return nil if input is cancelled (e.g. <C-c> or <Esc>)
    if not ok or char == "\27" then
        return nil
    end
    return M.replace_termcodes(char)
end

-- Gets a string input from the user.
---@param prompt string The input prompt.
---@return string|nil @The user input.
---@nodiscard
M.get_input = function(prompt)
    -- Since `vim.fn.input()` does not handle keyboard interrupts, we use a protected call to detect <C-c>
    local ok, result = pcall(vim.fn.input, { prompt = prompt, cancelreturn = vim.NIL })
    if ok and result ~= vim.NIL then
        return result
    end
end

return M
