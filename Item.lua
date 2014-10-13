local _, Inventorian = ...

local Item = CreateFrame("Button")
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
		item = CreateFrame("Button", ("InventorianItemButton%d"):format(self.count), nil, "ContainerFrameItemButtonTemplate")
		item = self:WrapItemButton(item)
	end

	return item
end


function Inventorian.Item:WrapItemButton(item)
	item = setmetatable(item, Item_MT)

	-- scripts
	item:SetScript("OnEvent", nil)
	item:SetScript("OnEnter", item.OnEnter)
	item:SetScript("OnLeave", item.OnLeave)
	item:SetScript("OnShow", item.OnShow)
	item.UpdateTooltip = nil
	
	-- elements
	local name = item:GetName()
	item.IconQuestTexture = _G[name .. "IconQuestTexture"]
	item.Cooldown = _G[name .. "Cooldown"]

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
	self:SetParent(nil)
	self:SetID(0)
	self:ClearAllPoints()
	self:Hide()

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
	self:Update()
end

-----------------------------------------------------------------------
-- Button style setters

function Item:Update()
	if not self:IsVisible() then
		return
	end

	local icon, count, locked, quality, readable, lootable, link = self:GetInfo()
	self:SetItem(link)
	self:SetTexture(icon)
	self:SetCount(count)
	self:SetLocked(locked)
	self:SetReadable(readable)
	self:UpdateCooldown()
	self:UpdateBorder(quality)

	if GameTooltip:IsOwned(self) then
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
	SetItemButtonTexture(self, icon or [[Interface\PaperDoll\UI-Backpack-EmptySlot]])
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
	if self:GetItem() then
		ContainerFrame_UpdateCooldown(self.bag, self)
	else
		CooldownFrame_SetTimer(self.Cooldown, 0, 0, 0)
		SetItemButtonTextureVertexColor(self, 1, 1, 1)
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

	if self.flashAnim:IsPlaying() or self.newitemglowAnim:IsPlaying() then
		self.flashAnim:Stop()
		self.newitemglowAnim:Stop()
	end
end

function Item:UpdateBorder(quality)
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
		
		if quality then
			if quality >= LE_ITEM_QUALITY_COMMON and BAG_ITEM_QUALITY_COLORS[quality] then
				self:SetBorderColor(BAG_ITEM_QUALITY_COLORS[quality].r, BAG_ITEM_QUALITY_COLORS[quality].g, BAG_ITEM_QUALITY_COLORS[quality].b)
			end
		end
	end
end

function Item:OnEnter()
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

function Item:GetBagContainer(container, bag)
	local bagContainers = container.bagContainers

	-- use a metatable to create the new bag wrappers on demand
	if not bagContainers then
		bagContainers = setmetatable({}, {
			__index = function(t, k)
				local f = CreateFrame('Frame', nil, container)
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

function Item:GetInfo()
	local icon, count, locked, quality, readable, lootable, link = GetContainerItemInfo(self.bag, self.slot)
	if link and quality < 0 then
		quality = select(3, GetItemInfo(link)) 
	end

	return icon, count, locked, quality, readable, lootable, link
end

function Item:GetQuestInfo()
	return GetContainerItemQuestInfo(self.bag, self.slot)
end

function Item:IsNew()
	return C_NewItems.IsNewItem(self.bag, self.slot), IsBattlePayItem(self.bag, self.slot)
end

function Item:IsBank()
	return self.bag == BANK_CONTAINER
end

function Item:IsReagentBank()
	return self.bag == REAGENTBANK_CONTAINER
end
