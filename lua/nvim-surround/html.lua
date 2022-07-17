local config = require("nvim-surround.config")

local M = {}

-- Returns the type of HTML selection that the character refers to.
---@param char string? The input character.
---@return string? @The HTML selection type, or nil if not an HTML character.
M.get_type = function(char)
    return config.get_opts().delimiters.HTML[char]
end

-- Returns a HTML open/closing pair.
---@param include_brackets? boolean Whether or not to include the angle brackets.
---@return string[][]? @The HTML tag pair.
M.get_tag = function(include_brackets)
    -- Handle cancellation by the user
    local ok, input = pcall(vim.fn.input, { prompt = "Enter an HTML tag: " })
    if not ok then
        return nil
    end
    local element = input:match("^<?([%w-]+)")
    local attributes = input:match(" +([^>]+)>?$")
    if not element then
        return nil
    end
    -- Only include attributes if they exist
    local open = attributes and element .. " " .. attributes or element
    local close = element
    -- Optionally include the angle brackets around the tag
    if include_brackets then
        open = "<" .. open .. ">"
        close = "</" .. close .. ">"
    end
    local tag = { { open }, { close } }

    return tag
end

-- Adjust the selection boundaries to only select the HTML tag type.
---@param selections? selections The coordinates of the open and closing HTML tags.
---@param type string? The type of selections to be returning.
---@return integer[]? @The coordinates of the adjusted HTML tag.
M.adjust_selections = function(selections, type)
    if not selections then
        return nil
    end
    local open, close = selections.left, selections.right
    -- Move the boundaries to deselect the angle brackets and attributes
    close.first_pos[2] = close.first_pos[2] + 2
    close.last_pos[2] = close.last_pos[2] - 1
    open.first_pos[2] = open.first_pos[2] + 1
    if type == "whole" then
        open.last_pos[2] = open.last_pos[2] - 1
    else
        open.last_pos[1] = open.first_pos[1]
        open.last_pos[2] = open.first_pos[2] + close.last_pos[2] - close.first_pos[2]
    end
    return {
        left = {
            first_pos = open.first_pos,
            last_pos = open.last_pos,
        },
        right = {
            first_pos = close.first_pos,
            last_pos = close.last_pos,
        },
    }
end

return M
