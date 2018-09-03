local _, addon = ...

local Currencies = Vortex:NewModule("Currencies", {
	items = false,
	altUI = true,
})

addon.ui = Currencies

function Currencies:BuildList(character)
	local list = {}
	for i = 1, addon:GetNumCurrencies(character) do
		local isHeader, name, id, count = addon:GetCurrencyInfo(character, i)
		if not isHeader and count > 0 then
			tinsert(list, {
				id = id,
				count = count,
				linkType = "currency",
			})
		end
	end
	return list
end

function Currencies:UpdateButton(button, object)
	local name, amount, texturePath, earnedThisWeek, weeklyMax, totalMax, isDiscovered = GetCurrencyInfo(object.id)
	local color = object.count > 0 and HIGHLIGHT_FONT_COLOR or GRAY_FONT_COLOR
	button.label:SetFormattedText("%s (%d)", name, object.count)
	button.label:SetTextColor(color.r, color.g, color.b)
	button.icon:SetTexture(texturePath)
	button.item = GetCurrencyLink(object.id)
end

function Currencies.sort(a, b)
	return GetCurrencyInfo(a.id) < GetCurrencyInfo(b.id)
end

Vortex:AddObjectType("currency", function(link)
	local name, _, texturePath = GetCurrencyInfo(strmatch(link, "currency:(%d+)"))
	return {
		name = name,
		icon = texturePath,
	}
end)

local function addTooltipInfo(self, id)
	if not Vortex.db.tooltip then
		return
	end
	if Vortex.db.tooltipModifier and not IsModifierKeyDown() then
		return
	end
	local numChars = 0
	local total = 0
	for i, character in ipairs(Vortex:GetCharacters()) do
		local accountKey, realmKey, charKey = strsplit(".", character)
		local name, count = addon:GetCurrencyInfoByID(character, id)
		if count and count > 0 then
			self:AddLine("|cffffffff"..count.."|r "..charKey)
			numChars = numChars + 1
			total = total + count
		end
	end
	-- don't bother displaying total amount if only one character has it
	if numChars > 1 then
		self:AddLine("Total: |cffffffff"..total)
	end
	self:Show()
end

hooksecurefunc(GameTooltip, "SetCurrencyByID", function(self, id)
	addTooltipInfo(self, id)
end)

hooksecurefunc(GameTooltip, "SetCurrencyToken", function(self, index)
	local link = GetCurrencyListLink(index)
	addTooltipInfo(self, link and tonumber(link:match("currency:(%d+)")))
end)

hooksecurefunc(GameTooltip, "SetBackpackToken", function(self, index)
	local name, count, icon, currencyID = GetBackpackCurrencyInfo(index)
	addTooltipInfo(self, currencyID)
end)

hooksecurefunc(GameTooltip, "SetHyperlink", function(self, link)
	local id = link:match("currency:(%d+)")
	addTooltipInfo(self, id and tonumber(id))
end)

hooksecurefunc(GameTooltip, "SetMerchantCostItem", function(self, index, itemIndex)
	addTooltipInfo(self, addon:GetCurrencyID(select(4, GetMerchantItemCostItem(index, itemIndex))))
end)

local scrollFrame

function Currencies:UpdateUI()
	scrollFrame:update()
end

