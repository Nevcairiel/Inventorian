local _, Inventorian = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Inventorian")

local WoW10 = select(4, GetBuildInfo()) >= 100000

local ItemCache = LibStub("LibItemCache-1.1-Inventorian")

local BagMixin = {}

Inventorian.Bag = {}
Inventorian.Bag.pool = {}

local NUM_TOTAL_EQUIPPED_BAG_SLOTS = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS

local ContainerFrameFilterDropDown_OnLoad
do
	local function OnBagFilterClicked(bagID, filterID, value)
		C_Container.SetBagSlotFlag(bagID, filterID, value)
		ContainerFrameSettingsManager:SetFilterFlag(bagID, filterID, value)
	end

	local function AddButtons_BagFilters(bagID, level)
		if not ContainerFrame_CanContainerUseFilterMenu(bagID) then
			return
		end

		local info = UIDropDownMenu_CreateInfo()
		info.text = BAG_FILTER_ASSIGN_TO
		info.isTitle = 1
		info.notCheckable = 1
		UIDropDownMenu_AddButton(info, level)

		info = UIDropDownMenu_CreateInfo()
		local activeBagFilter = ContainerFrameSettingsManager:GetFilterFlag(bagID)

		for i, flag in ContainerFrameUtil_EnumerateBagGearFilters() do
			info.text = BAG_FILTER_LABELS[flag]
			info.checked = activeBagFilter == flag
			info.func = function(_, _, _, value)
				return OnBagFilterClicked(bagID, flag, not value)
			end

			UIDropDownMenu_AddButton(info, level)
		end
	end

	local function AddButtons_BagCleanup(bagID, level)
		local info = UIDropDownMenu_CreateInfo()

		info.text = BAG_FILTER_CLEANUP
		info.isTitle = 1
		info.notCheckable = 1
		UIDropDownMenu_AddButton(info, level)

		info = UIDropDownMenu_CreateInfo()
		info.text = BAG_FILTER_IGNORE
		info.func = function(_, _, _, value)
			if bagID == -1 then -- bank
				C_Container.SetBankAutosortDisabled(not value)
			elseif bagID == 0 then -- backback
				C_Container.SetBackpackAutosortDisabled(not value)
			else
				C_Container.SetBagSlotFlag(bagID, Enum.BagSlotFlags.DisableAutoSort, not value)
			end
		end

		if bagID == -1 then -- bank
			info.checked = C_Container.GetBankAutosortDisabled()
		elseif bagID == 0 then -- backpack
			info.checked = C_Container.GetBackpackAutosortDisabled()
		else
			info.checked = C_Container.GetBagSlotFlag(bagID, Enum.BagSlotFlags.DisableAutoSort)
		end

		UIDropDownMenu_AddButton(info, level)
	end

	local ContainerFrameFilterDropDown_Initialize = function(self, level, addFiltersForAllBags)
		local frame = self:GetParent()
		local bagID = frame:GetID()

		AddButtons_BagFilters(bagID, level)
		AddButtons_BagCleanup(bagID, level)
	end

	ContainerFrameFilterDropDown_OnLoad = function(dropdown)
		UIDropDownMenu_SetInitializeFunction(dropdown, ContainerFrameFilterDropDown_Initialize);
	end
end

