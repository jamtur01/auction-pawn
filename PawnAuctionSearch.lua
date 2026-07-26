local addon = _G.PawnAuctionSearch or {}
_G.PawnAuctionSearch = addon

addon.ADDON_NAME = "PawnAuctionSearch"
addon.TAB_LABEL = "Pawn"
addon.AUCTIONS_PER_PAGE = 50

addon.defaults = {
  scaleName = "",
  canUse = false,
  affordable = false,
  useBuyout = true,
  bestPrice = false,
  unenchanted = false,
  force2h = false,
  armorPreference = "",
  slots = {
    HeadSlot = true,
    NeckSlot = true,
    ShoulderSlot = true,
    BackSlot = true,
    ShirtSlot = true,
    ChestSlot = true,
    WristSlot = true,
    HandsSlot = true,
    WaistSlot = true,
    LegsSlot = true,
    FeetSlot = true,
    TabardSlot = true,
    Finger0Slot = true,
    Finger1Slot = true,
    Trinket0Slot = true,
    Trinket1Slot = true,
    MainHandSlot = true,
    SecondaryHandSlot = true,
    RangedSlot = true,
  },
}

addon.equipLocSlots = {
  INVTYPE_HEAD = { "HeadSlot" },
  INVTYPE_NECK = { "NeckSlot" },
  INVTYPE_SHOULDER = { "ShoulderSlot" },
  INVTYPE_CLOAK = { "BackSlot" },
  INVTYPE_CHEST = { "ChestSlot" },
  INVTYPE_ROBE = { "ChestSlot" },
  INVTYPE_BODY = { "ShirtSlot" },
  INVTYPE_WRIST = { "WristSlot" },
  INVTYPE_HAND = { "HandsSlot" },
  INVTYPE_WAIST = { "WaistSlot" },
  INVTYPE_LEGS = { "LegsSlot" },
  INVTYPE_FEET = { "FeetSlot" },
  INVTYPE_TABARD = { "TabardSlot" },
  INVTYPE_FINGER = { "Finger0Slot", "Finger1Slot" },
  INVTYPE_TRINKET = { "Trinket0Slot", "Trinket1Slot" },
  INVTYPE_WEAPON = { "MainHandSlot", "SecondaryHandSlot" },
  INVTYPE_2HWEAPON = { "MainHandSlot" },
  INVTYPE_WEAPONMAINHAND = { "MainHandSlot" },
  INVTYPE_WEAPONOFFHAND = { "SecondaryHandSlot" },
  INVTYPE_HOLDABLE = { "SecondaryHandSlot" },
  INVTYPE_SHIELD = { "SecondaryHandSlot" },
  INVTYPE_RANGED = { "RangedSlot" },
  INVTYPE_RANGEDRIGHT = { "RangedSlot" },
  INVTYPE_THROWN = { "RangedSlot" },
  INVTYPE_RELIC = { "RangedSlot" },
}

addon.slotOptionAliases = {
  HeadSlot = "head",
  NeckSlot = "neck",
  ShoulderSlot = "shoulder",
  BackSlot = "back",
  ChestSlot = "chest",
  ShirtSlot = "shirt",
  WristSlot = "wrist",
  HandsSlot = "hands",
  WaistSlot = "waist",
  LegsSlot = "legs",
  FeetSlot = "feet",
  TabardSlot = "tabard",
  Finger0Slot = "finger",
  Finger1Slot = "finger",
  Trinket0Slot = "trinket",
  Trinket1Slot = "trinket",
  MainHandSlot = "mainHand",
  SecondaryHandSlot = { "offHand", "offhand" },
  RangedSlot = "ranged",
}

local function pawnIsReady()
  if type(PawnGetAllScalesEx) ~= "function" or type(PawnDoesScaleExist) ~= "function" then
    return false
  end
  if type(PawnIsInitialized) == "function" and not PawnIsInitialized() then
    return false
  end
  return true
end

local function pawnScoringIsReady()
  return pawnIsReady()
    and type(PawnGetItemData) == "function"
    and type(PawnGetItemDataForInventorySlot) == "function"
    and type(PawnGetSingleValueFromItem) == "function"
