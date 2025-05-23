local _, Inventorian = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Inventorian")

local ItemCache = LibStub("LibItemCache-1.1-Inventorian")

local FrameMixin = {}

local LibWindow = LibStub("LibWindow-1.1")
local Events = Inventorian:GetModule("Events")

local ITEM_CONTAINER_OFFSET_W = -22
local ITEM_CONTAINER_OFFSET_H = -95
local TOKEN_CONTAINER_HEIGHT = 20

local PLAYER_NAME = string.format("%s - %s", UnitName("player"), GetRealmName())

AddMoneyTypeInfo("INVENTORIAN", {
		UpdateFunc = function(self)
			return ItemCache:GetPlayerMoney(self:GetParent():GetPlayerName())
		end,

		collapse = 1,
		showSmallerCoins = "Backpack"
	})

local function OnDepositClick(button)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
	DepositReagentBank()
end

Inventorian.Frame = {}
Inventorian.Frame.defaults = {}
function Inventorian.Frame:Create(name, titleText, settings, config)
	local frame = Mixin(CreateFrame("Frame", name, UIParent, "InventorianFrameTemplate"), FrameMixin)

	-- settings
	frame.config = config
	frame.settings = settings
	frame.titleText = titleText
	frame.currentConfig = config[1]
	frame.bagButtons = {}

	if frame:IsBank() then
		frame:SetResizeBounds(275, 325)
	else
		frame:SetResizeBounds(250, 260)
	end

	frame.PortraitContainer.portrait:SetPoint("TOPLEFT", -5, 8)

	-- components
	frame.itemContainer = Inventorian.ItemContainer:Create(frame)
	frame.itemContainer:SetPoint("TOPLEFT", 10, -68)
	frame.itemContainer:Show()

	frame.DepositButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.DepositButton:SetText(REAGENTBANK_DEPOSIT)
	frame.DepositButton:SetSize(256, 24)
	frame.DepositButton:SetPoint("BOTTOM", 0, 31)
	frame.DepositButton:SetScript("OnClick", OnDepositClick)
	frame.DepositButton:SetFrameLevel(frame:GetFrameLevel() + 5)
	frame.DepositButton:Hide()

	if frame:IsBank() then
		frame.MoneyDepositButton = Mixin(CreateFrame("Button", nil, frame, "BankPanelMoneyFrameButtonTemplate"), BankPanelDepositMoneyButtonMixin)
		frame.MoneyDepositButton.GetBankFrame = function() return frame end
		frame.MoneyDepositButton:SetText(BANK_DEPOSIT_MONEY_BUTTON_LABEL)
		frame.MoneyDepositButton:SetScript("OnClick", frame.MoneyDepositButton.OnClick)
		frame.MoneyDepositButton:SetFrameLevel(frame:GetFrameLevel() + 5)
		frame.MoneyDepositButton:SetPoint("BOTTOMRIGHT", frame, -6, 6)
		frame.MoneyDepositButton:Hide()

		frame.MoneyWithdrawButton = Mixin(CreateFrame("Button", nil, frame, "BankPanelMoneyFrameButtonTemplate"), BankPanelWithdrawMoneyButtonMixin)
		frame.MoneyWithdrawButton.GetBankFrame = function() return frame end
		frame.MoneyWithdrawButton:SetText(BANK_WITHDRAW_MONEY_BUTTON_LABEL)
		frame.MoneyWithdrawButton:SetScript("OnClick", frame.MoneyWithdrawButton.OnClick)
		frame.MoneyWithdrawButton:SetFrameLevel(frame:GetFrameLevel() + 5)
		frame.MoneyWithdrawButton:SetPoint("RIGHT", frame.MoneyDepositButton, "LEFT", 0, 0)
		frame.MoneyWithdrawButton:Hide()

		frame.Money:ClearAllPoints()
		frame.Money:SetPoint("BOTTOMRIGHT", frame.MoneyWithdrawButton, "BOTTOMLEFT", 0, 3)
		frame.Money:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 9)
	end

	frame:CreateTabs()

	-- scripts
	frame:SetScript("OnShow", frame.OnShow)
	frame:SetScript("OnHide", frame.OnHide)
	frame:SetScript("OnEvent", frame.OnEvent)
	frame:SetScript("OnSizeChanged", frame.OnSizeChanged)

	-- bag events
	if frame:IsBank() then
		frame:RegisterEvent("BANK_TABS_CHANGED")
		frame:RegisterEvent("BANK_TAB_SETTINGS_UPDATED")
	end

	-- non-bag events
	frame:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player")

	-- load and apply config
	frame:SetWidth(settings.width)
	frame:SetHeight(settings.height)

	LibWindow.RegisterConfig(frame, settings)
	LibWindow.RestorePosition(frame)

	frame:UpdateTitleText()
	frame:SetCurrentBags()

	tinsert(UISpecialFrames, name)

	return frame
