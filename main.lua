
local addonName, _ = ...
local addon = LibStub('AceAddon-3.0'):NewAddon(addonName, 'AceConsole-3.0')

-- Game defaults
local grid_size    = 4
local start_tiles  = 2

-- UI Elements
local tile_size    = 60
local gutter_size  = 8
local board_width  = (tile_size * grid_size) + (gutter_size * (grid_size + 1))
local board_height = board_width
local title_height = 60
local score_height = 60
local intro_height = 30
local pad_size     = 24 * 3
local inner_width  = board_width
local inner_height = max(title_height, score_height) + intro_height + 10 + board_height + 10 + pad_size
local border_size  = 10


-- Message box
local messages = {
	['MSG_WON']     = { text = 'You won!',   butt1 = 'New game', butt2 = 'Keep playing' },
	['MSG_LOST']    = { text = 'Game over!', butt1 = 'Restart',  butt2 = nil            },
	['MSG_RESTART'] = { text = 'Restart?',   butt1 = 'Yes',      butt2 = 'No'           },
}

-- Textures and colors
local plain_bg = {
	bgFile = "Interface\\Buttons\\White8x8",
}

local colors = {
	['bg'] = {
		['frame'] = { 0.97, 0.96, 0.94, 1 },
		['score'] = { 0.73, 0.67, 0.62, 1 },
		['board'] = { 0.46, 0.43, 0.39, 1 },
		['tiles'] = {
			   [0] = { 0.73, 0.67, 0.62, 1 },
			   [2] = { 0.93, 0.89, 0.85, 1 },
			   [4] = { 0.92, 0.87, 0.78, 1 },
			   [8] = { 0.94, 0.69, 0.47, 1 },
			  [16] = { 0.96, 0.58, 0.38, 1 },
			  [32] = { 0.96, 0.48, 0.37, 1 },
			  [64] = { 0.96, 0.36, 0.23, 1 },
			 [128] = { 0.92, 0.81, 0.44, 1 },
			 [256] = { 0.92, 0.80, 0.38, 1 },
			 [512] = { 0.92, 0.78, 0.31, 1 },
			[1024] = { 0.92, 0.77, 0.24, 1 },
			[2048] = { 0.92, 0.76, 0.18, 1 },
			[4096] = { 0.23, 0.10, 0.19, 1 },
		},
		['pad']   = { 0.73, 0.67, 0.62, 1 },
	},
	['fg'] = {
		['title'] = { 0.46, 0.43, 0.39, 1 },
		['score'] = { 0.46, 0.43, 0.39, 1 },
		['info']  = { 0.46, 0.43, 0.39, 1 },
		['tiles'] = {
			   [0] = { 0.00, 0.00, 0.00, 1 },
			   [2] = { 0.46, 0.43, 0.39, 1 },
			   [4] = { 0.46, 0.43, 0.39, 1 },
			   [8] = { 0.97, 0.96, 0.94, 1 },
			  [16] = { 0.97, 0.96, 0.94, 1 },
			  [32] = { 0.97, 0.96, 0.94, 1 },
			  [64] = { 0.97, 0.96, 0.94, 1 },
			 [128] = { 0.97, 0.96, 0.94, 1 },
			 [256] = { 0.97, 0.96, 0.94, 1 },
			 [512] = { 0.97, 0.96, 0.94, 1 },
			[1024] = { 0.97, 0.96, 0.94, 1 },
			[2048] = { 0.97, 0.96, 0.94, 1 },
			[4096] = { 0.97, 0.96, 0.94, 1 },
		},
	},
}

-- Ace3 DB
local db_defaults = {
	global = {
		scale = 1.0,
		useKeyboard = true,
		pos = {
			x = 0,
			y = 0,
		},
		state = nil,
	},
}

