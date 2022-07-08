local utils = require("nvim-surround.utils")

local map = vim.keymap.set

local M = {}

M.default_opts = {
    keymaps = {
        insert = "ys",
        insert_line = "yss",
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
            ["i"] = function()
                return {
                    utils.get_input(
                        "Enter the left delimiter: "
                    ),
                    utils.get_input(
                        "Enter the right delimiter: "
                    )
                }
            end,
            ["f"] = function()
                return {
                    utils.get_input(
                        "Enter the function name: "
                    ) .. "(",
                    ")"
                }
            end,
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
    map("n", user_opts.keymaps.insert, require("nvim-surround").insert_surround,
        { silent = true, expr = true }
    )
    map("x", user_opts.keymaps.visual, require("nvim-surround").visual_surround,
        { silent = true, expr = true }
    )
    map("n", user_opts.keymaps.delete, require("nvim-surround").delete_surround,
        { silent = true, expr = true }
    )
    map("n", user_opts.keymaps.change, require("nvim-surround").change_surround,
        { silent = true, expr = true }
    )

    -- Configure highlight group
    if user_opts.highlight_motion then
        vim.cmd([[
            highlight default link NvimSurroundHighlightTextObject Visual
        ]])
    end
    -- Configure buffer setup autocommand
    local buffer_setup_group = vim.api.nvim_create_augroup("nvimSurroundBufferSetup", {})
    vim.api.nvim_create_autocmd("BufEnter", {
        callback = M.buffer_setup,
        group = buffer_setup_group,
    })
end

M.buffer_setup = function(buffer_opts)
    -- Grab the current buffer-local options, or the global user options otherwise
    local cur_opts = vim.b[0].buffer_opts and vim.b[0].buffer_opts or M.user_opts
    -- Overwrite the current options with buffer-local options, if they exist
    buffer_opts = buffer_opts and vim.tbl_deep_extend("force", cur_opts, buffer_opts) or cur_opts
    vim.b[0].buffer_opts = buffer_opts

    -- Setup buffer-local keymaps for calling plugin behavior
    map("n", buffer_opts.keymaps.insert, require("nvim-surround").insert_surround,
        { silent = true, expr = true, buffer = true }
    )
    map("n", buffer_opts.keymaps.insert_line, function()
        return "^" .. tostring(vim.v.count1) .. buffer_opts.keymaps.insert .. "g_"
    end, { silent = true, expr = true, buffer = true, remap = true })
    map("x", buffer_opts.keymaps.visual, require("nvim-surround").visual_surround,
        { silent = true, expr = true, buffer = true }
    )
    map("n", buffer_opts.keymaps.delete, require("nvim-surround").delete_surround,
        { silent = true, expr = true, buffer = true }
    )
    map("n", buffer_opts.keymaps.change, require("nvim-surround").change_surround,
        { silent = true, expr = true, buffer = true }
    )
end

return M
