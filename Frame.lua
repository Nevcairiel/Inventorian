local _, Inventorian = ...

local Frame = CreateFrame("Frame")
local Frame_MT = {__index = Frame}

local LibWindow = LibStub("LibWindow-1.1")
local Events = Inventorian:GetModule("Events")

local ITEM_CONTAINER_OFFSET_W = -22
local ITEM_CONTAINER_OFFSET_H = -95

Inventorian.Frame = {}
Inventorian.Frame.defaults = {}
Inventorian.Frame.prototype = Frame
function Inventorian.Frame:Create(name, titleText, settings, config, isBank)
	local frame = setmetatable(CreateFrame("Frame", name, UIParent, "InventorianFrameTemplate"), Frame_MT)

	-- settings
	frame.isBank = isBank
	frame.config = config
	frame.settings = settings
	frame.titleText = titleText

	-- components
	frame.itemContainer = Inventorian.ItemContainer:Create(frame)
	frame.itemContainer:SetPoint("TOPLEFT", 10, -64)
	frame.itemContainer:SetBags(config[1].bags)
	frame.itemContainer:Show()

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
	frame.itemContainer:SetBags(frame.config[tabID].bags)
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
end

function Frame:OnHide()
	PlaySound("igBackPackClose")

	if self:IsBank() and self:AtBank() then
		CloseBankFrame()
	end
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

function Frame:UpdateTitleText()
	self.Title:SetFormattedText(self.titleText, self:GetPlayerName())
end

function Frame:UpdateBags()
	if self.settings.showBags then

	end
	self:UpdateItemContainer()
end

function Frame:UpdateItemContainer(force)
	local width = self:GetWidth() + ITEM_CONTAINER_OFFSET_W
	local height = self:GetHeight() + ITEM_CONTAINER_OFFSET_H
	if self.settings.showBags then
		width = width - 36
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
	return self.isBank
end

function Frame:AtBank()
	return Events.atBank
end
