local M = {}

--[[
Returns a HTML open/closing pair.
@param Whether or not to include the angle brackets.
@return The HTML tag pair.
]]
M.get_tag = function(include_brackets)
    local input = vim.fn.input({
        prompt = "Enter an HTML tag: ",
        cancelreturn = nil,
    })
    if not input then
        return nil
    end
    local element = input:match("^[%w-]+")
    local attributes = input:match(" +(.+)$")
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
    local tag = { open, close }

    return tag
    --[[ TODO: Figure out how to make vim.ui.input blocking
    vim.ui.input({
        prompt = "Enter an HTML tag: ",
    }, function(input)
        if not input then
            return
        end
        -- Pattern match the element and attributes
        local element = input:match("^[%w-]+")
        local attributes = input:match(" +(.+)$")
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
        tag = { open, close }
    end) ]]
end

--[[
Adjust the selection boundaries to only select the HTML tag type.
@param The coordinates of the open and closing HTML tags.
@return The coordinates of the HTML tag.
]]
M.adjust_selections = function(selections)
    if not selections then
        return nil
    end
    local open, close = selections.left, selections.right
    -- Move the boundaries to deselect the angle brackets and attributes
    close.first_pos[2] = close.first_pos[2] + 2
    close.last_pos[2] = close.last_pos[2] - 1
    open.first_pos[2] = open.first_pos[2] + 1
    open.last_pos[2] = open.first_pos[2] + close.last_pos[2] - close.first_pos[2]
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
