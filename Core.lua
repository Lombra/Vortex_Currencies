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
				local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(currency.id)
				currenciesByName[currencyInfo.name] = currency.id
			end
		end
	end
end

local headersState
local headerCount

local function saveHeaders()
	headersState = {}
	headerCount = 0
	
	for i = C_CurrencyInfo.GetCurrencyListSize(), 1, -1 do
		local currencyInfo = C_CurrencyInfo.GetCurrencyListInfo(i)
		if currencyInfo.isHeader then
			headerCount = headerCount + 1
			if not currencyInfo.isHeaderExpanded then
				C_CurrencyInfo.ExpandCurrencyList(i, 1)
				headersState[headerCount] = true
			end
		end
	end
end

local function restoreHeaders()
	headerCount = 0
	for i = C_CurrencyInfo.GetCurrencyListSize(), 1, -1 do
		local currencyInfo = C_CurrencyInfo.GetCurrencyListInfo(i)
		if currencyInfo.isHeader then
			headerCount = headerCount + 1
			if headersState[headerCount] then
				C_CurrencyInfo.ExpandCurrencyList(i, 0)
			end
		end
	end
	headersState = nil
end

function addon:ScanCurrencies()
	saveHeaders()
	
	wipe(self.ThisCharacter)
	
	for i = 1, C_CurrencyInfo.GetCurrencyListSize() do
		local currencyInfo = C_CurrencyInfo.GetCurrencyListInfo(i)
		local link = C_CurrencyInfo.GetCurrencyListLink(i)
		local id = link and tonumber(link:match("currency:(%d+)"))
		
		local currency = {}
		if currencyInfo.isHeader then
			currency.isHeader = true
			currency.name = currencyInfo.name
		else
			currency.id = id
			currency.count = currencyInfo.quantity
			currenciesByName[currencyInfo.name] = id
		end
		tinsert(self.ThisCharacter, currency)
	end
	
	restoreHeaders()
	
	self.ui:Refresh()
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
		local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(currency.id)
		if not currency.isHeader and currencyInfo.name == name then
			return currency.id, currency.count
		end
	end
end

function addon:GetCurrencyID(name)
	return currenciesByName[name]
end