return {
    "customs/cpp-runner",
    dir = vim.fn.stdpath("config") .. "/lua/customs",
    opts = {},
    config = function(_, opts)
        require("customs.cpp-runner").setup(opts)
    end,
    ft = "cpp",
}
