---A WK plugin for showing available surrounds with keys.
---
---Users need to set_up this plugin before using it.
---
---To get a char with a WK popup, call pick().

---@diagnostic disable: missing-fields, inject-field
---@type wk.Plugin
local M = {}

M.name = "nvim-surround"

-- WK requires keymaps.
-- We use "⌨" here to make sure we never collide with actual keymaps.
local keys = "⌨S"

M.mappings = {
    {
        [1] = keys,
        plugin = M.name,
        icon = { icon = "⌨", color = "blue" },
        desc = "Nvim-surround",
        mode = { "n", "x" },
    },
}

local selected_key = nil
local expand_hints = {}

function M.expand()
    ---@type wk.Plugin.item[]
    local items = {}

    for key, label in pairs(expand_hints) do
        table.insert(items, {
            key = key,
            desc = label,
            value = "",
            action = function()
                selected_key = key
            end,
        })
    end

    table.sort(items, function(a, b)
        return a.key < b.key
    end)

    return items
end

---Gets a character from the user with the provided hints.
---
---@param hints table<string, string> A table from chars to their labels.
---@param mode "n"|"x"
---@return string? selected_key
function M.pick(hints, mode)
    selected_key = nil
    expand_hints = hints
    require("which-key").show({ keys = keys, mode = mode })
    return selected_key
end

---Whether the final user has set up this plugin.
---
---@type boolean
M.plugin_set_up = false

-- This function is called "set_up" to make sure it doesn't conflict with WK’s "setup."
function M.set_up()
    local wk = require("which-key")
    wk.add(M.mappings)
    require("which-key.plugins").plugins[M.name] = M
    require("which-key.plugins")._setup(M, {})
    M.plugin_set_up = true
end

return M