end

local function OnTabClick(tab)
	local frame = tab:GetParent()
	local tabID = tab:GetID()
	if frame.selectedTab ~= tabID then
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
	end

	PanelTemplates_SetTab(frame, tabID)
	frame.currentConfig = frame.config[tabID]
	frame:SetCurrentBags()

	-- hack for the warbank and reagent bank to behave properly when right-clicking inventory items
	if frame:IsBank() and frame:AtBank() then
		local bankTabIndex = frame:IsReagentBank() and 2 or frame:IsAccountBank() and 3 or 1
		BankFrame.selectedTab = bankTabIndex
		BankFrame.activeTabIndex = bankTabIndex
		if frame:IsReagentBank() or frame:IsAccountBank() then
			BankFrame:Show()
		else
			BankFrame:Hide()
		end
	end

	ReagentBankFrameUnlockInfo:Hide()
	frame.DepositButton:Hide()
	if frame:IsReagentBank() then
		if not IsReagentBankUnlocked() then
			local UnlockInfo = ReagentBankFrameUnlockInfo
			UnlockInfo:SetParent(frame.itemContainer)
			UnlockInfo:SetFrameLevel(frame.itemContainer:GetFrameLevel() + 10)
			UnlockInfo:ClearAllPoints()
			UnlockInfo:SetPoint("TOPLEFT", -8, 1)
			UnlockInfo:SetPoint("BOTTOMRIGHT", 8, -1)
			UnlockInfo:Show()

			MoneyFrame_Update(UnlockInfo.CostMoneyFrame, GetReagentBankCost())
		end

		frame.DepositButton:Show()
	end

	frame:UpdateBags()
	frame:UpdateMoneyFrame()
end

function FrameMixin:CreateTabs()
	local numConfigs = #self.config
	if numConfigs <= 1 then return end

	-- tab settings
	self.tabPadding = 0
	self.minTabWidth = 62
	self.maxTabWidth = 88

	self.tabs = {}
	for i = 1, numConfigs do
		local tab = CreateFrame("Button", self:GetName() .. "Tab" .. i, self, "PanelTabButtonTemplate")
		tab:SetScript("OnClick", OnTabClick)
		tab:SetID(i)
		tab:SetText(self.config[i].title)

		if i > 1 then
			tab:SetPoint("LEFT", self.tabs[i-1], "RIGHT", -16, 0)
		else
			tab:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 19, -30)
		end

		self.tabs[i] = tab
	end

	PanelTemplates_SetNumTabs(self, numConfigs)
	PanelTemplates_SetTab(self, 1)
end

function FrameMixin:SetCurrentBags()
	if self:IsAccountBank() then
		self.selectedWarbandBag = self.selectedWarbandBag or self.currentConfig.bags[1]
		self.itemContainer:SetBags({ self.selectedWarbandBag })
	else
		self.itemContainer:SetBags(self.currentConfig.bags)
	end
	self:UpdateBags()
	self:UpdateMoneyFrame()
end

