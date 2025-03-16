local M = {}
local Job

local vqd = nil
local buffer

function M.setup(opts)
	opts = opts or {}
	Job = require("plenary.job")
	if not Job then
		error("Failed to load plenary.job")
	end
	buffer = M.setup_buffer()
	vim.api.nvim_create_user_command("DuckAsk", function(call)
		M.send_message(call.args)
	end, {
		nargs = 1,
		desc = "Ask duckduckgo ai a question",
	})
end

function M.setup_buffer()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	vim.api.nvim_buf_set_keymap(buf, "n", "q", ":bd<CR>", { noremap = true, silent = true })
	return buf
end

function M.init_duck()
	local args = M.get_curl_args("x-vqd-accept: 1", nil, "https://duckduckgo.com/duckchat/v1/status")
	Job:new({
		command = "curl",
		args = args,
		cwd = ".",
		on_stdout = function(j, return_val)
			if return_val == 0 then
				vqd = j:result():match("x%-vqd%-4: ([^\r\n]+)")
			else
				print("failure in curl")
				print(return_val)
			end
		end,
		on_stderr = function(j, return_val)
			print(j:result())
		end,
	}):start()
end

function M.send_message(message)
	if vqd then
		local vqd_header = "x-vqd-4:" .. vqd
		local data = '{"messages": [{"content": "' .. message .. '", "role": "user"}],"model": "o3-mini"}'
		local args = M.get_curl_args(vqd_header, data, "https://duckduckgo.com/duckchat/v1/chat")
		Job:new({
			command = "curl",
			args = args,
			cwd = ".",
			on_stdout = function(j, return_val)
				if return_val == 0 then
					M.write_message_to_buffer(j:result())
				end
			end,
		}):start()
	end
	print("No VQD setting it....")
	M.init_duck()
end

function M.get_message(message)
	local message_objs = {}
	local complete_message = ""
	for line in string.gmatch(message, "[^\n]+") do
		if line:sub(1, 6) == "data: " then
			local json = line:sub(7)
			table.insert(message_objs, json)
		end
	end
	for _, message_part_obj in pairs(message_objs) do
		local success, message_part = pcall(vim.json.decode, message_part_obj)
		if success and message_part.message then
			complete_message = complete_message .. message_part.message
		end
	end
	return complete_message
end

function M.write_message_to_buffer(raw_message)
	local message = M.get_message(raw_message)
	local lines = {}
	for line in message:gmatch("([^\n]*)\n?") do
		table.insert(lines, line)
	end
	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
	local total_width = vim.o.columns
	local new_width = math.floor(total_width * 0.3)
	vim.cmd("vsplit")
	vim.api.nvim_set_current_buf(buffer)
	local new_win_id = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_width(new_win_id, new_width)
	vim.api.nvim_win_set_option(new_win_id, "wrap", true)
	vim.api.nvim_win_set_option(new_win_id, "linebreak", true)
end

function M.get_duck_headers(vqd_header)
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
		vqd_header,
		"Accept: text/event-stream",
	}
	return headers
end

function M.get_curl_args(vqd_header, data, endpoint)
	local args = { "-s", "-I" }
	if data then
		table.insert(args, "-d")
		table.insert(args, data)
	end
	local headers = M.get_duck_headers(vqd_header)
	for _, header in pairs(headers) do
		table.insert(args, "-H")
		table.insert(args, header)
	end
	table.insert(args, endpoint)
	return args
end

return M
