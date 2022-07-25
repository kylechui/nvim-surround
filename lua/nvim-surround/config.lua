local M = {}

-- Since `vim.fn.input()` does not handle keyboard interrupts, we use a protected call to check whether the user has
-- used `<C-c>` to cancel the input. This is not needed if `<Esc>` is used to cancel the input.
local get_input = function(prompt)
    local ok, result = pcall(vim.fn.input, { prompt = prompt })
    if not ok then
        return nil
    end
    return result
end

M.default_opts = {
    keymaps = {
        insert = "<C-g>s",
        insert_line = "<C-g>S",
        normal = "ys",
        normal_cur = "yss",
        normal_line = "yS",
        normal_cur_line = "ySS",
        visual = "S",
        visual_line = "gS",
        delete = "ds",
        change = "cs",
    },
    delimiters = {
        ["("] = {
            add = function()
                return { { "( " }, { " )" } }
            end,
        },
        [")"] = {
            add = function()
                return { { "(" }, { ")" } }
            end,
        },
        ["{"] = {
            add = function()
                return { { "{ " }, { " }" } }
            end,
        },
        ["}"] = {
            add = function()
                return { { "{" }, { "}" } }
            end,
        },
        ["<"] = {
            add = function()
                return { { "< " }, { " >" } }
            end,
        },
        [">"] = {
            add = function()
                return { { "<" }, { ">" } }
            end,
        },
        ["["] = {
            add = function()
                return { { "[ " }, { " ]" } }
            end,
        },
        ["]"] = {
            add = function()
                return { { "[" }, { "]" } }
            end,
        },
        ["'"] = {
            add = function()
                return { { "'" }, { "'" } }
            end,
        },
        ['"'] = {
            add = function()
                return { { '"' }, { '"' } }
            end,
        },
        ["`"] = {
            add = function()
                return { { "`" }, { "`" } }
            end,
        },
        ["i"] = {
            add = function()
                local left_delimiter = get_input("Enter the left delimiter: ")
                if left_delimiter then
                    local right_delimiter = get_input("Enter the right delimiter: ")
                    if right_delimiter then
                        return { left_delimiter, right_delimiter }
                    end
                end
            end,
        },
        ["f"] = {
            add = function()
                local result = get_input("Enter the function name: ")
                if result then
                    return { result .. "(", ")" }
                end
            end,
            find = "[%w_]+%b()",
            delete = "^([%w_]+%()().*(%))()$",
            change = {
                target = "^([%w_]+)().*()()$",
                replacement = function()
                    local result = get_input("Enter the function name: ")
                    if result then
                        return { { result }, { "" } }
                    end
                end,
            },
        },
    },
    aliases = {
        ["a"] = ">",
        ["b"] = ")",
        ["B"] = "}",
        ["r"] = "]",
        ["q"] = { '"', "'", "`" },
        ["s"] = { "}", "]", ")", ">", '"', "'", "`" },
    },
    highlight_motion = {
        duration = 0,
    },
    move_cursor = "begin",
    invalid_key_behavior = function()
        vim.api.nvim_err_writeln(
            "Error: Invalid character! Configure this message in " .. 'require("nvim-surround").setup()'
        )
    end,
}

-- Stores the global user-set options for the plugin.
M.user_opts = {}

-- Returns the buffer-local options for the plugin, or global options if buffer-local does not exist.
---@return options @The buffer-local options.
M.get_opts = function()
    return vim.b[0].nvim_surround_buffer_opts or M.user_opts
end

-- Updates the buffer-local options for the plugin based on the input.
---@param opts options? The options to be passed in.
M.merge_opts = function(opts)
    -- Grab the current buffer-local options, or the global user options otherwise
    local cur_opts = M.get_opts() or M.user_opts
    -- Overwrite the current options with buffer-local options, if they exist
    opts = opts and vim.tbl_deep_extend("force", cur_opts, opts) or cur_opts
    vim.b[0].nvim_surround_buffer_opts = opts
end

-- Check if a keymap should be added before setting it.
---@param args table The arguments to set the keymap.
M.set_keymap = function(args)
    -- If the keymap is disabled
    if not args.lhs then
        -- If the mapping is disabled globally, do nothing
        if not M.user_opts.keymaps[args.name] then
            return
        end
        -- Otherwise disable the global keymap
        args.lhs = M.user_opts.keymaps[args.name]
        args.rhs = "<NOP>"
    end
    vim.keymap.set(args.mode, args.lhs, args.rhs, args.opts)
end

