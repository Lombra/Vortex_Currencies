local _, addon = ...

local Currencies = Vortex:NewModule("Currencies", {
	noSearch = true,
	noSort = true,
	altUI = true,
})

function Currencies:BuildList(character)
	local list = {}
	for i = 1, addon:GetNumCurrencies(character) do
		-- local isHeader, name, count, icon = DataStore:GetCurrencyInfo(character, i)
		local currency = addon.Characters[character][i]
		if not isHeader then
			tinsert(list, {
				name = currency.name,
				id = currency.id,
				count = currency.count,
				isHeader = currency.isHeader,
			})
		end
	end
	return list
end

function Currencies:UpdateButton(button, object)
	local name, amount, texturePath, earnedThisWeek, weeklyMax, totalMax, isDiscovered = GetCurrencyInfo(object.id)
	local color = object.count > 0 and HIGHLIGHT_FONT_COLOR or GRAY_FONT_COLOR
	button.label:SetFormattedText("%s (%d)", object.name, object.count)
	button.label:SetTextColor(color.r, color.g, color.b)
	button.icon:SetTexture(texturePath)
	button.item = GetCurrencyLink(object.id)
end

local function addTooltipInfo(self, id)
	local numChars = 0
	local total = 0
	for i, character in ipairs(Vortex:GetCharacters()) do
		local accountKey, realmKey, charKey = strsplit(".", character)
		local isHeader, count = DataStore:GetCurrencyInfoByName(character, id)
		if count and count > 0 then
			self:AddLine(count.." "..charKey)
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
	addTooltipInfo(self, GetCurrencyInfo(id))
end)

hooksecurefunc(GameTooltip, "SetCurrencyToken", function(self, index)
	addTooltipInfo(self, GetCurrencyListInfo(index))
end)

hooksecurefunc(GameTooltip, "SetBackpackToken", function(self, index)
	local name, count, icon, currencyID = GetBackpackCurrencyInfo(index)
	addTooltipInfo(self, GetBackpackCurrencyInfo(index))
end)

hooksecurefunc(GameTooltip, "SetHyperlink", function(self, link)
	local id = link:match("currency:(%d+)")
	addTooltipInfo(self, id and GetCurrencyInfo(tonumber(id)))
end)

hooksecurefunc(GameTooltip, "SetMerchantCostItem", function(self, index, itemIndex)
	addTooltipInfo(self, select(4, GetMerchantItemCostItem(index, itemIndex)))
end)

local scrollFrame

function Currencies:UpdateUI()
	scrollFrame:update()
end

do
	local BUTTON_HEIGHT = 16
	local BUTTON_OFFSET = 4
	
	local function createButton(frame)
		local button = CreateFrame("Button", nil, frame)
		Vortex:SetupItemButton(button)
		button.x = 28
		button:SetHeight(BUTTON_HEIGHT)
		button:SetPoint("RIGHT", -5, 0)
		
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
		
		-- local left = button:CreateTexture(nil, "HIGHLIGHT")
		-- left:SetBlendMode("ADD")
		-- left:SetPoint("LEFT", -5, 0)
		-- left:SetSize(26, 18)
		-- left:SetTexture([[Interface\Buttons\CollapsibleHeader]])
		-- left:SetTexCoord(18 / 256, 44 / 256, 18 / 64, 36 / 64)
		
		-- local right = button:CreateTexture(nil, "HIGHLIGHT")
		-- right:SetBlendMode("ADD")
		-- right:SetPoint("RIGHT", 5, 0)
		-- right:SetSize(26, 18)
		-- right:SetTexture([[Interface\Buttons\CollapsibleHeader]])
		-- right:SetTexCoord(18 / 256, 44 / 256, 0, 18 / 64)
		
		-- local middle = button:CreateTexture(nil, "HIGHLIGHT")
		-- middle:SetBlendMode("ADD")
		-- middle:SetPoint("LEFT", left, "RIGHT")
		-- middle:SetPoint("RIGHT", right, "LEFT")
		-- middle:SetHeight(18)
		-- middle:SetTexture([[Interface\Buttons\CollapsibleHeader]])
		-- middle:SetTexCoord(0, 18 / 256, 0, 18 / 64)
		
		-- local highlight = button:CreateTexture()
		-- highlight:SetPoint("TOPLEFT", 3, -2)
		-- highlight:SetPoint("BOTTOMRIGHT", -3, 2)
		-- highlight:SetTexture([[Interface\TokenFrame\UI-TokenFrame-CategoryButton]])
		-- highlight:SetTexCoord(0, 1, 0.609375, 0.796875)
		-- button:SetHighlightTexture(highlight)
		
		return button
	end
	
	local function updateButton(button, object)
		if object.isHeader then
			button.label:SetText(object.name)
			button.label:SetFontObject("GameFontNormal")
			button.label:SetPoint("LEFT", 22, 0)
			button.count:SetText(nil)
			button.icon:SetTexture(nil)
			button:EnableDrawLayer("BORDER")
		else
			local name, _, texturePath = GetCurrencyInfo(object.id)
			button.label:SetText(object.name)
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
		button.item = object.id and GetCurrencyLink(object.id)
		
		if button.showingTooltip then
			if not isHeader then
				button:OnEnter()
			else
				GameTooltip:Hide()
			end
		end
	end
	
	local function update(self)
		local list = addon.Characters[Vortex:GetSelectedCharacter()]
		local offset = HybridScrollFrame_GetOffset(self)
		local buttons = self.buttons
		local numButtons = #buttons
		for i = 1, numButtons do
			local index = offset + i
			local object = list[index]
			local button = buttons[i]
			if object then
				updateButton(button, object)
			end
			button:SetShown(object ~= nil)
		end
		
		HybridScrollFrame_Update(self, #list * self.buttonHeight, numButtons * self.buttonHeight)
	end
	
	local name = "lool"
	scrollFrame = CreateFrame("ScrollFrame", name, Currencies.ui, "HybridScrollFrameTemplate")
	scrollFrame:SetPoint("TOP", 0, -4)
	scrollFrame:SetPoint("LEFT", 4, 0)
	scrollFrame:SetPoint("BOTTOMRIGHT", -23, 4)
	scrollFrame.update = function()
		update(scrollFrame)
	end
	-- _G[name] = nil
	
	local scrollBar = CreateFrame("Slider", nil, scrollFrame, "HybridScrollBarTemplate")
	scrollBar:ClearAllPoints()
	scrollBar:SetPoint("TOP", 0, -12)
	scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 0, 11)
	scrollBar.doNotHide = true
	scrollBar:HookScript("OnValueChanged", function(self, value, isUserInput)
		-- if isUserInput then
			-- self:SetValue(floor(value))
		-- end
	end)
	
	local buttons = {}
	scrollFrame.buttons = buttons
	
	for i = 1, (ceil(scrollFrame:GetHeight() / BUTTON_HEIGHT) + 1) do
		local button = createButton(scrollFrame.scrollChild)
		if i == 1 then
			button:SetPoint("TOPLEFT", 1, -2)
		else
			button:SetPoint("TOPLEFT", buttons[i - 1], "BOTTOMLEFT", 0, -BUTTON_OFFSET)
		end
		buttons[i] = button
	end
	
	HybridScrollFrame_CreateButtons(scrollFrame, nil, nil, nil, nil, nil, nil, -BUTTON_OFFSET)
end