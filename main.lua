
local addon = LibStub('AceAddon-3.0'):NewAddon('2048', 'AceConsole-3.0', 'AceTimer-3.0')
local L     = LibStub('AceLocale-3.0'):GetLocale('2048')

-- Game defaults
local grid_size    = 4

-- UI Elements
local tile_size    = 60
local gutter_size  = 8
local tile_gutter  = tile_size + gutter_size
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
	['MSG_WON']     = { text = L['You won!'],   butt1 = L['New game'], butt2 = L['Keep playing'] },
	['MSG_LOST']    = { text = L['Game over!'], butt1 = L['Restart'],  butt2 = nil               },
	['MSG_RESTART'] = { text = L['Restart?'],   butt1 = L['Yes'],      butt2 = L['No']           },
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
		['pad'] = { 0.73, 0.67, 0.62, 1 },
		['msgbox'] = {
			    ['msg'] = { 0.92, 0.81, 0.44, 1 },
			['button1'] = { 0.23, 0.10, 0.19, 1 },
			['button2'] = { 0.46, 0.43, 0.39, 1 }
		}
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
		['msgbox'] = {
			    ['msg'] = { 1, 1, 1, 1 },
			['button1'] = { 1, 1, 1, 1 },
			['button2'] = { 1, 1, 1, 1 }
		}
	},
}

-- Ace3 DB
local db_defaults = {
	global = {
		version = 1,
		frame = {
			scale = 1.0,
			useKeyboard = true,
			pos = {
				p = 'CENTER',
				x = 0,
				y = 0,
			},
		},
		game = {
			best  = 0,
			moves = 0,
			score = 0,
			over  = false,
			won   = false,
			cont  = false,
			grid  = {}	-- Always have a grid, even empty
		}
	}
}

-- Ace3 options table
local config_table = {
	name = '2048',
	handler = addon,
	type = 'group',
	args = {
		version = {
			order = 1,
			type  = 'description',
			name  = 'Version 1.0.0' -- GetAddOnMetadata('2048', 'Version') won't work :(
		},

		punchline = {
			order = 2,
			type  = 'description',
			name  = L['Play while you wait to play!'] .. '\n',
			fontSize  = 'medium'
		},

		author = {
			order = 3,
			type  = 'description',
			name  = 'Septh - https://github.com/Septh/WoW-2048'
		},

		sep = {
			order = 4,
			type = 'header',
			name = ''
		},

		useKeyboard = {
			order = 10,
			type = 'toggle',
			name = L['Enable keyboard use'],
			width = 'full',
			get = function(info) return addon.db.global.frame.useKeyboard end,
			set = function(info, value)
				addon.db.global.frame.useKeyboard = value
				addon.frame:EnableKeyboard(value)
			end,
		},
		scale = {
			order = 20,
			type = 'range',
			name = L['Window scale'],
			min = 0.3,
			max = 2.0,
			step = 0.05,
			width = 'full',
			get = function(info) return addon.db.global.frame.scale end,
			set = function(info, value)
				addon.db.global.frame.scale = value
				addon.frame:SetScale(value)
				end,
			isPercent = true,
		},
	},
}

