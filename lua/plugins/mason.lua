return {
    "mason-org/mason-lspconfig.nvim",
    opts = {
        ensure_installed = {"clangd", "marksman", "pyright", "lua_ls", "texlab", "cmake", "ts_ls"},
    },
    dependencies = {
        { "mason-org/mason.nvim", opts = {
            ui = {
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗"
                }
            }}
        },
        "neovim/nvim-lspconfig",
    },
}
