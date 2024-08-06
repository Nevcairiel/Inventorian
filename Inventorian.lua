local _, Inventorian = ...
Inventorian = LibStub("AceAddon-3.0"):NewAddon(Inventorian, "Inventorian", "AceEvent-3.0", "AceHook-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Inventorian")

local db
local defaults = {
	profile = {
		bag = {
			x = -20,
			y = -80,
			point = "RIGHT",
			width = 384,
			height = 512,
			showBags = false,
		},
		bank = {
			x = 220,
			y = 120,
			point = "LEFT",
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
	},
	{
		title = L["Reagents"],
		bags = { 5 },
		isReagentBag = true,
	}
}
local BANK_CONFIG =
{
	{
		title = BANK,
		bags = { BANK_CONTAINER, 6, 7, 8, 9, 10, 11, 12 },
		isBank = true,
	},
	{
		title = L["Reagents"],
		bags = { REAGENTBANK_CONTAINER },
		isBank = true,
		isReagentBank = true,
	},
	{
		title = ACCOUNT_QUEST_LABEL,
		bags = { Enum.BagIndex.AccountBankTab_1, Enum.BagIndex.AccountBankTab_2, Enum.BagIndex.AccountBankTab_3, Enum.BagIndex.AccountBankTab_4, Enum.BagIndex.AccountBankTab_5 },
		isBank = true,
		isAccountBank = true,
	},
}
local ACCOUNT_BANK_CONFIG =
{
	{
		title = ACCOUNT_QUEST_LABEL,
		bags = { Enum.BagIndex.AccountBankTab_1, Enum.BagIndex.AccountBankTab_2, Enum.BagIndex.AccountBankTab_3, Enum.BagIndex.AccountBankTab_4, Enum.BagIndex.AccountBankTab_5 },
		isBank = true,
		isAccountBank = true,
	}
}


function Inventorian:OnEnable()
	self.bag = Inventorian.Frame:Create("InventorianBagFrame", L["%s's Inventory"], db.bag, BAG_CONFIG)
	self.bank = Inventorian.Frame:Create("InventorianBankFrame", L["%s's Bank"], db.bank, BANK_CONFIG)
	self.accountbank = Inventorian.Frame:Create("InventorianAccountBankFrame", L["%s's Account Bank"], db.bank, ACCOUNT_BANK_CONFIG)
	self:SetupBagHooks()

	self:RegisterChatCommand("inventorian", "HandleSlash")

	SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_EQUIP_REAGENT_BAG, true);
end

function Inventorian:HandleSlash(cmd)
	if strtrim(cmd) == "bank" then
		self.bank:ShowFrame()
	else
		self:Print("Available Commands:")
		self:Print(" /inventorian bank: Show the current characters bank")
	end
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

function Inventorian:AutoShowAccountBank()
	self.accountbank:ShowFrame(true)
end

function Inventorian:AutoHideBank()
	self.bank:HideFrame(true)
	self.accountbank:HideFrame(true)
end

function Inventorian:UpdateBag()
	self.bag:Update()
	self.bank:Update()
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
	self:RawHook("OpenBag", "OpenAllBags", true)

	--self:RawHook("GetBackpackFrame", function() return self.bag:IsShown() and self.bag or nil end, true)

	self:SecureHook(ContainerFrameSettingsManager.TokenTracker, "Update", function() Inventorian.Frame.ManageBackpackTokenFrame(self.bag) end, true)

	BankFrame:UnregisterAllEvents()
	BankFrame:SetScript("OnShow", nil)
	BankFrame:SetParent(self.UIHider)

	local Events = self:GetModule("Events")
	Events.Register(self, "BANK_OPENED", function()
		self:AutoShowBank()
		self:AutoShowInventory()
	end)

	Events.Register(self, "ACCOUNT_BANK_OPENED", function()
		self:AutoShowAccountBank()
		self:AutoShowInventory()
	end)

	Events.Register(self, "BANK_CLOSED", function()
		self:AutoHideBank()
		self:AutoHideInventory()
	end)

	self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
	self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")

	self:SecureHook("ContainerFrame_UpdateAll", "UpdateBag")

	-- noop out container anchor update
	UpdateContainerFrameAnchors = function() end

	-- stop the bank from being a UI Panel
	BankFrame:SetAttribute("UIPanelLayout-defined", true)
	BankFrame:SetAttribute("UIPanelLayout-area", nil)
end

function Inventorian:PLAYER_INTERACTION_MANAGER_FRAME_SHOW(event, id)
	if id == Enum.PlayerInteractionType.TradePartner then
		self:AutoShowInventory()
	elseif id == Enum.PlayerInteractionType.Auctioneer then
		self:AutoShowInventory()
	end
end

function Inventorian:PLAYER_INTERACTION_MANAGER_FRAME_HIDE(event, id)
	if id == Enum.PlayerInteractionType.MailInfo then
		self:AutoHideInventory() -- only close when leaving the mailbox, don't auto-open here
	elseif id == Enum.PlayerInteractionType.TradePartner then
		self:AutoHideInventory()
	elseif id == Enum.PlayerInteractionType.Auctioneer then
		self:AutoHideInventory()
	end
end