-- Ace3 options table
local config_table = {
	name = addonName,
	handler = addon,
	type = 'group',
	args = {
		useKeyboard = {
			order = 10,
			type = 'toggle',
			name = 'Enable keyboard use',
			width = 'full',
			get = function(info) return addon.db.global.useKeyboard end,
			set = function(info, value)
				addon.db.global.useKeyboard = value
				addon.frame:EnableKeyboard(value)
			end,
		},
		scale = {
			order = 20,
			type = 'range',
			name = 'Window scale',
			min = 0.3,
			max = 2.0,
			step = 0.1,
			width = 'full',
			get = function(info) return addon.db.global.scale end,
			set = function(info, value)
				addon.db.global.scale = value
				addon.frame:SetScale(value)
				end,
			isPercent = true,
		},
	},
}

------------------------------------------------
-- Initialize the addon on load
function addon:OnInitialize()

	-- Load SavedVariables
	self.db = LibStub('AceDB-3.0'):New('DB2048', db_defaults, true)

	-- Prepare the fonts
	self.ClearSans14 = CreateFont('ClearSans14')
	self.ClearSans14:SetFont('Interface\\AddOns\\2048\\fonts\\ClearSans\\ClearSans-Regular.ttf', 14)
	self.ClearSans14:SetTextColor(1, 1, 1, 1)
	self.ClearSans20 = CreateFont('ClearSans20')
	self.ClearSans20:SetFont('Interface\\AddOns\\2048\\fonts\\ClearSans\\ClearSans-Regular.ttf', 20)
	self.ClearSans20:SetTextColor(1, 1, 1, 1)
	self.ClearSansBold14 = CreateFont('ClearSansBold14')
	self.ClearSansBold14:SetFont('Interface\\AddOns\\2048\\fonts\\ClearSans\\ClearSans-Bold.ttf', 14)
	self.ClearSansBold14:SetTextColor(1, 1, 1, 1)
	self.ClearSansBold20 = CreateFont('ClearSansBold20')
	self.ClearSansBold20:SetFont('Interface\\AddOns\\2048\\fonts\\ClearSans\\ClearSans-Bold.ttf', 20)
	self.ClearSansBold20:SetTextColor(1, 1, 1, 1)
	self.ClearSansBold32 = CreateFont('ClearSansBold32')
	self.ClearSansBold32:SetFont('Interface\\AddOns\\2048\\fonts\\ClearSans\\ClearSans-Bold.ttf', 32)
	self.ClearSansBold32:SetTextColor(1, 1, 1, 1)

	-- Create all the widgets
	self.frame = CreateFrame('frame', 'F2048', UIParent)
	self.frame:SetPoint('CENTER', unpack(self.db.global.pos))
	self.frame:SetSize(inner_width + (border_size * 2), inner_height + (border_size * 2))
	self.frame:SetScale(self.db.global.scale)
	self.frame:SetBackdrop(plain_bg)
	self.frame:SetBackdropColor(unpack(colors['bg']['frame']))
	self.frame:Hide()

	self.frame:EnableMouse(true)
	self.frame:SetMovable(true)
	self.frame:SetClampedToScreen(true)
	self.frame:RegisterForDrag('LeftButton')
	self.frame:SetScript('OnShow', function(self)
		if self:IsMouseOver() then
			self:SetAlpha(1.0)
			self:EnableKeyboard(addon.db.global.useKeyboard)
		else
			self:SetAlpha(0.5)
			self:EnableKeyboard(false)
		end
	end)
	self.frame:SetScript('OnEnter', function(self)
		self:SetAlpha(1.0)
		self:EnableKeyboard(addon.db.global.useKeyboard)
	end)
	self.frame:SetScript('OnLeave', function(self)
		if not self:IsMouseOver() then
			self:SetAlpha(0.5)
			self:EnableKeyboard(false)
		end
	end)
	self.frame:SetScript('OnDragStart', function(self, button)
		self:StartMoving()
	end)
	self.frame:SetScript('OnDragStop', function(self, button)
		self:StopMovingOrSizing()
		local p, rf, rp, x, y = self:GetPoint()
		addon.db.global.pos.x = x
		addon.db.global.pos.y = y
	end)
	self.frame:SetScript('OnKeyDown', function(self, key)
		addon:handle_key(key)
	end)

	-- title
	self.title = self.frame:CreateFontString(nil, 'ARTWORK')
	self.title:SetFontObject(self.ClearSansBold32)
	self.title:SetPoint('TOPLEFT', border_size, -border_size)
	self.title:SetSize(inner_width, title_height)
	self.title:SetText('2048')
	self.title:SetTextColor(unpack(colors['fg']['title']))
	self.title:SetJustifyH('LEFT')

	-- scores
	self.score = {}
	self.score.bg = self.frame:CreateTexture(nil, 'ARTWORK')
	self.score.bg:SetPoint('TOPRIGHT', self.title)
	self.score.bg:SetSize(tile_size, score_height)
	self.score.bg:SetTexture(unpack(colors['bg']['score']))
	self.score.label = self.frame:CreateFontString(nil, 'ARTWORK')
	self.score.label:SetPoint('TOP', self.score.bg, 'TOP', 0, -10)
	self.score.label:SetFontObject(self.ClearSansBold14)
	self.score.label:SetTextColor(unpack(colors['fg']['score']))
	self.score.label:SetText('SCORE')
	self.score.text = self.frame:CreateFontString(nil, 'ARTWORK')
	self.score.text:SetPoint('BOTTOM', self.score.bg, 'BOTTOM', 0, 10)
	self.score.text:SetFontObject(self.ClearSansBold14)
	self.score.text:SetTextColor(unpack(colors['fg']['score']))
	self.score.text:SetText('0')

	self.best = {}
	self.best.bg = self.frame:CreateTexture(nil, 'ARTWORK')
	self.best.bg:SetPoint('TOPRIGHT', self.score.bg, 'TOPLEFT', -gutter_size, 0)
	self.best.bg:SetSize(tile_size, score_height)
	self.best.bg:SetTexture(unpack(colors['bg']['score']))
	self.best.label = self.frame:CreateFontString(nil, 'ARTWORK')
	self.best.label:SetPoint('TOP', self.best.bg, 'TOP', 0, -10)
	self.best.label:SetFontObject(self.ClearSansBold14)
	self.best.label:SetTextColor(unpack(colors['fg']['score']))
	self.best.label:SetText('BEST')
	self.best.text = self.frame:CreateFontString(nil, 'ARTWORK')
	self.best.text:SetPoint('BOTTOM', self.best.bg, 'BOTTOM', 0, 10)
	self.best.text:SetFontObject(self.ClearSansBold14)
	self.best.text:SetTextColor(unpack(colors['fg']['score']))
	self.best.text:SetText('0')

	-- base line
	self.intro = self.frame:CreateFontString(nil, 'ARTWORK')
	self.intro:SetPoint('TOPLEFT', self.title, 'BOTTOMLEFT')
	self.intro:SetSize(inner_width, intro_height)
	self.intro:SetFontObject(self.ClearSans14)
	self.intro:SetTextColor(unpack(colors['fg']['info']))
	self.intro:SetJustifyH('LEFT')
	self.intro:SetText('Join the numbers and get to the |cFFFF00002048|r tile!')

	-- board
	self.board = self.frame:CreateTexture(nil, 'BACKGROUND', nil, 2)
	self.board:SetPoint('TOP', self.intro, 'BOTTOM', 0, -10)
	self.board:SetSize(board_width, board_height)
	self.board:SetTexture(unpack(colors['bg']['board']))
	local x, y = gutter_size, -gutter_size
	for row = 1, grid_size do
		for col = 1, grid_size do
			local bg = self.frame:CreateTexture(nil, 'BAKCGROUND', nil, 3)
			bg:SetPoint('TOPLEFT', self.board, x, y)
			bg:SetSize(tile_size, tile_size)
			bg:SetTexture(unpack(colors['bg']['tiles'][0]))
			x = x + tile_size + gutter_size
		end
		y = y - tile_size - gutter_size
		x = gutter_size
	end

	-- tiles
	self.tiles = {}
	local x, y = gutter_size, -gutter_size
	for row = 1, grid_size do
		for col = 1, grid_size do

			self.tiles[row..'x'..col] = CreateFrame('frame', nil, self.frame)
			local t = self.tiles[row..'x'..col]

			t:SetPoint('TOPLEFT', self.board, x, y)
			t:SetSize(tile_size, tile_size)
			t:SetBackdrop(plain_bg)
			t:SetBackdropColor(unpack(colors['bg']['tiles'][0]))

			t.s = t:CreateFontString(nil, 'ARTWORK')
			t.s:SetFontObject(self.ClearSansBold20)
			t.s:SetAllPoints(t)
			t.s:SetText(" ")