do
	scrollFrame = Vortex:CreateScrollFrame("Hybrid", Currencies.ui)
	scrollFrame:SetPoint("TOP", 0, -4)
	scrollFrame:SetPoint("LEFT", 4, 0)
	scrollFrame:SetPoint("BOTTOMRIGHT", -20, 4)
	scrollFrame:SetButtonHeight(16)
	scrollFrame.initialOffsetX = 1
	scrollFrame.initialOffsetY = -2
	scrollFrame.offsetY = -4
	scrollFrame.getNumItems = function()
		return #addon.Characters[Vortex:GetSelectedCharacter()]
	end
	scrollFrame.updateButton = function(button, index)
		local object = addon.Characters[Vortex:GetSelectedCharacter()][index]
		if object.isHeader then
			button.label:SetText(object.name)
			button.label:SetFontObject("GameFontNormal")
			button.label:SetPoint("LEFT", 22, 0)
			button.count:SetText(nil)
			button.icon:SetTexture(nil)
			button:EnableDrawLayer("BORDER")
		else
			local name, _, texturePath = GetCurrencyInfo(object.id)
			button.label:SetText(name)
			if object.count > 0 then
				button.label:SetFontObject("GameFontHighlight")
				button.count:SetFontObject("GameFontHighlight")
			else
				button.label:SetFontObject("GameFontDisable")
				button.count:SetFontObject("GameFontDisable")
			end
			button.label:SetPoint("LEFT", 11, 0)
			button.count:SetText(object.count)
			button.icon:SetTexture(texturePath)
			button:DisableDrawLayer("BORDER")
		end
		button.hl:SetShown(object.isHeader)
		button.hr:SetShown(object.isHeader)
		button.hm:SetShown(object.isHeader)
		button:GetHighlightTexture():SetShown(not object.isHeader)
		button.PostEnter = object.id and postEnter
		button.item = object.id and GetCurrencyLink(object.id, object.count)
		
		if GetMouseFocus() == button then
			if not object.isHeader then
				button:OnEnter()
			else
				button:OnLeave()
			end
		end
	end
	scrollFrame.createButton = function(parent)
		local button = CreateFrame("Button", nil, parent)
		Vortex:SetupItemButton(button)
		button:SetPoint("RIGHT", -5, 0)
		button.x = 28
		
		button.label = button:CreateFontString(nil, nil, "GameFontHighlightLeft")
		button:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
		
		button.icon = button:CreateTexture()
		button.icon:SetPoint("RIGHT", -20, 0)
		button.icon:SetSize(15, 15)
		
		button.count = button:CreateFontString(nil, nil, "GameFontHighlightRight")
		button.count:SetPoint("RIGHT", button.icon, "LEFT", -5, 0)
		
		local left = button:CreateTexture(nil, "BORDER")
		left:SetPoint("LEFT")
		left:SetSize(76, 16)
		left:SetTexture([[Interface\Buttons\CollapsibleHeader]])
		left:SetTexCoord(0.17578125, 0.47265625, 0.29687500, 0.54687500)
		
		local right = button:CreateTexture(nil, "BORDER")
		right:SetPoint("RIGHT")
		right:SetSize(76, 16)
		right:SetTexture([[Interface\Buttons\CollapsibleHeader]])
		right:SetTexCoord(0.17578125, 0.47265625, 0.01562500, 0.26562500)
		
		local middle = button:CreateTexture(nil, "BORDER")
		middle:SetPoint("LEFT", left, "RIGHT", -20, 0)
		middle:SetPoint("RIGHT", right, "LEFT", 20, 0)
		middle:SetHeight(16)
		middle:SetTexture([[Interface\Buttons\CollapsibleHeader]])
		middle:SetTexCoord(0.48046875, 0.98046875, 0.01562500, 0.26562500)
		
		local left = button:CreateTexture(nil, "HIGHLIGHT")
		left:SetBlendMode("ADD")
		left:SetPoint("LEFT", -5, 0)
		left:SetSize(26, 18)
		left:SetTexture([[Interface\Buttons\CollapsibleHeader]])
		left:SetTexCoord(18 / 256, 44 / 256, 18 / 64, 36 / 64)
		button.hl = left
		
		local right = button:CreateTexture(nil, "HIGHLIGHT")
		right:SetBlendMode("ADD")
		right:SetPoint("RIGHT", 5, 0)
		right:SetSize(26, 18)
		right:SetTexture([[Interface\Buttons\CollapsibleHeader]])
		right:SetTexCoord(18 / 256, 44 / 256, 0, 18 / 64)
		button.hr = right
		
		local middle = button:CreateTexture(nil, "HIGHLIGHT")
		middle:SetBlendMode("ADD")
		middle:SetPoint("LEFT", left, "RIGHT")
		middle:SetPoint("RIGHT", right, "LEFT")
		middle:SetHeight(18)
		middle:SetTexture([[Interface\Buttons\CollapsibleHeader]])
		middle:SetTexCoord(0, 18 / 256, 0, 18 / 64)
		button.hm = middle
		
		return button
	end
	scrollFrame:CreateButtons()
	
	local scrollBar = scrollFrame.scrollBar
	scrollBar:ClearAllPoints()
	scrollBar:SetPoint("TOPRIGHT", Currencies.ui, 0, -18)
	scrollBar:SetPoint("BOTTOMRIGHT", Currencies.ui, 0, 16)
	scrollBar.doNotHide = true
end