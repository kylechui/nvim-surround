local M = {}

--[[
Returns a HTML open/closing pair.
@param Whether or not to include the angle brackets.
@return The HTML tag pair.
]]
M.get_tag = function(include_brackets)
    local tag
    vim.ui.input({
        prompt = "Enter an HTML tag: ",
    }, function(input)
        -- Pattern match the element and attributes
        local element = input:match("^%w+")
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
    end)

    return tag
end

return M
