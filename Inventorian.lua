local _, Inventorian = ...
Inventorian = LibStub("AceAddon-3.0"):NewAddon(Inventorian, "Inventorian", "AceEvent-3.0")

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
	self.bag = Inventorian.Frame:Create("InventorianBagFrame", "Bag", db.bag, {0, 1, 2, 3, 4})
	self.bag:Show()
end
