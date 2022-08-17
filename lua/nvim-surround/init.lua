---@class selection
---@field first_pos integer[]
---@field last_pos integer[]

---@class selections
---@field left selection?
---@field right selection?

---@class surround
---@field add string[]|string[][]|function
---@field find string|function
---@field delete string|function
---@field change { target: string|function, replacement: string[]|string[][]|function? }

---@class options
---@field keymaps table<string, boolean|string>
---@field surrounds table<string, boolean|surround>
---@field aliases table<string, boolean|string|string[]>
---@field highlight { duration: boolean|integer }
---@field move_cursor boolean|string
---@field indent_lines boolean|function

local buffer = require("nvim-surround.buffer")
local cache = require("nvim-surround.cache")
local config = require("nvim-surround.config")
local utils = require("nvim-surround.utils")

local M = {}

-- Setup the plugin with user-defined options.
---@param user_opts options? The user options.
M.setup = function(user_opts)
    config.setup(user_opts)
end

-- Configure the plugin on a per-buffer basis.
---@param buffer_opts options? The buffer-local options.
M.buffer_setup = function(buffer_opts)
    config.buffer_setup(buffer_opts)
end

-- Add delimiters around the cursor, in insert mode.
M.insert_surround = function(line_mode)
    local curpos = buffer.get_curpos()
    local char = utils.get_char()
    local delimiters = utils.get_delimiters(char)
    if not delimiters then
        return
    end

    -- Add new lines if the addition is done line-wise
    if line_mode then
        table.insert(delimiters[2], 1, "")
        table.insert(delimiters[1], "")
    end

    buffer.insert_text(curpos, delimiters[2])
    buffer.insert_text(curpos, delimiters[1])
    buffer.set_curpos({ curpos[1] + #delimiters[1] - 1, curpos[2] + #delimiters[1][#delimiters[1]] })
    -- Indent the cursor to the correct level, if added line-wise
    local indent_lines = config.get_opts().indent_lines
    if indent_lines then
        curpos = buffer.get_curpos()
        indent_lines(curpos[1], curpos[1] + #delimiters[1] + #delimiters[2] - 2)
        buffer.set_curpos(curpos)
        if line_mode then
            local lnum = buffer.get_curpos()[1]
            vim.cmd(lnum .. "left " .. vim.fn.indent(lnum + 1) + vim.fn.shiftwidth())
            buffer.set_curpos({ lnum, #buffer.get_line(lnum) + 1 })
        end
    end
end

-- Holds the current position of the cursor, since calling opfunc will erase it.
M.normal_curpos = nil
-- Add delimiters around a text object.
---@param args { selection: selection, delimiters: string[][], curpos: integer[] }
---@return string?
M.normal_surround = function(args, line_mode)
    -- Call the operatorfunc if it has not been called yet
    if not args then
        -- Clear the normal cache (since it was user-called)
        cache.normal = { line_mode = line_mode }
        M.normal_curpos = buffer.get_curpos()

        vim.go.operatorfunc = "v:lua.require'nvim-surround'.normal_callback"
        return "g@"
    end

    local first_pos = args.selection.first_pos
    local last_pos = { args.selection.last_pos[1], args.selection.last_pos[2] + 1 }

    buffer.insert_text(last_pos, args.delimiters[2])
    buffer.insert_text(first_pos, args.delimiters[1])
    buffer.reset_curpos(M.normal_curpos)
end

-- Add delimiters around a visual selection.
M.visual_surround = function(line_mode)
    -- Save the current position of the cursor
    local curpos = buffer.get_curpos()
    -- Get a character and selection from the user
    local ins_char = utils.get_char()
    local delimiters = utils.get_delimiters(ins_char)
    local first_pos, last_pos = buffer.get_mark("<"), buffer.get_mark(">")
    if not delimiters or not first_pos or not last_pos then
        return
    end

    -- Add new lines if the addition is done line-wise
    if line_mode then
        table.insert(delimiters[2], 1, "")
        table.insert(delimiters[1], "")
    end

    -- Add the right delimiter first to ensure correct indexing
    if vim.fn.visualmode() == "V" then -- Visual line mode case (need to create new lines)
        table.insert(delimiters[2], 1, "")
        table.insert(delimiters[1], "")
        buffer.insert_text({ last_pos[1], #buffer.get_line(last_pos[1]) + 1 }, delimiters[2])
        buffer.insert_text(first_pos, delimiters[1])
    elseif vim.fn.visualmode() == "\22" then -- Visual block mode case (add delimiters to every line)
        -- Get (visually) what columns the start and end are located at
        local first_disp = vim.fn.strdisplaywidth(buffer.get_line(first_pos[1]):sub(1, first_pos[2] - 1)) + 1
        local last_disp = vim.fn.strdisplaywidth(buffer.get_line(last_pos[1]):sub(1, last_pos[2] - 1)) + 1
        -- Find the min/max for some variables, since visual blocks can either go diagonally or anti-diagonally
        local mn_disp, mx_disp = math.min(first_disp, last_disp), math.max(first_disp, last_disp)
        local mn_lnum, mx_lnum = math.min(first_pos[1], last_pos[1]), math.max(first_pos[1], last_pos[1])
        -- Surround each line with the delimiter pair, last to first (for indexing reasons)
        for lnum = mx_lnum, mn_lnum, -1 do
            local line = buffer.get_line(lnum)
            local index = buffer.get_last_byte({ lnum, 1 })[2]
            -- The current display count should be >= the desired one
            while vim.fn.strdisplaywidth(line:sub(1, index)) < mx_disp and index <= #line do
                index = buffer.get_last_byte({ lnum, index + 1 })[2]
            end
            -- Go to the end of the current character
            index = buffer.get_last_byte({ lnum, index })[2]
            buffer.insert_text({ lnum, index + 1 }, delimiters[2])
            index = 1
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

    if config.get_opts().indent_lines then
        config.get_opts().indent_lines(first_pos[1], last_pos[1] + #delimiters[1] + #delimiters[2] - 2)
    end
    buffer.reset_curpos(curpos)
end

-- Delete a surrounding delimiter pair, if it exists.
---@param args { del_char: string, curpos: integer[] }
---@return string?
M.delete_surround = function(args)
    -- Call the operatorfunc if it has not been called yet
    if not args then
        -- Clear the delete cache (since it was user-called)
        cache.delete = {}

        vim.go.operatorfunc = "v:lua.require'nvim-surround'.delete_callback"
        return "g@l"
    end

    -- Get the selections to delete
    local selections = utils.get_nearest_selections(args.del_char, "delete")

    if selections then
        -- Delete the right selection first to ensure selection positions are correct
        buffer.delete_selection(selections.right)
        buffer.delete_selection(selections.left)
        if config.get_opts().indent_lines then
            config.get_opts().indent_lines(
                selections.left.first_pos[1],
                selections.left.first_pos[1] + selections.right.first_pos[1] - selections.left.last_pos[1]
            )
        end
        buffer.set_curpos(selections.left.first_pos)
    end

    buffer.reset_curpos(args.curpos)
    cache.set_callback("v:lua.require'nvim-surround'.delete_callback")
end

-- Change a surrounding delimiter pair, if it exists.
---@param args? table
M.change_surround = function(args)
    -- Call the operatorfunc if it has not been called yet
    if not args then
        -- Clear the change cache (since it was user-called)
        cache.change = {}

        vim.go.operatorfunc = "v:lua.require'nvim-surround'.change_callback"
        return "g@l"
    end

    -- Get the selections to change
    local selections = utils.get_nearest_selections(args.del_char, "change")
    if selections then
        local delimiters = args.add_delimiters()
        -- Change the right selection first to ensure selection positions are correct
        buffer.change_selection(selections.right, delimiters[2])
        buffer.change_selection(selections.left, delimiters[1])
        buffer.set_curpos(selections.left.first_pos)
    end

    buffer.reset_curpos(args.curpos)
    cache.set_callback("v:lua.require'nvim-surround'.change_callback")
end

--[====================================================================================================================[
                                                   Callback Functions
--]====================================================================================================================]

---@param mode string
M.normal_callback = function(mode)
    -- Adjust the ] mark if the operator was in line-mode, e.g. `ip`
    if mode == "line" then
        local pos = buffer.get_mark("]")
        if not pos then
            return
        end
        pos = { pos[1], #buffer.get_line(pos[1]) }
        buffer.set_mark("]", pos)
    end
    -- Move the last position to the last byte of the character, if necessary
    buffer.set_mark("]", buffer.get_last_byte(buffer.get_mark("]")))

    buffer.adjust_mark("[")
    buffer.adjust_mark("]")
    local selection = {
        first_pos = buffer.get_mark("["),
        last_pos = buffer.get_mark("]"),
    }
    if not selection.first_pos or not selection.last_pos then
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
        local char = utils.get_char()
        -- Get the delimiter pair based on the input character
        cache.normal.delimiters = cache.normal.delimiters or utils.get_delimiters(char)
        -- Add new lines if the addition is done line-wise
        if cache.normal.line_mode then
            table.insert(cache.normal.delimiters[2], 1, "")
            table.insert(cache.normal.delimiters[1], "")
        end
        if not cache.normal.delimiters then
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
    })
end

M.delete_callback = function()
    -- Save the current position of the cursor
    local curpos = buffer.get_curpos()
    -- Get a character input if not cached
    cache.delete.char = cache.delete.char or utils.get_char()
    if not cache.delete.char then
        return
    end

    M.delete_surround({
        del_char = cache.delete.char,
        curpos = curpos,
    })
end

M.change_callback = function()
    -- Save the current position of the cursor
    local curpos = buffer.get_curpos()
    if not cache.change.del_char or not cache.change.add_delimiters then
        local del_char = utils.get_alias(utils.get_char())
        local change = config.get_change(del_char)
        -- Get the selections to change
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

        -- Get the new surrounding pair, querying the user for more input if no replacement is provided
        local ins_char, delimiters
        if change and change.replacement then
            delimiters = change.replacement()
        else
            ins_char = utils.get_char()
            delimiters = utils.get_delimiters(ins_char)
        end

        -- Clear the highlights after getting the replacement surround
        buffer.clear_highlights()
        if not delimiters then
            return
        end

        -- Set the cache
        cache.change = {
            del_char = del_char,
            add_delimiters = function()
                return delimiters
            end,
        }
    end
    local args = vim.deepcopy(cache.change)
    args.curpos = curpos
    M.change_surround(args)
end

return M
