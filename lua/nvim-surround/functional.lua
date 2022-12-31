local M = {}

-- Converts singular elements to lists of one element; does nothing to lists.
---@generic T
---@param t T|T[]? The input element.
---@return T[]? @The input wrapped in a list, if necessary.
M.to_list = function(t)
    if not t or vim.tbl_islist(t) then
        return t
    end
    return { t }
end

return M
