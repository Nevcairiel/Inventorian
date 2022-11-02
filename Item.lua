local _, Inventorian = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Inventorian")

local ItemCache = LibStub("LibItemCache-1.1")
local ItemSearch = LibStub("LibItemSearch-Inventorian-1.0")

local InventorianItemMixin = {}

local C_Container_GetContainerItemInfo = C_Container.GetContainerItemInfo
if not C_Container_GetContainerItemInfo then
	C_Container_GetContainerItemInfo = function(bag, slot)
		local icon, itemCount, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID, isBound = GetContainerItemInfo(bag, slot)
		if not icon then return nil end

		return { iconFileID = icon, stackCount = itemCount, isLocked = locked, quality = quality, isReadable = readable, hasLoot = lootable, hyperlink = itemLink, isFiltered = isFiltered, hasNoValue = noValue, itemID = itemID, isBound = isBound }
	end
end

local C_Container_GetContainerItemQuestInfo = C_Container.GetContainerItemQuestInfo
if not C_Container_GetContainerItemQuestInfo then
	C_Container_GetContainerItemQuestInfo = function(bag, slot)
		local isQuestItem, questId, isActive = GetContainerItemQuestInfo(bag, slot)
		return { isQuestItem = isQuestItem, questID = questId, isActive = isActive }
	end
end

local GetContainerItemCooldown = C_Container.GetContainerItemCooldown or GetContainerItemCooldown

local IsBattlePayItem = C_Container.IsBattlePayItem or IsBattlePayItem

Inventorian.Item = {}
Inventorian.Item.count = 0
Inventorian.Item.pool = nil
function Inventorian.Item:Create()
	if not self.pool then
		self:CreateItemPool()
	end

	local item = next(self.pool)
	if item then
		self.pool[item] = nil
	else
		self.count = self.count + 1
		item = CreateFrame("ItemButton", ("InventorianItemButton%d"):format(self.count), nil, "ContainerFrameItemButtonTemplate")
		item = self:WrapItemButton(item)
	end

	return item
end


function Inventorian.Item:WrapItemButton(item)
	item = Mixin(item, InventorianItemMixin)

	item:UnregisterAllEvents()

	-- replace scripts
	item:SetScript("OnEvent", item.OnEvent)
	item:SetScript("OnEnter", item.OnEnter)
	item:SetScript("OnLeave", item.OnLeave)
	item:SetScript("OnShow", item.OnShow)

	-- elements
	local name = item:GetName()
	item.IconQuestTexture = _G[name .. "IconQuestTexture"]
	item.Cooldown = _G[name .. "Cooldown"]

	-- adjust ther normal texture to be less "obvious" on empty buttons
	item:GetNormalTexture():SetVertexColor(1,1,1,0.66)

	-- cleanup state
	item:Reset()

	return item
end

local MAX_CONTAINER_ITEMS = 36

function Inventorian.Item:CreateItemPool()
	self.pool = {}
	for c = 1, NUM_CONTAINER_FRAMES do
		for i = 1, MAX_CONTAINER_ITEMS do
			local item = _G[("ContainerFrame%dItem%d"):format(c, i)]
			if item then
				item:SetID(0)
				item:ClearAllPoints()

				item = self:WrapItemButton(item)
				self.pool[item] = true
			end
		end
	end
end

function InventorianItemMixin:Free()
	self:Hide()
	self:SetParent(nil)
	self:SetID(0)
	self:ClearAllPoints()
	self:UnlockHighlight()

	Inventorian.Item.pool[self] = true
end

function InventorianItemMixin:Set(container, bag, slot)
	self.container = container
	self.bag = bag
	self.slot = slot

	self:SetParent(self:GetBagContainer(container, bag))
	self:SetID(slot)

	if self:IsVisible() then
		self:Update()
	else
		self:Show()
	end
end

function InventorianItemMixin:OnShow()
	if not self:GetParent() then return end
	self:Update()
