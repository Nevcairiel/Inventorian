local _, Inventorian = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Inventorian")

local ItemCache = LibStub("LibItemCache-1.1")
local ItemSearch = LibStub("LibItemSearch-Inventorian-1.0")

local Item = CreateFrame("ItemButton")
local Item_MT = {__index = Item}

Inventorian.Item = {}
Inventorian.Item.prototype = Item
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
	item = setmetatable(item, Item_MT)

	item:UnregisterAllEvents()

	-- scripts
	item:SetScript("OnEvent", item.OnEvent)
	item:SetScript("OnEnter", item.OnEnter)
	item:SetScript("OnLeave", item.OnLeave)
	item:SetScript("OnShow", item.OnShow)
	item.UpdateTooltip = nil

	-- elements
	local name = item:GetName()
	item.IconQuestTexture = _G[name .. "IconQuestTexture"]
	item.Cooldown = _G[name .. "Cooldown"]

	-- re-size search overlay to cover the item quality border as well
	item.searchOverlay:ClearAllPoints()
	item.searchOverlay:SetSize(39, 39)
	item.searchOverlay:SetPoint("CENTER")

	-- adjust ther normal texture to be less "obvious" on empty buttons
	item:GetNormalTexture():SetVertexColor(1,1,1,0.66)

	return item
end

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

function Item:Free()
	self:Hide()
	self:SetParent(nil)
	self:SetID(0)
	self:ClearAllPoints()
	self:UnlockHighlight()

	Inventorian.Item.pool[self] = true
end

function Item:Set(container, bag, slot)
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

function Item:OnShow()
	if not self:GetParent() then return end
	self:Update()
end

-----------------------------------------------------------------------
-- Button style setters

function Item:Update()
	if not self:IsVisible() then
		return
	end

	local icon, count, locked, quality, readable, lootable, link, noValue, itemID = self:GetInfo()
	self:SetItem(link)
	self:SetTexture(icon)
	self:SetCount(count)
	self:SetLocked(locked)
	self:SetReadable(readable)
	self:UpdateCooldown()
	self:UpdateBorder(quality, itemID, noValue)
	self:UpdateSearch(self.container.searchText)

	if GameTooltip:IsOwned(self) then
		if not self:GetItem() then
			self:OnLeave()
		end
		self:UpdateTooltip()
	end
end

function Item:SetItem(itemLink)
	self.hasItem = itemLink
end

function Item:GetItem()
	return self.hasItem
end

function Item:SetTexture(icon)
	if icon then
		SetItemButtonTexture(self, icon)
		self.icon:SetAlpha(1)
	else
		SetItemButtonTexture(self, [[Interface\PaperDoll\UI-Backpack-EmptySlot]])
		self.icon:SetAlpha(0.66)
	end
end

function Item:SetCount(count)
	SetItemButtonCount(self, count)
end

function Item:SetLocked(locked)
	SetItemButtonDesaturated(self, locked)
end

function Item:UpdateLocked()
	self:SetLocked(self:IsLocked())
end

-- returns true if the slot is locked, and false otherwise
function Item:IsLocked()
	return select(3, self:GetInfo())
end

function Item:SetReadable(readable)
	self.readable = readable
end

function Item:UpdateCooldown()
	if self:GetItem() and not self:IsCached() then
		ContainerFrame_UpdateCooldown(self.bag, self)
	else
		SetItemButtonTextureVertexColor(self, 1, 1, 1)
		self.Cooldown:Hide()
	end
end

function Item:SetBorderColor(r, g, b)
	self.IconBorder:SetVertexColor(r, g, b)
	self.IconBorder:Show()
end

function Item:HideBorder()
	self.NewItemTexture:Hide()
	self.IconQuestTexture:Hide()
	self.BattlepayItemTexture:Hide()
	self.IconBorder:Hide()
	self.IconOverlay:Hide()
	self.JunkIcon:Hide()

	if self.flashAnim:IsPlaying() or self.newitemglowAnim:IsPlaying() then
		self.flashAnim:Stop()
		self.newitemglowAnim:Stop()
	end
end

