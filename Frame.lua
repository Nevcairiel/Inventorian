local _, Inventorian = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Inventorian")

local Frame = CreateFrame("Frame")
local Frame_MT = {__index = Frame}

local LibWindow = LibStub("LibWindow-1.1")
local Events = Inventorian:GetModule("Events")

local ITEM_CONTAINER_OFFSET_W = -22
local ITEM_CONTAINER_OFFSET_H = -95

Inventorian.Frame = {}
Inventorian.Frame.defaults = {}
Inventorian.Frame.prototype = Frame
function Inventorian.Frame:Create(name, titleText, settings, config)
	local frame = setmetatable(CreateFrame("Frame", name, UIParent, "InventorianFrameTemplate"), Frame_MT)

	-- settings
	frame.config = config
	frame.settings = settings
	frame.titleText = titleText
	frame.currentConfig = config[1]
	frame.bagButtons = {}

	-- components
	frame.itemContainer = Inventorian.ItemContainer:Create(frame)
	frame.itemContainer:SetPoint("TOPLEFT", 10, -64)
	frame.itemContainer:SetBags(config[1].bags)
	frame.itemContainer:Show()

	frame.DepositButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.DepositButton:SetText(REAGENTBANK_DEPOSIT)
	frame.DepositButton:SetSize(256, 24)
	frame.DepositButton:SetPoint("BOTTOM", 0, 31)
	frame.DepositButton:SetScript("OnClick", frame.OnDepositClick)
	frame.DepositButton:Hide()

	frame:CreateTabs()

	-- scripts
	frame:SetScript("OnShow", frame.OnShow)
	frame:SetScript("OnHide", frame.OnHide)
	frame:SetScript("OnEvent", frame.OnEvent)
	frame:SetScript("OnSizeChanged", frame.OnSizeChanged)

	-- non-bag events
	frame:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player")

	-- load and apply config
	frame:SetWidth(settings.width)
	frame:SetHeight(settings.height)

	LibWindow.RegisterConfig(frame, settings)
	LibWindow.RestorePosition(frame)

	frame:UpdateTitleText()
	frame:UpdateBags()

	tinsert(UISpecialFrames, name)

	return frame
end

function Frame.OnTabClick(tab)
	local frame = tab:GetParent()
	local tabID = tab:GetID()
	if frame.selectedTab ~= tabID then
		PlaySound("igCharacterInfoTab")
	end

	PanelTemplates_SetTab(frame, tabID)
	frame.currentConfig = frame.config[tabID]
	frame.itemContainer:SetBags(frame.currentConfig.bags)

	-- hack for the reagent bank to behave properly when right-clicking inventory items
	if frame:IsBank() and frame:AtBank() then
		if tabID == 2 then
			BankFrame:Show()
			BankFrame.selectedTab = 2
		else
			BankFrame:Hide()
			BankFrame.selectedTab = 1
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
end

function Frame:CreateTabs()
	local numConfigs = #self.config
	if numConfigs <= 1 then return end

	self.tabs = {}
	for i = 1, numConfigs do
		local tab = CreateFrame("Button", self:GetName() .. "Tab" .. i, self, "InventorianFrameTabButtonTemplate")
		tab:SetScript("OnClick", self.OnTabClick)
		tab:SetID(i)
		tab:SetText(self.config[i].title)

		if i > 1 then
			tab:SetPoint("LEFT", self.tabs[i-1], "RIGHT", -16, 0)
		else
			tab:SetPoint("CENTER", self, "BOTTOMLEFT", 50, -14)
		end

		PanelTemplates_TabResize(tab, 0)
		tab:GetHighlightTexture():SetWidth(tab:GetTextWidth() + 30)

		self.tabs[i] = tab
	end

	PanelTemplates_SetNumTabs(self, numConfigs)
	PanelTemplates_SetTab(self, 1)
end

