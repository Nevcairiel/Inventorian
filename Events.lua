local _, Inventorian = ...

-- Bag Events module roughly based on Tekkubs SpecialEvents-Bags and Combuctor
--[[
	ITEM_SLOT_ADD
	args:		bag, slot, link, count, locked, coolingDown

	ITEM_SLOT_REMOVE
	args:		bag, slot

	ITEM_SLOT_UPDATE
	args:		bag, slot, link, count, locked, coolingDown

	ITEM_SLOT_UPDATE_COOLDOWN
	args:		bag, slot, coolingDown

	BANK_OPENED
	args:		none

	BANK_CLOSED
	args:		none
]]

local Events = Inventorian:NewModule("Events", "AceEvent-3.0")
Events.Fire = LibStub("CallbackHandler-1.0"):New(Events, "Register", "Unregister", "UnregisterAll").Fire

local ItemCache = LibStub("LibItemCache-Inventorian-1.1")

local function ToIndex(bag, slot)
	return (bag < 0 and bag * 100 - slot) or (bag * 100 + slot)
end

-- data storage
local slots = {}

function Events:OnEnable()
	self.firstVisit = true
	self.atBank = false

	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("BAG_UPDATE_COOLDOWN")
	self:RegisterEvent("BAG_NEW_ITEMS_UPDATED")
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("BANKFRAME_CLOSED")
	self:RegisterEvent("ITEM_LOCK_CHANGED", "GenericEvent")

	self:UpdateBagSize(BACKPACK_CONTAINER)
	self:UpdateItems(BACKPACK_CONTAINER)
end

function Events:GenericEvent(event, ...)
	self:Fire(event, ...)
end

-- items
function Events:AddItem(bag, slot)
	local index = ToIndex(bag,slot)
	if not slots[index] then slots[index] = {} end

	local data = slots[index]
	local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
	local start, duration, enable = GetContainerItemCooldown(bag, slot)
	local onCooldown = (start > 0 and duration > 0 and enable > 0)

	data[1] = link
	data[2] = count
	data[3] = locked
	data[4] = onCooldown
	data[5] = start

	self:Fire("ITEM_SLOT_ADD", bag, slot, link, count, locked, onCooldown)
end

function Events:RemoveItem(bag, slot)
	local data = slots[ToIndex(bag, slot)]

	if data and next(data) then
		local prevLink = data[1]
		wipe(data)

		self:Fire("ITEM_SLOT_REMOVE", bag, slot, prevLink)
	end
end

function Events:UpdateItem(bag, slot)
	local data = slots[ToIndex(bag, slot)]

	if data then
		local prevLink = data[1]
		local prevCount = data[2]

		local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
		local start, duration, enable = GetContainerItemCooldown(bag, slot)
		local onCooldown = (start > 0 and duration > 0 and enable > 0)

		if prevLink ~= link or prevCount ~= count then
			data[1] = link
			data[2] = count
			data[3] = locked
			data[4] = onCooldown
			data[5] = start

			self:Fire("ITEM_SLOT_UPDATE", bag, slot, link, count, locked, onCooldown)
		end
	end
end

function Events:UpdateItems(bag)
	for slot = 1, GetContainerNumSlots(bag) do
		self:UpdateItem(bag, slot)
	end
end

-- cooldowns
function Events:UpdateCooldown(bag, slot)
	local data = slots[ToIndex(bag,slot)]

	if data and data[1] then
		local start, duration, enable = GetContainerItemCooldown(bag, slot)
		local onCooldown = (start > 0 and duration > 0 and enable > 0)

		if data[4] ~= onCooldown or (onCooldown and data[5] ~= start) then
			data[4] = onCooldown
			data[5] = start
			self:Fire("ITEM_SLOT_UPDATE_COOLDOWN", bag, slot, onCooldown)
		end
	end
end

function Events:UpdateCooldowns(bag)
	for slot = 1, GetContainerNumSlots(bag) do
		self:UpdateCooldown(bag, slot)
	end
end

-- bag sizes
function Events:UpdateBagSize(bag)
	local prevSize = slots[bag*100] or 0
	local newSize = GetContainerNumSlots(bag) or 0
	slots[bag*100] = newSize

	if prevSize > newSize then
		for slot = newSize+1, prevSize do
			self:RemoveItem(bag, slot)
		end
	elseif prevSize < newSize then
		for slot = prevSize+1, newSize do
			self:AddItem(bag, slot)
		end
	end
end

function Events:UpdateBagSizes()
	if self.atBank then
		for bag = 1, NUM_BAG_SLOTS + GetNumBankSlots() do
			self:UpdateBagSize(bag)
		end
	else
		for bag = 1, NUM_BAG_SLOTS do
			self:UpdateBagSize(bag)
		end
	end
end

-- events
function Events:BAG_UPDATE(event, bag)
	self:UpdateBagSizes()
	self:UpdateItems(bag)
end

function Events:BAG_NEW_ITEMS_UPDATED(event)
	for bag = 0, NUM_BAG_SLOTS do
		self:UpdateItems(bag)
	end
end

function Events:PLAYERBANKSLOTS_CHANGED()
	self:UpdateBagSizes()
	self:UpdateItems(BANK_CONTAINER)
end

function Events:PLAYERREAGENTBANKSLOTS_CHANGED()
	self:UpdateItems(REAGENTBANK_CONTAINER)
end

function Events:BANKFRAME_OPENED()
	self.atBank = true
	ItemCache.AtBank = true

	if self.firstVisit then
		self.firstVisit = nil

		self:UpdateBagSize(BANK_CONTAINER)
		self:UpdateBagSize(REAGENTBANK_CONTAINER)
		self:UpdateBagSizes()
	end

	self:Fire("BANK_OPENED")
end

function Events:BANKFRAME_CLOSED()
	self.atBank = false
	ItemCache.AtBank = false
	self:Fire("BANK_CLOSED")
end

function Events:BAG_UPDATE_COOLDOWN()
	self:UpdateCooldowns(BACKPACK_CONTAINER)
		
	for bag = 1, NUM_BAG_SLOTS do
		self:UpdateCooldowns(bag)
	end
end
