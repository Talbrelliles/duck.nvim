local M = {}
local vqd

function M.init_duck()
	local args = { "curl", "-s", "-I" }
	local headers = get_duck_headers("x-vqd-accept: 1")
	for _, header in pairs(headers) do
		table.insert(args, "-H")
		table.insert(args, header)
	end
	table.insert(args, "https://duckduckgo.com/duckchat/v1/status")
	local result = vim.fn.system(args)
	local temp_vqd = result:match("x%-vqd%-4: ([^\r\n]+)")
	return temp_vqd
end

function M.get_vqd()
	return vqd
end

function M.send_message(message)
	if vqd == nil then
		vqd = M.init_duck()
	else
		print("running")
	end
	local headers = get_duck_headers("x-vqd-4:" .. vqd)
	local data = '{"messages": [{"content": "' .. message .. '", "role": "user"}],"model": "o3-mini"}'
	local args = { "curl", "-s", "-d", data }
	for _, header in pairs(headers) do
		table.insert(args, "-H")
		table.insert(args, header)
	end
	table.insert(args, "https://duckduckgo.com/duckchat/v1/chat")
	local result = vim.fn.system(args)
	local response = M.parse_json(result)
end

function M.get_messages(data)
	local json_objects = {}
	for line in string.gmatch(data, "[^\n]+") do
		if line:sub(1, 6) == "data: " then
			local json = line:sub(7)
			table.insert(json_objects, json)
		end
	end
	return json_objects
end

function M.parse_json(data)
	local message_str = ""
	local messages = M.get_messages(data)
	for _, message in pairs(messages) do
		local success, complete_message = pcall(vim.json.decode, message)
		if success and complete_message.message then
			message_str = message_str .. complete_message.message
		end
	end
	M.buffer_tests(message_str)
end

function get_duck_headers(vqd_val)
	local headers = {
		"Connection: keep-alive",
		"Sec-Fetch-Site: same-origin",
		"User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:127.0) Gecko/20100101 Firefox/127.0",
		"Accept-Encoding: gzip, deflate, br",
		"Cookie: dcm=1",
		"Sec-Fetch-Mode: cors",
		"Content-Type: application/json",
		"TE: trailers",
		"Sec-Fetch-Dest: empty",
		"Referer: https://duckduckgo.com/",
		"Origin: https://duckduckgo.com",
		"Cache-Control: no-store",
		"Accept-Language: en-US;q=0.7,en;q=0.3",
		"Pragma: no-cache",
		vqd_val,
		"Accept: text/event-stream",
	}
	return headers
end

function M.curl_test()
	M.send_message()
end

function M.buffer_tests(input)
	local lines = {}
	if type(input) == "table" then
		lines = input
	else
		for line in input:gmatch("([^\n]*)\n?") do
			table.insert(lines, line)
		end
	end
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	local total_width = vim.o.columns
	local new_width = math.floor(total_width * 0.3)
	vim.cmd("vsplit")
	vim.api.nvim_set_current_buf(buf)
	local new_win_id = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_width(new_win_id, new_width)
	vim.api.nvim_win_set_option(new_win_id, "wrap", true)
	vim.api.nvim_win_set_option(new_win_id, "linebreak", true)
	vim.api.nvim_buf_set_keymap(buf, "n", "q", ":bd<CR>", { noremap = true, silent = true })
end

function M.setup(opts)
	-- TODO: Default keybindings
	opts = opts or {}
	vim.api.nvim_create_user_command("DuckAsk", function(call)
		M.send_message(call.args)
	end, {
		nargs = 1,
		desc = "Ask duckduckgo ai a question",
	})
end

return M
