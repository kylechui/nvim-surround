local buffer = require("nvim-surround.buffer")
local cache = require("nvim-surround.cache")
local config = require("nvim-surround.config")
local filetypes = require("nvim-surround.filetypes")
local queries = require("nvim-surround.queries")
local utils = require("nvim-surround.utils")
local nvim_surround = require("nvim-surround")

--- Create a selection where `first_pos` is equal to `last_pos`
--- Mainly use to give a selection to the caller function for the restoration of cursor
---@param position position
---@return selection
local function make_dummy_selection(position)
    return { first_pos = position, last_pos = { position[1], position[2] - 1 } }
end

-- Adjust text indentation based on an indent string value
---@param blocks_of_lines string[][] Lines from regions
---@param baseline_indent string The base indentation string to apply to indentless lines
---@param single_indent_repr string The value that represent an indent string
local function shift_leftwards_by_delta(blocks_of_lines, baseline_indent, single_indent_repr)
    for i, block in ipairs(blocks_of_lines) do
        for j, line in ipairs(block) do
            if i ~= 1 or j ~= 1 then
                -- First line from first region does not need indent as it will take the place of the
                -- delimiter start position
                if j == 1 then
                    -- The other first lines of regions will inherit the indentation from baseline_indent
                    block[j] = line:gsub("^", baseline_indent, 1)
                else
                    -- The remaining lines will get their indent cut by `single_indent_repr`
                    block[j] = line:gsub("^" .. single_indent_repr, "", 1)
                end
            end
        end
    end
end

-- Temporarily set the user indent_lines function to one that will shift the text
---@param user_indent_lines function
---@return function
local function shift_rightwards_by_shiftwidth(user_indent_lines)
    return function(start, stop)
        local cursor_pos = buffer.get_curpos()
        -- We do not need to shift the line containing the delimiter. Also, the next line
        -- does not get formatted well with the `:left` command
        for lnum = start + 2, stop do
            vim.cmd(lnum .. "left " .. vim.fn.indent(lnum) + vim.fn.shiftwidth())
        end

        vim.cmd(string.format("silent normal! %dG==", start + 1))
        buffer.set_curpos(cursor_pos)
        config.get_opts().indent_lines = user_indent_lines
    end
end

