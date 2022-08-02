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
    delimiters = {
        ["("] = {
            add = { "( ", " )" },
            find = function()
                return M.get_selection({ textobject = "(" })
            end,
            delete = function()
                return M.get_selections({ char = "(", pattern = "^(. ?)().-( ?.)()$" })
            end,
            change = {
                target = function()
                    return M.get_selections({ char = "(", pattern = "^(. ?)().-( ?.)()$" })
                end,
            },
        },
        [")"] = {
            add = { "(", ")" },
            find = function()
                return M.get_selection({ textobject = ")" })
            end,
            delete = function()
                return M.get_selections({ char = ")", pattern = "^(.)().-(.)()$" })
            end,
            change = {
                target = function()
                    return M.get_selections({ char = ")", pattern = "^(.)().-(.)()$" })
                end,
            },
        },
        ["{"] = {
            add = { "{ ", " }" },
            find = function()
                return M.get_selection({ textobject = "{" })
            end,
            delete = function()
                return M.get_selections({ char = "{", pattern = "^(. ?)().-( ?.)()$" })
            end,
            change = {
                target = function()
                    return M.get_selections({ char = "{", pattern = "^(. ?)().-( ?.)()$" })
                end,
            },
        },
        ["}"] = {
            add = { "{", "}" },
            find = function()
                return M.get_selection({ textobject = "}" })
            end,
            delete = function()
                return M.get_selections({ char = "}", pattern = "^(.)().-(.)()$" })
            end,
            change = {
                target = function()
                    return M.get_selections({ char = "}", pattern = "^(.)().-(.)()$" })
                end,
            },
        },
        ["<"] = {
            add = { "< ", " >" },
            find = function()
                return M.get_selection({ textobject = "<" })
            end,
            delete = function()
                return M.get_selections({ char = "<", pattern = "^(. ?)().-( ?.)()$" })
            end,
            change = {
                target = function()
                    return M.get_selections({ char = "<", pattern = "^(. ?)().-( ?.)()$" })
                end,
            },
        },
        [">"] = {
            add = { "<", ">" },
            find = function()
                return M.get_selection({ textobject = ">" })
            end,
            delete = function()
                return M.get_selections({ char = ">", pattern = "^(.)().-(.)()$" })
            end,
            change = {
                target = function()
                    return M.get_selections({ char = ">", pattern = "^(.)().-(.)()$" })
                end,
            },
        },
        ["["] = {
            add = { "[ ", " ]" },
            find = function()
                return M.get_selection({ textobject = "[" })
            end,
            delete = function()
                return M.get_selections({ char = "[", pattern = "^(. ?)().-( ?.)()$" })
            end,
            change = {
                target = function()
                    return M.get_selections({ char = "[", pattern = "^(. ?)().-( ?.)()$" })
                end,
            },
        },
        ["]"] = {
            add = { "[", "]" },
            find = function()
                return M.get_selection({ textobject = "]" })
            end,
            delete = function()
                return M.get_selections({ char = "]", pattern = "^(.)().-(.)()$" })
            end,
            change = {
                target = function()
                    return M.get_selections({ char = "]", pattern = "^(.)().-(.)()$" })
                end,
            },
        },
        ["'"] = {
            add = { "'", "'" },
            find = function()
                return M.get_selection({ textobject = "'" })
            end,
            delete = function()
                return M.get_selections({ char = "'", pattern = "^(.)().-(.)()$" })
            end,
            change = {
                target = function()
                    return M.get_selections({ char = "'", pattern = "^(.)().-(.)()$" })
                end,
            },
        },
        ['"'] = {
            add = { '"', '"' },
            find = function()
                return M.get_selection({ textobject = '"' })
            end,
            delete = function()
                return M.get_selections({ char = '"', pattern = "^(.)().-(.)()$" })
            end,
            change = {
                target = function()
                    return M.get_selections({ char = '"', pattern = "^(.)().-(.)()$" })
                end,
            },
        },
        ["`"] = {
            add = { "`", "`" },
            find = function()
                return M.get_selection({ textobject = "`" })
            end,
            delete = function()
                return M.get_selections({ char = "`", pattern = "^(.)().-(.)()$" })
            end,
            change = {
                target = function()
                    return M.get_selections({ char = "`", pattern = "^(.)().-(.)()$" })
                end,
            },
        },
        ["i"] = {
            add = function()
                local left_delimiter = M.get_input("Enter the left delimiter: ")
                if left_delimiter then
                    local right_delimiter = M.get_input("Enter the right delimiter: ")
                    if right_delimiter then
                        return { { left_delimiter }, { right_delimiter } }
                    end
                end
            end,
            find = function() end,
            delete = function() end,
            change = { target = function() end },
        },
        ["t"] = {
            add = function()
                local input = M.get_input("Enter the HTML tag: ")
                if input then
                    local element = input:match("^<?([%w-]+)")
                    local attributes = input:match("%s+([^>]+)>?$")
                    if not element then
                        return nil
                    end

                    local open = attributes and element .. " " .. attributes or element
                    local close = element

                    return { { "<" .. open .. ">" }, { "</" .. close .. ">" } }
                end
            end,
            find = function()
                return M.get_selection({ textobject = "t" })
            end,
            delete = function()
                return M.get_selections({ char = "t", pattern = "^(%b<>)().-(%b<>)()$" })
            end,
            change = {
                target = function()
                    return M.get_selections({ char = "t", pattern = "^<([%w-]*)().-([^/]*)()>$" })
                end,
                replacement = function()
                    local element = M.get_input("Enter the HTML element: ")
                    if element then
                        return { { element }, { element } }
                    end
                end,
            },
        },
        ["T"] = {
            add = function()
                local input = M.get_input("Enter the HTML tag: ")
                if input then
                    local element = input:match("^<?([%w-]+)")
                    local attributes = input:match("%s+([^>]+)>?$")
                    if not element then
                        return nil
                    end

                    local open = attributes and element .. " " .. attributes or element
                    local close = element

                    return { { "<" .. open .. ">" }, { "</" .. close .. ">" } }
                end
            end,
            find = function()
                return M.get_selection({ textobject = "t" })
            end,
            delete = function()
                return M.get_selections({ char = "T", pattern = "^(%b<>)().-(%b<>)()$" })
            end,
            change = {
                target = function()
                    return M.get_selections({ char = "T", pattern = "^<([^>]*)().-([^%/]*)()>$" })
                end,
                replacement = function()
                    local input = M.get_input("Enter the HTML tag: ")
                    if input then
                        local element = input:match("^<?([%w-]+)")
                        local attributes = input:match("%s+([^>]+)>?$")
                        if not element then
                            return nil
                        end

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
                return M.get_selection({ pattern = "[%w_:.->]+%b()" })
            end,
            delete = function()
                return M.get_selections({ char = "f", pattern = "^([%w_:.->]+%()().-(%))()$" })
            end,
            change = {
                target = function()
                    return M.get_selections({ char = "f", pattern = "^.-([%w_]+)()%b()()()$" })
                end,
                replacement = function()
                    local result = M.get_input("Enter the function name: ")
                    if result then
                        return { { result }, { "" } }
                    end
                end,
            },
        },
        invalid_key_behavior = {
            add = function() end,
            find = function() end,
            delete = function() end,
            change = {
                target = function() end,
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
}

--[====================================================================================================================[
                                             Configuration Helper Functions
--]====================================================================================================================]

-- Gets input from the user.
---@param prompt string The input prompt.
---@return string? @The user input.
M.get_input = function(prompt)
    -- Since `vim.fn.input()` does not handle keyboard interrupts, we use a protected call to detect <C-c>
    local ok, result = pcall(vim.fn.input, { prompt = prompt })
    return ok and result
end

-- Gets a selection from the buffer based on some heuristic.
---@param args { char: string?, pattern: string?, textobject: string? }
---@return selection? The retrieved selection.
M.get_selection = function(args)
    if args.pattern then
        return require("nvim-surround.patterns").get_selection(args.pattern)
    elseif args.textobject then
        return require("nvim-surround.textobjects").get_selection(args.textobject)
    end
end

-- Gets a pair of selections from the buffer based on some heuristic.
---@param args { char: string?, pattern: string? }
M.get_selections = function(args)
    if args.pattern then
        return require("nvim-surround.utils").get_selections(args.char, args.pattern)
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
    return vim.b[0].nvim_surround_buffer_opts or M.user_opts
end

-- Returns the add key for the surround associated with a given character, if one exists.
---@param char string? The input character.
---@return function? @The function to get the delimiters to be added.
M.get_add = function(char)
    char = require("nvim-surround.utils").get_alias(char)
    local key = M.get_opts().delimiters[char] or M.get_opts().delimiters.invalid_key_behavior
    return key.add
end

-- Returns the delete key for the surround associated with a given character, if one exists.
---@param char string? The input character.
---@return function? @The function to get the selections to be deleted.
M.get_delete = function(char)
    char = require("nvim-surround.utils").get_alias(char)
    local key = M.get_opts().delimiters[char] or M.get_opts().delimiters.invalid_key_behavior
    return key.delete
end

-- Returns the change key for the surround associated with a given character, if one exists.
---@param char string? The input character.
---@return { target: function, replacement: function? }? @A table holding the target/replacment functions.
M.get_change = function(char)
    char = require("nvim-surround.utils").get_alias(char)
    local key = M.get_opts().delimiters[char] or M.get_opts().delimiters.invalid_key_behavior
    return key.change
end

-- Translates the user-provided configuration into the internal form.
---@param opts options? The user-provided options.
M.translate_opts = function(opts)
    if not (opts and opts.delimiters) then
        return opts
    end
    local invalid = opts.delimiters.invalid_key_behavior or M.default_opts.delimiters.invalid_key_behavior
    for char, val in pairs(opts.delimiters) do
        -- Validate that the delimiter has not been disabled
        if val then
            local add, find, delete, change = val.add, val.find, val.delete, val.change
            -- Ensure that all necessary keys are present
            if not add then
                opts.delimiters[char].add = invalid.add
            end
            if not find then
                opts.delimiters[char].find = invalid.find
            end
            if not delete then
                opts.delimiters[char].delete = invalid.delete
            end
            if not (change and change.target) then
                opts.delimiters[char].change = { target = invalid.change.target }
            end

            -- Handle `add` key translation
            if vim.tbl_islist(add) then -- Check if the add key is a table instead of a function
                -- Wrap the left/right delimiters in a table if they are strings (single line)
                if type(add[1]) == "string" then
                    add[1] = { add[1] }
                end
                if type(add[2]) == "string" then
                    add[2] = { add[2] }
                end
                -- Wrap the delimiter pair in a function
                opts.delimiters[char].add = function()
                    return add
                end
            end

            -- Handle `find` key translation
            if type(find) == "string" then
                -- Treat the string as a Lua pattern, and find the selection
                opts.delimiters[char].find = function()
                    return require("nvim-surround.patterns").get_selection(find)
                end
            end

            -- Handle `delete` key translation
            if type(delete) == "string" then
                -- Wrap delete in a function
                opts.delimiters[char].delete = function()
                    return require("nvim-surround.utils").get_selections(char, delete)
                end
            end

            -- Handle `change` key translation
            local target, replacement = change and change.target, change and change.replacement
            -- Wrap target in a function
            if type(target) == "string" then
                opts.delimiters[char].change.target = function()
                    return require("nvim-surround.utils").get_selections(char, target)
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
                opts.delimiters[char].change.replacement = function()
                    return replacement
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
    M.user_opts = M.merge_opts(M.translate_opts(M.default_opts), user_opts)
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
    -- Merge the given table into the existing buffer-local options, or global options otherwise
    vim.b[0].nvim_surround_buffer_opts = M.merge_opts(M.get_opts(), buffer_opts)
    -- Configure buffer-local keymaps
    M.set_keymaps(true)
end

return M