end

local function scaleIsVisible(scale)
  if not scale then
    return false
  end
  if scale.IsVisible ~= nil then
    return scale.IsVisible
  end
  if scale.Visible ~= nil then
    return scale.Visible
  end
  if scale.PerCharacterOptions and scale.PerCharacterOptions.Visible ~= nil then
    return scale.PerCharacterOptions.Visible
  end
  return true
end

local function normalizeSlotOptions(saved, defaults, aliases, hadSlots)
  if type(saved.slots) ~= "table" then
    saved.slots = {}
  end
  for slotName, enabled in pairs(defaults.slots) do
    local aliasesForSlot = aliases[slotName]
    if not hadSlots and type(aliasesForSlot) == "table" then
      for _, alias in ipairs(aliasesForSlot) do
        if saved[alias] ~= nil then
          saved.slots[slotName] = saved[alias]
          break
        end
      end
    elseif not hadSlots and aliasesForSlot and saved[aliasesForSlot] ~= nil then
      saved.slots[slotName] = saved[aliasesForSlot]
    end
    if saved.slots[slotName] == nil then
      saved.slots[slotName] = enabled
    end
  end
end

local function copyDefaults(defaults, saved)
  for key, value in pairs(defaults) do
    if type(value) == "table" then
      if type(saved[key]) ~= "table" then
        saved[key] = {}
      end
      copyDefaults(value, saved[key])
    elseif saved[key] == nil then
      saved[key] = value
    end
  end
end

addon.CopyDefaults = copyDefaults

function addon:NormalizeOptions(saved, hadSlots)
  normalizeSlotOptions(saved, self.defaults, self.slotOptionAliases, hadSlots)
end

function addon:Print(message)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00" .. self.ADDON_NAME .. ":|r " .. tostring(message))
  end
end

function addon:OnLoad()
  self.eventFrame = self.eventFrame or CreateFrame("Frame")
  self.eventFrame:SetScript("OnEvent", function(_, event, arg1)
    addon:OnEvent(event, arg1)
  end)
  self.eventFrame:RegisterEvent("ADDON_LOADED")
  self.eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
  self.eventFrame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
end

