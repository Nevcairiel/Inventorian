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

local Lib = LibStub:NewLibrary('LibItemCache-1.1-Inventorian', 31)
if not Lib then
	return
end

local PetLinkFormat = '|c%s|Hbattlepet:%sx0|h[%s]|h|r'
local PetDataFormat = '^' .. strrep('%d+:', 6) .. '%d+$'

local Cache = function(method, ...)
	if Lib.Cache[method] then
		return Lib.Cache[method](Lib.Cache, ...)
	end
end


--[[ Startup ]]--

Lib.PLAYER = UnitName('player')
Lib.FACTION = UnitFactionGroup('player')
Lib.REALM = GetRealmName()
Lib.Cache = {}


--[[ Players ]]--

function Lib:GetPlayerInfo(player)
	if self:IsPlayerCached(player) then
		return Cache('GetPlayer', self:GetPlayerAddress(player))
	else
		local _,class = UnitClass('player')
		local _,race = UnitRace('player')
		local sex = UnitSex('player')

		return class, race, sex, self.FACTION
	end
end

function Lib:GetPlayerMoney(player)
	if self:IsPlayerCached(player) then
		return Cache('GetMoney', self:GetPlayerAddress(player)) or 0, true
	else
		return GetMoney() or 0
	end
end

function Lib:GetPlayerGuild(player)
	if self:IsPlayerCached(player) then
		return Cache('GetGuild', self:GetPlayerAddress(player))
	else
		return GetGuildInfo('player')
	end
end

function Lib:GetPlayerAddress(address)
	local player, realm = strmatch(address or '', '(.+) %- (.+)')
	return realm or self.REALM, player or address or self.PLAYER
end

function Lib:IsPlayerCached(player)
	return player and player ~= self.PLAYER
end

function Lib:IteratePlayers()
	if not self.players then
		self.players = Cache('GetPlayers', self.REALM) or {self.PLAYER}

		for i, realm in self:IterateRealms() do
			for i, player in ipairs(Cache('GetPlayers', realm) or {}) do
				tinsert(self.players, player .. ' - ' .. realm)
			end
		end

		sort(self.players)
	end

	return ipairs(self.players)
end

function Lib:IterateAlliedPlayers()
	if not self.allied then
		self.allied = {}

		for i, player in self:IteratePlayers() do
			if select(4, self:GetPlayerInfo(player)) == self.FACTION then
				tinsert(self.allied, player)
			end
		end
	end

	return ipairs(self.allied)
end

function Lib:DeletePlayer(player)
	Cache('DeletePlayer', self:GetPlayerAddress(player))
	self.players, self.allied = nil
end


--[[ Realms ]]--

function Lib:IterateRealms()
	if not self.realms then
		local autoComplete = GetAutoCompleteRealms() or {}
		local targets = {}
		for i, realm in ipairs(autoComplete) do
			targets[realm] = true
		end

		self.realms = {}

		for i, realm in ipairs(Cache('GetRealms') or autoComplete) do
			if (targets[realm] or targets[gsub(realm, '%s+', '')]) and realm ~= self.REALM then
				tinsert(self.realms, realm)
			end
		end

		sort(self.realms)
	end

	return ipairs(self.realms)
end


--[[ Bags ]]--

