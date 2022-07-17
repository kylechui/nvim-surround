local M = {}

local get_input = function(prompt)
    local ok, result = pcall(vim.fn.input, { prompt = prompt })
    if not ok then
        return nil
    end
    return result
end

M.default_opts = {
    keymaps = {
        insert = "ys",
        insert_line = "yss",
        visual = "S",
        delete = "ds",
        change = "cs",
    },
    delimiters = {
        invalid_key_behavior = function()
            vim.api.nvim_err_writeln(
                "Error: Invalid character! Configure this message in " .. 'require("nvim-surround").setup()'
            )
        end,
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
                local left_delimiter = get_input("Enter the left delimiter: ")
                if left_delimiter then
                    local right_delimiter = get_input("Enter the right delimiter: ")
                    if right_delimiter then
                        return { left_delimiter, right_delimiter }
                    end
                end
            end,
            ["f"] = function()
                local result = get_input("Enter the function name: ")
                if result then
                    return { result .. "(", ")" }
                end
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
    },
    move_cursor = "begin",
}

M.user_opts = nil

-- Returns the buffer-local options for the plugin.
---@return options @The buffer-local options.
M.get_opts = function()
    return vim.b[0].nvim_surround_buffer_opts
end

-- Updates the buffer-local options for the plugin based on the input.
---@param opts options? The options to be passed in.
M.merge_opts = function(opts)
    -- Grab the current buffer-local options, or the global user options otherwise
    local cur_opts = M.get_opts() and M.get_opts() or M.user_opts
    -- Overwrite the current options with buffer-local options, if they exist
    opts = opts and vim.tbl_deep_extend("force", cur_opts, opts) or cur_opts
    vim.b[0].nvim_surround_buffer_opts = opts
end

-- Check if a keymap should be added before setting it.
---@param args table The arguments to set the keymap.
M.add_keymap = function(args)
    -- Only set the mapping if it hasn't been disabled
    if args.lhs then
        vim.keymap.set(args.mode, args.lhs, args.rhs, args.opts)
    end
end

-- Setup the global user options for all files.
---@param user_opts options? The user-defined options to be merged with default_opts.
M.setup = function(user_opts)
    -- Overwrite default options with user-defined options, if they exist
    user_opts = user_opts and vim.tbl_deep_extend("force", M.default_opts, user_opts) or M.default_opts
    M.user_opts = user_opts
    -- Configure user-set defaults for the current buffer in case the plugin is lazy-loaded
    M.buffer_setup(user_opts)

    -- Configure highlight group
    if user_opts.highlight_motion.duration then
        vim.cmd([[
            highlight default link NvimSurroundHighlightTextObject Visual
        ]])
    end

    -- Create autocommand to setup all subsequent buffers
    local buffer_setup_group = vim.api.nvim_create_augroup("nvimSurroundBufferSetup", {})
    vim.api.nvim_create_autocmd("BufEnter", {
        callback = M.buffer_setup,
        group = buffer_setup_group,
    })
end

-- Setup the user options for the current buffer.
---@param buffer_opts table? The buffer-local options to be merged with the global user_opts.
M.buffer_setup = function(buffer_opts)
    -- Merge the given table into the buffer-local options table
    M.merge_opts(buffer_opts)

    -- Setup buffer-local keymaps for calling plugin behavior
    M.add_keymap({
        mode = "n",
        lhs = M.get_opts().keymaps.insert,
        rhs = require("nvim-surround").insert_surround,
        opts = { silent = true, expr = true, buffer = true },
    })
    M.add_keymap({
        mode = "n",
        lhs = M.get_opts().keymaps.insert_line,
        rhs = function()
            return "^" .. tostring(vim.v.count1) .. M.get_opts().keymaps.insert .. "g_"
        end,
        opts = { silent = true, expr = true, buffer = true, remap = true },
    })
    M.add_keymap({
        mode = "x",
        lhs = M.get_opts().keymaps.visual,
        rhs = "<Esc><Cmd>lua require'nvim-surround'.visual_surround()<CR>",
        opts = { silent = true, buffer = true },
    })
    M.add_keymap({
        mode = "n",
        lhs = M.get_opts().keymaps.delete,
        rhs = require("nvim-surround").delete_surround,
        opts = { silent = true, expr = true, buffer = true },
    })
    M.add_keymap({
        mode = "n",
        lhs = M.get_opts().keymaps.change,
        rhs = require("nvim-surround").change_surround,
        opts = { silent = true, expr = true, buffer = true },
    })
end

return M
