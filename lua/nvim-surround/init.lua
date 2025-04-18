local M = {}

-- Setup the plugin with user-defined options.
---@param user_opts user_options|nil The user options.
M.setup = function(user_opts)
    require("nvim-surround.config").setup(user_opts)
end

-- Configure the plugin on a per-buffer basis.
---@param buffer_opts user_options|nil The buffer-local options.
M.buffer_setup = function(buffer_opts)
    require("nvim-surround.config").buffer_setup(buffer_opts)
end

-- Add delimiters around the cursor, in insert mode.
---@param args { line_mode: boolean } Whether or not the delimiters should get put on new lines.
M.insert_surround = function(args)
    local config = require("nvim-surround.config")
    local buffer = require("nvim-surround.buffer")
    local input = require("nvim-surround.input")
    local char = input.get_char()
    local curpos = buffer.get_curpos()
    local delimiters = config.get_delimiters(char, args.line_mode)
    if not delimiters then
        return
    end

    buffer.insert_text(curpos, delimiters[2])
    buffer.insert_text(curpos, delimiters[1])
    buffer.set_curpos({ curpos[1] + #delimiters[1] - 1, curpos[2] + #delimiters[1][#delimiters[1]] })
    -- Indent the cursor to the correct level, if added line-wise
    curpos = buffer.get_curpos()
    config.get_opts().indent_lines(curpos[1], curpos[1] + #delimiters[1] + #delimiters[2] - 2)
    buffer.set_curpos(curpos)
    if args.line_mode then
        local lnum = buffer.get_curpos()[1]
        vim.cmd(lnum .. "left " .. vim.fn.indent(lnum + 1) + vim.fn.shiftwidth())
        buffer.set_curpos({ lnum, #buffer.get_line(lnum) + 1 })
    end
end

-- Holds the current position of the cursor, since calling opfunc will erase it.
M.normal_curpos = nil
-- Detects if plugin is currently prompting the user for a motion / delimiter.
M.pending_surround = false
-- Add delimiters around a motion.
---@param args { selection: selection, delimiters: delimiter_pair, line_mode: boolean }
---@return "g@"|nil
M.normal_surround = function(args)
    local config = require("nvim-surround.config")
    local buffer = require("nvim-surround.buffer")
    local cache = require("nvim-surround.cache")
    local utils = require("nvim-surround.utils")
    -- Call the operatorfunc if it has not been called yet
    if not args.selection then
        -- Clear the normal cache's delimiters (since it was user-called)
        cache.normal = { line_mode = args.line_mode, count = vim.v.count1 }
        M.normal_curpos = buffer.get_curpos()
        M.pending_surround = true

        vim.go.operatorfunc = "v:lua.require'nvim-surround'.normal_callback"

        -- Very jank way of resetting v:count to 1 before getting the motion, to ensure that the count
        -- does not multiply against the motion
        local del_str = ""
        local n = vim.v.count1
        while n > 1 do
            del_str = del_str .. "<Del>"
            n = n / 10
        end
        return del_str .. "g@"
    end

    local first_pos = args.selection.first_pos
    local last_pos = { args.selection.last_pos[1], args.selection.last_pos[2] + 1 }

    local delimiters = utils.repeat_delimiters(args.delimiters, cache.normal.count)
    local sticky_pos = buffer.with_extmark(M.normal_curpos, function()
        buffer.insert_text(last_pos, delimiters[2])
        buffer.insert_text(first_pos, delimiters[1])
    end)
    buffer.restore_curpos({
        first_pos = first_pos,
        sticky_pos = sticky_pos,
        old_pos = M.normal_curpos,
    })

    if args.line_mode then
        config.get_opts().indent_lines(first_pos[1], last_pos[1] + #delimiters[1] + #delimiters[2] - 2)
    end
    M.pending_surround = false
end

-- Add delimiters around a visual selection.
---@param args { line_mode: boolean, curpos: position, curswant: number }
M.visual_surround = function(args)
    local config = require("nvim-surround.config")
    local buffer = require("nvim-surround.buffer")
    local input = require("nvim-surround.input")
    local utils = require("nvim-surround.utils")
    local ins_char = input.get_char()

    if vim.fn.visualmode() == "V" then
        args.line_mode = true
    end
    local first_pos, last_pos = buffer.get_mark("<"), buffer.get_mark(">")
    local raw_delimiters = config.get_delimiters(ins_char, args.line_mode)
    if not raw_delimiters or not first_pos or not last_pos then
        return
    end

    local delimiters = utils.repeat_delimiters(raw_delimiters, vim.v.count1)
    if vim.o.selection == "exclusive" then
        last_pos[2] = last_pos[2] - 1
    end
    local sticky_pos = buffer.with_extmark(args.curpos, function()
        if vim.fn.visualmode() == "\22" then -- Visual block mode case (add delimiters to every line)
            -- Get (visually) what columns the start and end are located at
            local first_disp = vim.fn.strdisplaywidth(buffer.get_line(first_pos[1]):sub(1, first_pos[2] - 1)) + 1
            local last_disp = vim.fn.strdisplaywidth(buffer.get_line(last_pos[1]):sub(1, last_pos[2] - 1)) + 1
            -- Find the min/max for some variables, since visual blocks can either go diagonally or anti-diagonally
            local mn_disp, mx_disp = math.min(first_disp, last_disp), math.max(first_disp, last_disp)
            local mn_lnum, mx_lnum = math.min(first_pos[1], last_pos[1]), math.max(first_pos[1], last_pos[1])
            -- Check if $ was used in creating the block selection
            local surround_to_end_of_line = args.curswant == vim.v.maxcol
            -- Surround each line with the delimiter pair, last to first (for indexing reasons)
            for lnum = mx_lnum, mn_lnum, -1 do
                local line = buffer.get_line(lnum)
                if surround_to_end_of_line then
                    buffer.insert_text({ lnum, #buffer.get_line(lnum) + 1 }, delimiters[2])
                else
                    local index = buffer.get_last_byte({ lnum, 1 })[2]
                    -- The current display count should be >= the desired one
                    while vim.fn.strdisplaywidth(line:sub(1, index)) < mx_disp and index <= #line do
                        index = buffer.get_last_byte({ lnum, index + 1 })[2]
                    end
                    -- Go to the end of the current character
                    index = buffer.get_last_byte({ lnum, index })[2]
                    buffer.insert_text({ lnum, index + 1 }, delimiters[2])
                end

                local index = 1
                -- The current display count should be <= the desired one
                while vim.fn.strdisplaywidth(line:sub(1, index - 1)) + 1 < mn_disp and index <= #line do
                    index = buffer.get_last_byte({ lnum, index })[2] + 1
                end
                if vim.fn.strdisplaywidth(line:sub(1, index - 1)) + 1 > mn_disp then
                    -- Go to the beginning of the previous character
                    index = buffer.get_first_byte({ lnum, index - 1 })[2]
                end
                buffer.insert_text({ lnum, index }, delimiters[1])
            end
        else -- Regular visual mode case
            last_pos = buffer.get_last_byte(last_pos)
            buffer.insert_text({ last_pos[1], last_pos[2] + 1 }, delimiters[2])
            buffer.insert_text(first_pos, delimiters[1])
        end
    end)

    config.get_opts().indent_lines(first_pos[1], last_pos[1] + #delimiters[1] + #delimiters[2] - 2)
    buffer.restore_curpos({
        first_pos = first_pos,
        sticky_pos = sticky_pos,
        old_pos = args.curpos,
    })
end

-- Delete a surrounding delimiter pair, if it exists.
---@param args { del_char: string, curpos: position }|nil
---@return "g@l"|nil
M.delete_surround = function(args)
    local config = require("nvim-surround.config")
    local buffer = require("nvim-surround.buffer")
    local cache = require("nvim-surround.cache")
    local utils = require("nvim-surround.utils")
    -- Call the operatorfunc if it has not been called yet
    if not args then
        -- Clear the delete cache (since it was user-called)
        cache.delete = { count = vim.v.count1 }

        vim.go.operatorfunc = "v:lua.require'nvim-surround'.delete_callback"
        return "g@l"
    end

    local selections = utils.get_nearest_selections(args.del_char, "delete")
    if selections then
        local sticky_pos = buffer.with_extmark(args.curpos, function()
            buffer.delete_selection(selections.right)
            buffer.delete_selection(selections.left)
        end)
        config.get_opts().indent_lines(
            selections.left.first_pos[1],
            selections.left.first_pos[1] + selections.right.first_pos[1] - selections.left.last_pos[1]
        )
        buffer.restore_curpos({
            first_pos = selections.left.first_pos,
            sticky_pos = sticky_pos,
            old_pos = args.curpos,
        })
    end

    cache.set_callback("v:lua.require'nvim-surround'.delete_callback")
end

-- Change a surrounding delimiter pair, if it exists.
---@param args { curpos: position, del_char: string, add_delimiters: add_func, line_mode: boolean }
---@return "g@l"|nil
M.change_surround = function(args)
    local config = require("nvim-surround.config")
    local buffer = require("nvim-surround.buffer")
    local cache = require("nvim-surround.cache")
    local utils = require("nvim-surround.utils")
    -- Call the operatorfunc if it has not been called yet
    if not args.del_char or not args.add_delimiters then
        -- Clear the change cache (since it was user-called)
        cache.change = { line_mode = args.line_mode, count = vim.v.count1 }

        vim.go.operatorfunc = "v:lua.require'nvim-surround'.change_callback"
        return "g@l"
    end

    buffer.set_curpos(args.curpos)
    -- Get the selections to change, as well as the delimiters to replace those selections
    local selections = utils.get_nearest_selections(args.del_char, "change")
    local raw_delimiters = args.add_delimiters()
    if not (selections and raw_delimiters) then
        cache.set_callback("v:lua.require'nvim-surround'.change_callback")
        return
    end
    local delimiters = utils.normalize_delimiters(raw_delimiters)
    -- Avoid adding any, and remove any existing whitespace after the
    -- opening delimiter if only whitespace exists between it and the end
    -- of the line. Avoid adding or removing leading whitespace before the
    -- closing delimiter if only whitespace exists between it and the
    -- beginning of the line.

    local space_begin, space_end = buffer.get_line(selections.left.last_pos[1]):find("%s*$")
    if space_begin - 1 <= selections.left.last_pos[2] then -- Whitespace is adjacent to opening delimiter
        -- Trim trailing whitespace from opening delimiter
        delimiters[1][#delimiters[1]] = delimiters[1][#delimiters[1]]:gsub("%s+$", "")
        -- Grow selection end to include trailing whitespace, so it gets removed
        selections.left.last_pos[2] = space_end
    end

    space_begin, space_end = buffer.get_line(selections.right.first_pos[1]):find("^%s*")
    if space_end + 1 >= selections.right.first_pos[2] then -- Whitespace is adjacent to closing delimiter
        -- Trim leading whitespace from closing delimiter
        delimiters[2][1] = delimiters[2][1]:gsub("^%s+", "")
        -- Shrink selection beginning to exclude leading whitespace, so it remains unchanged
        selections.right.first_pos[2] = space_end + 1
    end

    local sticky_pos = buffer.with_extmark(args.curpos, function()
        buffer.change_selection(selections.right, delimiters[2])
        buffer.change_selection(selections.left, delimiters[1])
    end)
    buffer.restore_curpos({
        first_pos = selections.left.first_pos,
        sticky_pos = sticky_pos,
        old_pos = args.curpos,
    })

    if args.line_mode then
        local first_line = selections.left.first_pos[1]
        local last_line = selections.right.last_pos[1]
        config.get_opts().indent_lines(first_line, last_line + #delimiters[1] + #delimiters[2] - 2)
    end

    cache.set_callback("v:lua.require'nvim-surround'.change_callback")
end

--[====================================================================================================================[
                                                   Callback Functions
--]====================================================================================================================]

---@param mode "char"|"line"|"block"
M.normal_callback = function(mode)
    local config = require("nvim-surround.config")
    local buffer = require("nvim-surround.buffer")
    local cache = require("nvim-surround.cache")
    local input = require("nvim-surround.input")
    buffer.restore_curpos({ old_pos = M.normal_curpos })
    -- Adjust the ] mark if the operator was in line-mode, e.g. `ip` or `3j`
    if mode == "line" then
        local first_pos = buffer.get_mark("[")
        local last_pos = buffer.get_mark("]")
        if not (first_pos and last_pos) then
            M.pending_surround = false
            return
        end
        first_pos = { first_pos[1], 1 }
        last_pos = { last_pos[1], #buffer.get_line(last_pos[1]) }
        buffer.set_mark("[", first_pos)
        buffer.set_mark("]", last_pos)
    end
    -- Move the last position to the last byte of the character, if necessary
    ---@diagnostic disable-next-line
    buffer.set_mark("]", buffer.get_last_byte(buffer.get_mark("]")))

    buffer.adjust_mark("[")
    buffer.adjust_mark("]")
    local selection = {
        first_pos = buffer.get_mark("["),
        last_pos = buffer.get_mark("]"),
    }
    if not selection.first_pos or not selection.last_pos then
        M.pending_surround = false
        return
    end
    -- Highlight the range and set a timer to clear it if necessary
    local highlight = config.get_opts().highlight
    if highlight.duration then
        buffer.highlight_selection(selection)
        if highlight.duration > 0 then
            vim.defer_fn(buffer.clear_highlights, highlight.duration)
        end
    end
    -- Get a character input and the delimiters (if not cached)
    if not cache.normal.delimiters then
        local char = input.get_char()
        -- Get the delimiter pair based on the input character
        cache.normal.delimiters = config.get_delimiters(char, cache.normal.line_mode)
        if not cache.normal.delimiters then
            M.pending_surround = false
            buffer.clear_highlights()
            return
        end
    end
    -- Clear the highlights right after the action is no longer pending
    buffer.clear_highlights()

    -- Call the normal surround function with some arguments
    M.normal_surround({
        delimiters = cache.normal.delimiters,
        selection = selection,
        line_mode = cache.normal.line_mode,
    })
end

M.delete_callback = function()
    local buffer = require("nvim-surround.buffer")
    local cache = require("nvim-surround.cache")
    local input = require("nvim-surround.input")
    -- Get a character input if not cached
    cache.delete.char = cache.delete.char or input.get_char()
    if not cache.delete.char then
        return
    end

    for _ = 1, cache.delete.count do
        M.delete_surround({
            del_char = cache.delete.char,
            curpos = buffer.get_curpos(),
        })
    end
end

M.change_callback = function()
    local config = require("nvim-surround.config")
    local buffer = require("nvim-surround.buffer")
    local cache = require("nvim-surround.cache")
    local input = require("nvim-surround.input")
    local utils = require("nvim-surround.utils")

    local del_char = cache.change.del_char or config.get_alias(input.get_char())
    local change = config.get_change(del_char)
    if not (del_char and change) then
        return
    end

    -- To handle number prefixing properly, we just run the replacement algorithm multiple times
    for _ = 1, cache.change.count do
        -- If at any point we are unable to find a surrounding pair to change, early exit
        local selections = utils.get_nearest_selections(del_char, "change")
        if not selections then
            return
        end

        -- Highlight the range and set a timer to clear it if necessary
        local highlight = config.get_opts().highlight
        if highlight.duration then
            buffer.highlight_selection(selections.left)
            buffer.highlight_selection(selections.right)
            if highlight.duration > 0 then
                vim.defer_fn(buffer.clear_highlights, highlight.duration)
            end
        end

        -- Get the new surrounding delimiter pair, prioritizing any delimiters in the cache
        -- NB: This must occur between drawing the highlights and clearing them, so the selections are properly
        --     highlighted if the user is providing (blocking) input
        local delimiters = cache.change.add_delimiters and cache.change.add_delimiters()
        if not delimiters then
            if change and change.replacement then
                delimiters = delimiters or change.replacement()
            else
                local ins_char = input.get_char()
                delimiters = delimiters or config.get_delimiters(ins_char, cache.change.line_mode)
            end
        end

        -- Clear the highlights after getting the replacement surround
        buffer.clear_highlights()
        if not delimiters then
            return
        end

        local add_delimiters = function()
            return delimiters
        end
        -- Set the cache
        cache.change = {
            del_char = del_char,
            add_delimiters = add_delimiters,
            line_mode = cache.change.line_mode,
            count = cache.change.count,
        }
        M.change_surround({
            del_char = del_char,
            add_delimiters = add_delimiters,
            line_mode = cache.change.line_mode,
            count = cache.change.count,
            curpos = buffer.get_curpos(),
        })
    end
end

return M