function addon:OnEvent(event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 ~= self.ADDON_NAME then
      return
    end
    PawnAuctionSearchDB = PawnAuctionSearchDB or {}
    local hadSlots = type(PawnAuctionSearchDB.slots) == "table"
    copyDefaults(self.defaults, PawnAuctionSearchDB)
    self:NormalizeOptions(PawnAuctionSearchDB, hadSlots)
    self.db = PawnAuctionSearchDB
    return
  end

  if event == "AUCTION_HOUSE_SHOW" then
    self:InitializeAuctionTab()
  elseif event == "AUCTION_ITEM_LIST_UPDATE" then
    self:OnAuctionItemListUpdate()
  end
end

function addon:InitializeAuctionTab()
  if self.auctionTab and _G.AuctionFrameTab4 then
    return
  end
  if not AuctionFrame or not AuctionFrameTab3 then
    return
  end

  local tab = _G.AuctionFrameTab4
    or CreateFrame("Button", "AuctionFrameTab4", AuctionFrame, "AuctionTabTemplate")
  tab:SetID(4)
  tab:SetText(self.TAB_LABEL)
  tab:SetPoint("LEFT", AuctionFrameTab3, "RIGHT", -8, 0)
  tab:SetScript("OnClick", function(frame)
    addon:SelectAuctionTab(frame:GetID())
  end)
  PanelTemplates_TabResize(tab, 0)
  PanelTemplates_SetNumTabs(AuctionFrame, 4)
  AuctionFrame.numTabs = 4

  self.auctionTab = tab
  self:CreateMainFrame()
end

function addon:GetScales()
  if not pawnIsReady() then
    return {}
  end

  local scales = {}
  for _, scale in pairs(PawnGetAllScalesEx() or {}) do
    if scaleIsVisible(scale) and scale.Name then
      table.insert(scales, {
        name = scale.Name,
        label = scale.LocalizedName or scale.Name,
      })
    end
  end
  return scales
end

function addon:UpdateScaleLabel()
  if not self.scaleLabel then
    return
  end
  local scaleName = self.db and self.db.scaleName or ""
  if scaleName == "" then
    self.scaleLabel:SetText("Scale: none selected")
  else
    self.scaleLabel:SetText("Scale: " .. scaleName)
  end
end

function addon:SetScale(scaleName)
  self.db = self.db or PawnAuctionSearchDB or self.defaults
  self.db.scaleName = scaleName
  if self.scaleDropDown and UIDropDownMenu_SetSelectedValue then
    UIDropDownMenu_SetSelectedValue(self.scaleDropDown, scaleName)
  end
  if self.scaleDropDown and UIDropDownMenu_SetText then
    UIDropDownMenu_SetText(self.scaleDropDown, scaleName)
  end
  self:UpdateScaleLabel()
end

function addon:EnsureScaleSelected()
  self.db = self.db or PawnAuctionSearchDB or self.defaults
  if type(self.db.scaleName) == "string" and self.db.scaleName ~= ""
    and PawnDoesScaleExist(self.db.scaleName) then
    return true
  end
  local scales = self:GetScales()
  if not scales[1] then
    return false
  end
  self:SetScale(scales[1].name)
  return true
end

function addon:CreateScaleSelector(parent)
  local label = parent:CreateFontString("PawnAuctionSearchScaleLabel", "ARTWORK", "GameFontNormal")
  label:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
  self.scaleLabel = label

  local dropdown = CreateFrame(
    "Frame",
    "PawnAuctionSearchScaleDropDown",
    parent,
    "UIDropDownMenuTemplate"
  )
  dropdown:SetPoint("TOPLEFT", label, "BOTTOMLEFT", -16, -4)
  self.scaleDropDown = dropdown
  if UIDropDownMenu_SetWidth then
    UIDropDownMenu_SetWidth(dropdown, 180)
  end
  if UIDropDownMenu_Initialize then
    UIDropDownMenu_Initialize(dropdown, function()
      for _, scale in ipairs(addon:GetScales()) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = scale.label
        info.value = scale.name
        info.func = function()
          addon:SetScale(scale.name)
        end
        UIDropDownMenu_AddButton(info)
      end
    end)
  end
  self:EnsureScaleSelected()
  self:UpdateScaleLabel()
  return dropdown
end

function addon:ValidateScale(scaleName)
  scaleName = scaleName or (self.db and self.db.scaleName)
  if not pawnIsReady() then
    return false, "Pawn is not installed or is not ready yet."
  end
  if type(scaleName) ~= "string" or scaleName == "" then
    return false, "Choose a Pawn scale before searching."
  end
  if not PawnDoesScaleExist(scaleName) then
    return false, "Pawn scale '" .. scaleName .. "' does not exist."
  end
  return true, scaleName
end

function addon:ReadAuctionRow(index)
  local name, texture, count, quality, canUse, level, minBid, minIncrement,
    buyoutPrice, bidAmount, highBidder, owner = GetAuctionItemInfo("list", index)
  local link = GetAuctionItemLink("list", index)
  if not name or not link then
    return nil
  end

  local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType,
    itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice =
    GetItemInfo(link)
  return {
    index = index,
    page = self.scanPage or 0,
    name = itemName or name,
    auctionName = name,
    link = itemLink or link,
    count = count,
    quality = itemRarity or quality,
    canUse = canUse,
    level = itemLevel or level,
    minLevel = itemMinLevel,
    minBid = minBid or 0,
    minIncrement = minIncrement or 0,
    buyoutPrice = buyoutPrice or 0,
    bidAmount = bidAmount or 0,
    highBidder = highBidder,
    owner = owner,
    itemType = itemType,
    itemSubType = itemSubType,
    itemStackCount = itemStackCount,
    equipLoc = itemEquipLoc,
    texture = itemTexture or texture,
    sellPrice = sellPrice,
    timeLeft = GetAuctionItemTimeLeft("list", index),
  }
end

function addon:GetSlotsForEquipLoc(equipLoc)
  local slotNames = self.equipLocSlots[equipLoc]
  if not slotNames then
    return nil
  end

  local slots = {}
  for _, slotName in ipairs(slotNames) do
    local slotId = GetInventorySlotInfo(slotName)
    if slotId and slotId > 0 then
      table.insert(slots, { name = slotName, id = slotId })
    end
  end
  return slots
end

function addon:GetPrice(row)
  if self.db and self.db.useBuyout and row.buyoutPrice and row.buyoutPrice > 0 then
    return row.buyoutPrice
  end
  if row.bidAmount and row.bidAmount > 0 then
    return row.bidAmount + (row.minIncrement or 0)
  end
  return row.minBid or 0
end

function addon:GetPawnValueForLink(link, scaleName)
  if not link or not pawnScoringIsReady() then
    return nil
  end
  local item = PawnGetItemData(link)
  if not item then
    return nil
  end
  return PawnGetSingleValueFromItem(item, scaleName) or 0
end

function addon:GetPawnValueForEquipped(slot, scaleName)
  if not slot or not pawnScoringIsReady() then
    return 0
  end
  local item = PawnGetItemDataForInventorySlot(slot, self.db and self.db.unenchanted, "player")
  if not item then
    return 0
  end
  return PawnGetSingleValueFromItem(item, scaleName) or 0
end

function addon:IsAffordable(row)
  if not row then
    return false
  end
  return self:GetPrice(row) <= GetMoney()
end

function addon:IsSlotEnabled(slotName)
  if self.db and type(self.db.slots) == "table" and self.db.slots[slotName] ~= nil then
    return self.db.slots[slotName]
  end

  local alias = self.slotOptionAliases[slotName]
  if type(alias) == "table" then
    for _, aliasName in ipairs(alias) do
      if self.db and self.db[aliasName] == false then
        return false
      end
    end
    return true
  end
  return not alias or not self.db or self.db[alias] ~= false
end

local function playerKnowsSpell(spellId)
  return type(IsSpellKnown) == "function" and IsSpellKnown(spellId)
end

function addon:CanDualWield()
  local _, classToken = UnitClass("player")
  if classToken == "ROGUE" or classToken == "DEATHKNIGHT" then
    return true
  end
  return playerKnowsSpell(674) or playerKnowsSpell(23588) or playerKnowsSpell(46917)
end

function addon:IsTwoHandEquipped()
  local mainHandId = GetInventorySlotInfo("MainHandSlot")
  if not mainHandId then
    return false
  end
  local link = GetInventoryItemLink("player", mainHandId)
  if not link then
    return false
  end
  local _, _, _, _, _, _, subType, _, equipLoc = GetItemInfo(link)
  if equipLoc == "INVTYPE_2HWEAPON" then
    return true
  end
  return type(subType) == "string" and string.find(subType, "Two%-Hand") ~= nil
end

local function slotByName(slotName)
  local slotId = GetInventorySlotInfo(slotName)
  if not slotId or slotId <= 0 then
    return nil
  end
  return { name = slotName, id = slotId }
end

local function singleSlot(slotName)
  local slot = slotByName(slotName)
  if not slot then
    return nil
  end
  return { slot }
end


function addon:GetComparisonSlots(row)
  local slots = self:GetSlotsForEquipLoc(row.equipLoc)
  if not slots or #slots == 0 then
    return nil
  end

  if row.equipLoc == "INVTYPE_WEAPON" then
    if self:IsTwoHandEquipped() or not self:CanDualWield() then
      return singleSlot("MainHandSlot"), "single"
    end
    return slots, "bestReplacement"
  end

  if row.equipLoc == "INVTYPE_WEAPONOFFHAND"
    or row.equipLoc == "INVTYPE_HOLDABLE"
    or row.equipLoc == "INVTYPE_SHIELD" then
    if self:IsTwoHandEquipped() then
      return singleSlot("MainHandSlot"), "single"
    end
    return slots, "single"
  end

  if row.equipLoc == "INVTYPE_2HWEAPON" then
    local offhand = slotByName("SecondaryHandSlot")
    if offhand then
      table.insert(slots, offhand)
    end
    if playerKnowsSpell(46917) then
      return slots, "bestReplacement"
    end
    return slots, "combined"
  end

  local mode = #slots > 1 and "bestReplacement" or "single"
  return slots, mode
end

function addon:GetEquippedComparisonValue(slots, scaleName, mode)
  local value
  for _, slot in ipairs(slots) do
    if not self:IsSlotEnabled(slot.name) then
      if mode == "combined" then
        return nil
      end
    else
      local equippedValue = self:GetPawnValueForEquipped(slot.id, scaleName)
      if mode == "combined" then
        value = (value or 0) + equippedValue
      elseif not value or equippedValue < value then
        value = equippedValue
      end
    end
  end
  return value
end

function addon:ScoreAuction(row, scaleName)
  if not row or not row.link or not row.equipLoc or row.equipLoc == "" then
    return nil
  end
  if IsEquippableItem and not IsEquippableItem(row.link) then
    return nil
  end
  if self.db and self.db.canUse and not row.canUse then
    return nil
  end
  if self.db and self.db.affordable and not self:IsAffordable(row) then
    return nil
  end

  local slots, mode = self:GetComparisonSlots(row)
  if not slots then
    return nil
  end
  local candidateValue = self:GetPawnValueForLink(row.link, scaleName)
  if not candidateValue then
    return nil
  end

  local equippedValue = self:GetEquippedComparisonValue(slots, scaleName, mode)
  if not equippedValue then
    return nil
  end
  row.value = candidateValue
  row.equippedValue = equippedValue
  row.delta = row.value - row.equippedValue
  if row.delta <= 0 then
    return nil
  end

  if self.db and self.db.bestPrice then
    local price = self:GetPrice(row)
    if price <= 0 then
      return nil
    end
    row.score = (10000 * row.delta) / price
  else
    row.score = row.delta
  end
  return row
end

local function formatCopper(copper)
  copper = copper or 0
  local gold = math.floor(copper / 10000)
  local silver = math.floor((copper % 10000) / 100)
  local copperOnly = copper % 100
  if gold > 0 then
    return gold .. "g " .. silver .. "s " .. copperOnly .. "c"
  end
  if silver > 0 then
    return silver .. "s " .. copperOnly .. "c"
  end
  return copperOnly .. "c"
end

local function sortByScore(left, right)
  return (left.score or 0) > (right.score or 0)
end

function addon:SelectAuctionTab(index)
  if index ~= 4 then
    if AuctionFrameTab_OnClick then
      AuctionFrameTab_OnClick(_G["AuctionFrameTab" .. tostring(index)])
    end
    return
  end
  PanelTemplates_SetTab(AuctionFrame, 4)
  if AuctionFrameBrowse then
    AuctionFrameBrowse:Hide()
  end
  if AuctionFrameBid then
    AuctionFrameBid:Hide()
  end
  if AuctionFrameAuctions then
    AuctionFrameAuctions:Hide()
  end
  self:CreateMainFrame()
  self.mainFrame:Show()
  AuctionFrame.type = "list"
end

function addon:CreateMainFrame()
  if self.mainFrame then
    return self.mainFrame
  end
  local frame = CreateFrame("Frame", "PawnAuctionSearchFrame", AuctionFrame)
  frame:SetPoint("TOPLEFT", AuctionFrame, "TOPLEFT", 20, -72)
  frame:SetPoint("BOTTOMRIGHT", AuctionFrame, "BOTTOMRIGHT", -20, 40)
  frame:Hide()

  self:CreateScaleSelector(frame)

  local status = frame:CreateFontString("PawnAuctionSearchStatusText", "ARTWORK", "GameFontNormal")
  status:SetPoint("TOPLEFT", self.scaleDropDown or frame, "BOTTOMLEFT", 16, -8)
  status:SetText("Choose a Pawn scale, then search.")
  frame.statusText = status
  self.statusText = status

  local button = CreateFrame("Button", "PawnAuctionSearchButton", frame, "UIPanelButtonTemplate")
  button:SetSize(96, 22)
  button:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -10)
  button:SetText("Search")
  button:SetScript("OnClick", function()
    addon:StartScan()
  end)
  frame.searchButton = button

  self.resultRows = self:CreateResults(frame)
  self.mainFrame = frame
  return frame
