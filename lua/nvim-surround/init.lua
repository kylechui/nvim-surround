local buffer = require("nvim-surround.buffer")
local cache = require("nvim-surround.cache")
local config = require("nvim-surround.config")
local html = require("nvim-surround.html")
local utils = require("nvim-surround.utils")

local M = {}

-- Setup the plugin with user-defined options
M.setup = function(user_opts)
    config.setup(user_opts)
end

-- Configure the plugin on a per-buffer basis
M.buffer_setup = function(buffer_opts)
    config.buffer_setup(buffer_opts)
end

-- API: Insert delimiters around a text object
M.insert_surround = function(args)
    -- Call the operatorfunc if it has not been called yet
    if not args then
        -- Clear the insert cache (since it was user-called)
        cache.insert = {}

        vim.go.operatorfunc = "v:lua.require'nvim-surround'.insert_callback"
        return "g@"
    end

    local first_pos = args.selection.first_pos
    local last_pos = { args.selection.last_pos[1], args.selection.last_pos[2] + 1 }

    buffer.insert_lines(last_pos, args.delimiters[2])
    buffer.insert_lines(first_pos, args.delimiters[1])
end

-- API: Insert delimiters around a visual selection
M.visual_surround = function(mode)
    -- Get a character and selection from the user
    local ins_char = utils.get_char()
    local selection = utils.get_selection(true)

    local args = {
        bufnr = vim.fn.bufnr(),
        selection = selection,
        text = buffer.get_selection(selection),
    }
    local delimiters = utils.get_delimiters(ins_char, args)
    if not delimiters or not selection then
        return
    end
    local first_pos, last_pos = selection.first_pos, selection.last_pos

    -- Insert the right delimiter first to ensure correct indexing
    if mode == "V" then -- Visual line mode case (need to create new lines)
        table.insert(delimiters[2], 1, "")
        table.insert(delimiters[1], #delimiters[1] + 1, "")
        buffer.insert_lines({ last_pos[1], #buffer.get_lines(last_pos[1], last_pos[1])[1] + 1 }, delimiters[2])
        buffer.insert_lines({ first_pos[1], 1 }, delimiters[1])
        -- Reformat the text
        buffer.format_lines(first_pos[1], last_pos[1] + #delimiters[1] + #delimiters[2])
    else -- Regular visual mode case
        buffer.insert_lines({ last_pos[1], last_pos[2] + 1 }, delimiters[2])
        buffer.insert_lines(first_pos, delimiters[1])
    end
end

-- API: Delete a surrounding delimiter pair, if it exists
M.delete_surround = function(del_char)
    -- Call the operatorfunc if it has not been called yet
    if not del_char then
        -- Clear the delete cache (since it was user-called)
        cache.delete = {}

        vim.go.operatorfunc = "v:lua.require'nvim-surround'.delete_callback"
        return "g@l"
    end

    local selections = utils.get_nearest_selections(del_char)
    if selections then
        -- Delete the right selection first to ensure selection positions are correct
        buffer.delete_selection(selections.right)
        buffer.delete_selection(selections.left)
    end

    cache.set_callback("v:lua.require'nvim-surround'.delete_callback")
end

-- API: Change a surrounding delimiter pair, if it exists
M.change_surround = function(args)
    -- Call the operatorfunc if it has not been called yet
    if not args then
        -- Clear the change cache (since it was user-called)
        cache.change = {}

        vim.go.operatorfunc = "v:lua.require'nvim-surround'.change_callback"
        return "g@l"
    end

    local selections = utils.get_nearest_selections(args.del_char)
    -- Adjust the selections for changing if we are changing a HTML tag
    if html.get_type(args.del_char) then
        selections = html.adjust_selections(selections, html.get_type(args.del_char))
    end

    if selections then
        -- Change the right selection first to ensure selection positions are correct
        buffer.change_selection(selections.right, args.ins_delimiters[2])
        buffer.change_selection(selections.left, args.ins_delimiters[1])
    end
    cache.set_callback("v:lua.require'nvim-surround'.change_callback")
end

--[============================================================================[
                               Callback Functions
--]============================================================================]

M.insert_callback = function(mode)
    -- Adjust the ] mark if the operator was in line-mode
    if mode == "line" then
        local pos = buffer.get_mark("]")
        if not pos then
            return
        end
        pos = { pos[1], #buffer.get_lines(pos[1], pos[1])[1] }
        buffer.set_mark("]", pos)
    end

    local selection = utils.get_selection(false)
    -- Highlight the range and set a timer to clear it if necessary
    buffer.highlight_selection(selection)
    local highlight_motion = utils.get_opts().highlight_motion
    if highlight_motion and highlight_motion.duration > 0 then
        vim.defer_fn(buffer.clear_highlights, highlight_motion.duration)
    end
    -- Get a character input and the delimiters (if not cached)
    if not cache.insert.delimiters then
        local char = utils.get_char()
        local args = {
            bufnr = vim.fn.bufnr(),
            selection = selection,
            text = buffer.get_selection(selection),
        }
        -- Get the delimiter pair based on the insert character
        cache.insert.delimiters = cache.insert.delimiters or utils.get_delimiters(char, args)
        if not cache.insert.delimiters then
            buffer.clear_highlights()
            return
        end
    end
    -- Clear the highlights right after the action is no longer pending
    buffer.clear_highlights()

    local args = {
        delimiters = cache.insert.delimiters,
        selection = selection,
    }
    -- Call the main insert function with some arguments
    M.insert_surround(args)
end

M.delete_callback = function()
    -- Get a character input if not cached
    cache.delete.char = cache.delete.char or utils.get_char()
    if not cache.delete.char then
        return
    end
    M.delete_surround(cache.delete.char)
end

M.change_callback = function()
    -- Get character inputs if not cached
    if not cache.change.del_char or not cache.change.ins_delimiters then
        -- Get the surrounding selections to delete
        local del_char = utils.get_char()
        local selections = utils.get_nearest_selections(del_char)
        -- Adjust the selections for changing if we are changing a HTML tag
        if html.get_type(del_char) then
            selections = html.adjust_selections(selections, html.get_type(del_char))
        end
        if not selections then
            return
        end

        -- Highlight the range and set a timer to clear it if necessary
        buffer.highlight_selection(selections.left)
        buffer.highlight_selection(selections.right)
        local highlight_motion = utils.get_opts().highlight_motion
        if highlight_motion and highlight_motion.duration > 0 then
            vim.defer_fn(buffer.clear_highlights, highlight_motion.duration)
        end
        -- Get the new surrounding pair
        local ins_char, delimiters
        if html.get_type(del_char) then
            delimiters = html.get_tag()
        else
            ins_char = utils.get_char()
            delimiters = utils.get_delimiters(ins_char)
        end
        buffer.clear_highlights()

        if not delimiters then
            return
        end
        -- Set the cache
        cache.change = {
            del_char = del_char,
            ins_delimiters = delimiters,
        }
    end

    M.change_surround(vim.deepcopy(cache.change))
end

return M