function FrameMixin:ShowTokenFrame()
	self:SetHeight(self.settings.height + TOKEN_CONTAINER_HEIGHT)
	BackpackTokenFrame:SetParent(self)
	BackpackTokenFrame:ClearAllPoints()
	BackpackTokenFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -6, 9)
	BackpackTokenFrame:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 6, 9)
	BackpackTokenFrame:Show()

	self.Money:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -6, 9 + TOKEN_CONTAINER_HEIGHT)
	self.Money:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 6, 9 + TOKEN_CONTAINER_HEIGHT)
end

function FrameMixin:HideTokenFrame()
	self:SetHeight(self.settings.height)
	BackpackTokenFrame:Hide()

	self.Money:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -6, 9)
	self.Money:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 6, 9)
end

function Inventorian.Frame.ManageBackpackTokenFrame(backpack)
	if not backpack or InventorianBagFrame:IsCached() then
		InventorianBagFrame:HideTokenFrame()
		return
	end
	if BackpackTokenFrame:ShouldShow() then
		InventorianBagFrame:ShowTokenFrame()
	else
		InventorianBagFrame:HideTokenFrame()
	end
end

function FrameMixin:OnShow()
	PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
	self:SetPortrait()

	if self:IsBank() and not self:IsCached() then
		local bankTabIndex = self:IsReagentBank() and 2 or self:IsAccountBank() and 3 or 1
		BankFrame.selectedTab = bankTabIndex
		BankFrame.activeTabIndex = bankTabIndex
		if self:IsReagentBank() or self:IsAccountBank() then
			BankFrame:Show()
		end
	end

	if not self:IsBank() then
		BackpackTokenFrame:Update()
	end
end

function FrameMixin:OnHide()
	PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)

	if self:IsBank() then
		if self:AtBank() then
			if C_Bank and C_Bank.CloseBankFrame then
				C_Bank.CloseBankFrame()
			else
				CloseBankFrame()
			end
		end
		BankFrame:Hide()
	else
		if BackpackTokenFrame then
			BackpackTokenFrame:Hide()
		end
	end

	-- clear search on hide
	self.SearchBox.clearButton:Click()

	-- close any dropdowns
	CloseDropDownMenus()

	-- reset to the default player when hiding
	if self.playerName then
		self:SetPlayer(nil)
	end

	-- hide tab settings
	if self.TabSettingsMenu then
		self.TabSettingsMenu:Hide()
	end
end

function FrameMixin:OnBagToggleClick(toggle, button)
	if button == "LeftButton" then
		_G[toggle:GetName() .. "Icon"]:SetTexCoord(0.075, 0.925, 0.075, 0.925)
		self:ToggleBagFrame()
	elseif button == "RightButton" then
		if not self:IsBank() and ItemCache:HasCache() then
			Inventorian.bank:ShowFrame(false)
		end
	end
end

function FrameMixin:OnSortClick(frame, button)
	if self:IsCached() then return end
	if button == "LeftButton" then
		PlaySound(SOUNDKIT.UI_BAG_SORTING_01)
		if self:IsReagentBank() then
			C_Container.SortReagentBankBags()
		elseif self:IsBank() then
			C_Container.SortBankBags()
		else
			C_Container.SortBags()
		end
	elseif button == "RightButton" then
		OnDepositClick(frame)
	end
end

function FrameMixin:OnSortButtonEnter(button)
	GameTooltip:SetOwner(button, "ANCHOR_LEFT")
	GameTooltip:SetText(BAG_CLEANUP_BAGS, 1, 1, 1)
	GameTooltip:AddLine(L["<Left-Click> to automatically sort this bag"])
	GameTooltip:AddLine(L["<Right-Click> to deposit reagents into the reagent bank"])
	GameTooltip:Show()
end

function FrameMixin:OnBagToggleEnter(toggle)
	GameTooltip:SetOwner(toggle, "ANCHOR_LEFT")
	GameTooltip:SetText(L["Bags"], 1, 1, 1)
	GameTooltip:AddLine(L["<Left-Click> to toggle the bag display"])
	if not self:IsBank() and ItemCache:HasCache() then
		GameTooltip:AddLine(L["<Right-Click> to show the bank contents"])
	end
	GameTooltip:Show()