local BagID = 1
function Inventorian.Bag:Create()
	local item = next(self.pool)
	if item then
		self.pool[item] = nil
		return item
	end
	local name = ("InventorianBag%d"):format(BagID)
	local bag = Mixin(CreateFrame("Button", name), BagMixin)

	bag:SetSize(30, 30)

	bag.Icon = bag:CreateTexture(name .. "IconTexture", "BORDER")
	bag.Icon:SetAllPoints(bag)

	bag.count = bag:CreateFontString(name .. "Count", "OVERLAY")
	bag.count:SetFontObject("NumberFontNormalSmall")
	bag.count:SetJustifyH("RIGHT")
	bag.count:SetPoint("BOTTOMRIGHT", -2, 2)

	local nt = bag:CreateTexture(name .. "NormalTexture")
	nt:SetTexture([[Interface\Buttons\UI-Quickslot2]])
	nt:SetWidth(64 * (5/6))
	nt:SetHeight(64 * (5/6))
	nt:SetPoint("CENTER", 0, -1)
	bag:SetNormalTexture(nt)

	local pt = bag:CreateTexture()
	pt:SetTexture([[Interface\Buttons\UI-Quickslot-Depress]])
	pt:SetAllPoints(bag)
	bag:SetPushedTexture(pt)

	local ht = bag:CreateTexture()
	ht:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
	ht:SetAllPoints(bag)
	bag:SetHighlightTexture(ht)

	bag.FilterDropDown = CreateFrame("Frame", name .. "FilterDropDown", bag, "UIDropDownMenuTemplate")
	ContainerFrameFilterDropDown_OnLoad(bag.FilterDropDown)

	bag.FilterIcon = CreateFrame("Frame", nil, bag)
	bag.FilterIcon:SetSize(28, 28)
	bag.FilterIcon:SetScale(0.7)
	bag.FilterIcon:SetPoint("CENTER", bag, "BOTTOMRIGHT", -9, 7)
	bag.FilterIcon.Icon = bag.FilterIcon:CreateTexture(nil, "OVERLAY")
	bag.FilterIcon.Icon:SetAtlas("bags-icon-consumables", true)
	bag.FilterIcon.Icon:SetPoint("CENTER")
	bag.FilterIcon:Hide()

	bag.SelectedTexture = bag:CreateTexture(nil, "OVERLAY")
	bag.SelectedTexture:SetBlendMode("ADD")
	bag.SelectedTexture:SetTexture("Interface\\Buttons\\CheckButtonHilight")
	bag.SelectedTexture:SetAllPoints(bag)
	bag.SelectedTexture:Hide()

	bag:RegisterForClicks("AnyUp")
	bag:RegisterForDrag("LeftButton")

	bag:SetScript("OnEnter", bag.OnEnter)
	bag:SetScript("OnShow", bag.OnShow)
	bag:SetScript("OnLeave", bag.OnLeave)
	bag:SetScript("OnClick", bag.OnClick)
	bag:SetScript("OnDragStart", bag.OnDrag)
	bag:SetScript("OnReceiveDrag", bag.OnClick)
	bag:SetScript("OnEvent", bag.OnEvent)

	BagID = BagID + 1
	return bag
end

function BagMixin:Free()
	Inventorian.Bag.pool[self] = true
	self.tabData = nil
	self:Hide()
	self:SetParent(nil)
	self:UnregisterAllEvents()
end

function BagMixin:Set(parent, id)
	self:SetID(id)
	self:SetParent(parent)
	self:SetSelected(false)

	if self:IsBank() or self:IsReagentBank() or self:IsBackpack() then
		SetItemButtonTexture(self, [[Interface\Buttons\Button-Backpack-Up]])
		SetItemButtonTextureVertexColor(self, 1, 1, 1)
	elseif self:IsAccountBag() then
		self.Icon:SetAtlas("Garr_Building-AddFollowerPlus", TextureKitConstants.UseAtlasSize)
		SetItemButtonTextureVertexColor(self, 1, 1, 1)
	else
		self:Update()

		self:RegisterEvent("ITEM_LOCK_CHANGED")
		self:RegisterEvent("CURSOR_CHANGED")
		self:RegisterEvent("BAG_UPDATE")
		self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")

		if self:IsBankBag() then
			self:RegisterEvent("BANKFRAME_OPENED")
			self:RegisterEvent("BANKFRAME_CLOSED")
			self:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
			self:RegisterEvent("BANK_BAG_SLOT_FLAGS_UPDATED")
		end

		if self:IsBackpackBag() then
			self:RegisterEvent("BAG_SLOT_FLAGS_UPDATED")
		end
	end
end

function BagMixin:SetWarbandData(data)
	if not self:IsAccountBag() then return end
	self.tabData = data

	self.Icon:SetTexture(self.tabData.icon or QUESTION_MARK_ICON)
end

function BagMixin:SetSelected(selected)
	self.SelectedTexture:SetShown(selected)
end

-- ContainerFrameMixin compat
function BagMixin:GetBagID()
	return self:GetID()
end

function BagMixin:OnEvent(event, ...)
	if event == "BANKFRAME_OPENED" or event == "BANKFRAME_CLOSED" then
		self:Update()
	elseif not self:IsCached() then
		if event == "ITEM_LOCK_CHANGED" then
			self:UpdateLock()
		elseif event == "CURSOR_CHANGED" then
			self:UpdateCursor()
		elseif event == "BAG_UPDATE" or event == "PLAYERBANKSLOTS_CHANGED" then
			self:Update()
		elseif event == "PLAYERBANKBAGSLOTS_CHANGED" then
			self:Update()
		elseif event == "BAG_SLOT_FLAGS_UPDATED" or event == "BANK_BAG_SLOT_FLAGS_UPDATED" then
			self:Update()
		end
	end
end

