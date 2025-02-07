local M = {}

local tours = {}
local current_tour = nil
local current_step = 1
local hint_buf = nil -- Buffer to store the hint window
local hint_win = nil -- Window handle for easy closing

-- Function to create a full-width floating buffer below the indicated line
local function show_hint_below_cursor(message, line)
	-- Close previous hint buffer if it exists
	if hint_win and vim.api.nvim_win_is_valid(hint_win) then
		vim.api.nvim_win_close(hint_win, true)
	end

	-- Create a scratch buffer for the hint
	hint_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(hint_buf, 0, -1, false, vim.split(message, "\n"))

	-- Get current window dimensions
	local win_width = vim.api.nvim_win_get_width(0)

	-- Position the buffer below the indicated line, default to top of file if no line specified
	hint_win = vim.api.nvim_open_win(hint_buf, false, {
		relative = "win",
		width = win_width,
		height = 3, -- Adjust for readability
		row = (line and line + 1) or 1, -- Position at line+1 or top of file
		col = 0,
		style = "minimal",
		border = "rounded",
	})
end

-- Function to open a temporary buffer with the description if no file exists
local function open_temp_buffer(message)
	-- Create a new full-screen buffer
	vim.cmd("enew") -- Open a new unnamed buffer
	local buf = vim.api.nvim_get_current_buf()

	-- Set buffer options using vim.bo
	vim.bo[buf].buftype = "nofile" -- No file association
	vim.bo[buf].bufhidden = "wipe" -- Auto-remove on close
	vim.bo[buf].swapfile = false -- No swap file

	-- Apply the same hint style
	show_hint_below_cursor(message, 1) -- Show at the top of the buffer
end

-- Apply buffer-local keybindings when a tour starts
local function set_tour_keymaps(bufnr)
	local opts = { noremap = true, silent = true }
	vim.api.nvim_buf_set_keymap(bufnr, "n", "<Leader>tn", ":CodeTourNext<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "<Leader>tp", ":CodeTourPrev<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "<Leader>te", ":lua require('codetour').exit_tour()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "<Leader>th", ":lua require('codetour').hide_hint()<CR>", opts)
end

-- Load a tour from a JSON file
function M.load_tour(tour_file)
	local file = io.open(tour_file, "r")
	if not file then
		print("Failed to load tour: " .. tour_file)
		return
	end
	local content = file:read("*a")
	file:close()
	tours[tour_file] = vim.fn.json_decode(content)
	current_tour = tours[tour_file]
	current_step = 1
	M.show_step()
end

-- Show the current step
function M.show_step()
	if not current_tour or #current_tour.steps == 0 then
		print("No tour loaded or no steps available.")
		return
	end

	local step = current_tour.steps[current_step]
	if step.file and step.file ~= "" then
		vim.cmd("edit " .. step.file)
		vim.api.nvim_win_set_cursor(0, { step.line or 1, 0 })
		local message = "Step " .. current_step .. ": " .. step.description
		show_hint_below_cursor(message, step.line)
	else
		open_temp_buffer("Step " .. current_step .. ": " .. step.description)
	end
	set_tour_keymaps(0)
end

-- Function to hide the hint window
function M.hide_hint()
	if hint_win and vim.api.nvim_win_is_valid(hint_win) then
		vim.api.nvim_win_close(hint_win, true)
	end
end

-- Function to exit the tour (clears the tour state)
function M.exit_tour()
	current_tour = nil
	current_step = 1
	M.hide_hint()
	print("Exited CodeTour.")
end

-- Navigate to the next step
function M.next_step()
	if current_tour and current_step < #current_tour.steps then
		current_step = current_step + 1
		M.show_step()
	else
		print("End of tour.")
	end
end

-- Navigate to the previous step
function M.prev_step()
	if current_tour and current_step > 1 then
		current_step = current_step - 1
		M.show_step()
	else
		print("Start of tour.")
	end
end

-- Setup commands
function M.setup()
	vim.api.nvim_create_user_command("CodeTourLoad", function(opts)
		M.load_tour(opts.fargs[1])
	end, { nargs = 1, complete = "file" })
	vim.api.nvim_create_user_command("CodeTourNext", M.next_step, {})
	vim.api.nvim_create_user_command("CodeTourPrev", M.prev_step, {})
	vim.api.nvim_create_user_command("CodeTourExit", M.exit_tour, {})
	vim.api.nvim_create_user_command("CodeTourHideHint", M.hide_hint, {})
end

return M