--[[
if false then
			local b = CreateFrame('button', nil, self.frame)
			b:SetPoint('TOPLEFT', self.board, x, y)
			b:SetSize(tile_size, tile_size)
			b:SetFrameLevel(b:GetFrameLevel() + 10)

			b.s = b:CreateFontString(nil, 'ARTWORK')
			b.s:SetFontObject(GameFontNormal)
			b.s:SetPoint('TOPLEFT', t)
			b.s:SetAlpha(0.3)
			b.s:SetFormattedText("#%d (%d,%d)", ((row-1) * grid_size) + col, row, col)

			b.col = col
			b.row = row
			b:RegisterForClicks('AnyUp')
			b:SetScript('OnClick', function(self, button)
				local cell = addon.game:get_cell(self.row, self.col)
				if button == 'RightButton' then
					cell.value = 0
				else
					cell.value = max(cell.value, 1) * 2
				end
				addon:update_tile(self.row, self.col)
			end)
end
]]
			-- Each tile must have its own animation group!
			t.ag = t:CreateAnimationGroup('ag_'..row..'x'..col)
			t.trans = t.ag:CreateAnimation('TRANSLATION', 'trans_'..row..'x'..col)
			t.scale = t.ag:CreateAnimation('SCALE', 'scale_'..row..'x'..col)

			-- Proceed to next tile in this row
			x = x + tile_size + gutter_size
		end
		-- Proceed to next row
		y = y - tile_size - gutter_size
		x = gutter_size
	end

	-- Pad
	self.pad = {}
	self.pad.b1 = CreateFrame('button', nil, self.frame, 'UIPanelSquareButton')
	self.pad.b1:SetPoint('TOP', self.board, 'BOTTOM', 0, -10 - 24)
	self.pad.b1:SetSize(24, 24)
	SquareButton_SetIcon(self.pad.b1, 'DELETE')
	self.pad.b1:RegisterForClicks('AnyUp')
	self.pad.b1:SetScript('OnClick', function(self, ...)
		addon:handle_key('RESTART')
	end)

	self.pad.b2 = CreateFrame('button', nil, self.frame, 'UIPanelSquareButton')
	self.pad.b2:SetPoint('BOTTOM', self.pad.b1, 'TOP', 0, 0)
	self.pad.b2:SetSize(24, 24)
	SquareButton_SetIcon(self.pad.b2, 'UP')
	self.pad.b2:RegisterForClicks('AnyUp')
	self.pad.b2:SetScript('OnClick', function(self, ...)
		addon:handle_key('UP')
	end)

	self.pad.b3 = CreateFrame('button', nil, self.frame, 'UIPanelSquareButton')
	self.pad.b3:SetPoint('RIGHT', self.pad.b1, 'LEFT', 0, 0)
	self.pad.b3:SetSize(24, 24)
	SquareButton_SetIcon(self.pad.b3, 'LEFT')
	self.pad.b3:RegisterForClicks('AnyUp')
	self.pad.b3:SetScript('OnClick', function(self, ...)
		addon:handle_key('LEFT')
	end)

	self.pad.b4 = CreateFrame('button', nil, self.frame, 'UIPanelSquareButton')
	self.pad.b4:SetPoint('TOP', self.pad.b1, 'BOTTOM', 0, 0)
	self.pad.b4:SetSize(24, 24)
	SquareButton_SetIcon(self.pad.b4, 'DOWN')
	self.pad.b4:RegisterForClicks('AnyUp')
	self.pad.b4:SetScript('OnClick', function(self, ...)
		addon:handle_key('DOWN')
	end)

	self.pad.b5 = CreateFrame('button', nil, self.frame, 'UIPanelSquareButton')
	self.pad.b5:SetPoint('LEFT', self.pad.b1, 'RIGHT', 0, 0)
	self.pad.b5:SetSize(24, 24)
	SquareButton_SetIcon(self.pad.b5, 'RIGHT')
	self.pad.b5:RegisterForClicks('AnyUp')
	self.pad.b5:SetScript('OnClick', function(self, ...)
		addon:handle_key('RIGHT')
	end)

	-- Message box
	self.msgbox = {}
	self.msgbox.frame = CreateFrame('frame', nil, self.frame)
	self.msgbox.frame:SetAllPoints(self.board)
	self.msgbox.frame:SetBackdrop(plain_bg)
	self.msgbox.frame:SetBackdropColor(0.92, 0.81, 0.44, 1)
	self.msgbox.frame:SetFrameStrata('HIGH')
	self.msgbox.frame:Hide()
	self.msgbox.text = self.msgbox.frame:CreateFontString(nil, 'ARTWORK')
	self.msgbox.text:SetAllPoints(self.board)
	self.msgbox.text:SetPoint('TOPLEFT', self.board, 'TOPLEFT', 0, -tile_size)
	self.msgbox.text:SetPoint('BOTTOMRIGHT', self.board, 'BOTTOMRIGHT', 0, tile_size*2)
	self.msgbox.text:SetJustifyV('TOP')
	self.msgbox.text:SetFontObject(self.ClearSansBold20)
	self.msgbox.text:SetTextColor(1, 1, 1, 1)

	self.msgbox.button1 = CreateFrame('button', nil, self.msgbox.frame)
	self.msgbox.button1:SetPoint('BOTTOM', 0, 10)
	self.msgbox.button1:SetSize(150, 30)
	self.msgbox.button1:SetBackdrop(plain_bg)
	self.msgbox.button1:SetBackdropColor(0.23, 0.10, 0.19, 1)
	self.msgbox.button1:SetNormalFontObject(self.ClearSansBold14)
	self.msgbox.button1:RegisterForClicks('AnyUp')
	self.msgbox.button1:SetScript('OnClick', function(self)
		addon:handle_message_button(1)
	end)

	self.msgbox.button2 = CreateFrame('button', nil, self.msgbox.frame)
	self.msgbox.button2:SetPoint('BOTTOM', self.msgbox.button1, 'TOP', 0, 10)
	self.msgbox.button2:SetSize(150, 30)
	self.msgbox.button2:SetBackdrop(plain_bg)
	self.msgbox.button2:SetBackdropColor(0.46, 0.43, 0.39, 1)
	self.msgbox.button2:SetNormalFontObject(self.ClearSansBold14)
	self.msgbox.button2:RegisterForClicks('AnyUp')
	self.msgbox.button2:SetScript('OnClick', function(self)
		addon:handle_message_button(2)
	end)

	-- Setup options panel
	LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, config_table);
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName);

	-- Enable slash command
	self:RegisterChatCommand('2048', 'OnChatCommand')
