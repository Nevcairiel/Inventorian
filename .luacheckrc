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
	"C_Container",
	"C_Item",
	"C_NewItems",
	"CreateFrame",
	"CursorCanGoInSlot",
	"CursorHasItem",
	"CursorUpdate",
	"DepositReagentBank",
	"GetBankSlotCost",
	"GetBuildInfo",
	"GetItemIcon",
	"GetItemInfo",
	"GetItemInfoInstant",
	"GetNumBankSlots",
	"GetReagentBankCost",
	"GetRealmName",
	"GetScreenWidth",
	"IsInventoryItemLocked",
	"IsReagentBankUnlocked",
	"PickupBagFromSlot",
	"PlaySound",
	"PurchaseSlot",
	"PutItemInBackpack",
	"PutItemInBag",
	"ReagentBankButtonIDToInvSlotID",
	"ResetCursor",
	"UnitName",

	-- FrameXML frames
	"BackpackTokenFrame",
	"BankFrame",
	"BattlePetTooltip",
	"ContainerFrameSettingsManager",
	"GameTooltip",
	"MerchantFrame",
	"ReagentBankFrameUnlockInfo",
	"UIParent",

	-- FrameXML API
	"BackpackTokenFrame_IsShown",
	"BackpackTokenFrame_Update",
	"CloseBankFrame",
	"CloseDropDownMenus",
	"ContainerFrame_CanContainerUseFilterMenu",
	"ContainerFrame_OnLoad",
	"ContainerFrame_UpdateCooldown",
	"ContainerFrameFilterDropDown_OnLoad",
	"ContainerFrameItemButton_OnEnter",
	"ContainerFrameMixin",
	"ContainerFrameUtil_EnumerateBagGearFilters",
	"HandleModifiedItemClick",
	"ItemButtonMixin",
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
	"UIDropDownMenu_CreateInfo",
	"UIDropDownMenu_SetInitializeFunction",
	"UISpecialFrames",

	-- FrameXML Constants
	"BACKPACK_CONTAINER",
	"BACKPACK_TOOLTIP",
	"BAG_CLEANUP_BAGS",
	"BAG_FILTER_ASSIGN_TO",
	"BAG_FILTER_CLEANUP",
	"BAG_FILTER_ICONS",
	"BAG_FILTER_IGNORE",
	"BAG_FILTER_LABELS",
	"BAGSLOT",
	"BANK",
	"BANK_BAG_PURCHASE",
	"BANK_CONTAINER",
	"CLASS_ICON_TCOORDS",
	"CONFIRM_BUY_BANK_SLOT",
	"Enum",
	"EQUIP_CONTAINER",
	"NEW_ITEM_ATLAS_BY_QUALITY",
	"NO",
	"NUM_BAG_SLOTS",
	"NUM_BANKBAGSLOTS",
	"NUM_CONTAINER_FRAMES",
	"NUM_TOTAL_EQUIPPED_BAG_SLOTS",
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