function Frame:OnShow()
	PlaySound("igBackPackOpen")
	SetPortraitTexture(self.portrait, "player")

	if self:IsBank() and self:AtBank() then
		if self.selectedTab == 2 then
			BankFrame:Show()
		end
	end
end

function Frame:OnHide()
	PlaySound("igBackPackClose")

	if self:IsBank() then
		if self:AtBank() then
			CloseBankFrame()
		end
		BankFrame:Hide()
	end

	-- clear search on hide
	self.SearchBox.clearButton:Click()
end

function Frame:OnBagToggleClick(toggle, button)
	if button == "LeftButton" then
		_G[toggle:GetName() .. "Icon"]:SetTexCoord(0.075, 0.925, 0.075, 0.925)
		self:ToggleBagFrame()
	end
end

function Frame:OnSortClick()
	PlaySound("UI_BagSorting_01")
	if self:IsReagentBank() then
		SortReagentBankBags()
	elseif self:IsBank() then
		SortBankBags()
	else
		SortBags()
	end
end

function Frame:OnBagToggleEnter(toggle)
	GameTooltip:SetOwner(toggle, "ANCHOR_LEFT")
	GameTooltip:SetText(L["Bags"], 1, 1, 1)
	GameTooltip:AddLine(L["<Left-Click> to toggle the bag display"])
	GameTooltip:Show()
end

function Frame.OnDepositClick(button)
	PlaySound("igMainMenuOption")
	DepositReagentBank()
end

function Frame:OnEvent(event, ...)
	if event == "UNIT_PORTRAIT_UPDATE" and self:IsShown() then
		SetPortraitTexture(self.portrait, "player")
	end
end

function Frame:OnSizeChanged(width, height)
	self.settings.width = width
	self.settings.height = height
	LibWindow.SavePosition(self)

	self:UpdateItemContainer()
end

function Frame:OnSearchTextChanged()
	self.itemContainer:Search(self.SearchBox:GetText())
end

function Frame:UpdateTitleText()
	self.Title:SetFormattedText(self.titleText, self:GetPlayerName())
end

function Frame:ToggleBagFrame()
	self.settings.showBags = not self.settings.showBags
	--self:UpdateBagToggleHighlight()
	self:UpdateBags()
end

function Frame:UpdateBags()
	for i, bag in pairs(self.bagButtons) do
		self.bagButtons[i] = nil
		bag:Free()
	end

	if self.settings.showBags then
		for _, bagID in ipairs(self.currentConfig.bags) do
			local bag = Inventorian.Bag:Create()
			bag:Set(self, bagID)
			tinsert(self.bagButtons, bag)
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
end

function Frame:UpdateItemContainer(force)
	local width = self:GetWidth() + ITEM_CONTAINER_OFFSET_W
	local height = self:GetHeight() + ITEM_CONTAINER_OFFSET_H
	if self.settings.showBags then
		width = width - 36
	end

	if self.DepositButton:IsShown() then
		height = height - 26
	end

	if width ~= self.itemContainer:GetWidth() or height ~= self.itemContainer:GetHeight() then
		self.itemContainer:SetWidth(width)
		self.itemContainer:SetHeight(height)
		self.itemContainer:Layout()
	end
end

function Frame:ToggleFrame(auto)
	if self:IsShown() then
		self:HideFrame(auto)
	else
		self:ShowFrame(auto)
	end
end

function Frame:ShowFrame(auto)
	if not self:IsShown() then
		self:Show()
		self.autoShown = auto or nil
	end
end

function Frame:HideFrame(auto)
	if self:IsShown() then
		if not auto or self.autoShown then
			self:Hide()
			self.autoShown = nil
		end
	end
end

-----------------------------------------------------------------------
-- Various information getters

function Frame:GetPlayerName()
	return UnitName("player")
end

function Frame:IsBank()
	return self.currentConfig.isBank
end

function Frame:IsReagentBank()
	return self.currentConfig.isReagentBank
end

function Frame:AtBank()
	return Events.atBank
end