end

function FrameMixin:OnEvent(event, ...)
	if event == "UNIT_PORTRAIT_UPDATE" and self:IsShown() and not self:GetPortrait().classIcon then
		self:SetPortraitToUnit("player")
	end
	if event == "BANK_TABS_CHANGED" or event == "BANK_TAB_SETTINGS_UPDATED" then
		self:SetCurrentBags()
	end
end

function FrameMixin:OnSizeChanged(width, height)
	if BackpackTokenFrame:IsShown() and BackpackTokenFrame:GetParent() == self then
		height = height - TOKEN_CONTAINER_HEIGHT
	end

	self.settings.width = width
	self.settings.height = height
	LibWindow.SavePosition(self)

	self:UpdateItemContainer()
end

function FrameMixin:SetPortrait()
	if self:IsCached() and self:GetPlayerName() ~= ItemCache.PLAYER then
		local classToken = ItemCache:GetPlayerInfo(self:GetPlayerName())
		self:SetPortraitTextureRaw("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
		self:SetPortraitTexCoord(CLASS_ICON_TCOORDS[classToken][1] + 0.01, CLASS_ICON_TCOORDS[classToken][2] - 0.01, CLASS_ICON_TCOORDS[classToken][3] + 0.01, CLASS_ICON_TCOORDS[classToken][4] - 0.01)
		self:GetPortrait().classIcon = true
	else
		self:SetPortraitToUnit("player")
		self:SetPortraitTexCoord(0, 1, 0, 1)
		self:GetPortrait().classIcon = false
	end
end

function FrameMixin:OnPortraitClick(portrait)
	self:TogglePlayerDropdown(portrait, 15, 10)
end

function FrameMixin:OnPortraitEnter(portrait)
	GameTooltip:SetOwner(portrait, "ANCHOR_RIGHT")
	GameTooltip:SetText(self:GetPlayerName(), 1, 1, 1)
	if ItemCache:HasCache() then
		GameTooltip:AddLine(L["<Left-Click> to switch characters"])
	else
		GameTooltip:AddLine(L["Install BagBrother to get access to the inventory of other characters."])
	end
	GameTooltip:Show()
end

function FrameMixin:OnSearchTextChanged()
	self.itemContainer:Search(self.SearchBox:GetText())
end

function FrameMixin:UpdateTitleText()
	if self:IsCached() then
		self.TitleContainer.TitleText:SetFormattedText(self.titleText .. " (%s)", self:GetPlayerName(), L["Cached"])
	else
		self.TitleContainer.TitleText:SetFormattedText(self.titleText, self:GetPlayerName())
	end
end

function FrameMixin:ToggleBagFrame()
	self.settings.showBags = not self.settings.showBags
	--self:UpdateBagToggleHighlight()
	self:UpdateBags()
end

function FrameMixin:UpdateBags()
	for i, bag in pairs(self.bagButtons) do
		self.bagButtons[i] = nil
		bag:Free()
	end

	if self:IsAccountBank() or self.settings.showBags then
		for _, bagID in ipairs(self.currentConfig.bags) do
			local bag = Inventorian.Bag:Create()
			bag:Set(self, bagID)
			tinsert(self.bagButtons, bag)
		end

		if self:IsAccountBank() then
			if self:IsCached() then
				for index, button in ipairs(self.bagButtons) do
					local link, numFreeSlots, icon, slot, numSlots = ItemCache:GetBagInfo(self:GetPlayerName(), button:GetID())
					if numSlots and numSlots > 0 then
						local data = { ID = button:GetID() }
						button:SetWarbandData(data)
					end
					button:SetSelected(self.selectedWarbandBag == button:GetID())
				end
			else
				local tabData = C_Bank.FetchPurchasedBankTabData(Enum.BankType.Account)
				for index, data in ipairs(tabData) do
					if self.bagButtons[index] then
						self.bagButtons[index]:SetWarbandData(data)
					end
					self.bagButtons[index]:SetSelected(self.selectedWarbandBag == data.ID)
				end
			end
		end

		for i, bag in ipairs(self.bagButtons) do
			bag:ClearAllPoints()
			if i > 1 then
				bag:SetPoint("TOP", self.bagButtons[i-1], "BOTTOM", 0, -2)
			else
				bag:SetPoint("TOPRIGHT", -12, -66)
			end
			bag:Show()
		end
	end
	self:UpdateItemContainer()

	if self:IsCached() then
		self.DepositButton:Disable()
		self.SortButton:Disable()
	else
		self.DepositButton:Enable()
		self.SortButton:Enable()
	end
end

function FrameMixin:UpdateItemContainer(force)
	local width = self:GetWidth() + ITEM_CONTAINER_OFFSET_W
	local height = self:GetHeight() + ITEM_CONTAINER_OFFSET_H
	if self.settings.showBags or self:IsAccountBank() then
		width = width - 36
	end

	if self.DepositButton:IsShown() then
		height = height - 26
	end

	if BackpackTokenFrame:IsShown() and BackpackTokenFrame:GetParent() == self then
		height = height - TOKEN_CONTAINER_HEIGHT
	end

	if width ~= self.itemContainer:GetWidth() or height ~= self.itemContainer:GetHeight() then
		self.itemContainer:SetWidth(width)
		self.itemContainer:SetHeight(height)
		self.itemContainer:Layout()
	end
end

function FrameMixin:UpdateMoneyFrame()
	-- update the money frame
	local showDepositButtons = false
	if self:IsAccountBank() then
		MoneyFrame_SetType(self.Money, "ACCOUNT")
		showDepositButtons = not self:IsCached()
	else
		if self:IsCached() then
			MoneyFrame_SetType(self.Money, "INVENTORIAN")
		else
			MoneyFrame_SetType(self.Money, "PLAYER")
		end
	end
	MoneyFrame_UpdateMoney(self.Money)

	if showDepositButtons then
		self.MoneyDepositButton:Show()
		self.MoneyWithdrawButton:Show()

		self.Money:ClearAllPoints()
		self.Money:SetPoint("BOTTOMRIGHT", self.MoneyWithdrawButton, "BOTTOMLEFT", 0, 3)
		self.Money:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 6, 9)
	else
		if self.MoneyDepositButton then
			self.MoneyDepositButton:Hide()
			self.MoneyWithdrawButton:Hide()
		end

		self.Money:ClearAllPoints()
		self.Money:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -6, 9)
		self.Money:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 6, 9)
	end