end

function addon:CreateResults(parent)
  if self.resultRows then
    return self.resultRows
  end
  local rows = {}
  local previous
  for index = 1, 10 do
    local row = CreateFrame("Button", "PawnAuctionSearchResult" .. index, parent)
    row:SetSize(560, 20)
    if previous then
      row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -2)
    else
      row:SetPoint("TOPLEFT", parent.searchButton, "BOTTOMLEFT", 0, -14)
    end
    row:RegisterForClicks("LeftButtonUp")
    row:SetScript("OnClick", function()
      addon:SelectResult(index)
    end)
    row.nameText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.nameText:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.deltaText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.deltaText:SetPoint("LEFT", row, "LEFT", 260, 0)
    row.priceText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.priceText:SetPoint("LEFT", row, "LEFT", 360, 0)
    row:Hide()
    rows[index] = row
    previous = row
  end
  return rows
end

function addon:SetStatus(message)
  self:CreateMainFrame()
  if self.statusText then
    self.statusText:SetText(message)
  end
end

function addon:QueryScanPage()
  if not self.scanActive then
    return false
  end
  if not CanSendAuctionQuery("list") then
    self:SetStatus("Auction query is throttled. Try again shortly.")
    return false
  end
  QueryAuctionItems("", "", "", nil, nil, nil, self.scanPage, false, -1)
  self:SetStatus("Scanning auction house page " .. tostring(self.scanPage + 1) .. "...")
  return true
