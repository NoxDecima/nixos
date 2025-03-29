return { -- amongst your other plugins
	"akinsho/toggleterm.nvim",
	config = true,
	cmd = "ToggleTerm",
	keys = {
		{
			"<C-/>",
			function()
				require("toggleterm").toggle(2, 0, vim.loop.cwd(), "horizontal", "Quick Terminal")
			end,
			desc = "Toggle terminal",
		},
		{
			"<leader>gt",
			function()
				require("toggleterm").toggle(3, 0, vim.loop.cwd(), "tab", "Terminal")
			end,
			desc = "[G]oto [T]erminal (Tab)",
		},
	},
	opts = {
		open_mapping = [[<C-/>]],
		-- direction = "float",
		shade_filetypes = {},
		hide_numbers = true,
		insert_mappings = true,
		terminal_mappings = true,
		start_in_insert = true,
		close_on_exit = true,
	},
}
