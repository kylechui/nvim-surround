-- https://github.com/Azganoth/tree-sitter-lua/blob/master/docs/extended_bnf.md

local ts = require("nvim-surround.treesitter")

---@type delimiters_params_func
local function get_function_delimiters()
    return { placeholder_offset = nil, pair = { { "function() " }, { " end" } } }
end

---@type regions_func
local function get_function_specifier(function_node)
    return ts.get_regions(function_node, { fields = { "name" }, types = {} }, { capture_extra = false })
end

---@type regions_func
local function get_function_body(function_node)
    return ts.get_regions(function_node, { fields = { "body" }, types = {} })
end

---@type delimiters_params_func
local function get_loop_delimiters()
    return { placeholder_offset = { col_offset = 4 }, pair = { { "for  do " }, { " end" } } }
end

---@type regions_func
local function get_loop_specifier(loop_node)
    return ts.get_regions(loop_node, { fields = { "clause", "condition" }, types = {} }, { capture_extra = false })
end

---@type regions_func
local function get_loop_body(loop_node)
    return ts.get_regions(loop_node, { fields = { "body" }, types = {} })
end

---@type delimiters_params_func
local function get_conditional_delimiters()
    return { placeholder_offset = { col_offset = 3 }, pair = { { "if  then " }, { " end" } } }
end

---@type regions_func
local function get_conditional_specifier(conditional_node)
    return ts.get_regions(conditional_node, { fields = { "condition" }, types = {} }, { capture_extra = false })
end

---@type regions_func
local function get_conditional_body(conditional_node)
    return ts.get_regions(
        conditional_node,
        { fields = { "consequence", "body" }, types = {} },
        { recurses = { fields = { "alternative" }, types = {} } }
    )
end

---@type filetype_spec
local lua_spec = {
    function_delimiters = get_function_delimiters,
    conditional_delimiters = get_conditional_delimiters,
    loop_delimiters = get_loop_delimiters,
    function_body = get_function_body,
    conditional_body = get_conditional_body,
    loop_body = get_loop_body,
    function_specifier = get_function_specifier,
    conditional_specifier = get_conditional_specifier,
    loop_specifier = get_loop_specifier,
}

return lua_spec
