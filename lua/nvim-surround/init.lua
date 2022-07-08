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
M.visual_surround = function(ins_char, mode)
    -- Call the operatorfunc if it has not been called yet
    if not ins_char then
        vim.go.operatorfunc = "v:lua.require'nvim-surround'.visual_callback"
        return "g@"
    end

    -- Get the visual selection
    local selection = utils.get_selection(true)
    if not selection then
        return
    end

    -- Define some local variables based on the arguments
    local delimiters = utils.get_delimiters(ins_char)
    if not delimiters then
        return
    end
    local first_pos, last_pos = selection.first_pos, selection.last_pos

    -- Insert the right delimiter first to ensure correct indexing
    if mode == "line" then -- Visual line mode case (need to create new lines)
        buffer.insert_lines({ last_pos[1] + 1, 1 }, { "", "" })
        buffer.insert_lines({ last_pos[1] + 1, 1 }, delimiters[2])
        buffer.insert_lines({ first_pos[1], 1 }, { "", "" })
        buffer.insert_lines({ first_pos[1], 1 }, delimiters[1])
        -- Reformat the text
        vim.cmd(string.format("silent normal! %dG=%dG",
            first_pos[1], last_pos[1] + #delimiters[1] + #delimiters[2]
        ))
    else -- Regular visual mode case
        buffer.insert_lines({ last_pos[1], last_pos[2] + 1 }, delimiters[2])
        buffer.insert_lines(first_pos, delimiters[1])
    end
end

-- API: Delete a surrounding delimiter pair, if it exists
M.delete_surround = function(del_char)
    -- Call the operatorfunc if it has not been called yet
    if not del_char then
        -- Clear the insert char (since it was user-called)
        cache.delete = {}

        vim.go.operatorfunc = "v:lua.require'nvim-surround'.delete_callback"
        return "g@l"
    end

    local selections = utils.get_nearest_selections(del_char)
    if not selections then
        return
    end

    -- Delete the right selection first to ensure selection positions are correct
    buffer.delete_selection(selections.right)
    buffer.delete_selection(selections.left)
    -- Cache callback (since finding selections overwrites opfunc)
    vim.go.operatorfunc = "v:lua.require'nvim-surround.utils'.NOOP"
    utils.feedkeys("g@l", "x")
    vim.go.operatorfunc = "v:lua.require'nvim-surround'.delete_callback"
end

-- API: Change a surrounding delimiter pair, if it exists
M.change_surround = function(args)
    -- Call the operatorfunc if it has not been called yet
    if not args then
        -- Clear the insert char (since it was user-called)
        cache.change = {}

        vim.go.operatorfunc = "v:lua.require'nvim-surround'.change_callback"
        return "g@l"
    end

    local selections = utils.get_nearest_selections(args.del_char)

    -- Adjust the selections for changing if we are changing a HTML tag
    if utils.is_HTML(args.del_char) then
        selections = html.adjust_selections(selections)
    end
    if not selections then
        return
    end
    local left_sel = selections.left
    local right_sel = selections.right

    buffer.change_selection(right_sel, args.ins_delimiters[2])
    buffer.change_selection(left_sel, args.ins_delimiters[1])
    -- Cache callback (since finding selections overwrites opfunc)
    vim.go.operatorfunc = "v:lua.require'nvim-surround.utils'.NOOP"
    utils.feedkeys("g@l", "x")
    vim.go.operatorfunc = "v:lua.require'nvim-surround'.change_callback"
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
    -- Highlight the range and set a timer to clear it if necessary
    buffer.highlight_range()
    local highlight_motion = config.user_opts.highlight_motion
    if highlight_motion and highlight_motion.duration > 0 then
        vim.defer_fn(buffer.clear_highlights, highlight_motion.duration)
    end
    -- Get a character input and the delimiters (if not cached)
    if not cache.insert.delimiters then
        local char = utils.get_char()
        -- Get the delimiter pair based on the insert character
        cache.insert.delimiters = cache.insert.delimiters or utils.get_delimiters(char)
        if not cache.insert.delimiters then
            return
        end
    end
    -- Clear the highlights right after the action is no longer pending
    buffer.clear_highlights()

    local selection = utils.get_selection(false)

    local args = {
        delimiters = cache.insert.delimiters,
        selection = selection,
    }
    -- Call the main insert function with some arguments
    M.insert_surround(args)
end

M.visual_callback = function(mode)
    -- Get a character input and the positions of the selection
    local char = utils.get_char()
    if not char then
        return
    end

    -- Call the main visual function with some arguments
    M.visual_surround(char, mode)
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
        local del_char = utils.get_char()
        if not del_char then
            return
        end

        local ins_char
        if utils.is_HTML(del_char) then
            ins_char = del_char
        else
            ins_char = utils.get_char()
        end
        if not ins_char then
            return
        end

        -- Get the new surrounding pair
        local delimiters
        if utils.is_HTML(del_char) then
            delimiters = html.get_tag()
        else
            delimiters = utils.get_delimiters(ins_char)
        end

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