end

------------------------------------------------
-- Toggle the frame
function addon:OnChatCommand(...)

	if self.frame:IsShown() then
		self.frame:Hide()
	else
		self.frame:Show()
	end
end

------------------------------------------------
-- Start a new game
function addon:OnEnable()

	-- Initialize LDB if found
	self.ldb = LibStub('LibDataBroker-1.1', true)
	if self.ldb then
		self.lbo = self.ldb:NewDataObject(addonName, {
				type = "launcher",
				icon = "Interface\\Icons\\INV_Letter_15",
				OnClick = function(self, button)
					addon:OnChatCommand()
				end,
		})
	end

	-- Initialize the game
	self.game = self:GetModule('game')
	self.game:new_game(grid_size, self.db.global.state)

	-- Draw the board
	self:update()
end

------------------------------------------------
-- Display a message
function addon:show_message_box(msg)

	-- Remember which question was asked
	self.msgbox.q = msg

	self.msgbox.text:SetText(messages[msg].text)
	self.msgbox.button1:SetText(messages[msg].butt1)
	if messages[msg].butt2 then
		self.msgbox.button2:SetText(messages[msg].butt2)
		self.msgbox.button2:Show()
	else
		self.msgbox.button2:Hide()
	end

	self.msgbox.frame:Show()
	UIFrameFadeIn(self.msgbox.frame, 0.3, 0, 0.8)
