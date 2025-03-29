return {
	"mfussenegger/nvim-dap",
	recommended = true,
	desc = "Debugging support. Requires language specific adapters to be configured.",

	dependencies = {
		"rcarriga/nvim-dap-ui",
		-- virtual text for the debugger
		{
			"theHamsta/nvim-dap-virtual-text",
			opts = {},
		},
		{
			"jay-babu/mason-nvim-dap.nvim",
			opts = {
				ensure_installed = {
					"python",
				},
			},
		},
	},
	-- stylua: ignore
	keys = {
		{ "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
		{ "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
		{ "<leader>dc", function() require("dap").continue() end, desc = "Run/Continue" },
		{ "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
		{ "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
		{ "<leader>dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },
		{ "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
		{ "<leader>dj", function() require("dap").down() end, desc = "Down" },
		{ "<leader>dk", function() require("dap").up() end, desc = "Up" },
		{ "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
		{ "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
		{ "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
		{ "<leader>dP", function() require("dap").pause() end, desc = "Pause" },
		{ "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
		{ "<leader>ds", function() require("dap").session() end, desc = "Session" },
		{ "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
		{ "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
	},
	-- opts = {
	-- 	adapters = {
	-- 		python = {
	-- 			type = "executable",
	-- 			-- TODO: make it use the current virtual environment
	-- 			command = os.getenv("HOME") .. "/.virtualenvs/tools/bin/python",
	-- 			args = { "-m", "debugpy.adapter" },
	-- 		},
	-- 	},
	-- 	configurations = {
	-- 		python = {
	-- 			{
	-- 				type = "python",
	-- 				request = "launch",
	-- 				name = "Launch file",
	-- 				program = "${file}",
	-- 				pythonPath = function()
	-- 					-- TODO: make it work with venv
	-- 					return "/usr/bin/python"
	-- 				end,
	-- 			},
	-- 		},
	-- 	},
	-- },
	config = function()
		local dap = require("dap")
		-- Adding python debugger
		dap.adapters.python = {
			type = "executable",
			-- TODO: make it use the current virtual environment
			-- command = "python3", -- os.getenv("HOME") .. "/.virtualenvs/tools/bin/python",
			-- args = { "-m", "debugpy.adapter" },
			command = "debugpy",
		}
		dap.configurations.python = {
			{
				type = "python",
				request = "launch",
				name = "Launch file",
				program = "${file}",
				pythonPath = function()
					-- TODO: make it work with venv
					return "/usr/bin/python"
				end,
			},
		}
		-- require("dap.ext.vscode").load_launchjs(path, type_to_filetypes)(nil, {})
	end,
}
