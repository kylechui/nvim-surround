local M = {}

-- Finds the nearest selection of a given Tree-sitter node type.
---@param type string The Tree-sitter node type to be retrieved.
---@return selection? @The selection of the node.
M.get_selection = function(type)
    local utils = require("nvim-surround.utils")
    local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
    if not ok then
        return nil
    end
    -- Find the root node of the given buffer
    local root = ts_utils.get_node_at_cursor()
    if not root then
        return {}
    end
    while root:parent() do
        root = root:parent()
    end
    -- DFS through the tree and find all nodes that have the given type
    local stack = { root }
    local nodes, selections_list = {}, {}
    while #stack > 0 do
        local cur = stack[#stack]
        -- If the current node's type matches the target type, process it
        if cur:type() == type then
            -- Add the current node to the stack
            nodes[#nodes + 1] = cur
            -- Compute the node's selection and add it to the list
            local range = { ts_utils.get_vim_range({ cur:range() }) }
            selections_list[#selections_list + 1] = {
                left = {
                    first_pos = { range[1], range[2] },
                },
                right = {
                    last_pos = { range[3], range[4] },
                },
            }
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