function Item:UpdateBorder(quality, itemID, noValue)
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

		SetItemButtonQuality(self, quality, itemID)
		self.JunkIcon:SetShown(quality == LE_ITEM_QUALITY_POOR and not noValue and MerchantFrame:IsShown())
	end
end

function Item:UpdateSearch(text)
	local found = false
	if text and self.hasItem then
		found = ItemSearch:Find(self.hasItem, text)
	end

	if not text or found then
		self.searchOverlay:Hide()
		local isNewItem = self:IsNew()
		if isNewItem and not self.newitemglowAnim:IsPlaying() then
			self.newitemglowAnim:Play()
		end
	else
		self.searchOverlay:Show()
		if self.flashAnim:IsPlaying() or self.newitemglowAnim:IsPlaying() then
			self.flashAnim:Stop()
			self.newitemglowAnim:Stop()
		end
	end
end

function Item:Highlight(enable)
	if enable then
		self:LockHighlight()
	else
		self:UnlockHighlight()
	end
end

function Item:OnEvent(event, ...)
	if event == "ITEM_DATA_LOAD_RESULT" then
		local id = (...)
		if id == self.itemID then
			self:UnregisterEvent("ITEM_DATA_LOAD_RESULT")
			self:Update()
		end
	end
end

function Item:OnEnter()
	if self:IsCached() then
		self.cacheOverlay = self.cacheOverlay or self:CreateCacheOverlay()
		self.cacheOverlay:Show()
		self.cacheOverlay:GetScript("OnEnter")(self.cacheOverlay)
	else
		if self:IsBank() or self:IsReagentBank() then
			if self:GetItem() then
				local id = self:IsBank() and BankButtonIDToInvSlotID(self:GetID()) or ReagentBankButtonIDToInvSlotID(self:GetID())
				self:AnchorTooltip()
				GameTooltip:SetInventoryItem("player", id)
				GameTooltip:Show()
				CursorUpdate(self)
			end
		else
			ContainerFrameItemButton_OnEnter(self)
		end
	end
end

function Item:OnLeave()
	GameTooltip:Hide()
	BattlePetTooltip:Hide()
	ResetCursor()
end

Item.UpdateTooltip = Item.OnEnter

function Item:AnchorTooltip()
	if self:GetRight() >= (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
end

-----------------------------------------------------------------------
-- Utility

local function CacheOverlay_OnEnter(self)
	local parent = self:GetParent()
	if parent:GetItem() then
		parent:AnchorTooltip()
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

function Item:CreateCacheOverlay()
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

function Item:GetBagContainer(container, bag)
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

function Item:IsCached()
	return self.container:GetParent():IsCached()
end

function Item:GetBag()
	return self.bag
end

function Item:GetInfo()
	local player = self.container:GetParent():GetPlayerName()
	local icon, count, locked, quality, readable, lootable, link, _, noValue, itemID
	if self:IsCached() then
		icon, count, locked, quality, readable, lootable, link = ItemCache:GetItemInfo(player, self.bag, self.slot)
	else
		-- LibItemCache doesn't provide noValue or itemID, so fallback to base API
		icon, count, locked, quality, readable, lootable, link, _, noValue, itemID = GetContainerItemInfo(self.bag, self.slot)
		if link and quality < 0 then
			quality = select(3, GetItemInfo(link))
		end
	end

	if not icon and link and (self:IsCached() or not C_Item.IsItemDataCached(ItemLocation:CreateFromBagAndSlot(self.bag, self.slot))) then
		self.itemID = GetItemInfoInstant(link)
		if self.itemID then
			self:RegisterEvent("ITEM_DATA_LOAD_RESULT")
			C_Item.RequestLoadItemDataByID(self.itemID)
		end
	end

	return icon, count, locked, quality, readable, lootable, link, noValue, itemID
end

function Item:GetQuestInfo()
	if not self:IsCached() then
		return GetContainerItemQuestInfo(self.bag, self.slot)
	end
end

function Item:IsNew()
	if not self:IsCached() then
		return C_NewItems.IsNewItem(self.bag, self.slot), IsBattlePayItem(self.bag, self.slot)
	end
end

function Item:IsBank()
	return self.bag == BANK_CONTAINER
end

function Item:IsReagentBank()
	return self.bag == REAGENTBANK_CONTAINER
end
