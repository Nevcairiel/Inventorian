local _, Inventorian = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Inventorian")

local ItemCache = LibStub("LibItemCache-1.1")

local ItemContainer = CreateFrame("Frame")
local ItemContainer_MT = {__index = ItemContainer}

local Events = Inventorian:GetModule("Events")

Inventorian.ItemContainer = {}
Inventorian.ItemContainer.defaults = {}
Inventorian.ItemContainer.prototype = ItemContainer
function Inventorian.ItemContainer:Create(parent)
	local frame = setmetatable(CreateFrame("Frame", nil, parent), ItemContainer_MT)

	-- settings
	frame.items = {}
	frame.itemCount = 0

	frame.bagSizes = {}

	-- scripts
	frame:SetScript("OnShow", frame.OnShow)
	frame:SetScript("OnHide", frame.OnHide)

	return frame
end

local function ToIndex(bag, slot)
	return (bag < 0 and bag * 100 - slot) or (bag * 100 + slot)
end

local function ToBag(index)
	return (index > 0 and floor(index / 100)) or ceil(index / 100)
end

function ItemContainer:SetBags(bags)
	self.bags = bags
	self:UpdateBags()
end

function ItemContainer:OnShow()
	self:GenerateItemButtons()

	Events.Register(self, "ITEM_SLOT_ADD", "ITEM_SLOT_UPDATE")
	Events.Register(self, "ITEM_SLOT_UPDATE")
	Events.Register(self, "ITEM_SLOT_REMOVE")
	Events.Register(self, "ITEM_SLOT_UPDATE_COOLDOWN")

	Events.Register(self, "ITEM_LOCK_CHANGED")
end

function ItemContainer:OnHide()
	Events.UnregisterAll(self)
end

function ItemContainer:ITEM_SLOT_UPDATE(event, bag, slot)
	if self:UpdateSlot(bag, slot) then
		self:Layout()
	end
end

function ItemContainer:ITEM_SLOT_REMOVE(event, bag, slot)
	if self:RemoveSlot(bag, slot) then
		self:Layout()
	end
end

function ItemContainer:ITEM_SLOT_UPDATE_COOLDOWN(event, bag, slot)
	local item = self.items[ToIndex(bag, slot)]
	if item then
		item:UpdateCooldown()
	end
end

function ItemContainer:ITEM_LOCK_CHANGED(event, bag, slot)
	if not slot then return end

	local item = self.items[ToIndex(bag, slot)]
	if item then
		item:UpdateLocked()
	end
end

function ItemContainer:RemoveAllItems()
	local items = self.items
	for i, item in pairs(items) do
		item:Free()
		items[i] = nil
	end
	self.itemCount = 0
end

function ItemContainer:ItemFilter(bag, slot, link)
	-- check for the bag
	local hasBag = false
	for _, bagID in pairs(self.bags) do
		if bag == bagID then
			hasBag = true
			break
		end
	end
	if not hasBag then return false end

	-- TODO: possible item filtering
	return true
end

function ItemContainer:Search(text)
	if text == "" then text = nil end
	self.searchText = text
	self:UpdateSearch()
end

function ItemContainer:UpdateSearch()
	for idx, item in pairs(self.items) do
		item:UpdateSearch(self.searchText)
	end
end

function ItemContainer:HighlightBag(bag)
	self.highlightBag = bag
	for _, item in pairs(self.items) do
		item:Highlight(item:GetBag() == bag)
	end
end

function ItemContainer:UpdateBags()
	self:RemoveAllItems()
	self:GenerateItemButtons()
end

function ItemContainer:UpdateSlot(bag, slot)
	if self:ItemFilter(bag, slot) then
		return self:AddSlot(bag, slot)
	end
	return self:RemoveSlot(bag, slot)
end

function ItemContainer:AddSlot(bag, slot)
	local index = ToIndex(bag, slot)

	if self.items[index] then
		self.items[index]:Update()
	else
		self.items[index] = Inventorian.Item:Create()
		self.items[index]:Set(self, bag, slot)
		self.itemCount = self.itemCount + 1
		return true
	end
end

function ItemContainer:RemoveSlot(bag, slot)
	local index = ToIndex(bag, slot)

	if self.items[index] then
		self.items[index]:Free()
		self.items[index] = nil
		self.itemCount = self.itemCount - 1
		return true
	end
end

function ItemContainer:Layout()
	local width, height = self:GetWidth(), self:GetHeight()
	local spacing = 2
	local count = self.itemCount
	local size = 36 + spacing*2
	local cols = 0
	local scale, rows

	if count <= 0 then return end

	repeat
		cols = cols + 1
		scale = width / (size*cols)
		rows = floor(height / (size*scale))
	until (scale <= 1.33 and cols*rows >= count)

	--layout the items
	local items = self.items
	local i = 0

	for _, bag in ipairs(self.bags) do
		for slot = 1, self:GetBagSize(bag) do
			local item = items[ToIndex(bag, slot)]
			if item then
				i = i + 1

				local row = mod(i-1, cols)
				local col = ceil(i / cols) - 1
				item:ClearAllPoints()
				item:SetScale(scale)
				item:SetPoint("TOPLEFT", self, "TOPLEFT", size*row + spacing, -(size*col + spacing))
				item:Show()
			end
		end
	end
end

function ItemContainer:GenerateItemButtons()
	if not self:IsVisible() then return end

	-- track if anything changed
	local slotChanged = false

	for _, bag in ipairs(self.bags) do
		local bagSize = self:GetBagSize(bag)

		-- check if the size changed
		if (self.bagSizes[bag] or 0) > bagSize then
			slotChanged = true
			for slot = bagSize, self.bagSizes[bag] do
				self:RemoveSlot(bag, slot)
			end
		end

		-- update slots
		for slot = 1, bagSize do
			if self:UpdateSlot(bag, slot) then
				slotChanged = true
			end
		end

		self.bagSizes[bag] = bagSize
	end

	if slotChanged then
		self:Layout()
	end
end

-----------------------------------------------------------------------
-- Various information getters

function ItemContainer:GetBagSize(bag)
	local link, numFreeSlots, icon, slot, numSlots = ItemCache:GetBagInfo(self:GetParent():GetPlayerName(), bag)
	return numSlots >= 0 and numSlots or 0
end