function BagMixin:OnClick(button)
	local link = self:GetInfo()
	if link and HandleModifiedItemClick(link) then
		return
	end

	if self:IsAccountBag() then
		if button == "RightButton" and self.tabData and not self:IsCached() then
			if not self:GetParent().TabSettingsMenu then
				self:GetParent().TabSettingsMenu = CreateFrame("Frame", nil, self:GetParent(), "BankPanelTabSettingsMenuTemplate")
				self:GetParent().TabSettingsMenu:SetPoint("TOPLEFT", self:GetParent(), "TOPRIGHT", 40, 5)
				self:GetParent().TabSettingsMenu.GetBankFrame = function() return self:GetParent() end
				self:GetParent().TabSettingsMenu:Hide()
			end
			self:GetParent().TabSettingsMenu:TriggerEvent(BankPanelTabSettingsMenuMixin.Event.OpenTabSettingsRequested, self.tabData.ID)
		elseif self.tabData then
			self:GetParent().selectedWarbandBag = self.tabData.ID
			self:GetParent():SetCurrentBags()
			self:GetParent():UpdateBags()
		elseif self:IsPurchasable() then
			self:PurchaseSlotWarband()
		end
	elseif self:IsCached() then
		return
	elseif button == "RightButton" then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		ToggleDropDownMenu(1, nil, self.FilterDropDown, self, 0, 0);
	elseif self:IsPurchasable() then
		self:PurchaseSlot()
	elseif CursorHasItem() then
		if self:IsBackpack() then
			PutItemInBackpack()
		else
			PutItemInBag(self:GetInventorySlot())
		end
	elseif not(self:IsBackpack() or self:IsBank()) then
		self:Pickup()
	end
end

function BagMixin:OnDrag()
	self:Pickup()
end