end

function FrameMixin:Update()
	self:UpdateBags()
	self.itemContainer:UpdateBags()
	self:UpdateTitleText()
	self:SetPortrait()
	self:UpdateMoneyFrame()

	self.cachedView = self:IsCached()
end

function FrameMixin:UpdateCachedView()
	if self.cachedView ~= self:IsCached() then
		self:Update()
	end
end

function FrameMixin:ToggleFrame(auto)
	if self:IsShown() then
		self:HideFrame(auto)
	else
		self:ShowFrame(auto)
	end
end

function FrameMixin:ShowFrame(auto)
	if self:IsCached() and not ItemCache:HasCache() then
		Inventorian:Print("No Cache available, please enable BagBrother to enable this functionality")
		return
	end

	if not self:IsShown() then
		self:Show()
		self.autoShown = auto or nil
	end
	if not auto then
		self.autoShown = nil
	end

	self:UpdateCachedView()
end

function FrameMixin:HideFrame(auto)
	if self:IsShown() then
		if not auto or self.autoShown then
			self:Hide()
			self.autoShown = nil
		else
			self:UpdateCachedView()
		end
	end
end

do
	local ActiveFrame
	local PlayerDropdown

	local function DeletePlayer(self)
		local playerName = self.value
		if Inventorian.bag:GetPlayerName() == playerName then
			Inventorian.bag:SetPlayer(nil)
		end

		if Inventorian.bank:GetPlayerName() == playerName then
			Inventorian.bank:SetPlayer(nil)
		end

		ItemCache:DeletePlayer(playerName)
		CloseDropDownMenus()
	end

	local function SetPlayer(self)
		ActiveFrame:SetPlayer(self.value)
		CloseDropDownMenus()
	end

	local function PlayerEntry(player)
		local class = ItemCache:GetPlayerInfo(player)
		if not RAID_CLASS_COLORS[class] or not RAID_CLASS_COLORS[class].colorStr then class = nil end

		UIDropDownMenu_AddButton({
			text = class and ("|c%s%s|r"):format(RAID_CLASS_COLORS[class].colorStr, player) or player,
			hasArrow = ItemCache:IsPlayerCached(player),
			checked = (player == ActiveFrame:GetPlayerName()),
			func = SetPlayer,
			value = player,
		})
	end

	local function CreatePlayerDropdown(self, level)
		if level == 2 then
			UIDropDownMenu_AddButton({ text = REMOVE, notCheckable = true, value = UIDROPDOWNMENU_MENU_VALUE, func = DeletePlayer}, 2)
		else
			PlayerEntry(ItemCache.PLAYER)

			for i, player in ItemCache:IteratePlayers() do
				if player ~= ItemCache.PLAYER then
					PlayerEntry(player)
				end
			end
		end
	end

	local function GetPlayerDropdown()
		if not PlayerDropdown then
			PlayerDropdown = CreateFrame("Frame", "InventorianPlayerDropdown", UIParent, "UIDropDownMenuTemplate")
			PlayerDropdown.initialize = CreatePlayerDropdown
			PlayerDropdown.displayMode = "MENU"
			PlayerDropdown:SetID(1)
		end

		return PlayerDropdown
	end

	function FrameMixin:TogglePlayerDropdown(anchor, offsetX, offsetY)
		if ItemCache:HasCache() then
			ActiveFrame = self
			ToggleDropDownMenu(1, nil, GetPlayerDropdown(), anchor, offsetX, offsetY)
		end
	end

