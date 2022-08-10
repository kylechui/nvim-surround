local config = require("nvim-surround.config")

local M = {}

M.nvim_surround_filetype_setup = vim.api.nvim_create_augroup("NvimSurroundFileTypeSetup", { clear = true })

M.language_setups = {
    cpp = function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["f"] = {
                    add = function()
                        local result = config.get_input("Enter the function name: ")
                        if result then
                            return { { result .. "(" }, { ")" } }
                        end
                    end,
                    find = function()
                        return config.get_selection({ node = "call_expression" })
                    end,
                    delete = "^([^=%s]+%()().-(%))()$",
                    change = {
                        target = "^.-([%w_]+)()%b()()()$",
                        replacement = function()
                            local result = config.get_input("Enter the function name: ")
                            if result then
                                return { { result }, { "" } }
                            end
                        end,
                    },
                },
            },
        })
    end,
    lua = function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["f"] = {
                    add = function()
                        local result = config.get_input("Enter the function name: ")
                        if result then
                            return { { result .. "(" }, { ")" } }
                        end
                    end,
                    find = function()
                        return config.get_selection({ node = "function_call" })
                    end,
                    delete = "^([^=%s]+%()().-(%))()$",
                    change = {
                        target = "^.-([%w_]+)()%b()()()$",
                        replacement = function()
                            local result = config.get_input("Enter the function name: ")
                            if result then
                                return { { result }, { "" } }
                            end
                        end,
                    },
                },
            },
        })
    end,
    python = function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["f"] = {
                    add = function()
                        local result = config.get_input("Enter the function name: ")
                        if result then
                            return { { result .. "(" }, { ")" } }
                        end
                    end,
                    find = function()
                        return config.get_selection({ node = "call" })
                    end,
                    delete = "^([^=%s]+%()().-(%))()$",
                    change = {
                        target = "^.-([%w_]+)()%b()()()$",
                        replacement = function()
                            local result = config.get_input("Enter the function name: ")
                            if result then
                                return { { result }, { "" } }
                            end
                        end,
                    },
                },
            },
        })
    end,
    typescriptreact = function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["t"] = {
                    add = function()
                        local input = config.get_input("Enter the HTML tag: ")
                        if input then
                            local element = input:match("^<?([^%s>]*)")
                            local attributes = input:match("^<?[^%s>]*%s+(.-)>?$")

                            local open = attributes and element .. " " .. attributes or element
                            local close = element

                            return { { "<" .. open .. ">" }, { "</" .. close .. ">" } }
                        end
                    end,
                    find = function()
                        return config.get_selection({ node = "jsx_element" })
                    end,
                    delete = "^(%b<>)().-(%b<>)()$",
                    change = {
                        target = "^<([^%s<>]*)().-([^/]*)()>$",
                        replacement = function()
                            local input = config.get_input("Enter the HTML tag: ")
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
            },
        })
    end,
}

M.setup = function(language)
    if M.language_setups[language] then
        vim.api.nvim_create_autocmd("FileType", {
            pattern = language,
            callback = M.language_setups[language],
            group = M.nvim_surround_filetype_setup,
        })
    end
end

return M
