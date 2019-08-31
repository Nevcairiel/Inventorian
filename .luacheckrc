std = "lua51"
max_line_length = false
exclude_files = {
	"libs/",
	"BagBrother/",
	".luacheckrc"
}

ignore = {
	"211", -- Unused local variable
	"212", -- Unused argument
	"213", -- Unused loop variable
	"311", -- Value assigned to a local variable is unused
	"542", -- empty if branch
}

globals = {
	"BankFrame.selectedTab",
	"MoneyTypeInfo",
	"StaticPopupDialogs",
	"UpdateContainerFrameAnchors",
}

read_globals = {
	"ceil", "floor",
	"mod",
	"strtrim",
	"tinsert",
	"wipe",

	-- our own globals
	"InventorianBagFrame",

	-- misc custom, third party libraries
	"LibStub",

	-- API functions
	"BankButtonIDToInvSlotID",
	"C_Item",
	"C_NewItems",
	"ContainerIDToInventoryID",
	"CreateFrame",
	"CursorCanGoInSlot",
	"CursorHasItem",
	"CursorUpdate",
	"DepositReagentBank",
	"GetBagSlotFlag",
	"GetBankBagSlotFlag",
	"GetBankSlotCost",
	"GetContainerItemCooldown",
	"GetContainerItemInfo",
	"GetContainerItemQuestInfo",
	"GetContainerNumSlots",
	"GetItemIcon",
	"GetItemInfo",
	"GetItemInfoInstant",
	"GetNumBankSlots",
	"GetReagentBankCost",
	"GetRealmName",
	"GetScreenWidth",
	"IsBattlePayItem",
	"IsInventoryItemLocked",
	"IsReagentBankUnlocked",
	"PickupBagFromSlot",
	"PlaySound",
	"PurchaseSlot",
	"PutItemInBackpack",
	"PutItemInBag",
	"ReagentBankButtonIDToInvSlotID",
	"ResetCursor",
	"SortBags",
	"SortBankBags",
	"SortReagentBankBags",
	"UnitName",

	-- FrameXML frames
	"BackpackTokenFrame",
	"BankFrame",
	"BattlePetTooltip",
	"GameTooltip",
	"MerchantFrame",
	"ReagentBankFrameUnlockInfo",
	"UIParent",

	-- FrameXML API
	"BackpackTokenFrame_IsShown",
	"BackpackTokenFrame_Update",
	"CloseBankFrame",
	"CloseDropDownMenus",
	"ContainerFrame_UpdateCooldown",
	"ContainerFrameFilterDropDown_OnLoad",
	"ContainerFrameItemButton_OnEnter",
	"HandleModifiedItemClick",
	"ItemLocation",
	"ManageBackpackTokenFrame",
	"MoneyFrame_SetType",
	"MoneyFrame_Update",
	"MoneyFrame_UpdateMoney",
	"PanelTemplates_SetNumTabs",
	"PanelTemplates_SetTab",
	"PanelTemplates_TabResize",
	"SetItemButtonCount",
	"SetItemButtonDesaturated",
	"SetItemButtonQuality",
	"SetItemButtonTexture",
	"SetItemButtonTextureVertexColor",
	"SetPortraitTexture",
	"SetTooltipMoney",
	"StaticPopup_Show",
	"ToggleDropDownMenu",
	"UIDropDownMenu_AddButton",
	"UISpecialFrames",

	-- FrameXML Constants
	"BACKPACK_CONTAINER",
	"BACKPACK_TOOLTIP",
	"BAG_CLEANUP_BAGS",
	"BAG_FILTER_ICONS",
	"BAGSLOT",
	"BANK",
	"BANK_BAG_PURCHASE",
	"BANK_CONTAINER",
	"CLASS_ICON_TCOORDS",
	"CONFIRM_BUY_BANK_SLOT",
	"EQUIP_CONTAINER",
	"LE_BAG_FILTER_FLAG_EQUIPMENT",
	"LE_ITEM_QUALITY_POOR",
	"MAX_CONTAINER_ITEMS",
	"NEW_ITEM_ATLAS_BY_QUALITY",
	"NO",
	"NUM_BAG_SLOTS",
	"NUM_BANKBAGSLOTS",
	"NUM_CONTAINER_FRAMES",
	"NUM_LE_BAG_FILTER_FLAGS",
	"RAID_CLASS_COLORS",
	"REAGENT_BANK",
	"REAGENTBANK_CONTAINER",
	"REAGENTBANK_DEPOSIT",
	"REMOVE",
	"SOUNDKIT",
	"STATICPOPUP_NUMDIALOGS",
	"TEXTURE_ITEM_QUEST_BANG",
	"TEXTURE_ITEM_QUEST_BORDER",
	"UIDROPDOWNMENU_MENU_VALUE",
	"YES",
}