---@type add_func
local function add(object)
    local selection_start = buffer.get_mark("[")
    if selection_start == nil then
        return
    end

    ---@type delimiters_params
    local delimiters = filetypes[vim.bo.filetype][object .. "_delimiters"]()
    local cursor_pos = buffer.get_curpos()
    local user_opts = config.get_opts()
    local current_line_is_empty = buffer.get_line(cursor_pos[1]) == ""

    if filetypes[vim.bo.filetype].indentation_based then
        user_opts.indent_lines = shift_rightwards_by_shiftwidth(user_opts.indent_lines)

        local next_line_is_empty = buffer.get_line(buffer.get_mark("]")[1] + 1) == ""
        local end_delimiter_is_empty = delimiters.pair[2][1] == ""

        -- For languages like python, adding a surround would add a blank line at the end of the
        -- block. We want to do this only if there is not already a blank line
        if end_delimiter_is_empty and cache.normal.line_mode and next_line_is_empty then
            delimiters.pair[2] = {}
        end
    end

    if delimiters.placeholder_offset then
        buffer.mark_jump()
        -- Temporarily ignore the setting to force return to the start position
        -- so that we have a constant offset for the placeholder
        local user_move_cursor = user_opts.move_cursor
        user_opts.move_cursor = "begin"

        vim.defer_fn(function()
            user_opts.move_cursor = user_move_cursor
            if current_line_is_empty then
                -- This is needed as the cursor cannot move on an empty line
                vim.cmd.normal("_")
            end
            buffer.start_insert_and_move_to(delimiters.placeholder_offset)
        end, 0)

        return delimiters.pair
    end

    if user_opts.move_cursor then
        buffer.mark_jump()
        if current_line_is_empty then
            vim.defer_fn(function()
                vim.cmd.normal("_")
            end, 0)
        end
        return delimiters.pair
    end

    vim.defer_fn(function()
        ---@type offsets
        local offsets = { col_offset = 0, row_offset = 0 }

        if cache.normal.line_mode then
            local two_first_lines_indents = vim.iter.map(function(line)
                return line:match("^%s*")
            end, buffer.get_lines(selection_start[1], selection_start[1] + 1))

            offsets.row_offset = 1
            -- If we are on an empty line, the indent of the second line can be less than the surround's
            offsets.col_offset = math.max(#two_first_lines_indents[2] - #two_first_lines_indents[1], 0)
        else
            -- If inline, we shift by the offset of the left delimiter if cursor is on the surround's line
            offsets.col_offset = cursor_pos[1] == selection_start[1] and #delimiters.pair[1][1] or 0
        end

        buffer.set_curpos({ cursor_pos[1] + offsets.row_offset, cursor_pos[2] + offsets.col_offset })
    end, 0)

    return delimiters.pair
end

---@type find_func
local function find(object)
    ---@type selection?
    return queries.get_selection("@" .. object .. ".outer", "textobjects")
end

---@type delete_func
local function delete(object)
    ---@type selection?
    local selection = queries.get_selection("@" .. object .. ".outer", "textobjects")

    if selection == nil then
        return
    end

    local node = vim.treesitter.get_node({ pos = { selection.first_pos[1] - 1, selection.first_pos[2] - 1 } })

    if node == nil then
        return
    end

    local user_opts = config.get_opts()
    local cursor_pos = buffer.get_curpos()
    local node_selection = utils.as_selection({ node:range() })

    if cache.delete.line_mode then
        node_selection.first_pos[2] = 1
        node_selection.last_pos[2] = vim.fn.col({ node_selection.last_pos[1], "$" }) - 1
    end
    -- The next 3 commented lines could be restored to add a layer of rubustness by ensuring proper
    -- indentation since the formatting functions presupopse the indentation level is not off.

    -- vim.cmd(string.format("silent normal! %dG==", node_selection.first_pos[1] + 1))
    -- node = vim.treesitter.get_node({ pos = node_selection.first_pos })
    -- node_selection = utils.as_selection({ node:range() })
    local node_selection_origin = node_selection.first_pos
    ---@type regions
    local regions_to_keep = filetypes[vim.bo.filetype][object .. "_body"](node)
    local regions_to_keep_origin = regions_to_keep[1].first_pos
    local is_multiline = node_selection.first_pos[1] < node_selection.last_pos[1]
    local indentation_based = filetypes[vim.bo.filetype].indentation_based
    local blocks_of_texts_to_keep = {}
    local cursor_regions_relative_row = nil
    local previous_region_relative_row = -1

    for _, region in ipairs(regions_to_keep) do
        table.insert(blocks_of_texts_to_keep, buffer.get_text(region))

        -- This is use to restore the cursor position relatively to the remaining text
        -- Some "pairs" can span non-contiguous regions, like conditionals with else statements
        if not cursor_regions_relative_row and buffer.is_inside(cursor_pos, { left = region, right = region }) then
            cursor_regions_relative_row = previous_region_relative_row + (cursor_pos[1] - region.first_pos[1]) + 1
        end

        previous_region_relative_row = previous_region_relative_row + 1 + region.last_pos[1] - region.first_pos[1]
    end

    -- Manually craft an indentation brick
    if is_multiline and indentation_based then
        local two_first_lines = buffer.get_lines(node_selection.first_pos[1], node_selection.first_pos[1] + 2)
        local baseline_indent = two_first_lines[1]:match("^%s*")
        local single_indent = two_first_lines[2]:match("^%s*"):sub(#baseline_indent + 1)
        shift_leftwards_by_delta(blocks_of_texts_to_keep, baseline_indent, single_indent)
    end

    local texts_to_keep = vim.iter(blocks_of_texts_to_keep):flatten():totable()
    buffer.change_selection(node_selection, texts_to_keep)

    if is_multiline and not indentation_based then
        user_opts.indent_lines(node_selection_origin[1], node_selection_origin[1] + #texts_to_keep)
    end

    -- We restore the postion only if `move_cursor` is false and the cursor is standing
    -- inside one of the remaining regions
    if user_opts.move_cursor ~= "begin" and cursor_regions_relative_row then
        local user_move_cursor = user_opts.move_cursor
        user_opts.move_cursor = false
        local pos = { node_selection_origin[1] + cursor_regions_relative_row }

        -- We handle the cursor differently depending on if it's on the line which will
        -- replace the start position of the selection, or just a line that will get indented
        if cursor_pos[1] ~= regions_to_keep_origin[1] then
            pos[2] = cursor_pos[2] - (regions_to_keep_origin[2] - node_selection_origin[2])
        else
            pos[2] = node_selection.first_pos[2] + (cursor_pos[2] - regions_to_keep_origin[2])
        end

        nvim_surround.old_pos = pos
        vim.defer_fn(function()
            user_opts.move_cursor = user_move_cursor
        end, 0)
    end

    local dummy_selection = make_dummy_selection(node_selection_origin)
    return { left = dummy_selection, right = dummy_selection }
end

---@type offsets
local replacement_offsets = {}
---@type delete_func
local change_target = function(object)
    ---@type selection?
    local selection = queries.get_selection("@" .. object .. ".outer", "textobjects")
    local user_opts = config.get_opts()

    if not selection then
        return
    end

    local node = vim.treesitter.get_node({ pos = { selection.first_pos[1] - 1, selection.first_pos[2] }, bufnr = 0 })
    if not node then
        return
    end

    ---@type regions
    local specifiers = filetypes[vim.bo.filetype][object .. "_specifier"](node)

    if vim.tbl_isempty(specifiers) then
        return
    end

    ---@type selection
    local specifier

    -- concat region as contiguous
    if #specifiers > 1 then
        -- A specifier is contiguous, but can be the result of more than one region
        specifier = { first_pos = specifiers[1].first_pos, last_pos = specifiers[#specifiers].last_pos }
    else
        specifier = specifiers[1]
    end

    buffer.mark_jump()
    nvim_surround.old_pos = specifier.first_pos
    local user_move_cursor = user_opts.move_cursor
    user_opts.move_cursor = "begin"
    -- This is for the specifiers that are at eol; the offset is necessary to not have dangling space
    local is_eol = specifier.last_pos[2] == vim.fn.col({ specifier.last_pos[1], "$" }) - 1
    replacement_offsets = { col_offset = is_eol and 1 or 0 }
    vim.defer_fn(function()
        user_opts.move_cursor = user_move_cursor
    end, 0)

    -- A specifier does not have a pair
    return { left = make_dummy_selection(specifier.first_pos), right = specifier }
end

---@param object string TS object
---@return {target: user_delete, replacement: user_add}
local change = function(object)
    return {
        target = function()
            return change_target(object)
        end,
        replacement = function()
            vim.defer_fn(function()
                buffer.start_insert_and_move_to(replacement_offsets)
            end, 0)
            return { { "" }, { "" } }
        end,
    }
end

---@param object string TS object
---@return user_surround
local function make_surrounds(object)
    return {
        add = function()
            return add(object)
        end,
        find = function()
            return find(object)
        end,
        delete = function()
            return delete(object)
        end,
        change = change(object),
    }
end

---@type table<string, user_surround>
local treesitter_surrounds = {
    ["conditional"] = make_surrounds("conditional"),
    ["function"] = make_surrounds("function"),
    ["loop"] = make_surrounds("loop"),
}

return treesitter_surrounds