end

------------------------------------------------
function addon:handle_message_button(button)

	-- Hide the frame
	self.msgbox.frame:Hide()

	if self.msgbox.q == 'MSG_WON' then
		if button == 1 then
			self.game:new_game()
		else
			self.game:keep_playing()
		end

	elseif self.msgbox.q == 'MSG_LOST' then
		self.game:new_game()

	elseif self.msgbox.q == 'MSG_RESTART' then
		if button == 1 then
			self.game:new_game()
		end
	end

	-- Redraw the board
	self:update()
end

------------------------------------------------
-- Redraw the whole frame
function addon:update()

	if self.msgbox.frame:IsShown() then return end

	self:update_scores()
	self:update_board()
end

------------------------------------------------
-- Redraw the scores
function addon:update_scores()

	local score, best = self.game:get_score()

	self.score.text:SetText(score)
	self.best.text:SetText(best)
end

------------------------------------------------
-- Redraw all the tiles in the board
function addon:update_board()

	for i = 1, grid_size do
		for j = 1, grid_size do
			self:update_tile(i, j)
		end
	end
end

------------------------------------------------
-- Redraw a single tile
function addon:update_tile(row, col)

	local tile = self.tiles[row..'x'..col]
	local val  = self.game:get_cell_value(row, col)

	-- Set the value
	tile.s:SetText(val > 0 and val or '')

	-- Set the colors accordingly
	if val > 4096 then val = 4096 end
	tile.s:SetTextColor(unpack(colors['fg']['tiles'][val]))
	tile:SetBackdropColor(unpack(colors['bg']['tiles'][val]))

	-- Restore frame level after animation
	tile:SetFrameLevel(self.frame:GetFrameLevel() + 1)