------------------------------------------------
-- Initialize the addon on load
------------------------------------------------
function addon:OnInitialize()

	-- Load or create SavedVariables
	self.db = LibStub('AceDB-3.0'):New('DB2048', db_defaults, true)
	if (self.db.global.version or 0) ~= 1 then
		self:Print(L['Old settings reset to defaults - sorry about that.'])
		self.db:ResetDB('Default')
	end

	-- Prepare the fonts
	local function make_font(name, style, size)
		local f = CreateFont(name)
		f:SetFont('Interface\\AddOns\\2048\\fonts\\ClearSans\\ClearSans-'..style..'.ttf', size)
		f:SetTextColor(1, 1, 1, 1)
		return f
	end
	self.ClearSans14     = make_font('ClearSans14',     'Regular', 14)
	self.ClearSans20     = make_font('ClearSans20',     'Regular', 20)
	self.ClearSansBold14 = make_font('ClearSansBold14', 'Bold',    14)
	self.ClearSansBold20 = make_font('ClearSansBold20', 'Bold',    20)
	self.ClearSansBold32 = make_font('ClearSansBold32', 'Bold',    32)

	-- Create the main game frame
	self.frame = CreateFrame('Frame', nil, UIParent)
	self.frame:SetPoint(self.db.global.frame.pos.p, self.db.global.frame.pos.x, self.db.global.frame.pos.y)
	self.frame:SetSize(inner_width + (border_size * 2), inner_height + (border_size * 2))
	self.frame:SetScale(self.db.global.frame.scale)
	self.frame:SetBackdrop(plain_bg)
	self.frame:SetBackdropColor(unpack(colors['bg']['frame']))
	self.frame:EnableMouse(true)
	self.frame:SetMovable(true)
	self.frame:SetClampedToScreen(true)
	self.frame:RegisterForDrag('LeftButton')
	self.frame:Hide()

	self.frame.fadein = self.frame:CreateAnimationGroup()
	self.frame.fadein.anim = self.frame.fadein:CreateAnimation('ALPHA')
	self.frame.fadein.anim:SetFromAlpha(0.5)
	self.frame.fadein.anim:SetToAlpha(1.0)
	self.frame.fadein.anim:SetDuration(0.2)
	self.frame.fadein.anim:SetSmoothing('NONE')
	self.frame.fadein:SetToFinalAlpha(true)

	self.frame.fadeout = self.frame:CreateAnimationGroup()
	self.frame.fadeout.anim = self.frame.fadeout:CreateAnimation('ALPHA')
	self.frame.fadeout.anim:SetFromAlpha(1.0)
	self.frame.fadeout.anim:SetToAlpha(0.5)
	self.frame.fadeout.anim:SetDuration(0.2)
	self.frame.fadeout.anim:SetSmoothing('NONE')
	self.frame.fadeout:SetToFinalAlpha(true)

	self.frame:SetScript('OnShow', function(frame)
		frame:SetAlpha(0.5)
		if frame:IsMouseOver() then
			frame.fadein:Play()
			frame:EnableKeyboard(addon.db.global.frame.useKeyboard)
		else
			frame:EnableKeyboard(false)
		end
	end)
	self.frame:SetScript('OnEnter', function(frame)
		if frame.skipNextEnter then frame.skipNextEnter = nil; return end
		frame.fadeout:Stop()
		frame.fadein:Play()
		frame:EnableKeyboard(addon.db.global.frame.useKeyboard)
	end)
	self.frame:SetScript('OnLeave', function(frame)
		if frame:IsMouseOver() then frame.skipNextEnter = true; return end
		frame.fadein:Stop()
		frame.fadeout:Play()
		frame:EnableKeyboard(false)
	end)
	self.frame:SetScript('OnDragStart', function(frame, button)
		frame:StartMoving()
	end)
	self.frame:SetScript('OnDragStop', function(frame, button)
		frame:StopMovingOrSizing()
		local p, rf, rp, x, y = frame:GetPoint()
		addon.db.global.frame.pos.p = p
		addon.db.global.frame.pos.x = x
		addon.db.global.frame.pos.y = y
	end)
	self.frame:SetScript('OnKeyDown', function(frame, key)
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
	self.best = {}
	self.best.bg = self.frame:CreateTexture(nil, 'ARTWORK')
	self.best.bg:SetPoint('TOPRIGHT', self.title)
	self.best.bg:SetSize(tile_size, score_height)
	self.best.bg:SetColorTexture(unpack(colors['bg']['score']))
	self.best.label = self.frame:CreateFontString(nil, 'ARTWORK')
	self.best.label:SetPoint('TOP', self.best.bg, 'TOP', 0, -10)
	self.best.label:SetFontObject(self.ClearSansBold14)
	self.best.label:SetTextColor(unpack(colors['fg']['score']))
	self.best.label:SetText(L['BEST'])
	self.best.text = self.frame:CreateFontString(nil, 'ARTWORK')
	self.best.text:SetPoint('BOTTOM', self.best.bg, 'BOTTOM', 0, 10)
	self.best.text:SetFontObject(self.ClearSansBold14)
	self.best.text:SetTextColor(unpack(colors['fg']['score']))
	self.best.text:SetText('0')

	self.score = {}
	self.score.bg = self.frame:CreateTexture(nil, 'ARTWORK')
	self.score.bg:SetPoint('TOPRIGHT', self.best.bg, 'TOPLEFT', -gutter_size / 2, 0)
	self.score.bg:SetSize(tile_size, score_height)
	self.score.bg:SetColorTexture(unpack(colors['bg']['score']))
	self.score.label = self.frame:CreateFontString(nil, 'ARTWORK')
	self.score.label:SetPoint('TOP', self.score.bg, 'TOP', 0, -10)
	self.score.label:SetFontObject(self.ClearSansBold14)
	self.score.label:SetTextColor(unpack(colors['fg']['score']))
	self.score.label:SetText(L['SCORE'])
	self.score.text = self.frame:CreateFontString(nil, 'ARTWORK')
	self.score.text:SetPoint('BOTTOM', self.score.bg, 'BOTTOM', 0, 10)
	self.score.text:SetFontObject(self.ClearSansBold14)
	self.score.text:SetTextColor(unpack(colors['fg']['score']))
	self.score.text:SetText('0')

	self.moves = {}
	self.moves.bg = self.frame:CreateTexture(nil, 'ARTWORK')
	self.moves.bg:SetPoint('TOPRIGHT', self.score.bg, 'TOPLEFT', -gutter_size / 2, 0)
	self.moves.bg:SetSize(tile_size, score_height)
	self.moves.bg:SetColorTexture(unpack(colors['bg']['score']))
	self.moves.label = self.frame:CreateFontString(nil, 'ARTWORK')
	self.moves.label:SetPoint('TOP', self.moves.bg, 'TOP', 0, -10)
	self.moves.label:SetFontObject(self.ClearSansBold14)
	self.moves.label:SetTextColor(unpack(colors['fg']['score']))
	self.moves.label:SetText(L['MOVES'])
	self.moves.text = self.frame:CreateFontString(nil, 'ARTWORK')
	self.moves.text:SetPoint('BOTTOM', self.moves.bg, 'BOTTOM', 0, 10)
	self.moves.text:SetFontObject(self.ClearSansBold14)
	self.moves.text:SetTextColor(unpack(colors['fg']['score']))
	self.moves.text:SetText('0')

	-- punch line
	self.punchline = self.frame:CreateFontString(nil, 'ARTWORK')
	self.punchline:SetPoint('TOPLEFT', self.title, 'BOTTOMLEFT')
	self.punchline:SetSize(inner_width, intro_height)
	self.punchline:SetFontObject(self.ClearSans14)
	self.punchline:SetTextColor(unpack(colors['fg']['info']))
	self.punchline:SetJustifyH('LEFT')
	self.punchline:SetText(L['Join the numbers and get to the |cFFFF00002048|r tile!'])

	-- board
	self.board = self.frame:CreateTexture(nil, 'BACKGROUND', nil, 2)
	self.board:SetPoint('TOP', self.punchline, 'BOTTOM', 0, -10)
	self.board:SetSize(board_width, board_height)
	self.board:SetColorTexture(unpack(colors['bg']['board']))
	local x, y = gutter_size, -gutter_size
	for row = 1, grid_size do
		for col = 1, grid_size do
			local bg = self.frame:CreateTexture(nil, 'BACKGROUND', nil, 3)
			bg:SetPoint('TOPLEFT', self.board, x, y)
			bg:SetSize(tile_size, tile_size)
			bg:SetColorTexture(unpack(colors['bg']['tiles'][0]))
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

			local t = CreateFrame('Frame', nil, self.frame)
			self.tiles[row..'x'..col] = t

			t:SetPoint('TOPLEFT', self.board, x, y)
			t:SetSize(tile_size, tile_size)
			t:SetBackdrop(plain_bg)
			t:SetBackdropColor(unpack(colors['bg']['tiles'][0]))

			t.s = t:CreateFontString(nil, 'ARTWORK')
			t.s:SetFontObject(self.ClearSansBold20)
			t.s:SetAllPoints(t)
			t.s:SetText(" ")

			-- Each tile must have its own animation groups!
			t.trans = t:CreateAnimationGroup()
			t.trans.anim = t.trans:CreateAnimation('TRANSLATION')

			t.scale = t:CreateAnimationGroup()
			t.scale.anim = t.scale:CreateAnimation('SCALE')

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
	self.msgbox.frame = CreateFrame('Frame', nil, self.frame)
	self.msgbox.frame:SetAllPoints(self.board)
	self.msgbox.frame:SetBackdrop(plain_bg)
	self.msgbox.frame:SetBackdropColor(unpack(colors['bg']['msgbox']['msg']))
	self.msgbox.frame:SetFrameLevel(self.frame:GetFrameLevel() + 10)
	self.msgbox.frame:Hide()

	self.msgbox.text = self.msgbox.frame:CreateFontString(nil, 'ARTWORK')
	self.msgbox.text:SetAllPoints(self.board)
	self.msgbox.text:SetPoint('TOPLEFT', self.board, 'TOPLEFT', 0, -tile_size)
	self.msgbox.text:SetPoint('BOTTOMRIGHT', self.board, 'BOTTOMRIGHT', 0, tile_size*2)
	self.msgbox.text:SetJustifyV('TOP')
	self.msgbox.text:SetFontObject(self.ClearSansBold20)
	self.msgbox.text:SetTextColor(unpack(colors['fg']['msgbox']['msg']))

	self.msgbox.button1 = CreateFrame('button', nil, self.msgbox.frame)
	self.msgbox.button1:SetPoint('BOTTOM', 0, 10)
	self.msgbox.button1:SetSize(150, 30)
	self.msgbox.button1:SetBackdrop(plain_bg)
	self.msgbox.button1:SetBackdropColor(unpack(colors['bg']['msgbox']['button1']))
	self.msgbox.button1:SetNormalFontObject(self.ClearSansBold14)
	self.msgbox.button1:RegisterForClicks('AnyUp')
	self.msgbox.button1:SetScript('OnClick', function(self)
		addon:handle_message_button(1)
	end)

	self.msgbox.button2 = CreateFrame('button', nil, self.msgbox.frame)
	self.msgbox.button2:SetPoint('BOTTOM', self.msgbox.button1, 'TOP', 0, 10)
	self.msgbox.button2:SetSize(150, 30)
	self.msgbox.button2:SetBackdrop(plain_bg)
	self.msgbox.button2:SetBackdropColor(unpack(colors['bg']['msgbox']['button2']))
	self.msgbox.button2:SetNormalFontObject(self.ClearSansBold14)
	self.msgbox.button2:RegisterForClicks('AnyUp')
	self.msgbox.button2:SetScript('OnClick', function(self)
		addon:handle_message_button(2)
	end)

	-- Setup options panel
	LibStub("AceConfig-3.0"):RegisterOptionsTable('2048', config_table)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions('2048')

	-- Enable slash command
	self:RegisterChatCommand('2048', 'ToggleGameBoard')
end

------------------------------------------------
-- Start a new game
------------------------------------------------
function addon:OnEnable()

	-- Initialize LDB if found
	-- (done here since we don't embed the LDB library and it may not be available at OnInitialize() time)
	self.ldb = self.ldb or LibStub('LibDataBroker-1.1', true)
	if self.ldb then
		self.lbo = self.lbo or self.ldb:NewDataObject('2048', {
				type = "launcher",
				icon = "Interface\\AddOns\\2048\\img\\checkboard",
				OnClick = function(self, button)
				              if button == 'LeftButton' then
							      addon:ToggleGameBoard()
							  elseif button == 'RightButton' then
								  InterfaceOptionsFrame_OpenToCategory('2048')
							  end
						  end
		})
	end

	-- Initialize the game
	self.game = self:GetModule('game')
	self.game:restore_game(self.db.global.game)

	-- Draw the board
	self:update()

	-- Saved game was won?
	if self.game:is_won() then
		self:show_message_box('MSG_WON')

	-- Or over?
	elseif self.game:is_over() then
		self:show_message_box('MSG_LOST')
	end
end

------------------------------------------------
-- Toggle the frame
------------------------------------------------
function addon:ToggleGameBoard()

	if self.frame:IsShown() then
		self.frame:Hide()
	else
		self.frame:Show()
	end
end

------------------------------------------------
-- Display a message and wait for an answer
------------------------------------------------
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
	UIFrameFadeIn(self.msgbox.frame, 0.3, 0, 0.9)
end

------------------------------------------------
function addon:handle_message_button(button)

	-- Hide the frame
	self.msgbox.frame:Hide()

	if self.msgbox.q == 'MSG_WON' then
		if button == 1 then
			self.game:new_game()
			self:update()
		else
			self.game:keep_playing()
			self:prepare_next_turn()
		end

	elseif self.msgbox.q == 'MSG_LOST' then
		self.game:new_game()
		self:update()

	elseif self.msgbox.q == 'MSG_RESTART' then
		if button == 1 then
			self.game:new_game()
			self:update()
		end
	end
end

------------------------------------------------
-- Redraw the whole game
------------------------------------------------
function addon:update()

	if self.msgbox.frame:IsShown() then return end

	self:update_scores()
	self:update_board()
end

------------------------------------------------
function addon:update_scores()
	local moves, score, best = self.game:get_scores()

	self.moves.text:SetText(moves)
	self.score.text:SetText(score)
	self.best.text:SetText(best)
end

------------------------------------------------
function addon:update_board()
	for row = 1, grid_size do
		for col = 1, grid_size do
			self:update_tile(row, col)
		end
	end
end

------------------------------------------------
function addon:update_tile(row, col)
	local cell = self.game:get_cell(row, col)
	local val  = cell.val
	local tile = self.tiles[row..'x'..col]

	-- Set the value
	tile.s:SetText(val > 0 and val or ' ')

	-- Set the colors accordingly
	if val > 4096 then val = 4096 end
	tile.s:SetTextColor(unpack(colors['fg']['tiles'][val]))
	tile:SetBackdropColor(unpack(colors['bg']['tiles'][val]))

	-- Restore the tile's frame level after animation
	tile:SetFrameLevel(self.frame:GetFrameLevel() + 1)
end

------------------------------------------------
-- Handle up/down/left/right/restart/escape keys
------------------------------------------------
local _keys = { LEFT = true, RIGHT = true, UP = true, DOWN = true }
local _anims_count = 0
function addon:handle_key(key)

	if self.msgbox.frame:IsShown() then return end

	if key == 'ESCAPE' then
		self:ToggleGameBoard()

	elseif key == 'RESTART' then
		self:show_message_box('MSG_RESTART')

	elseif _keys[key] then
		-- Move the tiles
		local moves = self.game:move_cells(key)

		-- Animate those tiles that were actually moved
		if #moves > 0 then
			_anims_count = 0
			for xx, move in ipairs(moves) do

				local p_tile = self.tiles[move.p_row..'x'..move.p_col]
				local n_tile = self.tiles[move.n_row..'x'..move.n_col]

				-- Transition the tiles from their previous position to the new
				p_tile:SetFrameLevel(p_tile:GetFrameLevel() + 2)	-- Make sure moving tiles are above the others
				p_tile.trans.anim:SetDuration(0.1)
				p_tile.trans.anim:SetOffset((move.n_col - move.p_col) * (tile_size + gutter_size), (move.n_row - move.p_row) * (tile_size + gutter_size) * -1)
				p_tile.trans.anim:SetStartDelay(xx * 0.01)			--- nicer
				p_tile.trans.anim:SetScript('OnFinished', function()
					_anims_count = _anims_count - 1

					-- Update the old position
					addon.game:set_cell_value(move.p_row, move.p_col, 0)
					addon:update_tile(move.p_row, move.p_col)

					-- then the new one
					addon.game:set_cell_value(move.n_row, move.n_col, move.n_val)
					addon:update_tile(move.n_row, move.n_col)

					-- Pulse?
					if move.merged then
						n_tile.scale.anim:SetDuration(0.1)
						n_tile.scale.anim:SetScale(1.2, 1.2)
						n_tile.scale.anim:SetOrigin('CENTER', 0, 0)
						n_tile.scale.anim:SetScript('OnFinished', function()
							_anims_count = _anims_count - 1
						end)

						_anims_count = _anims_count + 1
						n_tile.scale:Play()
					end
				end)
				_anims_count = _anims_count + 1
				p_tile.trans:Play()
			end

			-- Redraw the game and wait for user input
			self:prepare_next_turn()
		end
	end
end

------------------------------------------------
-- Prepare for next turn
------------------------------------------------
function addon:prepare_next_turn()

	-- Wait for all anims to finish
	if _anims_count > 0 then
		self:ScheduleTimer('prepare_next_turn', 0.1)
		return
	end

	-- Make everything up-to-date, save the game's current state and redraw the board
	self.game:next_turn()
	self.game:save_state(self.db.global.game)
	self:update()

	-- Game won?
	if self.game:is_won() then
		self:show_message_box('MSG_WON')

	-- Game over?
	elseif self.game:is_over() then
		self:show_message_box('MSG_LOST')
	end
end