end

-----------------------------------------------------------------------
-- Button style setters

function InventorianItemMixin:Update()
	if not self:IsVisible() then
		return
	end

	local icon, count, locked, quality, readable, lootable, link, noValue, itemID, isBound = self:GetInfo()
	self:SetItem(link)
	self:SetTexture(icon)
	self:SetCount(count)
	self:SetLocked(locked)
	self:SetReadable(readable)
	self:UpdateCooldown()
	self:UpdateBorder(quality, noValue, isBound)
	self:UpdateSearch(self.container.searchText)

	if GameTooltip:IsOwned(self) then
		if not self:GetItem() then
			self:OnLeave()
		end
		self:UpdateTooltip()
	end
end

function InventorianItemMixin:SetItem(itemLink)
	self.item = itemLink
	self.itemLink = itemLink
end

function InventorianItemMixin:SetTexture(icon)
	if icon then
		SetItemButtonTexture(self, icon)
		self.icon:SetAlpha(1)
	else
		SetItemButtonTexture(self, [[Interface\PaperDoll\UI-Backpack-EmptySlot]])
		self.icon:SetAlpha(0.66)
	end
end

function InventorianItemMixin:SetCount(count)
	SetItemButtonCount(self, count)
end

function InventorianItemMixin:SetLocked(locked)
	SetItemButtonDesaturated(self, locked)
end

function InventorianItemMixin:UpdateLocked()
	self:SetLocked(self:IsLocked())
end

-- returns true if the slot is locked, and false otherwise
function InventorianItemMixin:IsLocked()
	return select(3, self:GetInfo())
end

function InventorianItemMixin:SetReadable(readable)
	self.readable = readable
end

function InventorianItemMixin:UpdateCooldown()
	if self:GetItem() and not self:IsCached() then
		local start, duration, enable = GetContainerItemCooldown(self.bag, self.slot)
		CooldownFrame_Set(self.Cooldown, start, duration, enable)
		if duration > 0 and enable == 0 then
			SetItemButtonTextureVertexColor(self, 0.4, 0.4, 0.4)
		else
			SetItemButtonTextureVertexColor(self, 1, 1, 1)
		end
	else
		SetItemButtonTextureVertexColor(self, 1, 1, 1)
		self.Cooldown:Hide()
	end
end

function InventorianItemMixin:SetBorderColor(r, g, b)
	self.IconBorder:SetVertexColor(r, g, b)
	self.IconBorder:Show()
end

function InventorianItemMixin:HideBorder()
	self.NewItemTexture:Hide()
	self.IconQuestTexture:Hide()
	self.BattlepayItemTexture:Hide()
	self.IconBorder:Hide()
	self.JunkIcon:Hide()
	ClearItemButtonOverlay(self)


	if self.flashAnim:IsPlaying() or self.newitemglowAnim:IsPlaying() then
		self.flashAnim:Stop()
		self.newitemglowAnim:Stop()
	end
end

function InventorianItemMixin:UpdateBorder(quality, noValue, isBound)
	local item = self:GetItem()
	self:HideBorder()

	if item then
		local isQuestItem, questId, isActive = self:GetQuestInfo()
		if questId and not isActive then
			self.IconQuestTexture:SetTexture(TEXTURE_ITEM_QUEST_BANG)
			self.IconQuestTexture:Show()
		elseif questId or isQuestItem then
			self.IconQuestTexture:SetTexture(TEXTURE_ITEM_QUEST_BORDER)
			self.IconQuestTexture:Show()
		end

		local isNewItem, isBattlePayItem = self:IsNew()
		if isNewItem then
			if isBattlePayItem then
				self.BattlepayItemTexture:Show()
			else
				if quality and NEW_ITEM_ATLAS_BY_QUALITY[quality] then
					self.NewItemTexture:SetAtlas(NEW_ITEM_ATLAS_BY_QUALITY[quality])
				else
					self.NewItemTexture:SetAtlas("bags-glow-white")
				end
				self.NewItemTexture:Show()
			end
			if not self.flashAnim:IsPlaying() and not self.newitemglowAnim:IsPlaying() then
				self.flashAnim:Play()
				self.newitemglowAnim:Play()
			end
		end

		SetItemButtonQuality(self, quality, item, false, isBound)
		self.JunkIcon:SetShown(quality == Enum.ItemQuality.Poor and not noValue and MerchantFrame:IsShown())
	end
