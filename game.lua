
local addon = LibStub('AceAddon-3.0'):GetAddon('2048')
local game  = addon:NewModule('game')

local grid_size         = 4	-- actuel gris size
local start_tiles       = 2	-- # of tiles on game startup

------------------------------------------------
-- Initialize the grid
------------------------------------------------
function game:OnInitialize()

	self.size = grid_size
	self.grid = {}

	-- Initialize out of bounds cells to -1
	for row = 0, self.size + 1 do
		self.grid[row] = {}
		for col = 0, self.size + 1 do
			self.grid[row][col] = {
				row = row,
				col = col,
				val = (row < 1 or row > self.size or col < 1 or col > self.size) and -1 or 0
			}
		end
	end
end

------------------------------------------------
-- Restore a saved game -- used at addon startup
------------------------------------------------
function game:restore_game(state)

	if #state.grid > 0 then
		-- We have some data to start with
		self.best  = state.best
		self.score = state.score
		self.moves = state.moves
		self.over  = state.over
		self.won   = state.won
		self.cont  = state.cont

		for row = 1, self.size do
			for col = 1, self.size do
				self.grid[row][col].val = state.grid[row][col]
			end
		end
	else
		-- Just start a new game
		self:new_game()
	end
end

------------------------------------------------
-- Start a brand new game
------------------------------------------------
function game:new_game()

	self.best  = self.best or 0
	self.score = 0
	self.moves = 0
	self.over  = false
	self.won   = false
	self.cont  = false

	for row = 1, self.size do
		for col = 1, self.size do
			self.grid[row][col].val = 0
		end
	end

	-- Add a few cells to start with
	for i = 1, start_tiles do
		self:add_random_cell()
	end
end

------------------------------------------------
-- Save current game state
------------------------------------------------
function game:save_state(state)

	-- Copy state
	state.best  = self.best
	state.score = self.score
	state.moves = self.moves
	state.over  = self.over
	state.won   = self.won
	state.cont  = self.cont

	state.grid  = wipe(state.grid or {})
	for row = 1, self.size do
		state.grid[row] = {}
		for col = 1, self.size do
			state.grid[row][col] = self.grid[row][col].val
		end
	end
end

------------------------------------------------
-- Get/set the cell at (row,col)
------------------------------------------------
function game:get_cell(row, col)
	return self.grid[row][col]
end

------------------------------------------------
function game:set_cell_value(row, col, val)
	self.grid[row][col].val = val
end

-----------------------------------------------
-- Check if further moves are possible
-----------------------------------------------
function game:moves_available()

	for row = 1, self.size do
		for col = 1, self.size do
			-- Only check right and down as actual left and up were checked on previous iteration
			local cell  = self.grid[row][col].val
			local right = self.grid[row][col + 1].val
			local below = self.grid[row + 1][col].val

			if right == 0 or right == cell or below == 0 or below == cell then
				return true
			end
		end
	end
	return false
end

------------------------------------------------
-- Set a random cell to a random value
------------------------------------------------
local _empty = {}
function game:add_random_cell()

	-- Collect and count empty cells
	wipe(_empty)
	for row = 1, self.size do
		for col = 1, self.size do
			if self.grid[row][col].val == 0 then
				table.insert(_empty, { row = row, col = col } )
			end
		end
	end

	if #_empty > 0 then
		local random_cell  = math.ceil(math.random() * #_empty)
		local random_value = (math.random() < 0.7) and 2 or 4

		self:set_cell_value(_empty[random_cell].row, _empty[random_cell].col, random_value)
		return true
	end
	return false
end

------------------------------------------------
-- Get/set the score
------------------------------------------------
function game:add_score(n)
	self.score = self.score + n
	if self.score > self.best then
		self.best = self.score
	end
end

------------------------------------------------
function game:add_move()
	self.moves = self.moves + 1
end

------------------------------------------------
function game:get_scores()
	return self.moves, self.score, self.best
end

------------------------------------------------
-- Check whether the game is terminated
------------------------------------------------
function game:is_terminated()
	return self:is_won() or self:is_over()
end

------------------------------------------------
function game:is_won()
	return self.won and not self.cont
end

------------------------------------------------
function game:is_over()
	return self.over
end

------------------------------------------------
-- Continue playing
function game:keep_playing()
	self.cont = true
end

-----------------------------------------------
-- Move cells on the grid in the specified direction
-----------------------------------------------
local _moves = {}
function game:move_cells(direction)

	-- Find the farthest destination for a cell in the given direction
	local function find_dest(cell, row_delta, col_delta)

		local dest = self.grid[cell.row + row_delta][cell.col + col_delta]
		while dest.val == 0 do
			-- Destination is empty, try further
			dest = self.grid[dest.row + row_delta][dest.col + col_delta]
		end

		if (dest.val == cell.val) and not (cell.merged or dest.merged) then
			-- We can merge with this cell but only if neither cell and dest were already merged
			return dest
		end

		-- We either reached out of bounds or we are blocked by another cell
		-- In any case, return the last valid cell we found
		return self.grid[dest.row - row_delta][dest.col - col_delta]
	end

	-- Move a cell to its destination
	local function move_cell(cell, dest)
		if dest.row ~= cell.row or dest.col ~= cell.col then
			local merged = dest.val == cell.val

			table.insert(_moves, {
				p_row  = cell.row,
				p_col  = cell.col,
				p_val  = cell.val,
				n_row  = dest.row,
				n_col  = dest.col,
				n_val  = dest.val + cell.val,
				merged = merged
			 })

			dest.val  = dest.val  + cell.val	-- dest.val is either 0 or same as cell.val
			dest.merged = merged
			cell.val  = 0

			if merged then
				self:add_score(dest.val)

				-- The mighty 2048 tile?
				self.won = self.won or (dest.val == 2048)
			end
		end
	end

	-- Move thes cells
	wipe(_moves)
	if not self:is_terminated() then

		self:add_move()

		-- Traverse the grid in the right direction
		local source
		if direction == 'UP' then
			for row = 2, self.size do				-- skip row #1 since it can't move up
				for col = 1, self.size do
					source = self.grid[row][col]
					if source.val > 0 then
						move_cell(source, find_dest(source, -1, 0))
					end
				end
			end
		elseif direction == 'DOWN' then
			for row = self.size-1, 1, -1 do			-- skip last row since it can't move down
				for col = 1, self.size do
					source = self.grid[row][col]
					if source.val > 0 then
						move_cell(source, find_dest(source, 1, 0))
					end
				end
			end
		elseif direction == 'LEFT' then
			for row = 1, self.size do
				for col = 2, self.size do			-- skip col #1 since it can't move left
					source = self.grid[row][col]
					if source.val > 0 then
						move_cell(source, find_dest(source, 0, -1))
					end
				end
			end
		elseif direction == 'RIGHT' then
			for row = 1, self.size do
				for col = self.size-1, 1, -1 do		-- skip last col since it can't move right
					source = self.grid[row][col]
					if source.val > 0 then
						move_cell(source, find_dest(source, 0, 1))
					end
				end
			end
		end
	end

	return _moves
end

-----------------------------------------------
function game:next_turn()

	-- Reset all cells states
	for row = 1, self.size do
		for col = 1, self.size do
			local cell = self.grid[row][col]
			cell.row    = row
			cell.col    = col
			cell.merged = false
		end
	end

	-- Update the values of those cells that actually moved
	for _, move in ipairs(_moves) do
		local cell = self.grid[move.n_row][move.n_col]
		cell.val  = move.n_val
	end

	-- Add a new cell, check for game over
	self.over = not (self:add_random_cell() and self:moves_available())
end
