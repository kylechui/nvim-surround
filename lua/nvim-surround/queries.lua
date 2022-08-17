local utils = require("nvim-surround.utils")
local queries = require("nvim-treesitter.query")
local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

M.get_selection = function(capture, query)
    local selections_list = M.get_selections_list(capture, query)
    local best_selections = utils.filter_selections_list(selections_list)
    return best_selections
        and {
            first_pos = best_selections.left.first_pos,
            last_pos = best_selections.right.last_pos,
        }
end

M.get_selections_list = function(capture, query)
    local selections_list = {}
    local table_list = queries.get_capture_matches_recursively(0, capture, query)
    for _, tab in ipairs(table_list) do
        local node = tab.node
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
    return selections_list
end

return M
