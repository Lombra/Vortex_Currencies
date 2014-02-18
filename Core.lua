local Libra = LibStub("Libra")

local addon = Libra:NewAddon(...)

local currenciesByName = {}

local defaults = {
	global = {
		Characters = {
			["*"] = {}
		}
	}
}

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("Vortex_CurrenciesDB", defaults)
	self.ThisCharacter = self.db.global.Characters[DataStore:GetCharacter()]
	self.Characters = self.db.global.Characters
	self:RegisterEvent("PLAYER_LOGIN", "ScanCurrencies")
	self:RegisterEvent("CURRENCY_DISPLAY_UPDATE", "ScanCurrencies")
	for k, character in pairs(self.Characters) do
		for i, currency in ipairs(character) do
			if not currency.isHeader then
				currenciesByName[GetCurrencyInfo(currency.id)] = currency.id
			end
		end
	end
end

local headersState
local headerCount

local function SaveHeaders()
	headersState = {}
	headerCount = 0		-- use a counter to avoid being bound to header names, which might not be unique.
	
	for i = GetCurrencyListSize(), 1, -1 do		-- 1st pass, expand all categories
		local _, isHeader, isExpanded = GetCurrencyListInfo(i)
		if isHeader then
			headerCount = headerCount + 1
			if not isExpanded then
				ExpandCurrencyList(i, 1)
				headersState[headerCount] = true
			end
		end
	end
end

local function RestoreHeaders()
	headerCount = 0
	for i = GetCurrencyListSize(), 1, -1 do
		local _, isHeader = GetCurrencyListInfo(i)
		if isHeader then
			headerCount = headerCount + 1
			if headersState[headerCount] then
				ExpandCurrencyList(i, 0)		-- collapses the header
			end
		end
	end
	headersState = nil
end

function addon:ScanCurrencies()
	SaveHeaders()
	
	wipe(self.ThisCharacter)
	
	for i = 1, GetCurrencyListSize() do
		local name, isHeader, isExpanded, isUnused, isWatched, count, extraCurrencyType, icon = GetCurrencyListInfo(i)
		local link = GetCurrencyListLink(i)
		local id = link and tonumber(link:match("currency:(%d+)"))
		
		local currency = {}
		if isHeader then
			currency.isHeader = true
			currency.name = name
		else
			currency.id = id
			currency.count = count
			currenciesByName[name] = id
		end
		tinsert(self.ThisCharacter, currency)
	end
	
	RestoreHeaders()
end

function addon:GetNumCurrencies(character)
	return #self.Characters[character]
end

function addon:GetCurrencyInfo(character, index)
	local currency = self.Characters[character][index]
	return currency.isHeader, currency.name, currency.id, currency.count
end

function addon:GetCurrencyInfoByID(character, id)
	for i = 1, self:GetNumCurrencies(character) do	
		local currency = self.Characters[character][i]
		if currency.id == id then
			return currency.name, currency.count
		end
	end
end

function addon:GetCurrencyInfoByName(character, name)
	for i = 1, self:GetNumCurrencies(character) do	
		local currency = self.Characters[character][i]
		if not currency.isHeader and GetCurrencyInfo(currency.id) == name then
			return currency.id, currency.count
		end
	end
end

function addon:GetCurrencyID(name)
	return currenciesByName[name]
end