-- Set up user-configured keymaps, globally or for the buffer.
---@param buffer boolean Whether the keymaps should be set for the buffer or not.
M.set_keymaps = function(buffer)
    M.set_keymap({
        name = "insert",
        mode = "i",
        lhs = M.get_opts().keymaps.insert,
        rhs = require("nvim-surround").insert_surround,
        opts = {
            buffer = buffer,
            desc = "Add a surrounding pair around the cursor (insert mode).",
            silent = true,
        },
    })
    M.set_keymap({
        name = "insert_line",
        mode = "i",
        lhs = M.get_opts().keymaps.insert_line,
        rhs = function()
            require("nvim-surround").insert_surround(true)
        end,
        opts = {
            buffer = buffer,
            desc = "Add a surrounding pair around the cursor, on new lines (insert mode).",
            silent = true,
        },
    })
    M.set_keymap({
        name = "normal",
        mode = "n",
        lhs = M.get_opts().keymaps.normal,
        rhs = require("nvim-surround").normal_surround,
        opts = {
            buffer = buffer,
            desc = "Add a surrounding pair around a motion (normal mode).",
            expr = true,
            silent = true,
        },
    })
    M.set_keymap({
        name = "normal_cur",
        mode = "n",
        lhs = M.get_opts().keymaps.normal_cur,
        rhs = function()
            return "^" .. tostring(vim.v.count1) .. M.get_opts().keymaps.normal .. "g_"
        end,
        opts = {
            buffer = buffer,
            desc = "Add a surrounding pair around the current line (normal mode).",
            expr = true,
            remap = true,
            silent = true,
        },
    })
    M.set_keymap({
        name = "normal_line",
        mode = "n",
        lhs = M.get_opts().keymaps.normal_line,
        rhs = function()
            return require("nvim-surround").normal_surround(nil, true)
        end,
        opts = {
            buffer = buffer,
            desc = "Add a surrounding pair around a motion, on new lines (normal mode).",
            expr = true,
            silent = true,
        },
    })
    M.set_keymap({
        name = "normal_cur_line",
        mode = "n",
        lhs = M.get_opts().keymaps.normal_cur_line,
        rhs = function()
            return "^" .. tostring(vim.v.count1) .. M.get_opts().keymaps.normal_line .. "g_"
        end,
        opts = {
            buffer = buffer,
            desc = "Add a surrounding pair around the current line, on new lines (normal mode).",
            expr = true,
            remap = true,
            silent = true,
        },
    })
    M.set_keymap({
        name = "visual",
        mode = "x",
        lhs = M.get_opts().keymaps.visual,
        rhs = "<Esc><Cmd>lua require'nvim-surround'.visual_surround()<CR>",
        opts = {
            buffer = buffer,
            desc = "Add a surrounding pair around a visual selection.",
            silent = true,
        },
    })
    M.set_keymap({
        name = "visual_line",
        mode = "x",
        lhs = M.get_opts().keymaps.visual_line,
        rhs = "<Esc><Cmd>lua require'nvim-surround'.visual_surround(true)<CR>",
        opts = {
            buffer = buffer,
            desc = "Add a surrounding pair around a visual selection, on new lines.",
            silent = true,
        },
    })
    M.set_keymap({
        name = "delete",
        mode = "n",
        lhs = M.get_opts().keymaps.delete,
        rhs = require("nvim-surround").delete_surround,
        opts = {
            buffer = buffer,
            desc = "Delete a surrounding pair.",
            expr = true,
            silent = true,
        },
    })
    M.set_keymap({
        name = "change",
        mode = "n",
        lhs = M.get_opts().keymaps.change,
        rhs = require("nvim-surround").change_surround,
        opts = {
            buffer = buffer,
            desc = "Change a surrounding pair.",
            expr = true,
            silent = true,
        },
    })
end

-- Setup the global user options for all files.
---@param user_opts options? The user-defined options to be merged with default_opts.
M.setup = function(user_opts)
    -- Overwrite default options with user-defined options, if they exist
    M.user_opts = user_opts and vim.tbl_deep_extend("force", M.default_opts, user_opts) or M.default_opts
    -- Configure global keymaps
    M.set_keymaps(false)
    -- Configure highlight group, if necessary
    if M.user_opts.highlight_motion.duration then
        vim.cmd([[
            highlight default link NvimSurroundHighlightTextObject Visual
        ]])
    end
end

-- Setup the user options for the current buffer.
---@param buffer_opts table? The buffer-local options to be merged with the global user_opts.
M.buffer_setup = function(buffer_opts)
    -- Merge the given table into the buffer-local options table
    M.merge_opts(buffer_opts)
    -- Configure buffer-local keymaps
    M.set_keymaps(true)
end

return M
