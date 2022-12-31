local buffer = require("nvim-surround.buffer")
local config = require("nvim-surround.config")
local functional = require("nvim-surround.functional")

local M = {}

-- Do nothing.
M.NOOP = function() end

-- Gets the nearest two selections for the left and right surrounding pair.
---@param char string? A character representing what kind of surrounding pair is to be selected.
---@param action "delete"|"change" A string representing what action is being performed.
---@return selections? @A table containing the start and end positions of the delimiters.
---@nodiscard
M.get_nearest_selections = function(char, action)
    char = config.get_alias(char)

    local chars = functional.to_list(config.get_opts().aliases[char] or char)
    local curpos = buffer.get_curpos()
    local selections_list = {}
    -- Iterate through all possible selections for each aliased character, and find the closest pair
    for _, c in ipairs(chars) do
        local cur_selections = (function()
            if action == "change" then
                return config.get_change(c).target(c)
            else
                return config.get_delete(c)(c)
            end
        end)()
        -- If found, add the current selections to the list of all possible selections
        if cur_selections then
            selections_list[#selections_list + 1] = cur_selections
        end
        -- Reset the cursor position
        buffer.set_curpos(curpos)
    end
    local nearest_selections = M.filter_selections_list(selections_list)
    -- If a pair of selections is found, jump to the beginning of the left one
    if nearest_selections then
        buffer.set_curpos(nearest_selections.left.first_pos)
    end

    return nearest_selections
end

-- Filters down a list of selections to the best one, based on the jumping heuristic.
---@param selections_list selections[] The given list of selections.
---@return selections? @The best selections from the list.
---@nodiscard
M.filter_selections_list = function(selections_list)
    local curpos = buffer.get_curpos()
    local best_selections
    for _, cur_selections in ipairs(selections_list) do
        if cur_selections then
            best_selections = best_selections or cur_selections
            if buffer.is_inside(curpos, best_selections) then
                -- Handle case where the cursor is inside the nearest selections
                if
                    buffer.is_inside(curpos, cur_selections)
                    and buffer.comes_before(best_selections.left.first_pos, cur_selections.left.first_pos)
                    and buffer.comes_before(cur_selections.right.last_pos, best_selections.right.last_pos)
                then
                    best_selections = cur_selections
                end
            elseif buffer.comes_before(curpos, best_selections.left.first_pos) then
                -- Handle case where the cursor comes before the nearest selections
                if
                    buffer.is_inside(curpos, cur_selections)
                    or buffer.comes_before(curpos, cur_selections.left.first_pos)
                        and buffer.comes_before(cur_selections.left.first_pos, best_selections.left.first_pos)
                then
                    best_selections = cur_selections
                end
            else
                -- Handle case where the cursor comes after the nearest selections
                if
                    buffer.is_inside(curpos, cur_selections)
                    or buffer.comes_before(best_selections.right.last_pos, cur_selections.right.last_pos)
                then
                    best_selections = cur_selections
                end
            end
        end
    end
    return best_selections
end

return M
