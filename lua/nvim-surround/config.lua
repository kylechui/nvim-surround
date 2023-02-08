local input = require("nvim-surround.input")
local functional = require("nvim-surround.functional")

local M = {}

---@type user_options
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
                local left_delimiter = input.get_input("Enter the left delimiter: ")
                local right_delimiter = left_delimiter and input.get_input("Enter the right delimiter: ")
                if right_delimiter then
                    return { { left_delimiter }, { right_delimiter } }
                end
            end,
            find = function() end,
            delete = function() end,
        },
        ["t"] = {
            add = function()
                local user_input = input.get_input("Enter the HTML tag: ")
                if user_input then
                    local element = user_input:match("^<?([^%s>]*)")
                    local attributes = user_input:match("^<?[^%s>]*%s+(.-)>?$")

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
                    local user_input = input.get_input("Enter the HTML tag: ")
                    if user_input then
                        local element = user_input:match("^<?([^%s>]*)")
                        local attributes = user_input:match("^<?[^%s>]*%s+(.-)>?$")

                        local open = attributes and element .. " " .. attributes or element
                        local close = element

                        return { { open }, { close } }
                    end
                end,
            },
        },
        ["T"] = {
            add = function()
                local user_input = input.get_input("Enter the HTML tag: ")
                if user_input then
                    local element = user_input:match("^<?([^%s>]*)")
                    local attributes = user_input:match("^<?[^%s>]*%s+(.-)>?$")

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
                    local user_input = input.get_input("Enter the HTML tag: ")
                    if user_input then
                        local element = user_input:match("^<?([^%s>]*)")
                        local attributes = user_input:match("^<?[^%s>]*%s+(.-)>?$")

                        local open = attributes and element .. " " .. attributes or element
                        local close = element

                        return { { open }, { close } }
                    end
                end,
            },
        },
        ["f"] = {
            add = function()
                local result = input.get_input("Enter the function name: ")
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
                return M.get_selection({ pattern = "[^=%s%(%){}]+%b()" })
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
                    local result = input.get_input("Enter the function name: ")
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
---@nodiscard
M.get_input = function(prompt)
    return input.get_input(prompt)
end

-- Gets a selection from the buffer based on some heuristic.
---@param args { char: string?, motion: string?, pattern: string?, node: string?, query: { capture: string, type: string }? }
---@return selection? @The retrieved selection.
---@nodiscard
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
    elseif args.textobject then ---@diagnostic disable-line: undefined-field
        vim.deprecate("The `textobject` key for `config.get_selection`", "`motion`", "v2.0.0", "nvim-surround")
    else
        vim.notify("Invalid key provided for `:h nvim-surround.config.get_selection()`.", vim.log.levels.ERROR)
    end
end

-- Gets a pair of selections from the buffer based on some heuristic.
---@param args { char: string, pattern: string?, exclude: function? }
---@nodiscard
M.get_selections = function(args)
    local selection = M.get_selection({ char = args.char })
    if not selection then
        return nil
    end
    if args.pattern then
        return require("nvim-surround.patterns").get_selections(selection, args.pattern)
    elseif args.exclude then
        local outer_selection = M.get_opts().surrounds[args.char].find()
        if not outer_selection then
            return nil
        end
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
---@nodiscard
M.get_opts = function()
    return vim.b[0].nvim_surround_buffer_opts or M.user_opts or {}
end

-- Returns the value that the input is aliased to, or the character if no alias exists.
---@param char string? The input character.
---@return string? @The aliased character if it exists, or the original if none exists.
---@nodiscard
M.get_alias = function(char)
    local aliases = M.get_opts().aliases
    if type(aliases[char]) == "string" then
        return aliases[char]
    end
    return char
end

-- Gets a delimiter pair for a user-inputted character.
---@param char string? The user-given character.
---@param line_mode boolean Whether or not the delimiters should be put on new lines.
---@return delimiter_pair? @A pair of delimiters for the given input, or nil if not applicable.
---@nodiscard
M.get_delimiters = function(char, line_mode)
    if not char then
        return nil
    end

    char = M.get_alias(char)
    -- Get the delimiters, using invalid_key_behavior if the add function is undefined for the character
    local delimiters = (function()
        if M.get_add(char) then
            return M.get_add(char)(char)
        else
            return M.get_opts().surrounds.invalid_key_behavior.add(char)
        end
    end)()
    -- Add new lines if the addition is done line-wise
    if line_mode then
        table.insert(delimiters[2], 1, "")
        table.insert(delimiters[1], "")
    end

    return delimiters
end

-- Returns the add key for the surround associated with a given character, if one exists.
---@param char string? The input character.
---@return add_func @The function to get the delimiters to be added.
---@nodiscard
M.get_add = function(char)
    char = M.get_alias(char)
    if M.get_opts().surrounds[char] then
        return M.get_opts().surrounds[char].add
    end
    return M.get_opts().surrounds.invalid_key_behavior.add
end

-- Returns the delete key for the surround associated with a given character, if one exists.
---@param char string? The input character.
---@return delete_func @The function to get the selections to be deleted.
---@nodiscard
M.get_delete = function(char)
    char = M.get_alias(char)
    if M.get_opts().surrounds[char] then
        return M.get_opts().surrounds[char].delete
    end
    return M.get_opts().surrounds.invalid_key_behavior.delete
end

-- Returns the change key for the surround associated with a given character, if one exists.
---@param char string? The input character.
---@return { target: delete_func, replacement: add_func? }? @A table holding the target/replacment functions.
---@nodiscard
M.get_change = function(char)
    char = M.get_alias(char)
    if M.get_opts().surrounds[char] then
        if M.get_opts().surrounds[char].change then
            return M.get_opts().surrounds[char].change
        else
            return {
                target = M.get_opts().surrounds[char].delete,
            }
        end
    end
    return M.get_opts().surrounds.invalid_key_behavior.change
end

-- Returns a set of opts, with missing keys filled in by the invalid_key_behavior key.
-- TODO: Change this function name!
---@param opts options? The provided options.
---@return options? @The modified options.
M.fill_missing_surrounds = function(opts)
    -- If there are no surrounds, then no modification is necessary
    if not (opts and opts.surrounds) then
        return opts
    end

    for char, surround in pairs(opts.surrounds) do
        local invalid = M.get_opts().surrounds.invalid_key_behavior
        if invalid and surround then
            -- For each surround, if a key is missing, fill it in using the correspnding key from `invalid_key_behavior`
            local add, find, delete = surround.add, surround.find, surround.delete
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
        end
    end
    return opts
end

-- Translates the user-provided surround.add into the internal form.
---@param user_add string[]|string[][]|add_func? The user-provided add key.
---@return add_func? @The translated add key.
M.translate_add = function(user_add)
    -- If the add key does not exist or is already in internal form, return
    if type(user_add) == "nil" or type(user_add) == "function" then
        return user_add
    end
    return function()
        return {
            functional.to_list(user_add[1]),
            functional.to_list(user_add[2]),
        }
    end
end

-- Translates the user-provided surround.find into the internal form.
---@param user_find string|find_func? The user-provided find key.
---@return find_func? @The translated find key.
M.translate_find = function(user_find)
    if type(user_find) == "function" then
        return user_find
    end
    -- Treat the string as a Lua pattern, and find the selection
    return function()
        return M.get_selection({ pattern = user_find })
    end
end

-- Translates the user-provided surround.delete into the internal form.
---@param char string The character used to activate the surround.
---@param user_delete string|delete_func? The user-provided delete key.
---@return delete_func? @The translated delete key.
M.translate_delete = function(char, user_delete)
    if type(user_delete) == "function" then
        return user_delete
    end
    -- Treat the string as a Lua pattern, and find the selection
    return function()
        return M.get_selections({ char = char, pattern = user_delete })
    end
end

-- Translates the user-provided surround.change into the internal form.
---@param char string The character used to activate the surround.
---@param user_change { target: string|delete_func, replacement: string[]|string[][]|add_func? }? The user-provided change key.
---@return { target: delete_func, replacement: add_func? }? @The translated change key.
M.translate_change = function(char, user_change)
    if not user_change then
        return nil
    end
    return {
        target = M.translate_delete(char, user_change.target),
        replacement = M.translate_add(user_change.replacement),
    }
end

-- Translates the user-provided surround into the internal form.
---@param char string The character used to activate the surround.
---@param user_surround user_surround? The user-provided surround.
---@return surround? @The translated surround.
M.translate_surround = function(char, user_surround)
    if not user_surround then
        return nil
    end
    local surround = {}
    surround.add = M.translate_add(user_surround.add)
    surround.find = M.translate_find(user_surround.find)
    surround.delete = M.translate_delete(char, user_surround.delete)
    surround.change = M.translate_change(char, user_surround.change)

    return surround
end

-- Translates the user-provided configuration into the internal form.
---@param user_opts user_options The user-provided options.
---@return options @The translated options.
M.translate_opts = function(user_opts)
    if user_opts.highlight_motion then ---@diagnostic disable-line: undefined-field
        vim.deprecate("`config.highlight_motion`", "`config.highlight`", "v2.0.0", "nvim-surround")
    end
    if user_opts.delimiters then ---@diagnostic disable-line: undefined-field
        vim.deprecate("`config.delimiters`", "`config.surrounds`", "v2.0.0", "nvim-surround")
    end

    local opts = {}
    for key, value in pairs(user_opts) do
        if key == "surrounds" then
        elseif key == "indent_lines" then
            opts[key] = value or function() end
        else
            opts[key] = value
        end
    end
    if not user_opts.surrounds then
        return opts
    end
    opts.surrounds = {}
    for char, user_surround in pairs(user_opts.surrounds) do
        if char == "pairs" or char == "separators" then
            vim.deprecate(
                "`config.surrounds.pairs` and `config.surrounds.separators`",
                "`config.surrounds`",
                "v2.0.0",
                "nvim-surround"
            )
        end
        -- Check if the delimiter has not been disabled
        if not user_surround then
            opts.surrounds[char] = false
        else
            opts.surrounds[char] = M.translate_surround(char, user_surround)
        end
    end
    return opts
end

-- Updates the buffer-local options for the plugin based on the input.
---@param base_opts options The base options that will be used for configuration.
---@param new_opts user_options? The new options to potentially override the base options.
---@return options The merged options.
M.merge_opts = function(base_opts, new_opts)
    new_opts = new_opts or {}
    local opts = vim.tbl_deep_extend("force", base_opts, M.translate_opts(new_opts))
    return opts
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
        mode = "i",
        lhs = "<Plug>(nvim-surround-insert)",
        rhs = require("nvim-surround").insert_surround,
        opts = {
            buffer = buffer,
            desc = "Add a surrounding pair around the cursor (insert mode)",
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
            desc = "Add a surrounding pair around the cursor, on new lines (insert mode)",
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
            desc = "Add a surrounding pair around a motion (normal mode)",
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
            desc = "Add a surrounding pair around the current line (normal mode)",
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
            desc = "Add a surrounding pair around a motion, on new lines (normal mode)",
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
            desc = "Add a surrounding pair around the current line, on new lines (normal mode)",
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
            desc = "Add a surrounding pair around a visual selection",
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
            desc = "Add a surrounding pair around a visual selection, on new lines",
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
            desc = "Delete a surrounding pair",
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
            desc = "Change a surrounding pair",
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
        opts = {
            desc = "Add a surrounding pair around the cursor (insert mode)",
        },
    })
    M.set_keymap({
        name = "insert_line",
        mode = "i",
        lhs = M.get_opts().keymaps.insert_line,
        rhs = "<Plug>(nvim-surround-insert-line)",
        opts = {
            desc = "Add a surrounding pair around the cursor, on new lines (insert mode)",
        },
    })
    M.set_keymap({
        name = "normal",
        mode = "n",
        lhs = M.get_opts().keymaps.normal,
        rhs = "<Plug>(nvim-surround-normal)",
        opts = {
            desc = "Add a surrounding pair around a motion (normal mode)",
        },
    })
    M.set_keymap({
        name = "normal_cur",
        mode = "n",
        lhs = M.get_opts().keymaps.normal_cur,
        rhs = "<Plug>(nvim-surround-normal-cur)",
        opts = {
            desc = "Add a surrounding pair around the current line (normal mode)",
        },
    })
    M.set_keymap({
        name = "normal_line",
        mode = "n",
        lhs = M.get_opts().keymaps.normal_line,
        rhs = "<Plug>(nvim-surround-normal-line)",
        opts = {
            desc = "Add a surrounding pair around a motion, on new lines (normal mode)",
        },
    })
    M.set_keymap({
        name = "normal_cur_line",
        mode = "n",
        lhs = M.get_opts().keymaps.normal_cur_line,
        rhs = "<Plug>(nvim-surround-normal-cur-line)",
        opts = {
            desc = "Add a surrounding pair around the current line, on new lines (normal mode)",
        },
    })
    M.set_keymap({
        name = "visual",
        mode = "x",
        lhs = M.get_opts().keymaps.visual,
        rhs = "<Plug>(nvim-surround-visual)",
        opts = {
            desc = "Add a surrounding pair around a visual selection",
        },
    })
    M.set_keymap({
        name = "visual_line",
        mode = "x",
        lhs = M.get_opts().keymaps.visual_line,
        rhs = "<Plug>(nvim-surround-visual-line)",
        opts = {
            desc = "Add a surrounding pair around a visual selection, on new lines",
        },
    })
    M.set_keymap({
        name = "delete",
        mode = "n",
        lhs = M.get_opts().keymaps.delete,
        rhs = "<Plug>(nvim-surround-delete)",
        opts = {
            desc = "Delete a surrounding pair",
        },
    })
    M.set_keymap({
        name = "change",
        mode = "n",
        lhs = M.get_opts().keymaps.change,
        rhs = "<Plug>(nvim-surround-change)",
        opts = {
            desc = "Change a surrounding pair",
        },
    })
end

-- Setup the global user options for all files.
---@param user_opts user_options? The user-defined options to be merged with default_opts.
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
        vim.cmd.highlight("default link NvimSurroundHighlight Visual")
    end
end

-- Setup the user options for the current buffer.
---@param buffer_opts user_options? The buffer-local options to be merged with the global user_opts.
M.buffer_setup = function(buffer_opts)
    -- Merge the given table into the existing buffer-local options, or global options otherwise
    vim.b[0].nvim_surround_buffer_opts = M.merge_opts(M.get_opts(), buffer_opts)
    -- Filling in missing keys must occur after, since the user might have defined their own `invalid_key_behavior`
    vim.b[0].nvim_surround_buffer_opts = M.fill_missing_surrounds(vim.b[0].nvim_surround_buffer_opts)
    -- Configure buffer-local keymaps
    M.set_keymaps(true)
end

return M
