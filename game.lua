
local addon = LibStub('AceAddon-3.0'):GetAddon('2048')
local game  = addon:NewModule('game')

local min_grid_size     = 4	-- minimum grid size
local max_grid_size     = 8	-- maximum grid size
local default_grid_size = 4	-- grid size if not specified
local start_tiles       = 2	-- # of tiles on game startup

------------------------------------------------
function game:OnInitialize()
end

------------------------------------------------
function game:OnEnable()
end

------------------------------------------------
-- Start a new game
function game:new_game(size, state)

	-- Continue an old game or start a new one?
	if type(state) == 'table' then
		self.score = state.score or 0
		self.best  = state.best or 0
		self.over  = state.over
		self.won   = state.win
		self.cont  = state.cont

		self.size  = state.size
		self.grid  = wipe(self.grid or {})

		-- Recreate the grid matrix
		for row = 0, self.size + 1 do
			self.grid[row] = {}
			for col = 0, self.size + 1 do
				self.grid[row][col] = {
					col = col,
					row = row,
				}

				-- Set value to -1 for 'out of bounds' cells
				if row < 1 or row > self.size or col < 1 or col > self.size then
					self.grid[row][col].value = -1
				else
					self.grid[row][col].value = state.grid[row][col]	-- State only store values
				end
			end
		end
	else
		self.score = 0
		self.best  = 0
		self.over  = false
		self.won   = false
		self.cont  = false

		-- Set the grid size
		self.size = size or default_grid_size
		if self.size < min_grid_size then
			self.size = min_grid_size
		elseif self.size > max_grid_size then
			self.size = max_grid_size
		end

		-- Create the grid matrix
		self.grid = wipe(self.grid or {})
		for row = 0, self.size + 1 do
			self.grid[row] = {}
			for col = 0, self.size + 1 do
				self.grid[row][col] = {
					col = col,
					row = row,
					value = 0,
				}
				-- Set value to -1 for 'out of bounds' cells
				if row < 1 or row > self.size or col < 1 or col > self.size then
					self.grid[row][col].value = -1
				end
			end
		end

		-- Add a few cells to start with
		for i = 1, start_tiles do
			self:add_random_cell()
		end
	end
end

------------------------------------------------
-- Save current game state
function game:save_state(state)

	state.score = self.score
	state.best  = self.best
	state.over  = self.over
	state.win   = self.won
	state.cont  = self.cont

	state.size  = self.size
	state.grid   = {}
	for row = 1, self.size do
		state.grid[row] = {}
		for col = 1, self.size do
			state.grid[row][col] = self.grid[row][col]['value']	-- Only save values
		end
	end
end

------------------------------------------------
-- Call function on every cell
function game:for_each_cell(callback)
	for row = 1, self.size do
		for col = 1, self.size do
			callback(row, col, self.grid[row][col])
		end
	end
end

------------------------------------------------
-- Return the cell at (row,col)
function game:get_cell(row, col)
	return self.grid[row][col]
end

------------------------------------------------
-- Return the value of the cell at (row,col)
function game:get_cell_value(row, col)
	return self.grid[row][col]['value']
end

------------------------------------------------
-- Set the value of the cell at (row,col)
function game:set_cell_value(row, col, value)
	self.grid[row][col]['value'] = value
end

------------------------------------------------
-- Find all empty cells
local _empty = {}
function game:get_empty_cells()

	wipe(_empty)
	for row = 1, self.size do
		for col = 1, self.size do
			if self.grid[row][col]['value'] == 0 then
				table.insert(_empty, { row = row, col = col } )
			end
		end
	end
	return _empty
end

