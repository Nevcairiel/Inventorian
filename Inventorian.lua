local _, Inventorian = ...
Inventorian = LibStub("AceAddon-3.0"):NewAddon(Inventorian, "Inventorian", "AceEvent-3.0", "AceHook-3.0")

local db
local defaults = {
	profile = {
		bag = {
			x = 0,
			y = 0,
			point = "CENTER",
			width = 384,
			height = 512,
		},
		bank = {
			width = 512,
			height = 512,
		},
	}
}

function Inventorian:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("InventorianDB", defaults, true)
	db = self.db.profile
end

function Inventorian:OnEnable()
	self.bag = Inventorian.Frame:Create("InventorianBagFrame", "Bag", db.bag, {0, 1, 2, 3, 4})
	self.bank = Inventorian.Frame:Create("InventorianBankFrame", "Bank", db.bank, {-1, 5, 6, 7, 8, 9, 10, 11}, true)
	self:SetupBagHooks()
end

function Inventorian:AutoShowInventory()
	self.bag:ShowFrame(true)
end

function Inventorian:AutoHideInventory()
	self.bag:HideFrame(true)
end

function Inventorian:ToggleBackpack()
	self.bag:ToggleFrame()
end

function Inventorian:OpenAllBags()
	self.bag:ShowFrame()
end

function Inventorian:CloseAllBags()
	self.bag:HideFrame()
end

function Inventorian:AutoShowBank()
	self.bank:ShowFrame(true)
end

function Inventorian:AutoHideBank()
	self.bank:HideFrame(true)
end

function Inventorian:SetupBagHooks()
	-- auto magic display code
	self:RawHook("OpenBackpack", "AutoShowInventory", true)
	self:SecureHook("CloseBackpack", "AutoHideInventory")

	self:RawHook("ToggleBag", "ToggleBackpack", true)
	self:RawHook("ToggleBackpack", true)
	self:RawHook("ToggleAllBags", "ToggleBackpack", true)
	self:RawHook("OpenAllBags", true)

	--closing the game menu triggers this function, and can be done in combat,
	self:SecureHook("CloseAllBags")

	BankFrame:UnregisterAllEvents()

	local Events = self:GetModule("Events")
	Events.Register(self, "BANK_OPENED", function()
		self:AutoShowBank()
		self:AutoShowInventory()
	end)

	Events.Register(self, "BANK_CLOSED", function()
		self:AutoHideBank()
		self:AutoHideInventory()
	end)

	self:RegisterEvent("MAIL_CLOSED", "AutoHideInventory")
	self:RegisterEvent("TRADE_SHOW", "AutoShowInventory")
	self:RegisterEvent("TRADE_CLOSED", "AutoHideInventory")
	self:RegisterEvent("TRADE_SKILL_SHOW", "AutoShowInventory")
	self:RegisterEvent("TRADE_SKILL_CLOSE", "AutoHideInventory")
	self:RegisterEvent("AUCTION_HOUSE_SHOW", "AutoShowInventory")
	self:RegisterEvent("AUCTION_HOUSE_CLOSED", "AutoHideInventory")
end