end

function InventorianItemMixin:UpdateSearch(text)
	local found = false
	if text and self:GetItem() then
		found = ItemSearch:Find(self:GetItem(), text)
	end

	if not text or found then
		self:SetMatchesSearch(found or nil)
		local isNewItem = self:IsNew()
		if isNewItem and not self.newitemglowAnim:IsPlaying() then
			self.newitemglowAnim:Play()
		end
	else
		self:SetMatchesSearch(false)
		if self.flashAnim:IsPlaying() or self.newitemglowAnim:IsPlaying() then
			self.flashAnim:Stop()
			self.newitemglowAnim:Stop()
		end
	end
end

function InventorianItemMixin:UpdateItemContextOverlay()
	ItemButtonMixin.UpdateItemContextOverlay(self)

	-- update anchoring for the color texture to cover the borders
	if self.ItemContextOverlay:GetTexture() == nil then
		self.ItemContextOverlay:ClearAllPoints()
		self.ItemContextOverlay:SetSize(39, 39)
		self.ItemContextOverlay:SetPoint("CENTER")
	end
end

function InventorianItemMixin:Highlight(enable)
	if enable then
		self:LockHighlight()
	else
		self:UnlockHighlight()
	end
end

function InventorianItemMixin:OnEvent(event, ...)
	if event == "ITEM_DATA_LOAD_RESULT" then
		local id = (...)
		if id == self.itemID then
			self:UnregisterEvent("ITEM_DATA_LOAD_RESULT")
			self:Update()
		end
	end
end

function InventorianItemMixin:OnEnter()
	if self:IsCached() then
		self.cacheOverlay = self.cacheOverlay or self:CreateCacheOverlay()
		self.cacheOverlay:Show()
		self.cacheOverlay:GetScript("OnEnter")(self.cacheOverlay)
	else
		if self:IsBank() or self:IsReagentBank() then
			if self:GetItem() then
				local id = self:IsBank() and BankButtonIDToInvSlotID(self:GetID()) or ReagentBankButtonIDToInvSlotID(self:GetID())
				GameTooltip:SetOwner(self, "ANCHOR_NONE")
				ContainerFrameItemButton_CalculateItemTooltipAnchors(self, GameTooltip)
				GameTooltip:SetInventoryItem("player", id)
				GameTooltip:Show()
				CursorUpdate(self)
			end
		else
			ContainerFrameItemButtonMixin.OnEnter(self)
		end
	end
end

function InventorianItemMixin:OnLeave()
	GameTooltip:Hide()
	BattlePetTooltip:Hide()
	ResetCursor()
end

InventorianItemMixin.UpdateTooltip = InventorianItemMixin.OnEnter

-----------------------------------------------------------------------
-- Utility

local function CacheOverlay_OnEnter(self)
	local parent = self:GetParent()
	if parent:GetItem() then
		GameTooltip:SetOwner(parent, "ANCHOR_NONE")
		ContainerFrameItemButton_CalculateItemTooltipAnchors(parent, GameTooltip)
		GameTooltip:SetHyperlink(parent:GetItem())
		GameTooltip:Show()
	end

	parent:LockHighlight()
	CursorUpdate(parent)
end

local function CacheOverlay_OnLeave(self)
	self:GetParent():OnLeave()
	self:Hide()
end

