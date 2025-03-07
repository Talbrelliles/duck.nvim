local M = {}

function M.say_hello()
	print("Hello from duck.lua")
end

function M.setup(opts)
	-- TODO: Default keybindings
	opts = opts or {}
	vim.api.nvim_create_user_command("HelloWorld", M.say_hello, {})
	local keymap = opts.keymap or "<leader>hw"

	vim.keymap.set("n", keymap, M.say_hello, {
		desc = "Say hello from duck",
		silent = true,
	})
end

return M
