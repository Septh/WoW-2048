
local addon = LibStub('AceAddon-3.0'):NewAddon('2048', 'AceConsole-3.0', 'AceTimer-3.0')
local L     = LibStub('AceLocale-3.0'):GetLocale('2048')

-- Game defaults
local grid_size     = 4

-- UI Elements
local tile_size     = 60
local gutter_size   = 8
local tile_distance = tile_size + gutter_size			-- The distance a tile moves on the board
local board_width   = (tile_size * grid_size) + (gutter_size * (grid_size + 1))
local board_height  = board_width
local title_height  = 60
local score_height  = 60
local intro_height  = 30
local pad_size      = 24 * 3
local inner_width   = board_width
local inner_height  = math.max(title_height, score_height) + intro_height + 10 + board_height + 10 + pad_size
local border_size   = 10
local frame_width   = inner_width + (border_size * 2)
local frame_height  = inner_height + (border_size * 2)	-- Full height, including pad

-- Message box
local messages = {
	['MSG_WON']     = { text = L['You won!'],   butt1 = L['New game'], butt2 = L['Keep playing'] },
	['MSG_LOST']    = { text = L['Game over!'], butt1 = L['Restart'],  butt2 = nil               },
	['MSG_RESTART'] = { text = L['Restart?'],   butt1 = L['Yes'],      butt2 = L['No']           },
}

