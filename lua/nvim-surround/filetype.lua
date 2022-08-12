local config = require("nvim-surround.config")

local M = {}

M.nvim_surround_filetype_setup = vim.api.nvim_create_augroup("NvimSurroundFileTypeSetup", { clear = true })

M.filetype_configurations = {
    c = function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["f"] = {
                    find = function()
                        return config.get_selection({ node = "call_expression" })
                    end,
                },
            },
        })
    end,
    cs = function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["f"] = {
                    find = function()
                        return config.get_selection({ node = "invocation_expression" })
                    end,
                },
            },
        })
    end,
    cpp = function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["f"] = {
                    find = function()
                        return config.get_selection({ node = "call_expression" })
                    end,
                },
            },
        })
    end,
    go = function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["f"] = {
                    find = function()
                        return config.get_selection({ node = "call_expression" })
                    end,
                },
            },
        })
    end,
    java = function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["f"] = {
                    find = function()
                        return config.get_selection({ node = "method_invocation" })
                    end,
                },
            },
        })
    end,
    javascript = function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["f"] = {
                    find = function()
                        return config.get_selection({ node = "call_expression" })
                    end,
                },
            },
        })
    end,
    lua = function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["f"] = {
                    find = function()
                        return config.get_selection({ node = "function_call" })
                    end,
                    delete = "^([^=%s]+%()().-(%))()$",
                },
            },
        })
    end,
    python = function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["f"] = {
                    find = function()
                        return config.get_selection({ node = "call" })
                    end,
                },
            },
        })
    end,
    r = function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["f"] = {
                    find = function()
                        return config.get_selection({ node = "call" })
                    end,
                },
            },
        })
    end,
    ruby = function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["f"] = {
                    find = function()
                        return config.get_selection({ node = "call" })
                    end,
                },
            },
        })
    end,
    rust = function() -- TODO: Try to add support for macros?
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["f"] = {
                    find = function()
                        return config.get_selection({ node = "call_expression" })
                    end,
                },
            },
        })
    end,
    typescriptreact = function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["t"] = {
                    find = function()
                        return config.get_selection({ node = "jsx_element" })
                    end,
                },
                ["T"] = {
                    find = function()
                        return config.get_selection({ node = "jsx_element" })
                    end,
                },
            },
        })
    end,
    vim = function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["f"] = {
                    find = function()
                        return config.get_selection({ node = "call_expression" })
                    end,
                },
            },
        })
    end,
}

M.setup = function()
    vim.api.nvim_create_autocmd("FileType", {
        pattern = vim.tbl_keys(M.filetype_configurations),
        callback = function()
            M.filetype_configurations[vim.bo.filetype]()
        end,
        group = M.nvim_surround_filetype_setup,
    })
end

return M