function BagMixin:OnEnter()
	if self:GetRight() > (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end

	self:UpdateTooltip()
	self:HighlightItems()
end

function BagMixin:OnLeave()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
	self:ClearHighlightItems()
end

function BagMixin:OnShow()
	self:Update()
end

function BagMixin:Update()
	if not self:IsVisible() or not self:GetParent() then return end

	self:UpdateLock()
	self:UpdateSlotInfo()
	self:UpdateCursor()
	self:UpdateFilterIcon()
end

function BagMixin:UpdateLock()
	if self:IsCustomSlot() then
		SetItemButtonDesaturated(self, self:IsLocked())
	end
end

function BagMixin:UpdateCursor()
	if not self:IsCustomSlot() then return end

	if not self:IsCached() and C_PaperDollInfo.CanCursorCanGoInSlot(self:GetInventorySlot()) then
		self:LockHighlight()
	else
		self:UnlockHighlight()
	end
end

function BagMixin:UpdateSlotInfo()
	if not self:IsCustomSlot() then return end

	local link, count, texture = self:GetInfo()
	if link then
		self.hasItem = link

		SetItemButtonTexture(self, texture or C_Item.GetItemIconByID(link))
		SetItemButtonTextureVertexColor(self, 1, 1, 1)
	else
		self.hasItem = nil

		SetItemButtonTexture(self, [[Interface\PaperDoll\UI-PaperDoll-Slot-Bag]])

		--color red if the bag can be purchased
		if self:IsPurchasable() then
			SetItemButtonTextureVertexColor(self, 1, 0.1, 0.1)
		else
			SetItemButtonTextureVertexColor(self, 1, 1, 1)
		end
	end
	self:SetCount(count)
end

function BagMixin:UpdateFilterIcon()
	local id = self:GetID()

	self.FilterIcon:Hide()
	if id > 0 and not self:IsCached() then
		ContainerFrameMixin.UpdateFilterIcon(self)
	end
end

function BagMixin:SetCount(count)
	count = count or 0

	if count > 1 then
		if count > 999 then
			self.count:SetFormattedText("%.1fk", count/1000)
		else
			self.count:SetText(count)
		end
		self.count:Show()
	else
		self.count:Hide()
	end
end

function BagMixin:Pickup()
	PickupBagFromSlot(self:GetInventorySlot())
end

function BagMixin:HighlightItems()
	self:GetParent().itemContainer:HighlightBag(self:GetID())
end

function BagMixin:ClearHighlightItems()
	self:GetParent().itemContainer:HighlightBag(nil)
end

--show the purchase slot dialog
function BagMixin:PurchaseSlot()
	if not StaticPopupDialogs["CONFIRM_BUY_BANK_SLOT_INVENTORIAN"] then
		StaticPopupDialogs["CONFIRM_BUY_BANK_SLOT_INVENTORIAN"] = {
			text = CONFIRM_BUY_BANK_SLOT,
			button1 = YES,
			button2 = NO,

			OnAccept = function(f)
				PurchaseSlot()
			end,

			OnShow = function(f)
				MoneyFrame_Update(f:GetName().. "MoneyFrame", GetBankSlotCost(GetNumBankSlots()))
			end,

			hasMoneyFrame = 1,
			timeout = 0,
			hideOnEscape = 1,
			preferredIndex = STATICPOPUP_NUMDIALOGS,
		}
	end

	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
	StaticPopup_Show("CONFIRM_BUY_BANK_SLOT_INVENTORIAN")
end

function BagMixin:PurchaseSlotWarband()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
	StaticPopup_Show("CONFIRM_BUY_BANK_TAB", nil, nil, { bankType = Enum.BankType.Account })
end

function BagMixin:UpdateTooltip()
	GameTooltip:ClearLines()

	if self:IsBackpack() then
		GameTooltip:SetText(BACKPACK_TOOLTIP, 1, 1, 1)
	elseif self:IsBank() then
		GameTooltip:SetText(BANK, 1, 1, 1)
	elseif self:IsReagentBank() then
		GameTooltip:SetText(REAGENT_BANK, 1, 1, 1)
	elseif self:IsAccountBag() then
		if self.tabData then
			BankPanelTabMixin.ShowTooltip(self)
		elseif self:IsPurchasable() then
			GameTooltip:SetText(BANK_BAG_PURCHASE, 1, 1, 1)
			GameTooltip:AddLine(L["Click to purchase"])
			local tabCost = C_Bank.FetchNextPurchasableBankTabCost(Enum.BankType.Account)
			if tabCost then
				SetTooltipMoney(GameTooltip, tabCost)
			end
		end
	else
		self:UpdateBagTooltip()
	end

	GameTooltip:Show()
end

function BagMixin:UpdateBagTooltip()
	if not GameTooltip:SetInventoryItem("player", self:GetInventorySlot()) then
		if self:IsPurchasable() then
			GameTooltip:SetText(BANK_BAG_PURCHASE, 1, 1, 1)
			GameTooltip:AddLine(L["Click to purchase"])
			SetTooltipMoney(GameTooltip, GetBankSlotCost(GetNumBankSlots()))
		else
			GameTooltip:SetText(EQUIP_CONTAINER, 1, 1, 1)
		end
	end
end

-----------------------------------------------------------------------
-- Various information getters

function BagMixin:GetPlayer()
	return self:GetParent():GetPlayerName()
end

function BagMixin:IsCached()
	return self:GetParent():IsCached()
end

function BagMixin:IsBackpack()
	return (self:GetID() == BACKPACK_CONTAINER)
end

function BagMixin:IsBank()
	return (self:GetID() == BANK_CONTAINER)
end

function BagMixin:IsReagentBank()
	return (self:GetID() == REAGENTBANK_CONTAINER)
end

function BagMixin:IsReagentBag()
	return self:IsBackpackBag() and self:GetID() > NUM_BAG_SLOTS
end

function BagMixin:IsBackpackBag()
	return (self:GetID() > 0 and self:GetID() <= NUM_TOTAL_EQUIPPED_BAG_SLOTS)
end

function BagMixin:IsBankBag()
	return (self:GetID() > NUM_TOTAL_EQUIPPED_BAG_SLOTS and self:GetID() <= (NUM_TOTAL_EQUIPPED_BAG_SLOTS + NUM_BANKBAGSLOTS))
end

function BagMixin:IsAccountBag()
	return (self:GetID() >= Enum.BagIndex.AccountBankTab_1 and self:GetID() <= Enum.BagIndex.AccountBankTab_5)
end

function BagMixin:IsCustomSlot()
	return self:IsBackpackBag() or self:IsBankBag()
end

function BagMixin:IsPurchasable()
	if self:IsCached() then
		return false
	end
	if self:IsAccountBag() then
		return C_Bank.FetchNumPurchasedBankTabs(Enum.BankType.Account) < 5 and C_Bank.CanPurchaseBankTab(Enum.BankType.Account)
	end
	return self:IsBankBag() and (self:GetID() - NUM_TOTAL_EQUIPPED_BAG_SLOTS) > GetNumBankSlots()
end

function BagMixin:GetInventorySlot()
	return self:IsCustomSlot() and C_Container.ContainerIDToInventoryID(self:GetID()) or nil
end

function BagMixin:GetInfo()
	local link, freeSlots, icon, slot, numSlots = ItemCache:GetBagInfo(self:GetPlayer(), self:GetID())
	return link, 0, icon
end

function BagMixin:IsLocked()
	if self:IsCached() then
		return false
	end
	local slot = self:GetInventorySlot()
	if slot then
		return IsInventoryItemLocked(slot)
	end
	return false
end
