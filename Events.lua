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

local ItemCache = LibStub("LibItemCache-1.1-Inventorian")

local NUM_TOTAL_EQUIPPED_BAG_SLOTS = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS

local function ToIndex(bag, slot)
	return (bag < 0 and bag * 100 - slot) or (bag * 100 + slot)
end

-- data storage
local slots = {}

function Events:OnEnable()
	self.firstVisit = true
	self.atBank = false
	self.atAccountBank = false

	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("BAG_UPDATE_COOLDOWN")
	self:RegisterEvent("BAG_NEW_ITEMS_UPDATED")
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")

	self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
	self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")

	self:RegisterEvent("BANK_TABS_CHANGED")

	self:RegisterEvent("ITEM_LOCK_CHANGED", "GenericEvent")

	self:UpdateBagSize(BACKPACK_CONTAINER)
	self:UpdateItems(BACKPACK_CONTAINER)
end

function Events:GenericEvent(event, ...)
	self:Fire(event, ...)
end

local emptyItemTbl = {}

-- items
function Events:AddItem(bag, slot)
	local index = ToIndex(bag,slot)
	if not slots[index] then slots[index] = {} end

	local data = slots[index]
	local info = C_Container.GetContainerItemInfo(bag, slot) or emptyItemTbl
	local start, duration, enable = C_Container.GetContainerItemCooldown(bag, slot)
	local onCooldown = (start and start > 0 and duration and duration > 0 and enable and enable > 0)

	data[1] = info.hyperlink
	data[2] = info.stackCount
	data[3] = info.isLocked
	data[4] = onCooldown
	data[5] = start

	self:Fire("ITEM_SLOT_ADD", bag, slot, info.hyperlink, info.stackCount, info.isLocked, onCooldown)
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

		local info = C_Container.GetContainerItemInfo(bag, slot) or emptyItemTbl
		local start, duration, enable = C_Container.GetContainerItemCooldown(bag, slot)
		local onCooldown = (start and start > 0 and duration and duration > 0 and enable and enable > 0)

		if prevLink ~= info.hyperlink or prevCount ~= info.stackCount then
			data[1] = info.hyperlink
			data[2] = info.stackCount
			data[3] = info.isLocked
			data[4] = onCooldown
			data[5] = start

			self:Fire("ITEM_SLOT_UPDATE", bag, slot,  info.hyperlink, info.stackCount, info.isLocked, onCooldown)
		end
	end
end

function Events:UpdateItems(bag)
	for slot = 1, C_Container.GetContainerNumSlots(bag) do
		self:UpdateItem(bag, slot)
	end
end

-- cooldowns
function Events:UpdateCooldown(bag, slot)
	local data = slots[ToIndex(bag,slot)]

	if data and data[1] then
		local start, duration, enable = C_Container.GetContainerItemCooldown(bag, slot)
		local onCooldown = (start and start > 0 and duration and duration > 0 and enable and enable > 0)

		if data[4] ~= onCooldown or (onCooldown and data[5] ~= start) then
			data[4] = onCooldown
			data[5] = start
			self:Fire("ITEM_SLOT_UPDATE_COOLDOWN", bag, slot, onCooldown)
		end
	end
end

function Events:UpdateCooldowns(bag)
	for slot = 1, C_Container.GetContainerNumSlots(bag) do
		self:UpdateCooldown(bag, slot)
	end
end

-- bag sizes
function Events:UpdateBagSize(bag)
	local prevSize = slots[bag*100] or 0
	local newSize = C_Container.GetContainerNumSlots(bag) or 0
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
		for bag = 1, NUM_TOTAL_EQUIPPED_BAG_SLOTS + GetNumBankSlots() do
			self:UpdateBagSize(bag)
		end
	else
		for bag = 1, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
			self:UpdateBagSize(bag)
		end
	end

	if self.atBank or self.atAccountBank then
		for bag = Enum.BagIndex.AccountBankTab_1, Enum.BagIndex.AccountBankTab_5 do
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
	for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
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

function Events:BANK_TABS_CHANGED()
	self:UpdateBagSizes()
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

function Events:ACCOUNT_BANKFRAME_OPENED()
	self.atAccountBank = true
	ItemCache.AtAccountBank = true

	if self.firstVisit then
		self.firstVisit = nil

		self:UpdateBagSize(BANK_CONTAINER)
		self:UpdateBagSize(REAGENTBANK_CONTAINER)
		self:UpdateBagSizes()
	end

	self:Fire("ACCOUNT_BANK_OPENED")
end

function Events:BANKFRAME_CLOSED()
	self.atBank = false
	ItemCache.AtBank = false
	self.atAccountBank = false
	ItemCache.AtAccountBank = false
	self:Fire("BANK_CLOSED")
end

function Events:PLAYER_INTERACTION_MANAGER_FRAME_SHOW(event, id)
	if id == Enum.PlayerInteractionType.Banker then
		self:BANKFRAME_OPENED()
	elseif id == Enum.PlayerInteractionType.AccountBanker then
		self:ACCOUNT_BANKFRAME_OPENED()
	end
end

function Events:PLAYER_INTERACTION_MANAGER_FRAME_HIDE(event, id)
	if id == Enum.PlayerInteractionType.Banker or id == Enum.PlayerInteractionType.AccountBanker then
		self:BANKFRAME_CLOSED()
	end
end

function Events:BAG_UPDATE_COOLDOWN()
	self:UpdateCooldowns(BACKPACK_CONTAINER)

	for bag = 1, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
		self:UpdateCooldowns(bag)
	end
end