end

------------------------------------------------
-- Handle up/down/left/right/restart keys
local _keys = { ['LEFT'] = true, ['RIGHT'] = true, ['UP'] = true, ['DOWN'] = true }
local _anims = {}
function addon:handle_key(key)

	if self.msgbox.frame:IsShown() then return end

	if key == 'RESTART' then
		self:show_message_box('MSG_RESTART')
	elseif _keys[key] then
		-- Save current state
		self.db.global.state = wipe(self.db.global.state or {})
		self.game:save_state(self.db.global.state)

		-- Move the tiles
		local moves = self.game:move_cells(key)

		-- Animate those tiles that were actually moved
		wipe(_anims)
		for _, cell in ipairs(moves) do
			local tile = self.tiles[cell.p_row..'x'..cell.p_col]
			tile:SetFrameLevel(tile:GetFrameLevel() + 2)	-- Make sure animated tiles are above non-moving ones
			tile.trans:SetOffset((cell.col - cell.p_col) * 68, (cell.row - cell.p_row) * -68)
			tile.trans:SetOrder(1)
			tile.trans:SetDuration(0.1)
			tile.trans:SetScript('OnFinished', function(self)
				addon:update_tile(cell.p_row, cell.p_col)
				addon:update_tile(cell.row,   cell.col)
			end)
--[[
if false then
			if cell.merged then
				tile.scale:SetScale(1.2, 1.2)
				tile.scale:SetOrigin('CENTER', 0, 0)
				tile.scale:SetOrder(2)
				tile.scale:SetDuration(0.1)
			end
end
]]
			tile.ag:SetLooping('NONE')
			table.insert(_anims, tile.ag)
		end

		-- Play all pending animations
		self.anim_count = #_anims
		for _, anim in ipairs(_anims) do
			anim:SetScript('OnFinished', function(self)
				addon.anim_count = addon.anim_count - 1
				if addon.anim_count == 0 then
					-- All anims are done, prepare for next turn
					addon:prepare_next_turn()
				end
			end)
			anim:Play()
		end
	end
end

------------------------------------------------
-- Prepare for next turn
function addon:prepare_next_turn()

	-- Redraw the board
	self:update()

	-- Game over?
	if self.game:is_over() then
		self:show_message_box('MSG_LOST')

	-- Game won?
	elseif self.game:is_won() then
		self:show_message_box('MSG_WON')
	end
end
