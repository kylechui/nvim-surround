local config = require("nvim-surround.config")

local nvim_surround_lua = vim.api.nvim_create_augroup("NvimSurroundLua", {})
vim.api.nvim_create_autocmd("FileType", {
    pattern = "lua",
    callback = function()
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
    group = nvim_surround_lua,
})
