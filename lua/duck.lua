local M = {}

function M.init_duck()
	local curl_cmd = {
		"curl",
		"-I",
		"-s",
		"-o",
		"/dev/null",
		"-w",
		"%header{x-vqd-4}",
		"https://duckduckgo.com/duckchat/v1/status",
		"|",
		"grep",
		'"Content-Type:"',
		"|",
		"awk",
		"'{print $2}'",
	}

	-- curl -I -s -o /dev/null -w '%header{etag}' https://example.com/

	local headers = get_headers(true, "")
	for _, header in ipairs(headers) do
		table.insert(curl_cmd, 3, header)
	end

	local result = vim.fn.system(curl_cmd)
	if vim.v.shell_error == 0 then
		print("command succeeded with " .. result)
	else
		print("failed")
	end
end

function get_headers(is_setup, vqd)
	local headers = {
		'-H " User-Agent : Mozilla/5.0 (X11; Linux x86_64; rv:127.0) Gecko/20100101 Firefox/127.0"',
		'-H " Accept : text/event-stream"',
		'-H " Accept-Language : en-US;q=0.7,en;q=0.3"',
		'-H " Accept-Encoding : gzip, deflate, br"',
		'-H " Referer : https://duckduckgo.com/"',
		'-H " Content-Type : application/json"',
		'-H " Origin : https://duckduckgo.com"',
		'-H " Connection : keep-alive"',
		'-H " Cookie : dcm=1"',
		'-H " Sec-Fetch-Dest : empty"',
		'-H " Sec-Fetch-Mode : cors"',
		'-H " Sec-Fetch-Site : same-origin"',
		'-H " Pragma : no-cache"',
		'-H " TE : trailers"',
		'-H " Cache-Control : no-store"',
	}
	if is_setup == true then
		table.insert(headers, '-H " x-vqd-accept : 1"')
	else
		table.insert(headers, '-H " x-vqd-4 :' .. vqd .. '"')
	end
	return headers
end

function M.setup(opts)
	-- TODO: Default keybindings
	opts = opts or {}
	vim.api.nvim_create_user_command("HelloWorld", M.init_duck, {})
	local keymap = opts.keymap or "<leader>hw"

	vim.keymap.set("n", keymap, M.init_duck, {
		desc = "Call duck headers again 3456",
		silent = true,
	})
end

return M