function Lib:GetBagInfo(player, bag)
	local isCached, _,_, tab = self:GetBagType(player, bag)
	local realm, player = self:GetPlayerAddress(player)
	local owned = true

	if tab then
		if isCached then
			return Cache('GetBag', realm, player, bag, tab)
		end
		return GetGuildBankTabInfo(tab)

    elseif bag >= Enum.BagIndex.AccountBankTab_1 and bag <= Enum.BagIndex.AccountBankTab_5 then
		if isCached then
			owned = Cache('GetBag', realm, player, bag)
			return nil, 0, nil, nil, owned and Cache('GetBagSize', realm, player, bag) or 0, true
		else
			owned = C_Bank.FetchNumPurchasedBankTabs(Enum.BankType.Account) > (bag - Enum.BagIndex.AccountBankTab_1)
		end
	elseif bag >= Enum.BagIndex.CharacterBankTab_1 and bag <= Enum.BagIndex.CharacterBankTab_6 then
		if isCached then
			owned = Cache('GetBag', realm, player, bag)
			return nil, 0, nil, nil, owned and Cache('GetBagSize', realm, player, bag) or 0, true
		else
			owned = C_Bank.FetchNumPurchasedBankTabs(Enum.BankType.Character) > (bag - Enum.BagIndex.CharacterBankTab_1)
		end
	elseif bag ~= BACKPACK_CONTAINER then
		local slot = C_Container.ContainerIDToInventoryID(bag)

		if isCached then
			local data, size = Cache('GetBag', realm, player, bag, nil, slot)
			local link, icon = self:RestoreLink(data)

			return link, 0, icon, slot, tonumber(size) or 0, true
		else
			local link = GetInventoryItemLink('player', slot)
			local icon = GetInventoryItemTexture('player', slot)

			return link, C_Container.GetContainerNumFreeSlots(bag), icon, slot, C_Container.GetContainerNumSlots(bag)
		end
	elseif isCached and bag == BACKPACK_CONTAINER then
		local size = Cache('GetBackpackSize', realm, player)
		return nil, 0, nil, nil, tonumber(size) or C_Container.GetContainerNumSlots(bag), true
	end

	return nil, C_Container.GetContainerNumFreeSlots(bag), nil, nil, owned and C_Container.GetContainerNumSlots(bag) or 0, isCached
end

function Lib:GetBagType(player, bag)
	local kind = type(bag)
	local tab = kind == 'string' and tonumber(bag:match('^guild(%d+)$'))
	if tab then
		return not self.AtGuild or self:GetPlayerGuild(player) ~= self:GetPlayerGuild(self.PLAYER), nil,nil, tab
	end

	local accountBank = kind == 'number' and bag >= Enum.BagIndex.AccountBankTab_1 and bag <= Enum.BagIndex.AccountBankTab_5
	local bank = kind == 'number' and bag >= Enum.BagIndex.CharacterBankTab_1 and bag <= Enum.BagIndex.CharacterBankTab_6
	local cached = self:IsPlayerCached(player) or accountBank and not (self.AtAccountBank or self.AtBank) or bank and not self.AtBank

	return cached, bank, accountBank
end


--[[ Items ]]--

function Lib:GetItemInfo(player, bag, slot)
	local isCached, _, _, tab = self:GetBagType(player, bag)

	if isCached then
		local realm, player = self:GetPlayerAddress(player)
		local data, count = Cache('GetItem', realm, player, bag, tab, slot)
		local link, icon, quality = self:RestoreLink(data)

		return icon, tonumber(count) or 1, nil, quality, nil, nil, link, true

	elseif tab then
		local link = GetGuildBankItemLink(tab, slot)
		local icon, count, locked = GetGuildBankItemInfo(tab, slot)
		local quality = link and self:GetItemQuality(link)

		return icon, count, locked, quality, nil, nil, link

	else
		local info = C_Container.GetContainerItemInfo(bag, slot)
		if not info then return end
		if info.hyperlink and not info.quality or info.quality < 0 then
			info.quality = self:GetItemQuality(info.hyperlink)
		end

		return info.iconFileID, info.stackCount, info.isLocked, info.quality, info.isReadable, info.hasLoot, info.hyperlink
	end
end

function Lib:GetItemQuality(link)
	if link:find('battlepet') then
		return tonumber(link:match('%d+:%d+:(%d+)'))
	else
		return C_Item.GetItemQualityByID(link)
	end
end

--[[ Partial Links ]]--

function Lib:RestoreLink(partial)
	if partial then
		if partial:find(PetDataFormat) then
			return self:RestorePetLink(partial)
		else
			return self:RestoreItemLink(partial)
		end
	end
end

function Lib:RestorePetLink(partial)
	local id, _, quality = strsplit(':', partial)
	local name, icon = C_PetJournal.GetPetInfoBySpeciesID(id)

	local color = select(4, C_Item.GetItemQualityColor(quality))
	local link = PetLinkFormat:format(color, partial, name)

	return link, icon, tonumber(quality)
end

function Lib:RestoreItemLink(partial)
	local partial = 'item:' .. partial
	local _, link, quality = C_Item.GetItemInfo(partial)
	return link or partial, C_Item.GetItemIconByID(link or partial), quality
end


--[[ Caches ]]--

function Lib:NewCache()
	self.NewCache = nil
	return self.Cache
end

function Lib:HasCache()
	return not self.NewCache
end