end

function addon:StartScan()
  self.db = self.db or PawnAuctionSearchDB or self.defaults
  self:EnsureScaleSelected()
  local valid, scaleOrMessage = self:ValidateScale(self.db and self.db.scaleName)
  if not valid then
    self.scanActive = false
    self:SetStatus(scaleOrMessage)
    return
  end
  self.results = {}
  self.scanActive = true
  self.scanPage = 0
  self.scanScaleName = scaleOrMessage
  self:UpdateResults()

  if not self:QueryScanPage() then
    self.scanActive = false
  end
end

function addon:OnAuctionItemListUpdate()
  if not self.scanActive then
    return
  end
  local count, total = GetNumAuctionItems("list")
  count = count or 0
  total = total or count
  self.results = self.results or {}
  self.currentAuctionPage = self.scanPage
  for index = 1, count do
    local row = self:ReadAuctionRow(index)
    local result = self:ScoreAuction(row, self.scanScaleName)
    if result then
      table.insert(self.results, result)
    end
  end

  local scanned = (self.scanPage + 1) * self.AUCTIONS_PER_PAGE
  if scanned < total then
    self.scanPage = self.scanPage + 1
    if self:QueryScanPage() then
      return
    end
  end

  table.sort(self.results, sortByScore)
  self.scanActive = false
  self:SetStatus("Found " .. tostring(#self.results) .. " upgrade auctions.")
  self:UpdateResults()
end

function addon:UpdateResults()
  self:CreateMainFrame()
  local results = self.results or {}
  for index = 1, 10 do
    local row = self.resultRows[index]
    local result = results[index]
    if result then
      row.resultIndex = index
      row.nameText:SetText(result.link or result.name or "")
      row.deltaText:SetText(tostring(result.delta or 0))
      local bid = result.bidAmount and result.bidAmount > 0 and result.bidAmount or result.minBid
      row.priceText:SetText("Buyout " .. formatCopper(result.buyoutPrice)
        .. " / Bid " .. formatCopper(bid))
      row:Show()
    else
      row.resultIndex = nil
      row.nameText:SetText("")
      row.deltaText:SetText("")
      row.priceText:SetText("")
      row:Hide()
    end
  end
end

function addon:SelectResult(resultIndex)
  local result = self.results and self.results[resultIndex]
  if not result then
    return
  end
  if result.page ~= self.currentAuctionPage then
    self:SetStatus("Result is from another auction page. Search again before selecting it.")
    return
  end
  SetSelectedAuctionItem("list", result.index)
end

addon:OnLoad()
