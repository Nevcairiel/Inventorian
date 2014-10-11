local Inventorian = LibStub("AceAddon-3.0"):GetAddon("Inventorian")

local LibWindow = LibStub("LibWindow-1.1")

Inventorian.Frame = setmetatable({}, { __index = CreateFrame("Frame")})

function Inventorian:CreateFrame(name, title, settings)
	local frame = CreateFrame("Frame", name, UIParent, "InventorianFrameTemplate")
	frame = setmetatable(frame, {__index = Inventorian.Frame})
	
	frame.settings = settings

	-- setup scripts
	frame:SetScript("OnSizeChanged", frame.OnSizeChanged)

	-- load settings
	LibWindow.RegisterConfig(frame, settings)
	LibWindow.RestorePosition(frame)

	frame:SetWidth(frame.settings.width)
	frame:SetHeight(frame.settings.height)

	return frame
end

function Inventorian.Frame:OnSizeChanged(width, height)
	self.settings.width = width
	self.settings.height = height

	LibWindow.SavePosition(self)
end
