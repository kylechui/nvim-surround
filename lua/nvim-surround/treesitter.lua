local utils = require("nvim-surround.utils")
local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

-- Finds the nearest selection of a given Tree-sitter node type.
---@param type string The Tree-sitter node type to be retrieved.
---@return selection? @The selection of the node.
M.get_selection = function(type)
    local nodes = M.get_nodes(type)
    local selections_list = {}
    for _, node in ipairs(nodes) do
        local range = { ts_utils.get_vim_range({ node:range() }) }
        selections_list[#selections_list + 1] = {
            left = {
                first_pos = { range[1], range[2] },
            },
            right = {
                last_pos = { range[3], range[4] },
            },
        }
    end

    local best_selections = utils.filter_selections_list(selections_list)
    return best_selections
        and {
            first_pos = best_selections.left.first_pos,
            last_pos = best_selections.right.last_pos,
        }
end

-- Retrieves all Tree-sitter nodes of a given type.
---@param type string The node type to be found.
---@return table @A table of all the nodes of the given type in the buffer.
M.get_nodes = function(type)
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
    local nodes = {}
    while #stack > 0 do
        local cur = stack[#stack]
        -- If the current node's type matches the target type, add it to the list
        if cur:type() == type then
            nodes[#nodes + 1] = cur
        end
        stack[#stack] = nil
        for child in cur:iter_children() do
            stack[#stack + 1] = child
        end
    end
    return nodes
end

return M
