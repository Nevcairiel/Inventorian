--[[
Copyright 2011-2017 João Cardoso
LibItemCache is distributed under the terms of the GNU General Public License.
You can redistribute it and/or modify it under the terms of the license as
published by the Free Software Foundation.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this library. If not, see <http://www.gnu.org/licenses/>.

This file is part of LibItemCache.
--]]

local Lib = LibStub('LibItemCache-1.1')
if not BagBrother or Lib:HasCache() then
	return
end

local Cache = Lib:NewCache()
local NUM_TOTAL_EQUIPPED_BAG_SLOTS = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS
local LAST_BANK_SLOT = NUM_TOTAL_EQUIPPED_BAG_SLOTS + NUM_BANKBAGSLOTS
local FIRST_BANK_SLOT = NUM_TOTAL_EQUIPPED_BAG_SLOTS + 1
local ITEM_COUNT = ';(%d+)$'


--[[ Items ]]--

function Cache:GetBag(realm, player, bag, tab, slot)
	if tab then
		local tab = self:GetGuildTab(realm, player, tab)
		if tab then
			return tab.name, tab.icon, tab.view, tab.deposit, tab.withdraw, nil, true
		end
	elseif slot then
		return self:GetItem(realm, player, 'equip', nil, slot)
	else
		return self:GetPersonalBag(realm, player, bag)
	end
end

function Cache:GetItem(realm, player, bag, tab, slot)
	if tab then
		bag = self:GetGuildTab(realm, player, tab)
	else
		bag = self:GetPersonalBag(realm, player, bag)
	end

	local item = bag and bag[slot]
	if item then
		return strsplit(';', item)
	end
end

function Cache:GetGuildTab(realm, player, tab)
	local name = self:GetGuild(realm, player)
	local guild = name and BrotherBags[realm][name .. '*']

	return guild and guild[tab]
end

function Cache:GetPersonalBag(realm, player, bag)
	return BrotherBags[realm][player][bag]
end

function Cache:GetBagSize(realm, player, bag)
	return BrotherBags[realm][player].BagSize[bag]
end

function Cache:GetBackpackSize(realm, player)
	return BrotherBags[realm][player].backpackSize
end


--[[ Others ]]--

function Cache:GetGuild(realm, player)
	return BrotherBags[realm][player].guild
end

function Cache:GetMoney(realm, player)
	return BrotherBags[realm][player].money
end


--[[ Players ]]--

function Cache:GetPlayer(realm, player)
	realm = BrotherBags[realm]
	player = realm and realm[player]

	if player then
		return player.class, player.race, player.sex, player.faction and 'Alliance' or 'Horde'
	end
end

function Cache:DeletePlayer(realm, player)
	local realm = BrotherBags[realm]
	local guild = realm and realm[player] and realm[player].guild
	realm[player] = nil

	if guild then
		for _, actor in pairs(realm) do
			if actor.guild == guild then
				return
			end
		end

		realm[guild .. '*'] = nil
	end
end

function Cache:GetPlayers(realm)
	local players = {}
	for name in pairs(BrotherBags[realm] or {}) do
		if not name:find('*$') then
			tinsert(players, name)
		end
	end

	return players
end


--[[ Realms ]]--

function Cache:GetRealms()
	local realms = {}
	for name in pairs(BrotherBags) do
		tinsert(realms, name)
	end

	return realms
end