local function CacheOverlay_OnHide(self)
	self:GetParent():UnlockHighlight()
end

local function CacheOverlay_OnClick(self)
	local item = self:GetParent():GetItem()
	if item then
		HandleModifiedItemClick(item)
	end
end

function InventorianItemMixin:CreateCacheOverlay()
	local overlay = CreateFrame("Button", nil, self)
	overlay:RegisterForClicks("anyUp")
	overlay:EnableMouse(true)
	overlay:SetAllPoints(self)

	overlay.UpdateTooltip = CacheOverlay_OnEnter
	overlay:SetScript("OnClick", CacheOverlay_OnClick)
	overlay:SetScript("OnEnter", CacheOverlay_OnEnter)
	overlay:SetScript("OnLeave", CacheOverlay_OnLeave)
	overlay:SetScript("OnHide", CacheOverlay_OnHide)

	return overlay
end

function InventorianItemMixin:GetBagContainer(container, bag)
	local bagContainers = container.bagContainers

	-- use a metatable to create the new bag wrappers on demand
	if not bagContainers then
		bagContainers = setmetatable({}, {
			__index = function(t, k)
				local f = CreateFrame("Frame", nil, container)
				f:SetID(k)
				t[k] = f
				return f
			end
		})
		container.bagContainers = bagContainers
	end
	return bagContainers[bag]
end

-----------------------------------------------------------------------
-- Various information getters

function InventorianItemMixin:IsCached()
	return self.container:GetParent():IsCached()
end

function InventorianItemMixin:GetBag()
	return self.bag
end

function InventorianItemMixin:GetInfo()
	local player = self.container:GetParent():GetPlayerName()
	local icon, count, locked, quality, readable, lootable, link, _, noValue, itemID, isBound
	if self:IsCached() then
		icon, count, locked, quality, readable, lootable, link = ItemCache:GetItemInfo(player, self.bag, self.slot)
		if link then
			itemID = GetItemInfoInstant(link)
		end
	else
		-- LibItemCache doesn't provide noValue or itemID, so fallback to base API
		local info = C_Container_GetContainerItemInfo(self.bag, self.slot)
		if info then
			icon = info.iconFileID
			count = info.stackCount
			locked = info.isLocked
			quality = info.quality
			readable = info.isReadable
			lootable = info.hasLoot
			link = info.hyperlink
			noValue = info.hasNoValue
			itemID = info.itemID
			isBound = info.isBound
		end
		if link and (not quality or quality < 0) then
			quality = select(3, GetItemInfo(link))
		end
	end

	if not icon and (itemID or link) then
		self.itemID = itemID or GetItemInfoInstant(link)
		if self:IsCached() then
			self:RegisterEvent("ITEM_DATA_LOAD_RESULT")
			C_Item.RequestLoadItemDataByID(self.itemID)
		else
			local location = ItemLocation:CreateFromBagAndSlot(self.bag, self.slot)
			if C_Item.DoesItemExist(location) and not C_Item.IsItemDataCached(location) then
				self:RegisterEvent("ITEM_DATA_LOAD_RESULT")
				C_Item.RequestLoadItemData(location)
			end
		end
	end

	return icon, count, locked, quality, readable, lootable, link, noValue, itemID, isBound
end

function InventorianItemMixin:GetQuestInfo()
	if not self:IsCached() then
		local info = C_Container_GetContainerItemQuestInfo(self.bag, self.slot)
		if info then
			return info.isQuestItem, info.questID, info.isActive
		end
	end
end

function InventorianItemMixin:IsNew()
	if not self:IsCached() then
		return C_NewItems.IsNewItem(self.bag, self.slot), IsBattlePayItem(self.bag, self.slot)
	end
end

function InventorianItemMixin:IsBank()
	return self.bag == BANK_CONTAINER
end

function InventorianItemMixin:IsReagentBank()
	return self.bag == REAGENTBANK_CONTAINER
end
