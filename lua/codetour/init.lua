local M = {}

local tours = {}
local current_tour = nil
local current_step = 1
local display_mode = "inline" -- Default: "inline" (bottom buffer) or "popup"

-- Function to show the step in a bottom buffer
local function show_bottom_buffer(message)
	-- Create a scratch buffer
	local buf = vim.api.nvim_create_buf(false, true)

	-- Set buffer lines
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { message })

	-- Open buffer as a horizontal split
	vim.api.nvim_open_win(buf, false, {
		relative = "editor",
		width = vim.o.columns,
		height = 4, -- Adjust height as needed
		row = vim.o.lines - 5, -- Position it at the bottom
		col = 0,
		style = "minimal",
		border = "none",
	})
end

-- Function to create a floating window (popup)
local function show_popup(message)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { message })

	local width = math.ceil(vim.o.columns * 0.5)
	local height = 3
	local row = math.ceil((vim.o.lines - height) / 2)
	local col = math.ceil((vim.o.columns - width) / 2)

	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	})
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
	vim.cmd("edit " .. step.file)
	vim.api.nvim_win_set_cursor(0, { step.line, 0 })

	local message = "Step " .. current_step .. ": " .. step.description

	if display_mode == "popup" then
		show_popup(message)
	else
		show_bottom_buffer(message)
	end
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

-- Set display mode
function M.set_display_mode(mode)
	if mode == "popup" or mode == "inline" then
		display_mode = mode
		print("CodeTour display mode set to: " .. mode)
	else
		print("Invalid mode. Use 'popup' or 'inline'.")
	end
end

-- Setup commands
function M.setup()
	vim.api.nvim_create_user_command("CodeTourLoad", function(opts)
		M.load_tour(opts.args)
	end, { nargs = 1 })

	vim.api.nvim_create_user_command("CodeTourNext", M.next_step, {})
	vim.api.nvim_create_user_command("CodeTourPrev", M.prev_step, {})

	-- Allow setting display mode
	vim.api.nvim_create_user_command("CodeTourMode", function(opts)
		M.set_display_mode(opts.args)
	end, { nargs = 1 })
end

return M
