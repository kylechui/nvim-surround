local M = {}

-- Returns whether or not a target node type is found in a list of types.
---@param target string The target type to be found.
---@param types string[] The list of types to search through.
---@return boolean @Whether or not the target type is found.
---@nodiscard
local function is_any_of(target, types)
    for _, type in ipairs(types) do
        if target == type then
            return true
        end
    end
    return false
end

-- Gets the root node for the buffer.
---@return TSNode|nil @The root node for the buffer.
---@nodiscard
M.get_root = function()
    if vim.treesitter then
        return vim.treesitter.get_node():tree():root()
    end

    local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
    if not ok then
        return nil
    end

    local node = ts_utils.get_node_at_cursor()
    if node == nil then
        return nil
    end
    return ts_utils.get_root_for_node(node)
end

-- Gets the selection that a TreeSitter node spans.
---@param node TSNode The given TreeSitter node.
---@return selection @The span of the input node.
---@nodiscard
M.get_node_selection = function(node)
    ---@type integer, integer, integer, integer
    local srow, scol, erow, ecol = node:range()
    srow = srow + 1
    scol = scol + 1
    erow = erow + 1

    if ecol == 0 then
        -- Use the value of the last col of the previous row instead.
        erow = erow - 1
        ecol = math.max(1, vim.fn.col({ erow, "$" }) - 1)
    end
    return {
        first_pos = { srow, scol },
        last_pos = { erow, ecol },
    }
end

-- Finds the nearest selection of a given Tree-sitter node type or types.
---@param node_types string|string[] The Tree-sitter node type(s) to be retrieved.
---@return selection|nil @The selection of the node.
---@nodiscard
M.get_selection = function(node_types)
    local utils = require("nvim-surround.utils")

    if type(node_types) == "string" then
        node_types = { node_types }
    end

    local root = M.get_root()
    if root == nil then
        return nil
    end
    -- DFS through the tree and find all nodes that have the given type
    local stack = { root }
    local nodes, selections_list = {}, {}
    while #stack > 0 do
        local cur = stack[#stack]
        -- If the current node's type matches the target type, process it
        if is_any_of(cur:type(), node_types) then
            -- Add the current node to the stack
            nodes[#nodes + 1] = cur
            -- Compute the node's selection and add it to the list
            local selection = M.get_node_selection(cur)
            selections_list[#selections_list + 1] = selection
        end
        -- Pop off of the stack
        stack[#stack] = nil
        -- Add the current node's children to the stack
        for child in cur:iter_children() do
            stack[#stack + 1] = child
        end
    end
    -- Filter out the best pair of selections from the list
    local best_selections = utils.filter_selections_list(selections_list)
    return best_selections
        and {
            first_pos = best_selections.left.first_pos,
            last_pos = best_selections.right.last_pos,
        }
end

return M
