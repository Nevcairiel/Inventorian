--[[
Copyright 2011-2017 João Cardoso
BagBrother is distributed under the terms of the GNU General Public License (Version 3).
As a special exception, the copyright holders of this addon do not give permission to
redistribute and/or modify it.

This addon is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the addon. If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.

This file is part of BagBrother.
--]]

local EquipmentSlots = INVSLOT_LAST_EQUIPPED

local Backpack = Enum.BagIndex.Backpack


--[[ Continuous Events ]]--

function InventorianBagBrother:BAG_UPDATE(bag)
	local isBag = bag > Bank
	local isBank = bag >= Enum.BagIndex.CharacterBankTab_1 and bag <= Enum.BagIndex.CharacterBankTab_6
	local isAccountBank = bag >= Enum.BagIndex.AccountBankTab_1 and bag <= Enum.BagIndex.AccountBankTab_5

	if (isBank and not self.atBank) or (isAccountBank and not (self.atBank or self.atAccountBank)) then
		return
	end

	if isBag then
		self:SaveBag(bag, bag == Backpack or isBank or isAccountBank)
		if bag == Backpack then
			self.Player.backpackSize = C_Container.GetContainerNumSlots(Backpack)
		end
	end
end

function InventorianBagBrother:UNIT_INVENTORY_CHANGED(unit)
	if unit == 'player' then
		for i = 1, EquipmentSlots do
			self:SaveEquip(i)
		end
	end
end

function InventorianBagBrother:PLAYER_MONEY()
	self.Player.money = GetMoney()
end

function InventorianBagBrother:PLAYER_ENTERING_WORLD()
	self.Player.backpackSize = C_Container.GetContainerNumSlots(Backpack)
end

function InventorianBagBrother:PLAYER_INTERACTION_MANAGER_FRAME_SHOW(id)
	if id == Enum.PlayerInteractionType.Banker then
		self:BANKFRAME_OPENED()
	elseif id == Enum.PlayerInteractionType.AccountBanker then
		self:ACCOUNT_BANKFRAME_OPENED()
	elseif id == Enum.PlayerInteractionType.GuildBanker then
		self:GUILDBANKFRAME_OPENED()
	end
end

function InventorianBagBrother:PLAYER_INTERACTION_MANAGER_FRAME_HIDE(id)
	if id == Enum.PlayerInteractionType.Banker then
		self:BANKFRAME_CLOSED()
	elseif id == Enum.PlayerInteractionType.AccountBanker then
		self:ACCOUNT_BANKFRAME_CLOSED()
	elseif id == Enum.PlayerInteractionType.GuildBanker then
		self:GUILDBANKFRAME_CLOSED()
	end
end

--[[ Bank Events ]]--

function InventorianBagBrother:BANKFRAME_OPENED()
	self.atBank = true
	for i = Enum.BagIndex.CharacterBankTab_1, Enum.BagIndex.CharacterBankTab_6 do
		self:SaveBag(i, true)
	end
	for i = Enum.BagIndex.AccountBankTab_1, Enum.BagIndex.AccountBankTab_5 do
		self:SaveBag(i, true)
	end
end

function InventorianBagBrother:ACCOUNT_BANKFRAME_OPENED()
	self.atAccountBank = true
	for i = Enum.BagIndex.AccountBankTab_1, Enum.BagIndex.AccountBankTab_5 do
		self:SaveBag(i, true)
	end
end

function InventorianBagBrother:BANKFRAME_CLOSED()
	self.atBank = nil
end

function InventorianBagBrother:ACCOUNT_BANKFRAME_CLOSED()
	self.atAccountBank = nil
end

--[[ Guild Events ]]--

function InventorianBagBrother:GUILDBANKFRAME_OPENED()
	self.atGuild = true
end

function InventorianBagBrother:GUILDBANKFRAME_CLOSED()
	self.atGuild = nil
end

function InventorianBagBrother:GUILD_ROSTER_UPDATE()
	self.Player.guild = GetGuildInfo('player')
end

function InventorianBagBrother:GUILDBANKBAGSLOTS_CHANGED()
	if self.atGuild then
		local id = GetGuildInfo('player') .. '*'
		local tab = GetCurrentGuildBankTab()
		local tabs = self.Realm[id] or {}

		for i = 1, GetNumGuildBankTabs() do
			tabs[i] = tabs[i] or {}
			tabs[i].name, tabs[i].icon, tabs[i].view, tabs[i].deposit, tabs[i].withdraw = GetGuildBankTabInfo(i)
			tabs[i].info = nil
		end

		local items = tabs[tab]
		if items then
			for i = 1, 98 do
				local link = GetGuildBankItemLink(tab, i)
				local _, count = GetGuildBankItemInfo(tab, i)

				items[i] = self:ParseItem(link, count)
			end
		end

		self.Realm[id] = tabs
	end
end