------------------------------------------------
-- Set a random cell to a random value
function game:add_random_cell()

	-- Collect and count empty cells
	local empty = self:get_empty_cells()

	if #empty > 0 then
		local random_cell  = math.ceil(math.random() * #empty)
		local random_value = (math.random() < 0.9) and 2 or 4

		self:set_cell_value(empty[random_cell].row, empty[random_cell].col, random_value)
		return true
	end
	return false
end

------------------------------------------------
-- Update the scores
function game:add_score(n)
	self.score = self.score + n
	if self.score > self.best then
		self.best = self.score
	end
end

------------------------------------------------
-- Return the scores
function game:get_score()
	return self.score, self.best
end

------------------------------------------------
-- Check if the game is terminated
function game:is_terminated()
	return self.over or (self.won and not self.cont)
end

------------------------------------------------
-- Check if the game is won
function game:is_won()
	return self.won and not self.cont
end

------------------------------------------------
-- Check if the game is over
function game:is_over()
	return self.over
end

------------------------------------------------
-- Continue playing
function game:keep_playing()
	self.cont = true
end

-----------------------------------------------
-- Check if further moves are possible
function game:moves_available()

	for row = 1, self.size do
		for col = 1, self.size do
			local cell  = self:get_cell_value(row, col)
			local right = self:get_cell_value(row, col + 1)
			local below = self:get_cell_value(row + 1, col)

			-- Only check right and down as they imply left and up, respectively
			if right == 0 or right == cell or
			   below == 0 or below == cell then
				return true
			end
		end
	end
	return false
end

-----------------------------------------------
-- Move tiles on the grid in the specified direction
local _moves = {}
function game:move_cells(direction)

	-- Find the farthest destination for a cell in the given direction
	local function find_dest(cell, row_delta, col_delta)

		local dest = self.grid[cell.row + row_delta][cell.col + col_delta]
		while dest.value == 0 do
			-- Destination is empty, try further
			dest = self.grid[dest.row + row_delta][dest.col + col_delta]
		end

		if (dest.value == cell.value) and not cell.merged and not dest.merged then
			-- We can merge with this cell but only if neither cell and dest were already merged
			return dest
		end

		-- We either reached out of bounds or we are blocked by another cell
		-- In any case, return the previous cell
		return self.grid[dest.row - row_delta][dest.col - col_delta]
	end

	-- Move a cell to its destination
	local function move_cell(cell, dest)
		if not (dest.row == cell.row and dest.col == cell.col) then
			local merge = dest.value == cell.value

			dest.value  = dest.value  + cell.value	-- dest.value is either 0 or same as cell.value
			dest.moved  = true
			dest.merged = merge
			dest.p_row = cell.row
			dest.p_col = cell.col
			cell.value  = 0
			cell.moved = false

			if merge then
				self:add_score(dest.value)

				-- The mighty 2048 tile?
				self.won = (dest.value == 2048) and true or false
			end

			table.insert(_moves, dest)
			return true
		end
		return false
	end


	wipe(_moves)
	if not self:is_terminated() then

		-- 1) Save all cells positions and remove move/merge info
		self:for_each_cell(function(row, col, cell)
			cell.row    = row
			cell.col    = col
			cell.moved  = false
			cell.merged = false
			cell.p_row  = row
			cell.p_col  = col
		end)

		--- 2) Traverse the grid in the right direction
		local source
		if direction == 'UP' then
			for col = 1, self.size do
				for row = 2, self.size do			-- from top to bottom, skipping row #1 since it can't move up
					source = self.grid[row][col]
					if source.value > 0 then
						move_cell(source, find_dest(source, -1, 0))
					end
				end
			end
		elseif direction == 'DOWN' then
			for col = 1, self.size do
				for row = self.size-1, 1, -1 do		-- from bottom to top, skipping last row since it can't move down
					source = self.grid[row][col]
					if source.value > 0 then
						move_cell(source, find_dest(source, 1, 0))
					end
				end
			end
		elseif direction == 'LEFT' then
			for row = 1, self.size do
				for col = 2, self.size do			-- from left to right, skipping col #1 since it can't move left
					source = self.grid[row][col]
					if source.value > 0 then
						move_cell(source, find_dest(source, 0, -1))
					end
				end
			end
		elseif direction == 'RIGHT' then
			for row = 1, self.size do
				for col = self.size-1, 1, -1 do		-- from right to left, skipping last col since it can't move right
					source = self.grid[row][col]
					if source.value > 0 then
						move_cell(source, find_dest(source, 0, 1))
					end
				end
			end
		end

		-- Add a new cell
		if #_moves > 0 then
			self:add_random_cell()

			-- Game over?
			self.over = not self:moves_available()
		end
	end

	return _moves
end
