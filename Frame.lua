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
function Inventorian.Frame:Create(name, titleText, settings, bags, isBank)
	local frame = setmetatable(CreateFrame("Frame", name, UIParent, "InventorianFrameTemplate"), Frame_MT)

	-- settings
	frame.isBank = isBank
	frame.bags = bags
	frame.settings = settings
	frame.titleText = titleText

	-- components
	frame.itemContainer = Inventorian.ItemContainer:Create(frame)
	frame.itemContainer:SetPoint("TOPLEFT", 10, -64)
	frame.itemContainer:Show()

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

	return frame
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
