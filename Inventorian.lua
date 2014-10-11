local Inventorian = LibStub("AceAddon-3.0"):NewAddon("Inventorian", "AceEvent-3.0")

local db
local defaults = {
	profile = {
		bag = {
			x = 0,
			y = 0,
			point = "CENTER",
			width = 300,
			height = 400,
		},
		bank = {},
	}
}

function Inventorian:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("InventorianDB", defaults, true)
	db = self.db.profile
end

function Inventorian:OnEnable()
	self.bag = self:CreateFrame("InventorianBagFrame", "Bag", db.bag)
	self.bag:Show()
end
