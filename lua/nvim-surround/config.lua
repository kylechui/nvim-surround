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
            ["s"] = { "}", "]", ")", ">", '"', "'", "`" },
        },
    },
    highlight_motion = {
        duration = 0,
    }
}

M.user_opts = nil

M.setup = function(user_opts)
    -- Overwrite default options with user-defined options, if they exist
    user_opts = user_opts and vim.tbl_deep_extend("force", M.default_opts, user_opts) or M.default_opts
    M.user_opts = user_opts

    -- Setup keymaps for calling plugin behavior
    map("n", user_opts.keymaps.insert, require("nvim-surround").insert_surround, { silent = true, expr = true })
    map("x", user_opts.keymaps.visual, require("nvim-surround").visual_surround, { silent = true, expr = true })
    map("n", user_opts.keymaps.delete, require("nvim-surround").delete_surround, { silent = true, expr = true })
    map("n", user_opts.keymaps.change, require("nvim-surround").change_surround, { silent = true, expr = true })

    -- Setup delimiters table in utils
    utils.delimiters = user_opts.delimiters
    -- Configure highlight group
    if user_opts.highlight_motion then
        vim.cmd([[
            highlight default link NvimSurroundHighlightTextObject Visual
        ]])
    end
end

return M
