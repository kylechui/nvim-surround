local M = {}

-- Retrieves the node that corresponds exactly to a given selection.
---@param selection selection The given selection.
---@return TSNode|nil @The corresponding node.
---@nodiscard
M.get_node = function(selection)
    local treesitter = require("nvim-surround.treesitter")

    local root = treesitter.get_root()
    if root == nil then
        return nil
    end
    -- DFS through the tree and find all nodes that have the given type
    local stack = { root }
    while #stack > 0 do
        local cur = stack[#stack]
        -- If the current node's range is equal to the desired selection, return the node
        if vim.deep_equal(selection, treesitter.get_node_selection(cur)) then
            return cur
        end
        -- Pop off of the stack
        stack[#stack] = nil
        -- Add the current node's children to the stack
        for child in cur:iter_children() do
            stack[#stack + 1] = child
        end
    end
    return nil
end

-- Finds the nearest selection of a given query capture and its source.
---@param capture string The capture to be retrieved.
---@param type string The type of query to get the capture from.
---@return selection|nil @The selection of the capture.
---@nodiscard
M.get_selection = function(capture, type)
    local utils = require("nvim-surround.utils")
    local treesitter = require("nvim-surround.treesitter")
    local ts_query = require("nvim-treesitter.query")

    -- Get a table of all nodes that match the query
    local table_list = ts_query.get_capture_matches_recursively(0, capture, type)
    -- Convert the list of nodes into a list of selections
    local selections_list = {}
    for _, tab in ipairs(table_list) do
        local selection = treesitter.get_node_selection(tab.node)

        local range = { selection.first_pos[1], selection.first_pos[2], selection.last_pos[1], selection.last_pos[2] }
        selections_list[#selections_list + 1] = {
            left = {
                first_pos = { range[1], range[2] },
                last_pos = { range[3], range[4] },
            },
            right = {
                first_pos = { range[3], range[4] + 1 },
                last_pos = { range[3], range[4] },
            },
        }
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
