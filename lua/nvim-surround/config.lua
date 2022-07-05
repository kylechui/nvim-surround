local utils = require("nvim-surround.utils")

local map = vim.keymap.set

local M = {}

M.default_opts = {
    keymaps = {
        insert = "ys",
        visual = "S",
        delete = "ds",
        change = "cs",
    },
    delimiters = {
        pairs = {
            ["("] = { "( ", " )" },
            [")"] = { "(", ")" },
            ["{"] = { "{ ", " }" },
            ["}"] = { "{", "}" },
            ["<"] = { "< ", " >" },
            [">"] = { "<", ">" },
            ["["] = { "[ ", " ]" },
            ["]"] = { "[", "]" },
        },
        separators = {
            ["'"] = { "'", "'" },
            ['"'] = { '"', '"' },
            ["`"] = { "`", "`" },
        },
        HTML = {
            ["t"] = true,
        },
        aliases = {
            ["a"] = ">",
            ["b"] = ")",
            ["B"] = "}",
            ["r"] = "]",
            ["q"] = { '"', "'", "`" },
        },
    },
    highlight_motion = {
        duration = 0,
    }
}

M.user_opts = nil

M.setup = function(user_opts)
    -- Overwrite default options with user-defined options, if they exist
    local opts = user_opts and M.merge_options(M.default_opts, user_opts) or M.default_opts
    M.user_opts = opts

    -- Setup keymaps for calling plugin behavior
    map("n", opts.keymaps.insert, require("nvim-surround").insert_surround, { silent = true, expr = true })
    map("x", opts.keymaps.visual, require("nvim-surround").visual_surround, { silent = true, expr = true })
    map("n", opts.keymaps.delete, require("nvim-surround").delete_surround, { silent = true, expr = true })
    map("n", opts.keymaps.change, require("nvim-surround").change_surround, { silent = true, expr = true })

    -- Setup delimiters table in utils
    utils.delimiters = opts.delimiters
    -- Configure highlight group
    if opts.highlight_motion then
        vim.cmd([[
            highlight default link NvimSurroundHighlightTextObject Visual
        ]])
    end
end

--[[
Merges two tables, overwriting values in the former with the corresponding values in the latter
@param t1 The fallback table.
@param t2 The table to overwrite t1.
@return The merged table.
]]
M.merge_options = function(t1, t2)
    for k, v in pairs(t2) do
        -- If t2 is an array, then early return
        if type(k) == "number" then
            return t2
        end

        t1[k] = type(v) == "table" and M.merge_options(t1[k], v) or v
    end
    return t1
end

return M
