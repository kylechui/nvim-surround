local utils = require("nvim-surround.utils")

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
            ["t"] = "type",
            ["T"] = "whole",
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
    -- Configure user-set defaults for the current buffer in case the plugin is lazy-loaded
    M.buffer_setup(user_opts)

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
    utils.set_opts(buffer_opts)

    -- Setup buffer-local keymaps for calling plugin behavior
    M.add_keymap({
        mode = "n",
        lhs = buffer_opts.keymaps.insert,
        rhs = require("nvim-surround").insert_surround,
        opts = { silent = true, expr = true, buffer = true },
    })
    M.add_keymap({
        mode = "n",
        lhs = buffer_opts.keymaps.insert_line,
        rhs = function()
            return "^" .. tostring(vim.v.count1) .. buffer_opts.keymaps.insert .. "g_"
        end,
        opts = { silent = true, expr = true, buffer = true, remap = true },
    })
    M.add_keymap({
        mode = "x",
        lhs = buffer_opts.keymaps.visual,
        rhs = function()
            local mode = vim.fn.mode()
            return "<Esc><Cmd>lua require'nvim-surround'.visual_surround('" .. mode .. "')<CR>"
        end,
        opts = { silent = true, expr = true, buffer = true },
    })
    M.add_keymap({
        mode = "n",
        lhs = buffer_opts.keymaps.delete,
        rhs = require("nvim-surround").delete_surround,
        opts = { silent = true, expr = true, buffer = true },
    })
    M.add_keymap({
        mode = "n",
        lhs = buffer_opts.keymaps.change,
        rhs = require("nvim-surround").change_surround,
        opts = { silent = true, expr = true, buffer = true },
    })
end

M.add_keymap = function(args)
    -- If the mapping has been disabled, don't set it
    if not args.lhs then
        return
    end
    vim.keymap.set(args.mode, args.lhs, args.rhs, args.opts)
end

return M
