local utils = require("nvim-surround.utils")
local ts_query = require("nvim-treesitter.query")
local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

-- Finds the nearest selection of a given query capture and its source.
---@param capture string The capture to be retrieved.
---@param type string The type of query to get the capture from.
---@return selection? @The selection of the capture.
M.get_selection = function(capture, type)
    -- Get a table of all nodes that match the query
    local table_list = ts_query.get_capture_matches_recursively(0, capture, type)
    -- Convert the list of nodes into a list of selections
    local selections_list = {}
    for _, tab in ipairs(table_list) do
        local range = { ts_utils.get_vim_range({ tab.node:range() }) }
        selections_list[#selections_list + 1] = {
            left = {
                first_pos = { range[1], range[2] },
            },
            right = {
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
