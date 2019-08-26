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
local BagSlots = NUM_BAG_SLOTS
local BankSlots = NUM_BANKBAGSLOTS
local VaultSlots = 80 * 2

local FirstBankSlot = 1 + BagSlots
local LastBankSlot = BankSlots + BagSlots
local Backpack = BACKPACK_CONTAINER
local Bank = BANK_CONTAINER


--[[ Continuous Events ]]--

function BagBrother:BAG_UPDATE(bag)
	local isBag = bag > Bank and bag <= BagSlots

	if isBag then
  		self:SaveBag(bag, bag == Backpack)
	end
end

function BagBrother:UNIT_INVENTORY_CHANGED(unit)
	if unit == 'player' then
		for i = 1, EquipmentSlots do
			self:SaveEquip(i)
		end
	end
end

function BagBrother:PLAYER_MONEY()
	self.Player.money = GetMoney()
end


--[[ Bank Events ]]--

function BagBrother:BANKFRAME_OPENED()
	self.atBank = true
end

function BagBrother:BANKFRAME_CLOSED()
	if self.atBank then
		for i = FirstBankSlot, LastBankSlot do
			self:SaveBag(i)
		end

		self:SaveBag(Bank, true)
		self.atBank = nil
	end
end
