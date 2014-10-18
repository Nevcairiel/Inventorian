local _, Inventorian = ...
Inventorian = LibStub("AceAddon-3.0"):NewAddon(Inventorian, "Inventorian", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Inventorian")

local db
local defaults = {
	profile = {
		bag = {
			x = 0,
			y = 0,
			point = "CENTER",
			width = 384,
			height = 512,
			showBags = false,
		},
		bank = {
			width = 512,
			height = 512,
			showBags = false,
		},
	}
}

function Inventorian:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("InventorianDB", defaults, true)
	db = self.db.profile
end

local BAG_CONFIG =
{
	{
		title = BAGSLOT,
		bags = { BACKPACK_CONTAINER, 1, 2, 3, 4 }
	}
}

local BANK_CONFIG =
{
	{
		title = BANK,
		bags = { BANK_CONTAINER, 5, 6, 7, 8, 9, 10, 11 }
	},
	{
		title = L["Reagents"],
		bags = { REAGENTBANK_CONTAINER }
	}
}

function Inventorian:OnEnable()
	self.bag = Inventorian.Frame:Create("InventorianBagFrame", L["%s's Inventory"], db.bag, BAG_CONFIG)
	self.bank = Inventorian.Frame:Create("InventorianBankFrame", L["%s's Bank"], db.bank, BANK_CONFIG, true)
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
	self.UIHider = CreateFrame("Frame")
	self.UIHider:Hide()

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
	BankFrame:SetScript("OnShow", nil)
	BankFrame:SetParent(self.UIHider)

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
