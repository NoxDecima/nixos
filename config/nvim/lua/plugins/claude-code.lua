return {
  "greggh/claude-code.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("claude-code").setup({
      window = {
        position = "vertical botright",
        split_ratio = 0.4,
      },
    })
  end,
}
