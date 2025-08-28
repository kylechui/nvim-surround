local M = {}

-- Some compatibility shims over the builtin `vim.treesitter` functions
local get_query = vim.treesitter.get_query or vim.treesitter.query.get

--- Returns the language name to be used when loading a parser for {filetype}.
---
--- If no language has been explicitly registered via |vim.treesitter.language.register()|,
--- default to {filetype}. For composite filetypes like `html.glimmer`, only the main filetype is
--- returned.
---
--- NOTE: This is a copy-pasted implementation from the Neovim v0.11 source code; it is to avoid nil-dereferencing
---       issues on older versions of Neovim.
--- @param filetype string
--- @return string|nil
local get_lang = function(filetype)
    if filetype == "" then
        return nil
    end

    ---@type table<string,string>
    local ft_to_lang = {
        help = "vimdoc",
        checkhealth = "vimdoc",
    }

    if ft_to_lang[filetype] then
        return ft_to_lang[filetype]
    end
    -- for subfiletypes like html.glimmer use only "main" filetype
    filetype = vim.split(filetype, ".", { plain = true })[1]
    return ft_to_lang[filetype] or filetype
end

-- Retrieves the node that corresponds exactly to a given selection.
---@param selection selection The given selection.
---@return TSNode|nil @The corresponding node.
---@nodiscard
M.get_node = function(selection)
    local treesitter = require("nvim-surround.treesitter")

    local root = treesitter.get_root()
    if root == nil then
        return nil
    end
    -- DFS through the tree and find all nodes that have the given type
    local stack = { root }
    while #stack > 0 do
        local cur = stack[#stack]
        -- If the current node's range is equal to the desired selection, return the node
        if vim.deep_equal(selection, treesitter.get_node_selection(cur)) then
            return cur
        end
        -- Pop off of the stack
        stack[#stack] = nil
        -- Add the current node's children to the stack
        for child in cur:iter_children() do
            stack[#stack + 1] = child
        end
    end
    return nil
end

-- Finds the nearest selection of a given query capture and its source.
---@param capture string The capture to be retrieved.
---@param type string The type of query to get the capture from.
---@return selection|nil @The selection of the capture.
---@nodiscard
M.get_selection = function(capture, type)
    local utils = require("nvim-surround.utils")
    local treesitter = require("nvim-surround.treesitter")

    local root = treesitter.get_root()
    local language = get_lang(vim.bo.filetype)
    if root == nil or language == nil then
        return nil
    end

    local query = get_query(language, type)
    if query == nil then
        return nil
    end

    -- Get a list of all selections in the query that match the capture group
    local selections_list = {}
    for id, node in query:iter_captures(root, 0) do
        local name = query.captures[id]
        -- TODO: Figure out why sometimes the name from a capture group like `@call.outer` is missing the `@`
        if capture:sub(1, 1) == "@" then
            capture = capture:sub(1 - capture:len())
        end

        if name == capture then
            local selection = treesitter.get_node_selection(node)

            local range =
                { selection.first_pos[1], selection.first_pos[2], selection.last_pos[1], selection.last_pos[2] }
            selections_list[#selections_list + 1] = {
                left = {
                    first_pos = { range[1], range[2] },
                    last_pos = { range[3], range[4] },
                },
                right = {
                    first_pos = { range[3], range[4] + 1 },
                    last_pos = { range[3], range[4] },
                },
            }
        end
    end

    -- Filter out the best pair of selections from the list
    local best_selections = utils.filter_selections_list(selections_list)
    return best_selections
        and {
            first_pos = best_selections.left.first_pos,
            last_pos = best_selections.right.last_pos,
        }
end

return M