end

-----------------------------------------------------------------------
-- Bank Panel helpers

function FrameMixin:GetBankType()
	return self:IsAccountBank() and Enum.BankType.Account or Enum.BankType.Character
end

function FrameMixin:IsBankTypeLocked()
	if self:IsAccountBank() then
		return not C_PlayerInfo.HasAccountInventoryLock()
	end
	return false
end

function FrameMixin:GetTabData(tabID)
	local purchasedTabData = C_Bank.FetchPurchasedBankTabData(self:GetBankType())
	if not purchasedTabData then return end

	for index, tabData in ipairs(purchasedTabData) do
		if tabData.ID == tabID then
			return tabData
		end
	end
end

-----------------------------------------------------------------------
-- Various information getters

function FrameMixin:SetPlayer(player)
	if not player or not ItemCache:IsPlayerCached(player) then
		self.playerName = nil
	else
		self.playerName = player
	end
	self:Update()
end

function FrameMixin:GetPlayerName()
	local name = self.playerName or PLAYER_NAME

	-- only return the realm name if its not the current realm
	local realm, player = ItemCache:GetPlayerAddress(name)
	if realm == GetRealmName() then
		name = player
	end
	return name
end

function FrameMixin:IsCached()
	return ItemCache:IsPlayerCached(self:GetPlayerName()) or (self:IsBank() and not self:AtBank())
end

function FrameMixin:IsBank()
	return self.currentConfig.isBank
end

function FrameMixin:IsReagentBank()
	return self.currentConfig.isReagentBank
end

function FrameMixin:IsAccountBank()
	return self.currentConfig.isAccountBank
end

function FrameMixin:AtBank()
	return (self:IsAccountBank() and Events.atAccountBank) or Events.atBank
end
