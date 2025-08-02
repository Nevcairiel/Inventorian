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
	"BankFrame.BankPanel.bankType",
	"UpdateContainerFrameAnchors",
}

read_globals = {
	"ceil", "floor",
	"mod",
	"strtrim",
	"tinsert", "tContains",
	"wipe",

	-- our own globals
	"InventorianBagFrame",

	-- misc custom, third party libraries
	"LibStub",

	-- API functions
	"C_Bank",
	"C_Container",
	"C_Item",
	"C_NewItems",
	"C_PaperDollInfo",
	"C_PlayerInfo",
	"CreateFrame",
	"CursorHasItem",
	"CursorUpdate",
	"GetRealmName",
	"GetScreenWidth",
	"IsInventoryItemLocked",
	"PickupBagFromSlot",
	"PlaySound",
	"PutItemInBackpack",
	"PutItemInBag",
	"ResetCursor",
	"SetCVarBitfield",
	"UnitName",

	-- FrameXML frames
	"BackpackTokenFrame",
	"BankFrame",
	"BankFrame.BankPanel.Show",
	"BankFrame.BankPanel.Hide",
	"BattlePetTooltip",
	"ContainerFrameSettingsManager",
	"GameTooltip",
	"MerchantFrame",
	"UIParent",

	-- FrameXML API
	"AddMoneyTypeInfo",
	"BankPanelDepositMoneyButtonMixin",
	"BankPanelTabMixin",
	"BankPanelTabSettingsMenuMixin",
	"BankPanelWithdrawMoneyButtonMixin",
	"ClearItemButtonOverlay",
	"CloseDropDownMenus",
	"ContainerFrame_CanContainerUseFilterMenu",
	"ContainerFrameItemButton_CalculateItemTooltipAnchors",
	"ContainerFrameItemButtonMixin",
	"ContainerFrameMixin",
	"ContainerFrameUtil_EnumerateBagGearFilters",
	"CooldownFrame_Set",
	"HandleModifiedItemClick",
	"ItemButtonMixin",
	"ItemLocation",
	"Mixin",
	"MoneyFrame_SetType",
	"MoneyFrame_UpdateMoney",
	"PanelTemplates_SetNumTabs",
	"PanelTemplates_SetTab",
	"SetItemButtonCount",
	"SetItemButtonDesaturated",
	"SetItemButtonQuality",
	"SetItemButtonTexture",
	"SetItemButtonTextureVertexColor",
	"SetTooltipMoney",
	"ToggleDropDownMenu",
	"UIDropDownMenu_AddButton",
	"UIDropDownMenu_CreateInfo",
	"UIDROPDOWNMENU_MENU_VALUE",
	"UIDropDownMenu_SetInitializeFunction",
	"UISpecialFrames",

	-- FrameXML Constants
	"ACCOUNT_BANK_DEPOSIT_BUTTON_LABEL",
	"ACCOUNT_QUEST_LABEL",
	"BACKPACK_CONTAINER",
	"BACKPACK_TOOLTIP",
	"BAG_CLEANUP_BAGS",
	"BAG_FILTER_ASSIGN_TO",
	"BAG_FILTER_CLEANUP",
	"BAG_FILTER_IGNORE",
	"BAG_FILTER_LABELS",
	"BAGSLOT",
	"BANK",
	"BANK_BAG_PURCHASE",
	"BANK_DEPOSIT_MONEY_BUTTON_LABEL",
	"BANK_WITHDRAW_MONEY_BUTTON_LABEL",
	"CHARACTER_BANK_DEPOSIT_BUTTON_LABEL",
	"CLASS_ICON_TCOORDS",
	"Enum",
	"EQUIP_CONTAINER",
	"NEW_ITEM_ATLAS_BY_QUALITY",
	"NUM_CONTAINER_FRAMES",
	"NUM_TOTAL_EQUIPPED_BAG_SLOTS",
	"QUESTION_MARK_ICON",
	"RAID_CLASS_COLORS",
	"REMOVE",
	"SELL_ALL_JUNK_ITEMS_EXCLUDE_FLAG",
	"SOUNDKIT",
	"TEXTURE_ITEM_QUEST_BANG",
	"TEXTURE_ITEM_QUEST_BORDER",
	"TextureKitConstants",

	"LE_FRAME_TUTORIAL_EQUIP_REAGENT_BAG",
}