-- Textures and colors
local plain_bg = {
	bgFile = 'Interface\\Buttons\\White8x8',
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
		version = 1.1,
		frame = {
			scale = 1.0,
			useKeyboard = true,
			usePad = true,
			pos = {
				p = 'CENTER',
				x = 0,
				y = 0,
			},
		},
		game = {
			best  = 0,
			score = 0,
			moves = 0,
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
		punchline = {
			order = 1,
			type  = 'description',
			name  = L['Play while you wait to play!'] .. '\n',
			fontSize  = 'medium'
		},

		version = {
			order = 2,
			type  = 'description',
			name  = 'Version 1.1.0' -- GetAddOnMetadata('2048', 'Version') won't work :(
		},

		author = {
			order = 3,
			type  = 'description',
			name  = 'Septh - https://github.com/Septh/WoW-2048'
		},

		sep = {
			order = 4,
			type  = 'header',
			name  = ''
		},

		useKeyboard = {
			order = 10,
			type  = 'toggle',
			name  = L['Enable keyboard use'],
			get   = function(info) return addon.db.global.frame.useKeyboard end,
			set   = function(info, value)
				addon.db.global.frame.useKeyboard = value
				addon.frame:EnableKeyboard(value)
			end,
		},
		useKeyboard_crlf = {
			order = 11,
			type  = 'description',
			name  = ''
		},

		usePad = {
			order = 15,
			type  = 'toggle',
			name  = L['Enable pad'],
			get   = function(info) return addon.db.global.frame.usePad end,
			set   = function(info, value)
				addon.db.global.frame.usePad = value
				if value then
					addon.frame:SetHeight(frame_height)
					addon.frame.pad:Show()
				else
					addon.frame.pad:Hide()
					addon.frame:SetHeight(frame_height - pad_size)
				end
			end,
		},
		usePad_crlf = {
			order = 16,
			type  = 'description',
			name  = ''
		},

		scale = {
			order = 20,
			type  = 'range',
			name  = L['Window scale'],
			min   = 0.3,
			max   = 2.0,
			step  = 0.05,
			width = 'full',
			get   = function(info) return addon.db.global.frame.scale end,
			set   = function(info, value)
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
	if math.floor(self.db.global.version or 0) < 1 then self:import_old_settings() end

	-- Prepare the fonts
	local function make_font(name, style, size)
		local f = CreateFont(name)
		f:SetFont('Interface\\AddOns\\2048\\fonts\\ClearSans\\ClearSans-' .. style .. '.ttf', size)
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
	self.frame:SetSize(frame_width, frame_height)
	self.frame:SetScale(self.db.global.frame.scale)
	self.frame:SetBackdrop(plain_bg)
	self.frame:SetBackdropColor(unpack(colors['bg']['frame']))
	self.frame:EnableMouse(true)
	self.frame:SetMovable(true)
	self.frame:SetClampedToScreen(true)
	self.frame:RegisterForDrag('LeftButton')
	self.frame:Hide()

	self.frame.fadein = self.frame:CreateAnimationGroup()
	self.frame.fadein.anim = self.frame.fadein:CreateAnimation('Alpha')
	self.frame.fadein.anim:SetFromAlpha(0.5)
	self.frame.fadein.anim:SetToAlpha(1.0)
	self.frame.fadein.anim:SetDuration(0.2)
	self.frame.fadein.anim:SetSmoothing('IN')
	self.frame.fadein:SetToFinalAlpha(true)

	self.frame.fadeout = self.frame:CreateAnimationGroup()
	self.frame.fadeout.anim = self.frame.fadeout:CreateAnimation('Alpha')
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
	self.frame:SetScript('OnEnter', function(frame, motion)
		if not motion or frame.skipNextEnter then frame.skipNextEnter = nil; return end
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
	self.frame.title = self.frame:CreateFontString(nil, 'ARTWORK')
	self.frame.title:SetFontObject(self.ClearSansBold32)
	self.frame.title:SetPoint('TOPLEFT', border_size, -border_size)
	self.frame.title:SetSize(inner_width, title_height)
	self.frame.title:SetText('2048')
	self.frame.title:SetTextColor(unpack(colors['fg']['title']))
	self.frame.title:SetJustifyH('LEFT')

	-- scores
	self.frame.best = {}
	self.frame.best.bg = self.frame:CreateTexture(nil, 'BACKGROUND', nil, 1)
	self.frame.best.bg:SetPoint('TOPRIGHT', -border_size, -border_size)
	self.frame.best.bg:SetSize(tile_size, score_height)
	self.frame.best.bg:SetColorTexture(unpack(colors['bg']['score']))
	self.frame.best.label = self.frame:CreateFontString(nil, 'ARTWORK')
	self.frame.best.label:SetPoint('TOP', self.frame.best.bg, 'TOP', 0, -10)
	self.frame.best.label:SetFontObject(self.ClearSansBold14)
	self.frame.best.label:SetTextColor(unpack(colors['fg']['score']))
	self.frame.best.label:SetText(L['BEST'])
	self.frame.best.text = self.frame:CreateFontString(nil, 'ARTWORK')
	self.frame.best.text:SetPoint('BOTTOM', self.frame.best.bg, 'BOTTOM', 0, 10)
	self.frame.best.text:SetFontObject(self.ClearSansBold14)
	self.frame.best.text:SetTextColor(unpack(colors['fg']['score']))
	self.frame.best.text:SetText('0')

	self.frame.score = {}
	self.frame.score.bg = self.frame:CreateTexture(nil, 'BACKGROUND', nil, 1)
	self.frame.score.bg:SetPoint('TOPRIGHT', self.frame.best.bg, 'TOPLEFT', -1, 0)
	self.frame.score.bg:SetSize(tile_size, score_height)
	self.frame.score.bg:SetColorTexture(unpack(colors['bg']['score']))
	self.frame.score.label = self.frame:CreateFontString(nil, 'ARTWORK')
	self.frame.score.label:SetPoint('TOP', self.frame.score.bg, 'TOP', 0, -10)
	self.frame.score.label:SetFontObject(self.ClearSansBold14)
	self.frame.score.label:SetTextColor(unpack(colors['fg']['score']))
	self.frame.score.label:SetText(L['SCORE'])
	self.frame.score.text = self.frame:CreateFontString(nil, 'ARTWORK')
	self.frame.score.text:SetPoint('BOTTOM', self.frame.score.bg, 'BOTTOM', 0, 10)
	self.frame.score.text:SetFontObject(self.ClearSansBold14)
	self.frame.score.text:SetTextColor(unpack(colors['fg']['score']))
	self.frame.score.text:SetText('0')

	self.frame.moves = {}
	self.frame.moves.bg = self.frame:CreateTexture(nil, 'BACKGROUND', nil, 1)
	self.frame.moves.bg:SetPoint('TOPRIGHT', self.frame.score.bg, 'TOPLEFT', -1, 0)
	self.frame.moves.bg:SetSize(tile_size, score_height)
	self.frame.moves.bg:SetColorTexture(unpack(colors['bg']['score']))
	self.frame.moves.label = self.frame:CreateFontString(nil, 'ARTWORK')
	self.frame.moves.label:SetPoint('TOP', self.frame.moves.bg, 'TOP', 0, -10)
	self.frame.moves.label:SetFontObject(self.ClearSansBold14)
	self.frame.moves.label:SetTextColor(unpack(colors['fg']['score']))
	self.frame.moves.label:SetText(L['MOVES'])
	self.frame.moves.text = self.frame:CreateFontString(nil, 'ARTWORK')
	self.frame.moves.text:SetPoint('BOTTOM', self.frame.moves.bg, 'BOTTOM', 0, 10)
	self.frame.moves.text:SetFontObject(self.ClearSansBold14)
	self.frame.moves.text:SetTextColor(unpack(colors['fg']['score']))
	self.frame.moves.text:SetText('0')

	-- punch line
	self.frame.punchline = self.frame:CreateFontString(nil, 'ARTWORK')
	self.frame.punchline:SetPoint('TOPLEFT', self.frame.title, 'BOTTOMLEFT')
	self.frame.punchline:SetSize(inner_width, intro_height)
	self.frame.punchline:SetFontObject(self.ClearSans14)
	self.frame.punchline:SetTextColor(unpack(colors['fg']['info']))
	self.frame.punchline:SetJustifyH('LEFT')
	self.frame.punchline:SetText(L['Join the numbers and get to the |cFFFF00002048|r tile!'])

	-- board
	self.frame.board = self.frame:CreateTexture(nil, 'BACKGROUND', nil, 1)
	self.frame.board:SetPoint('TOP', self.frame.punchline, 'BOTTOM', 0, -10)
	self.frame.board:SetSize(board_width, board_height)
	self.frame.board:SetColorTexture(unpack(colors['bg']['board']))
	local x, y = gutter_size, -gutter_size
	for row = 1, grid_size do
		for col = 1, grid_size do
			local bg = self.frame:CreateTexture(nil, 'BACKGROUND', nil, 2)
			bg:SetPoint('TOPLEFT', self.frame.board, x, y)
			bg:SetSize(tile_size, tile_size)
			bg:SetColorTexture(unpack(colors['bg']['tiles'][0]))
			x = x + tile_size + gutter_size
		end
		y = y - tile_size - gutter_size
		x = gutter_size
	end

	-- Pad
	self.frame.pad = CreateFrame('Frame', nil, self.frame)
	self.frame.pad:SetPoint('TOP', self.frame.board, 'BOTTOM', 0, -10)
	self.frame.pad:SetSize(pad_size, pad_size)

	self.frame.pad.b1 = CreateFrame('Button', nil, self.frame.pad, 'UIPanelSquareButton')
	self.frame.pad.b1:SetPoint('CENTER')
	self.frame.pad.b1:SetSize(24, 24)
	SquareButton_SetIcon(self.frame.pad.b1, 'DELETE')
	self.frame.pad.b1:RegisterForClicks('AnyUp')
	self.frame.pad.b1:SetScript('OnClick', function(self, ...)
		addon:handle_key('ENTER')
	end)

	self.frame.pad.b2 = CreateFrame('Button', nil, self.frame.pad, 'UIPanelSquareButton')
	self.frame.pad.b2:SetPoint('TOP')
	self.frame.pad.b2:SetSize(24, 24)
	SquareButton_SetIcon(self.frame.pad.b2, 'UP')
	self.frame.pad.b2:RegisterForClicks('AnyUp')
	self.frame.pad.b2:SetScript('OnClick', function(self, ...)
		addon:handle_key('UP')
	end)

	self.frame.pad.b3 = CreateFrame('Button', nil, self.frame.pad, 'UIPanelSquareButton')
	self.frame.pad.b3:SetPoint('LEFT')
	self.frame.pad.b3:SetSize(24, 24)
	SquareButton_SetIcon(self.frame.pad.b3, 'LEFT')
	self.frame.pad.b3:RegisterForClicks('AnyUp')
	self.frame.pad.b3:SetScript('OnClick', function(self, ...)
		addon:handle_key('LEFT')
	end)

	self.frame.pad.b4 = CreateFrame('Button', nil, self.frame.pad, 'UIPanelSquareButton')
	self.frame.pad.b4:SetPoint('BOTTOM')
	self.frame.pad.b4:SetSize(24, 24)
	SquareButton_SetIcon(self.frame.pad.b4, 'DOWN')
	self.frame.pad.b4:RegisterForClicks('AnyUp')
	self.frame.pad.b4:SetScript('OnClick', function(self, ...)
		addon:handle_key('DOWN')
	end)

	self.frame.pad.b5 = CreateFrame('Button', nil, self.frame.pad, 'UIPanelSquareButton')
	self.frame.pad.b5:SetPoint('RIGHT')
	self.frame.pad.b5:SetSize(24, 24)
	SquareButton_SetIcon(self.frame.pad.b5, 'RIGHT')
	self.frame.pad.b5:RegisterForClicks('AnyUp')
	self.frame.pad.b5:SetScript('OnClick', function(self, ...)
		addon:handle_key('RIGHT')
	end)

	if not self.db.global.frame.usePad then
		self.frame.pad:Hide()
		self.frame:SetHeight(frame_height - pad_size)
	end

	-- Special frames: tiles
	self.tiles = {}
	local x, y = gutter_size, -gutter_size
	for row = 1, grid_size do
		for col = 1, grid_size do

			local t = CreateFrame('Frame', nil, self.frame)
			self.tiles[row..'x'..col] = t

			t:SetPoint('TOPLEFT', self.frame.board, x, y)
			t:SetSize(tile_size, tile_size)
			t:SetBackdrop(plain_bg)
			t:SetBackdropColor(unpack(colors['bg']['tiles'][0]))

			t.s = t:CreateFontString(nil, 'ARTWORK')
			t.s:SetFontObject(self.ClearSansBold20)
			t.s:SetAllPoints(t)
			t.s:SetText('')

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

	-- Special frame: Message box
	self.msgbox = CreateFrame('Frame', nil, self.frame)
	self.msgbox:SetAllPoints(self.frame.board)
	self.msgbox:SetBackdrop(plain_bg)
	self.msgbox:SetBackdropColor(unpack(colors['bg']['msgbox']['msg']))
	self.msgbox:SetFrameLevel(self.frame:GetFrameLevel() + 10)
	self.msgbox:EnableKeyboard(true)
	self.msgbox:Hide()
	self.msgbox:SetScript('OnKeyDown', function(frame, key)
		addon:handle_key(key)
	end)

	self.msgbox.text = self.msgbox:CreateFontString(nil, 'ARTWORK')
	self.msgbox.text:SetAllPoints(self.frame.board)
	self.msgbox.text:SetPoint('TOPLEFT', self.frame.board, 'TOPLEFT', 0, -tile_size)
	self.msgbox.text:SetPoint('BOTTOMRIGHT', self.frame.board, 'BOTTOMRIGHT', 0, tile_size*2)
	self.msgbox.text:SetJustifyV('TOP')
	self.msgbox.text:SetFontObject(self.ClearSansBold20)
	self.msgbox.text:SetTextColor(unpack(colors['fg']['msgbox']['msg']))

	self.msgbox.button1 = CreateFrame('button', nil, self.msgbox)
	self.msgbox.button1:SetPoint('BOTTOM', 0, 10)
	self.msgbox.button1:SetSize(150, 30)
	self.msgbox.button1:SetBackdrop(plain_bg)
	self.msgbox.button1:SetBackdropColor(unpack(colors['bg']['msgbox']['button1']))
	self.msgbox.button1:SetNormalFontObject(self.ClearSansBold14)
	self.msgbox.button1:SetHighlightTexture('Interface\\Buttons\\UI-Common-MouseHilight', 'ADD')
	self.msgbox.button1:RegisterForClicks('AnyUp')
	self.msgbox.button1:SetScript('OnClick', function(self)
		addon:handle_message_button(1)
	end)

	self.msgbox.button2 = CreateFrame('button', nil, self.msgbox)
	self.msgbox.button2:SetPoint('BOTTOM', self.msgbox.button1, 'TOP', 0, 10)
	self.msgbox.button2:SetSize(150, 30)
	self.msgbox.button2:SetBackdrop(plain_bg)
	self.msgbox.button2:SetBackdropColor(unpack(colors['bg']['msgbox']['button2']))
	self.msgbox.button2:SetNormalFontObject(self.ClearSansBold14)
	self.msgbox.button2:SetHighlightTexture('Interface\\Buttons\\UI-Common-MouseHilight', 'ADD')
	self.msgbox.button2:RegisterForClicks('AnyUp')
	self.msgbox.button2:SetScript('OnClick', function(self)
		addon:handle_message_button(2)
	end)

	self.msgbox.fadein = self.msgbox:CreateAnimationGroup()
	self.msgbox.fadein.anim = self.msgbox.fadein:CreateAnimation('Alpha')
	self.msgbox.fadein.anim:SetDuration(0.5)
	-- self.msgbox.fadein.anim:SetStartDelay(0.2)
	self.msgbox.fadein.anim:SetFromAlpha(0)
	self.msgbox.fadein.anim:SetToAlpha(1.0)
	self.msgbox.fadein.anim:SetDuration(0.2)
	self.msgbox.fadein.anim:SetSmoothing('NONE')
	self.msgbox.fadein:SetToFinalAlpha(true)
	self.msgbox.fadein:SetScript('OnPlay', function()
		addon.msgbox:SetAlpha(0)
		addon.msgbox:Show()
	end)

	self.msgbox.fadeout = self.msgbox:CreateAnimationGroup()
	self.msgbox.fadeout.anim = self.msgbox.fadeout:CreateAnimation('Alpha')
	self.msgbox.fadeout.anim:SetDuration(0.5)
	-- self.msgbox.fadeout.anim:SetStartDelay(0.3)
	self.msgbox.fadeout.anim:SetFromAlpha(1.0)
	self.msgbox.fadeout.anim:SetToAlpha(0)
	self.msgbox.fadeout.anim:SetDuration(0.2)
	self.msgbox.fadeout.anim:SetSmoothing('NONE')
	self.msgbox.fadeout:SetToFinalAlpha(true)
	self.msgbox.fadeout:SetScript('OnFinished', function()
		addon.msgbox:Hide()
		addon.msgbox:SetAlpha(0)
	end)

	-- Setup options panel
	LibStub('AceConfig-3.0'):RegisterOptionsTable('2048', config_table)
    LibStub('AceConfigDialog-3.0'):AddToBlizOptions('2048')

	-- Enable slash command
	self:RegisterChatCommand('2048', 'ToggleGameBoard')
end

------------------------------------------------
function addon:import_old_settings()
	self:Print(L['Old settings reset to defaults - sorry about that.'])
	self.db:ResetDB('Default')
end

------------------------------------------------
function addon:OnEnable()

	-- Initialize LDB if found (done here since we don't embed
	-- the LDB library and it may not be available at OnInitialize() time)
	self.ldb = self.ldb or LibStub('LibDataBroker-1.1', true)
	if self.ldb then

		-- Texture for LDB frame highlighting
		if not self.highlightFrame then
			self.highlightFrame = CreateFrame('Frame')
			self.highlightFrame:Hide()
		end
		if not self.highlightTexture then
			self.highlightTexture = self.highlightFrame:CreateTexture(nil, 'OVERLAY')
			self.highlightTexture:SetTexture('Interface\\QuestFrame\\UI-QuestTitleHighlight')
			self.highlightTexture:SetBlendMode('ADD')
		end

		self.lbo = self.lbo or self.ldb:NewDataObject('2048', {
				type = 'launcher',
				icon = 'Interface\\AddOns\\2048\\img\\checkboard',
				OnEnter = function(LDBFrame)
					-- Highlight the LDB frame if not using Bazooka
					local LDBFrameName = LDBFrame:GetName() or ''
					if not LDBFrameName:find('Bazooka', 1) then
						addon.highlightTexture:SetParent(LDBFrame)
						addon.highlightTexture:SetAllPoints(LDBFrame)
					end

					-- Show the tooltip
					local x, y, w, h = LDBFrame:GetRect()
					local sw, sh = UIParent:GetSize()
					local p

					if (y + h) < (sh / 2)  then
						p = 'ANCHOR_TOP'
					else
						p = 'ANCHOR_BOTTOM'
					end

					GameTooltip:SetOwner(LDBFrame, p)
					GameTooltip:AddLine('2048')
					GameTooltip:Show()
				end,
				OnLeave = function(LDBFrame)
					if GameTooltip:GetOwner() == LDBFrame then
						-- Hide the tooltip
						GameTooltip:Hide()

						-- Turn highlighting off
						addon.highlightTexture:SetParent(addon.highlightFrame)
					end
				end,
				OnClick = function(LDBFrame, button)
					if button == 'LeftButton' then
						addon:ToggleGameBoard()
					elseif button == 'RightButton' then
						InterfaceOptionsFrame_OpenToCategory('2048')
						InterfaceOptionsFrame_OpenToCategory('2048')	-- Twice
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

	-- Simply play the anim, the OnPlay script will show the frame
	self.msgbox.fadein:Play()
end

------------------------------------------------
function addon:hide_message_box()
	-- Simply play the anim, the OnFinished script will hide the frame
	self.msgbox.fadeout:Play()
end

------------------------------------------------
function addon:msgbox_is_shown()
	 -- Shown, showing or not finished hidding
	return (self.msgbox:IsShown() and not self.msgbox.fadeout:IsPlaying()) or self.msgbox.fadein:IsPlaying()
end

------------------------------------------------
function addon:handle_message_button(button)

	-- Hide the frame
	self:hide_message_box()

	-- Handle the button
	if self.msgbox.q == 'MSG_WON' then
		if button == 1 then
			-- Can't call next_turn() here since it would add a new tile
			self.game:new_game()
			self.game:save_state(self.db.global.game)
			self:update()
		else
			self.game:keep_playing()
			self:prepare_next_turn()
		end

	elseif self.msgbox.q == 'MSG_LOST' then
		-- Ditto
		self.game:new_game()
		self.game:save_state(self.db.global.game)
		self:update()

	elseif self.msgbox.q == 'MSG_RESTART' then
		if button == 1 then
			-- Ditto
			self.game:new_game()
			self.game:save_state(self.db.global.game)
			self:update()
		end
	end
end

------------------------------------------------
-- Redraw the whole game
------------------------------------------------
function addon:update()

	if self:msgbox_is_shown() then return end

	self:update_scores()
	self:update_board()
end

------------------------------------------------
function addon:update_scores()
	local moves, score, best = self.game:get_scores()

	self.frame.moves.text:SetText(moves)
	self.frame.score.text:SetText(score)
	self.frame.best.text:SetText(best)
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

	if key == 'ESCAPE' then
		-- Works whether the message_box is shown or not
		self:ToggleGameBoard()
	elseif self:msgbox_is_shown() then
		return
	end

	if key == 'ENTER' then
		self:show_message_box('MSG_RESTART')

	elseif _keys[key] then
		-- Move the tiles
		local moves = self.game:move_cells(key)

		-- Animate those tiles that were actually moved
		if #moves > 0 then
			_anims_count = 0
			for xx, move in ipairs(moves) do
				local p_row, p_col, n_row, n_col, n_val = move.p_row, move.p_col, move.n_row, move.n_col, move.n_val

				local p_tile = self.tiles[p_row..'x'..p_col]
				local n_tile = self.tiles[n_row..'x'..n_col]

				-- Transition the tiles from their previous position to the new one
				p_tile:SetFrameLevel(p_tile:GetFrameLevel() + 2)	-- Make sure moving tiles are above the others
				p_tile.trans.anim:SetDuration(0.1)
				p_tile.trans.anim:SetOffset((n_col - p_col) * tile_distance, -((n_row - p_row) * tile_distance))
				p_tile.trans.anim:SetStartDelay(xx * 0.01)			--- nicer
				p_tile.trans.anim:SetScript('OnFinished', function()
					_anims_count = _anims_count - 1

					-- Update the old position
					addon.game:set_cell_value(p_row, p_col, 0)
					addon:update_tile(p_row, p_col)

					-- then the new one
					addon.game:set_cell_value(n_row, n_col, n_val)
					addon:update_tile(n_row, n_col)

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
