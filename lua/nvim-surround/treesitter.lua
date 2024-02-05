local utils = require("nvim-surround.utils")
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

-- Finds the nearest selection of a given Tree-sitter node type or types.
---@param node_types string|string[] The Tree-sitter node type(s) to be retrieved.
---@return selection|nil @The selection of the node.
---@nodiscard
M.get_selection = function(node_types)
    if type(node_types) == "string" then
        node_types = { node_types }
    end

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
        if is_any_of(cur:type(), node_types) then
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

--- Traverse a TSNode and iterate on children. If a node from `kinds` is found, add its bounds to
--- the resulting list. If `recurses` is present, then these nodes will be recursively visited.
--- `capture_extra` is for whether or not to include stuff like comments.
---@param node TSNode
---@param kinds TS_kinds
---@param opts {capture_extra?: boolean, recurses?: TS_kinds}?
---@return regions
M.get_regions = function(node, kinds, opts)
    opts = opts or {}
    local recurses = opts.recurses or { fields = {}, types = {} }
    local capture_extra = opts.capture_extra == nil and true or opts.capture_extra
    local regions = {}

    for child, child_field in node:iter_children() do
        local child_type = child:type()
        local has_recurses_field = vim.list_contains(recurses.fields, child_field)
        local has_recurses_type = vim.list_contains(recurses.types, child_type)

        if has_recurses_field or has_recurses_type then
            vim.list_extend(regions, M.get_regions(child, kinds, opts))
        else
            local has_kinds_field = vim.list_contains(kinds.fields, child_field)
            local has_kinds_type = vim.list_contains(kinds.types, child_type)

            if has_kinds_field or has_kinds_type or (capture_extra and child:extra()) then
                table.insert(regions, utils.as_selection({ child:range() }))
            end
        end
    end

    return regions
end

return M
