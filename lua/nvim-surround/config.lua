local M = {}

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
    surrounds = {
        ["("] = {
            add = { "( ", " )" },
            find = function()
                return M.get_selection({ motion = "a(" })
            end,
            delete = "^(. ?)().-( ?.)()$",
        },
        [")"] = {
            add = { "(", ")" },
            find = function()
                return M.get_selection({ motion = "a)" })
            end,
            delete = "^(.)().-(.)()$",
        },
        ["{"] = {
            add = { "{ ", " }" },
            find = function()
                return M.get_selection({ motion = "a{" })
            end,
            delete = "^(. ?)().-( ?.)()$",
        },
        ["}"] = {
            add = { "{", "}" },
            find = function()
                return M.get_selection({ motion = "a}" })
            end,
            delete = "^(.)().-(.)()$",
        },
        ["<"] = {
            add = { "< ", " >" },
            find = function()
                return M.get_selection({ motion = "a<" })
            end,
            delete = "^(. ?)().-( ?.)()$",
        },
        [">"] = {
            add = { "<", ">" },
            find = function()
                return M.get_selection({ motion = "a>" })
            end,
            delete = "^(.)().-(.)()$",
        },
        ["["] = {
            add = { "[ ", " ]" },
            find = function()
                return M.get_selection({ motion = "a[" })
            end,
            delete = "^(. ?)().-( ?.)()$",
        },
        ["]"] = {
            add = { "[", "]" },
            find = function()
                return M.get_selection({ motion = "a]" })
            end,
            delete = "^(.)().-(.)()$",
        },
        ["'"] = {
            add = { "'", "'" },
            find = function()
                return M.get_selection({ motion = "a'" })
            end,
            delete = "^(.)().-(.)()$",
        },
        ['"'] = {
            add = { '"', '"' },
            find = function()
                return M.get_selection({ motion = 'a"' })
            end,
            delete = "^(.)().-(.)()$",
        },
        ["`"] = {
            add = { "`", "`" },
            find = function()
                return M.get_selection({ motion = "a`" })
            end,
            delete = "^(.)().-(.)()$",
        },
        ["i"] = { -- TODO: Add find/delete/change functions
            add = function()
                local left_delimiter = M.get_input("Enter the left delimiter: ")
                local right_delimiter = left_delimiter and M.get_input("Enter the right delimiter: ")
                if right_delimiter then
                    return { { left_delimiter }, { right_delimiter } }
                end
            end,
            find = function() end,
            delete = function() end,
        },
        ["t"] = {
            add = function()
                local input = M.get_input("Enter the HTML tag: ")
                if input then
                    local element = input:match("^<?([^%s>]*)")
                    local attributes = input:match("^<?[^%s>]*%s+(.-)>?$")

                    local open = attributes and element .. " " .. attributes or element
                    local close = element

                    return { { "<" .. open .. ">" }, { "</" .. close .. ">" } }
                end
            end,
            find = function()
                return M.get_selection({ motion = "at" })
            end,
            delete = "^(%b<>)().-(%b<>)()$",
            change = {
                target = "^<([^%s<>]*)().-([^/]*)()>$",
                replacement = function()
                    local input = M.get_input("Enter the HTML tag: ")
                    if input then
                        local element = input:match("^<?([^%s>]*)")
                        local attributes = input:match("^<?[^%s>]*%s+(.-)>?$")

                        local open = attributes and element .. " " .. attributes or element
                        local close = element

                        return { { open }, { close } }
                    end
                end,
            },
        },
        ["T"] = {
            add = function()
                local input = M.get_input("Enter the HTML tag: ")
                if input then
                    local element = input:match("^<?([^%s>]*)")
                    local attributes = input:match("^<?[^%s>]*%s+(.-)>?$")

                    local open = attributes and element .. " " .. attributes or element
                    local close = element

                    return { { "<" .. open .. ">" }, { "</" .. close .. ">" } }
                end
            end,
            find = function()
                return M.get_selection({ motion = "at" })
            end,
            delete = "^(%b<>)().-(%b<>)()$",
            change = {
                target = "^<([^>]*)().-([^/]*)()>$",
                replacement = function()
                    local input = M.get_input("Enter the HTML tag: ")
                    if input then
                        local element = input:match("^<?([^%s>]*)")
                        local attributes = input:match("^<?[^%s>]*%s+(.-)>?$")

                        local open = attributes and element .. " " .. attributes or element
                        local close = element

                        return { { open }, { close } }
                    end
                end,
            },
        },
        ["f"] = {
            add = function()
                local result = M.get_input("Enter the function name: ")
                if result then
                    return { { result .. "(" }, { ")" } }
                end
            end,
            find = function()
                local selection
                if vim.g.loaded_nvim_treesitter then
                    selection = M.get_selection({
                        query = {
                            capture = "@call.outer",
                            type = "textobjects",
                        },
                    })
                end
                if selection then
                    return selection
                end
                return M.get_selection({ pattern = "[^=%s%(%)]+%b()" })
            end,
            delete = "^(.-%()().-(%))()$",
            --[[ function()
                local selections
                if vim.g.loaded_nvim_treesitter then
                    selections = M.get_selections({
                        char = "f",
                        exclude = function()
                            return M.get_selection({
                                query = {
                                    capture = "@call.inner",
                                    type = "textobjects",
                                },
                            })
                        end,
                    })
                end
                if selections then
                    return selections
                end
                return M.get_selections({ char = "f", pattern = "^([^=%s%(%)]+%()().-(%))()$" })
            end, ]]
            change = {
                target = "^.-([%w_]+)()%(.-%)()()$",
                replacement = function()
                    local result = M.get_input("Enter the function name: ")
                    if result then
                        return { { result }, { "" } }
                    end
                end,
            },
        },
        invalid_key_behavior = {
            add = function(char)
                return { { char }, { char } }
            end,
            find = function(char)
                return M.get_selection({
                    pattern = vim.pesc(char) .. ".-" .. vim.pesc(char),
                })
            end,
            delete = function(char)
                return M.get_selections({
                    char = char,
                    pattern = "^(.)().-(.)()$",
                })
            end,
            change = {
                target = function(char)
                    return M.get_selections({
                        char = char,
                        pattern = "^(.)().-(.)()$",
                    })
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
    highlight = {
        duration = 0,
    },
    move_cursor = "begin",
    indent_lines = function(start, stop)
        local b = vim.bo
        -- Only re-indent the selection if a formatter is set up already
        if start <= stop and (b.equalprg ~= "" or b.indentexpr ~= "" or b.cindent or b.smartindent or b.lisp) then
            vim.cmd(string.format("silent normal! %dG=%dG", start, stop))
        end
    end,
}

--[====================================================================================================================[
                                             Configuration Helper Functions
--]====================================================================================================================]

-- Gets input from the user.
---@param prompt string The input prompt.
---@return string? @The user input.
M.get_input = function(prompt)
    -- Since `vim.fn.input()` does not handle keyboard interrupts, we use a protected call to detect <C-c>
    local ok, result = pcall(vim.fn.input, { prompt = prompt, cancelreturn = vim.NIL })
    if ok and result ~= vim.NIL then
        return result
    end
end

-- Gets a selection from the buffer based on some heuristic.
---@param args { char: string?, motion: string?, pattern: string?, node: string?, query: { capture: string, type: string }? }
---@return selection? The retrieved selection.
M.get_selection = function(args)
    if args.char then
        if M.get_opts().surrounds[args.char] then
            return M.get_opts().surrounds[args.char].find(args.char)
        end
        return M.get_opts().surrounds.invalid_key_behavior.find(args.char)
    elseif args.motion then
        return require("nvim-surround.motions").get_selection(args.motion)
    elseif args.node then
        return require("nvim-surround.treesitter").get_selection(args.node)
    elseif args.pattern then
        return require("nvim-surround.patterns").get_selection(args.pattern)
    elseif args.query then
        return require("nvim-surround.queries").get_selection(args.query.capture, args.query.type)
        ---[=[ DEPRECATION WARNING
        ---@diagnostic disable-next-line: undefined-field
    elseif args.textobject then
        local textobject_warning = {
            "The `textobject` key has been deprecated in favor of the `motion` key.",
            "Please pre-pend text-object keys with 'a'. See :h nvim-surround.config.get_selection() for details",
        }
        vim.notify_once(table.concat(textobject_warning, "\n"), vim.log.levels.ERROR)
        --]=]
    else
        vim.notify("Invalid key provided for `:h nvim-surround.config.get_selection()`.", vim.log.levels.ERROR)
    end
end

-- Gets a pair of selections from the buffer based on some heuristic.
---@param args { char: string, pattern: string?, exclude: function? }
M.get_selections = function(args)
    local selection = M.get_selection({ char = args.char })
    if not selection then
        return nil
    end
    if args.pattern then
        return require("nvim-surround.patterns").get_selections(selection, args.pattern)
    elseif args.exclude then
        local outer_selection = M.get_opts().surrounds[args.char].find()
        vim.fn.cursor(outer_selection.first_pos)
        local inner_selection = args.exclude()
        if not inner_selection then
            return nil
        end
        -- Properly exclude the inner selection from the outer selection
        local selections = {
            left = {
                first_pos = outer_selection.first_pos,
                last_pos = { inner_selection.first_pos[1], inner_selection.first_pos[2] - 1 },
            },
            right = {
                first_pos = { inner_selection.last_pos[1], inner_selection.last_pos[2] + 1 },
                last_pos = outer_selection.last_pos,
            },
        }
        return selections
    else
        vim.notify("Invalid key provided for `:h nvim-surround.config.get_selections()`.", vim.log.levels.ERROR)
    end
end

--[====================================================================================================================[
                                                End of Helper Functions
--]====================================================================================================================]

-- Stores the global user-set options for the plugin.
M.user_opts = nil

-- Returns the buffer-local options for the plugin, or global options if buffer-local does not exist.
---@return options @The buffer-local options.
M.get_opts = function()
    return vim.b[0].nvim_surround_buffer_opts or M.user_opts or {}
end

-- Returns the add key for the surround associated with a given character, if one exists.
---@param char string? The input character.
---@return string|string[]|fun(string?): string[][]? @The function to get the delimiters to be added.
M.get_add = function(char)
    char = require("nvim-surround.utils").get_alias(char)
    local key = M.get_opts().surrounds[char] or M.get_opts().surrounds.invalid_key_behavior
    return key.add
end

-- Returns the delete key for the surround associated with a given character, if one exists.
---@param char string? The input character.
---@return string|fun(string?): selections? @The function to get the selections to be deleted.
M.get_delete = function(char)
    char = require("nvim-surround.utils").get_alias(char)
    local key = M.get_opts().surrounds[char] or M.get_opts().surrounds.invalid_key_behavior
    return key.delete
end

-- Returns the change key for the surround associated with a given character, if one exists.
---@param char string? The input character.
---@return { target: function, replacement: function? }? @A table holding the target/replacment functions.
M.get_change = function(char)
    char = require("nvim-surround.utils").get_alias(char)
    local key = M.get_opts().surrounds[char] or M.get_opts().surrounds.invalid_key_behavior
    return key.change
end

-- Returns a set of opts, with missing keys filled in by the invalid_key_behavior key.
---@param opts options? The provided options.
---@return options? @The modified options.
M.fill_missing_surrounds = function(opts)
    -- If there are no surrounds, then no modification is necessary
    if not (opts and opts.surrounds) then
        return opts
    end

    for char, val in pairs(opts.surrounds) do
        if val then
            -- For each surround, if a key is missing, fill it in using the correspnding key from `invalid_key_behavior`
            local add, find, delete, change = val.add, val.find, val.delete, val.change
            local invalid = M.get_opts().surrounds.invalid_key_behavior
            if not add then
                opts.surrounds[char].add = function()
                    return invalid.add(char)
                end
            end
            if not find then
                opts.surrounds[char].find = function()
                    return invalid.find(char)
                end
            end
            if not delete then
                opts.surrounds[char].delete = function()
                    return invalid.delete(char)
                end
            end
            if not (change and change.target) then
                opts.surrounds[char].change = {
                    target = function()
                        return invalid.change.target(char)
                    end,
                }
            end
        end
    end
    return opts
end

-- Translates the user-provided configuration into the internal form.
---@param opts options? The user-provided options.
---@return options? @The translated options.
M.translate_opts = function(opts)
    ---[=[ DEPRECATION WARNINGS
    ---@diagnostic disable-next-line: undefined-field
    if opts and opts.highlight_motion then
        local highlight_warning = {
            "The `highlight_motion` table has been renamed to `highlight`.",
            "See :h nvim-surround.config.highlight for details",
        }
        vim.notify_once(table.concat(highlight_warning, "\n"), vim.log.levels.ERROR)
    end
    ---@diagnostic disable-next-line: undefined-field
    if opts and opts.delimiters then
        local delimiter_warning = {
            "The `delimiters` table has been renamed to `surrounds`.",
            "See :h nvim-surround.config.surrounds for details",
        }
        vim.notify_once(table.concat(delimiter_warning, "\n"), vim.log.levels.ERROR)
    end
    --]=]

    if not (opts and opts.surrounds) then
        return opts
    end
    for char, val in pairs(opts.surrounds) do
        ---[=[ DEPRECATION WARNINGS
        if char == "pairs" or char == "separators" then
            local delimiter_warning = {
                "The `pairs` and `separators` tables have been deprecated; configuration for surrounds",
                "goes in `surrounds`. See :h nvim-surround.config.surrounds for details.",
            }
            vim.notify_once(table.concat(delimiter_warning, "\n"), vim.log.levels.ERROR)
        end
        if vim.tbl_islist(val) then
            local add_warning = {
                "The old configuration for defining surrounds has been deprecated; see",
                ":h nvim-surround.config.surrounds for details.",
            }
            vim.notify_once(table.concat(add_warning, "\n"), vim.log.levels.ERROR)
        end
        --]=]

        -- Validate that the delimiter has not been disabled
        if val then
            local add, find, delete, change = val.add, val.find, val.delete, val.change
            -- Handle `add` key translation
            if add and vim.tbl_islist(add) then -- Check if the add key is a table instead of a function
                -- Wrap the left/right delimiters in a table if they are strings (single line)
                if type(add[1]) == "string" then
                    add[1] = { add[1] }
                end
                if type(add[2]) == "string" then
                    add[2] = { add[2] }
                end
                -- Wrap the delimiter pair in a function
                opts.surrounds[char].add = function()
                    return add
                end
            end

            -- Handle `find` key translation
            if find and type(find) == "string" then
                -- Treat the string as a Lua pattern, and find the selection
                opts.surrounds[char].find = function()
                    return M.get_selection({ pattern = find })
                end
            end

            -- Handle `delete` key translation
            if delete and type(delete) == "string" then
                -- Wrap delete in a function
                opts.surrounds[char].delete = function()
                    return M.get_selections({ char = char, pattern = delete })
                end
            end

            -- Handle `change` key translation
            if change then
                local target, replacement = change.target, change.replacement
                -- Wrap target in a function
                if target and type(target) == "string" then
                    opts.surrounds[char].change.target = function()
                        return M.get_selections({ char = char, pattern = target })
                    end
                end
                -- Check if the replacement key is a table instead of a function
                if replacement and vim.tbl_islist(replacement) then
                    -- Wrap the left/right delimiters in a table if they are strings (single line)
                    if type(replacement[1]) == "string" then
                        replacement[1] = { replacement[1] }
                    end
                    if type(replacement[2]) == "string" then
                        replacement[2] = { replacement[2] }
                    end
                    -- Wrap the delimiter pair in a function
                    opts.surrounds[char].change.replacement = function()
                        return replacement
                    end
                end
            else
                if M.get_opts().surrounds and M.get_opts().surrounds[char] then
                    opts.surrounds[char].change = M.get_opts().surrounds[char].change
                else
                    opts.surrounds[char].change = {
                        target = opts.surrounds[char].delete,
                    }
                end
            end
        end
    end
    return opts
end

-- Updates the buffer-local options for the plugin based on the input.
---@param base_opts options The base options that will be used for configuration.
---@param new_opts options? The new options to potentially override the base options.
---@return options The merged options.
M.merge_opts = function(base_opts, new_opts)
    return new_opts and vim.tbl_deep_extend("force", base_opts, M.translate_opts(new_opts)) or base_opts
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
    -- Set up <Plug> keymaps
    M.set_keymap({
        mode = "n",
        lhs = "<Plug>(nvim-surround-insert)",
        rhs = require("nvim-surround").insert_surround,
        opts = {
            buffer = buffer,
            desc = "Add a surrounding pair around the cursor (insert mode).",
            remap = true,
            silent = true,
        },
    })
    M.set_keymap({
        mode = "i",
        lhs = "<Plug>(nvim-surround-insert-line)",
        rhs = function()
            require("nvim-surround").insert_surround(true)
        end,
        opts = {
            buffer = buffer,
            desc = "Add a surrounding pair around the cursor, on new lines (insert mode).",
            remap = true,
            silent = true,
        },
    })
    M.set_keymap({
        mode = "n",
        lhs = "<Plug>(nvim-surround-normal)",
        rhs = require("nvim-surround").normal_surround,
        opts = {
            buffer = buffer,
            desc = "Add a surrounding pair around a motion (normal mode).",
            expr = true,
            remap = true,
            silent = true,
        },
    })
    M.set_keymap({
        mode = "n",
        lhs = "<Plug>(nvim-surround-normal-cur)",
        rhs = function()
            return "^" .. tostring(vim.v.count1) .. "<Plug>(nvim-surround-normal)g_"
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
        mode = "n",
        lhs = "<Plug>(nvim-surround-normal-line)",
        rhs = function()
            return require("nvim-surround").normal_surround(nil, true)
        end,
        opts = {
            buffer = buffer,
            desc = "Add a surrounding pair around a motion, on new lines (normal mode).",
            expr = true,
            remap = true,
            silent = true,
        },
    })
    M.set_keymap({
        mode = "n",
        lhs = "<Plug>(nvim-surround-normal-cur-line)",
        rhs = function()
            return "^" .. tostring(vim.v.count1) .. "<Plug>(nvim-surround-normal-line)g_"
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
        mode = "x",
        lhs = "<Plug>(nvim-surround-visual)",
        rhs = "<Esc><Cmd>lua require'nvim-surround'.visual_surround()<CR>",
        opts = {
            buffer = buffer,
            desc = "Add a surrounding pair around a visual selection.",
            remap = true,
            silent = true,
        },
    })
    M.set_keymap({
        mode = "x",
        lhs = "<Plug>(nvim-surround-visual-line)",
        rhs = "<Esc><Cmd>lua require'nvim-surround'.visual_surround(true)<CR>",
        opts = {
            buffer = buffer,
            desc = "Add a surrounding pair around a visual selection, on new lines.",
            remap = true,
            silent = true,
        },
    })
    M.set_keymap({
        mode = "n",
        lhs = "<Plug>(nvim-surround-delete)",
        rhs = require("nvim-surround").delete_surround,
        opts = {
            buffer = buffer,
            desc = "Delete a surrounding pair.",
            expr = true,
            remap = true,
            silent = true,
        },
    })
    M.set_keymap({
        mode = "n",
        lhs = "<Plug>(nvim-surround-change)",
        rhs = require("nvim-surround").change_surround,
        opts = {
            buffer = buffer,
            desc = "Change a surrounding pair.",
            expr = true,
            remap = true,
            silent = true,
        },
    })

    -- Set up user-defined keymaps
    M.set_keymap({
        name = "insert",
        mode = "i",
        lhs = M.get_opts().keymaps.insert,
        rhs = "<Plug>(nvim-surround-insert)",
    })
    M.set_keymap({
        name = "insert_line",
        mode = "i",
        lhs = M.get_opts().keymaps.insert_line,
        rhs = "<Plug>(nvim-surround-insert-line)",
    })
    M.set_keymap({
        name = "normal",
        mode = "n",
        lhs = M.get_opts().keymaps.normal,
        rhs = "<Plug>(nvim-surround-normal)",
    })
    M.set_keymap({
        name = "normal_cur",
        mode = "n",
        lhs = M.get_opts().keymaps.normal_cur,
        rhs = "<Plug>(nvim-surround-normal-cur)",
    })
    M.set_keymap({
        name = "normal_line",
        mode = "n",
        lhs = M.get_opts().keymaps.normal_line,
        rhs = "<Plug>(nvim-surround-normal-line)",
    })
    M.set_keymap({
        name = "normal_cur_line",
        mode = "n",
        lhs = M.get_opts().keymaps.normal_cur_line,
        rhs = "<Plug>(nvim-surround-normal-cur-line)",
    })
    M.set_keymap({
        name = "visual",
        mode = "x",
        lhs = M.get_opts().keymaps.visual,
        rhs = "<Plug>(nvim-surround-visual)",
    })
    M.set_keymap({
        name = "visual_line",
        mode = "x",
        lhs = M.get_opts().keymaps.visual_line,
        rhs = "<Plug>(nvim-surround-visual-line)",
    })
    M.set_keymap({
        name = "delete",
        mode = "n",
        lhs = M.get_opts().keymaps.delete,
        rhs = "<Plug>(nvim-surround-delete)",
    })
    M.set_keymap({
        name = "change",
        mode = "n",
        lhs = M.get_opts().keymaps.change,
        rhs = "<Plug>(nvim-surround-change)",
    })
end

-- Setup the global user options for all files.
---@param user_opts options? The user-defined options to be merged with default_opts.
M.setup = function(user_opts)
    -- Overwrite default options with user-defined options, if they exist
    ---@diagnostic disable-next-line
    M.user_opts = M.merge_opts(M.translate_opts(M.default_opts), user_opts)
    -- Filling in missing keys must occur after, since the user might have defined their own `invalid_key_behavior`
    M.user_opts = M.fill_missing_surrounds(M.user_opts)
    -- Configure global keymaps
    M.set_keymaps(false)
    -- Configure highlight group, if necessary
    if M.user_opts.highlight.duration then
        vim.cmd([[
            highlight default link NvimSurroundHighlight Visual
        ]])
    end
end

-- Setup the user options for the current buffer.
---@param buffer_opts table? The buffer-local options to be merged with the global user_opts.
M.buffer_setup = function(buffer_opts)
    -- Merge the given table into the existing buffer-local options, or global options otherwise
    vim.b[0].nvim_surround_buffer_opts = M.merge_opts(M.get_opts(), buffer_opts)
    -- Filling in missing keys must occur after, since the user might have defined their own `invalid_key_behavior`
    vim.b[0].nvim_surround_buffer_opts = M.fill_missing_surrounds(vim.b[0].nvim_surround_buffer_opts)
    -- Configure buffer-local keymaps
    M.set_keymaps(true)
end

return M
