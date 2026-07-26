local addon = _G.PawnAuctionSearch or {}
_G.PawnAuctionSearch = addon

addon.ADDON_NAME = "PawnAuctionSearch"
addon.TAB_LABEL = "Pawn"
addon.AUCTIONS_PER_PAGE = 50
addon.SCALE_DROPDOWN_WIDTH = 130
addon.SCALE_DROPDOWN_PAGE_SIZE = 7
addon.AUTO_GEAR_SCALE_NAME = "__AUTOGEAR__"
addon.MIN_DISPLAY_DELTA = 0.005
addon.ARMOR_DROPDOWN_WIDTH = 130
addon.LEFT_CONTROLS_TOP_OFFSET = -32
addon.LEFT_CONTROLS_LEFT_OFFSET = 1
addon.SLOT_FILTER_COLUMN_WIDTH = 150
addon.RESULTS_LEFT_OFFSET = 260
addon.RESULTS_STATUS_OFFSET = -200
addon.RESULTS_TOP_OFFSET = -220
addon.RESULT_SCROLL_WIDTH = 465
addon.RESULT_ROW_WIDTH = 434
addon.RESULT_NAME_WIDTH = 170
addon.RESULT_DELTA_OFFSET = 180
addon.RESULT_BID_PRICE_OFFSET = 250
addon.RESULT_BUYOUT_PRICE_OFFSET = 340
addon.ACTION_BUTTON_WIDTH = 80
addon.ACTION_BUTTON_HEIGHT = 22
addon.RESULTS_VISIBLE_ROWS = 4
addon.RESULT_ROW_HEIGHT = 21
addon.OPTION_FILTER_ROWS = 6
addon.SLOT_FILTERS_TOP_OFFSET = -32
addon.OPTION_FILTER_COLUMN_WIDTH = 165
addon.SLOT_FILTER_ROWS = 6
addon.SLOT_FILTERS_LEFT_OFFSET = 280
addon.CHECK_BUTTON_SIZE = 24
addon.CHECK_BUTTON_ROW_HEIGHT = 24
addon.TAB_GLOBAL_NAME = "AuctionFrameTabPawnAuctionSearch"
addon.FAST_SCAN_ROWS_PER_TICK = 250
addon.FAST_SCAN_STATUS_INTERVAL = 1000

addon.slotFilters = {
  { label = "Head", slots = { "HeadSlot" } },
  { label = "Neck", slots = { "NeckSlot" } },
  { label = "Shoulder", slots = { "ShoulderSlot" } },
  { label = "Back", slots = { "BackSlot" } },
  { label = "Chest", slots = { "ChestSlot" } },
  { label = "Wrist", slots = { "WristSlot" } },
  { label = "Hands", slots = { "HandsSlot" } },
  { label = "Waist", slots = { "WaistSlot" } },
  { label = "Legs", slots = { "LegsSlot" } },
  { label = "Feet", slots = { "FeetSlot" } },
  { label = "Finger", slots = { "Finger0Slot", "Finger1Slot" } },
  { label = "Trinket", slots = { "Trinket0Slot", "Trinket1Slot" } },
  { label = "Main Hand", slots = { "MainHandSlot" } },
  { label = "Off-hand", slots = { "SecondaryHandSlot" } },
  { label = "Ranged", slots = { "RangedSlot" } },
}

addon.defaults = {
  scaleName = "",
  canUse = false,
  affordable = false,
  useBuyout = false,
  bestPrice = false,
  unenchanted = false,
  force2h = false,
  armorPreference = "",
  slots = {
    HeadSlot = true,
    NeckSlot = true,
    ShoulderSlot = true,
    BackSlot = true,
    ChestSlot = true,
    WristSlot = true,
    HandsSlot = true,
    WaistSlot = true,
    LegsSlot = true,
    FeetSlot = true,
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
  INVTYPE_WRIST = { "WristSlot" },
  INVTYPE_HAND = { "HandsSlot" },
  INVTYPE_WAIST = { "WaistSlot" },
  INVTYPE_LEGS = { "LegsSlot" },
  INVTYPE_FEET = { "FeetSlot" },
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
  WristSlot = "wrist",
  HandsSlot = "hands",
  WaistSlot = "waist",
  LegsSlot = "legs",
  FeetSlot = "feet",
  Finger0Slot = "finger",
  Finger1Slot = "finger",
  Trinket0Slot = "trinket",
  Trinket1Slot = "trinket",
  MainHandSlot = "mainHand",
  SecondaryHandSlot = { "offHand", "offhand" },
  RangedSlot = "ranged",
}

local function localizedGlobal(fallback, ...)
  for index = 1, select("#", ...) do
    local value = _G[select(index, ...)]
    if type(value) == "string" and value ~= "" then
      return value
    end
  end
  return fallback
end

addon.armorPreferenceOptions = {
  { key = "", label = "No Preference", names = {} },
  {
    key = "cloth",
    label = localizedGlobal("Cloth", "ITEM_SUB_CLASS_4_1", "ARMOR_SUBCLASS_CLOTH"),
    names = { "Cloth", localizedGlobal("Cloth", "ITEM_SUB_CLASS_4_1", "ARMOR_SUBCLASS_CLOTH") },
  },
  {
    key = "leather",
    label = localizedGlobal("Leather", "ITEM_SUB_CLASS_4_2", "ARMOR_SUBCLASS_LEATHER"),
    names = {
      "Leather",
      localizedGlobal("Leather", "ITEM_SUB_CLASS_4_2", "ARMOR_SUBCLASS_LEATHER"),
    },
  },
  {
    key = "mail",
    label = localizedGlobal("Mail", "ITEM_SUB_CLASS_4_3", "ARMOR_SUBCLASS_MAIL"),
    names = { "Mail", localizedGlobal("Mail", "ITEM_SUB_CLASS_4_3", "ARMOR_SUBCLASS_MAIL") },
  },
  {
    key = "plate",
    label = localizedGlobal("Plate", "ITEM_SUB_CLASS_4_4", "ARMOR_SUBCLASS_PLATE"),
    names = { "Plate", localizedGlobal("Plate", "ITEM_SUB_CLASS_4_4", "ARMOR_SUBCLASS_PLATE") },
  },
}

addon.armorPreferenceEquipLocs = {
  INVTYPE_HEAD = true,
  INVTYPE_SHOULDER = true,
  INVTYPE_CHEST = true,
  INVTYPE_ROBE = true,
  INVTYPE_WRIST = true,
  INVTYPE_HAND = true,
  INVTYPE_WAIST = true,
  INVTYPE_LEGS = true,
  INVTYPE_FEET = true,
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

function addon:EnsureDatabase()
  PawnAuctionSearchDB = PawnAuctionSearchDB or {}
  local hadSlots = type(PawnAuctionSearchDB.slots) == "table"
  copyDefaults(self.defaults, PawnAuctionSearchDB)
  self:NormalizeOptions(PawnAuctionSearchDB, hadSlots)
  self.db = PawnAuctionSearchDB
  return self.db
end


addon.CopyDefaults = copyDefaults

function addon:NormalizeOptions(saved, hadSlots)
  normalizeSlotOptions(saved, self.defaults, self.slotOptionAliases, hadSlots)
  if saved.armorPreference == "No Preference" then
    saved.armorPreference = ""
  elseif type(saved.armorPreference) == "string" then
    local lower = string.lower(saved.armorPreference)
    for _, option in ipairs(self.armorPreferenceOptions) do
      if lower == string.lower(option.label) or lower == option.key then
        saved.armorPreference = option.key
        return
      end
    end
    saved.armorPreference = ""
  end
end

function addon:Print(message)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00" .. self.ADDON_NAME .. ":|r " .. tostring(message))
  end
end

local function getCheckButtonText(check)
  local name = check.GetName and check:GetName()
  return name and _G[name .. "Text"] or nil
end

function addon:ShowHelpTooltip(owner, title, text)
  if not GameTooltip then
    return
  end
  GameTooltip:SetOwner(owner or UIParent, "ANCHOR_RIGHT")
  GameTooltip:ClearLines()
  if GameTooltip.AddLine then
    GameTooltip:AddLine(title)
    GameTooltip:AddLine(text)
  else
    GameTooltip:SetHyperlink(title .. ": " .. text)
  end
  GameTooltip:Show()
end

function addon:AttachHelpTooltip(frame, title, text)
  if not frame or not frame.SetScript then
    return
  end
  frame.tooltipTitle = title
  frame.tooltipText = text
  frame:SetScript("OnEnter", function(owner)
    addon:ShowHelpTooltip(owner, title, text)
  end)
  frame:SetScript("OnLeave", function()
    if GameTooltip then
      GameTooltip:Hide()
    end
  end)
end

function addon:AttachDropdownHelpTooltip(dropdown, title, text)
  self:AttachHelpTooltip(dropdown, title, text)
  if not dropdown or not dropdown.GetName then
    return
  end
  local name = dropdown:GetName()
  local button = name and _G[name .. "Button"]
  self:AttachHelpTooltip(button, title, text)
end

function addon:RestoreAuctionFrameChrome()
  if AuctionFrameMoneyFrame then
    AuctionFrameMoneyFrame:Show()
  end
end

function addon:PrepareAuctionFrameChrome()
  if AuctionFrameMoneyFrame then
    AuctionFrameMoneyFrame:Show()
  end
  if SetAuctionsTabShowing then
    SetAuctionsTabShowing(false)
  end
end

function addon:IsScanning()
  return self.scanActive or self.fastScanActive or self.fastScanProcessing
    or self.auctioneerScanProcessing or self.waitingForQuery or self.pendingSelection
end

function addon:UpdateSearchButton()
  if not self.searchButton then
    return
  end
  if self:IsScanning() then
    self.searchButton:SetText("Cancel")
    self.searchButton:Enable()
    return
  end
  self.searchButton:SetText("Search")
  local canQuery = true
  if CanSendAuctionQuery then
    canQuery = CanSendAuctionQuery("list") and true or false
  end
  if canQuery then
    self.searchButton:Enable()
  else
    self.searchButton:Disable()
  end
end

function addon:HideMainFrame()
  if self.mainFrame then
    self.mainFrame:Hide()
  end
  self:RestoreAuctionFrameChrome()
end

function addon:HookBlizzardTabs()
  if self.tabHooked or type(hooksecurefunc) ~= "function" then
    return
  end
  if type(AuctionFrameTab_OnClick) == "function" then
    hooksecurefunc("AuctionFrameTab_OnClick", function(tab)
      if tab ~= addon.auctionTab then
        addon:HideMainFrame()
      end
    end)
    self.tabHooked = true
  end
end


function addon:CancelActiveScan(message)
  local wasScanning = self.scanActive or self.fastScanActive or self.fastScanProcessing
    or self.auctioneerScanProcessing
  if not wasScanning and not self.waitingForQuery and not self.pendingSelection then
    return
  end
  self.scanActive = false
  self.fastScanActive = false
  self.fastScanProcessing = false
  self.fastScanProcessIndex = nil
  self.fastScanProcessTotal = nil
  self.fastScanNextStatus = nil
  self.fastScanWaitElapsed = nil
  self.fastScanLastStatusSecond = nil
  self.auctioneerScanProcessing = false
  self.auctioneerScanImage = nil
  self.auctioneerScanConst = nil
  self.auctioneerScanIndex = nil
  self.auctioneerScanTotal = nil
  self.auctioneerScanNextStatus = nil
  self.auctioneerScanApi = nil
  self.waitingForQuery = false
  self.waitingPage = nil
  self.pendingSelection = nil
  if wasScanning then
    self.auctionCacheRows = nil
    self.auctionCacheComplete = false
    if message then
      self:SetStatus(message)
    end
  end
end


function addon:OnLoad()
  self.eventFrame = self.eventFrame or CreateFrame("Frame")
  self.eventFrame:SetScript("OnEvent", function(_, event, arg1)
    addon:OnEvent(event, arg1)
  end)
  self.eventFrame:SetScript("OnUpdate", function(_, elapsed)
    addon:OnUpdate(elapsed)
  end)
  self.eventFrame:RegisterEvent("ADDON_LOADED")
  self.eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
  self.eventFrame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
  self.eventFrame:RegisterEvent("AUCTION_HOUSE_CLOSED")
end

function addon:OnEvent(event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 ~= self.ADDON_NAME then
      return
    end
    self:EnsureDatabase()
    return
  end

  if event == "AUCTION_HOUSE_SHOW" then
    self:InitializeAuctionTab()
  elseif event == "AUCTION_HOUSE_CLOSED" then
    self:CancelActiveScan("Auction House closed; scan canceled.")
  elseif event == "AUCTION_ITEM_LIST_UPDATE" then
    self:OnAuctionItemListUpdate()
  end
end

function addon:InitializeAuctionTab()
  if self.auctionTab then
    return
  end
  if not AuctionFrame or not AuctionFrameTab3 then
    return
  end

  local tab = _G[self.TAB_GLOBAL_NAME]
    or CreateFrame("Button", self.TAB_GLOBAL_NAME, AuctionFrame, "AuctionTabTemplate")
  local tabID = (AuctionFrame.numTabs or 3) + 1
  tab:SetID(tabID)
  tab:SetText(self.TAB_LABEL)
  _G["AuctionFrameTab" .. tostring(tabID)] = tab
  local previousTab = _G["AuctionFrameTab" .. tostring(tabID - 1)] or AuctionFrameTab3
  tab:SetPoint("LEFT", previousTab, "RIGHT", -8, 0)
  tab:SetScript("OnClick", function(frame)
    addon:SelectAuctionTab(frame:GetID())
  end)
  PanelTemplates_TabResize(tab, 0)
  PanelTemplates_SetNumTabs(AuctionFrame, tabID)
  AuctionFrame.numTabs = tabID

  self.auctionTab = tab
  self:HookBlizzardTabs()
  self:CreateMainFrame()
end

function addon:IsAutoGearReady()
  return type(AutoGearReadItemInfo) == "function"
    and type(AutoGearDetermineItemScore) == "function"
    and type(AutoGearGetBestSetItems) == "function"
    and type(AutoGearGetTooltipScoreComparisonInfo) == "function"
    and type(AutoGearUpdateEquippedItems) == "function"
end

function addon:IsAutoGearScale(scaleName)
  return scaleName == self.AUTO_GEAR_SCALE_NAME
end

function addon:GetScales()
  local scales = {}
  if pawnIsReady() then
    for _, scale in pairs(PawnGetAllScalesEx() or {}) do
      if scaleIsVisible(scale) and scale.Name then
        table.insert(scales, {
          name = scale.Name,
          label = scale.LocalizedName or scale.Name,
        })
      end
    end
  end
  if self:IsAutoGearReady() then
    table.insert(scales, {
      name = self.AUTO_GEAR_SCALE_NAME,
      label = "AutoGear",
    })
  end
  return scales
end
function addon:GetScaleLabel(scaleName)
  for _, scale in ipairs(self:GetScales()) do
    if scale.name == scaleName then
      return scale.label
    end
  end
  return scaleName or ""
end


local function utf8Length(text)
  if strlenutf8 then
    return strlenutf8(text)
  end
  local count = 0
  for index = 1, string.len(text) do
    local byte = string.byte(text, index)
    if byte < 128 or byte >= 192 then
      count = count + 1
    end
  end
  return count
end

local function utf8Prefix(text, maxLength)
  local count = 0
  local lastByte = 0
  for index = 1, string.len(text) do
    local byte = string.byte(text, index)
    if byte < 128 or byte >= 192 then
      count = count + 1
      if count > maxLength then
        break
      end
    end
    lastByte = index
  end
  return string.sub(text, 1, lastByte)
end

function addon:GetDisplayScaleLabel(label)
  label = label or ""
  local maxLength = 14
  if utf8Length(label) <= maxLength then
    return label
  end
  local separatorStart, separatorEnd = string.find(label, ": ", 1, true)
  if separatorEnd then
    local prefix = string.sub(label, 1, separatorStart - 1)
    if utf8Length(prefix) > 6 then
      prefix = utf8Prefix(prefix, 5) .. "."
    end
    local suffixLength = maxLength - utf8Length(prefix) - 3
    if suffixLength > 0 then
      local suffix = string.sub(label, separatorEnd + 1)
      return prefix .. ": " .. utf8Prefix(suffix, suffixLength) .. "."
    end
  end
  return utf8Prefix(label, maxLength - 3) .. "..."
end


function addon:UpdateScaleLabel()
  if not self.scaleLabel then
    return
  end
  local scaleName = self.db and self.db.scaleName or ""
  if scaleName == "" then
    self.scaleLabel:SetText("Scale: none selected")
  else
    self.scaleLabel:SetText("Scale: " .. self:GetDisplayScaleLabel(self:GetScaleLabel(scaleName)))
  end
end

function addon:SetScale(scaleName)
  self.db = self:EnsureDatabase()
  self.db.scaleName = scaleName
  local label = self:GetScaleLabel(scaleName)
  if self.scaleDropDown and UIDropDownMenu_SetSelectedValue then
    UIDropDownMenu_SetSelectedValue(self.scaleDropDown, scaleName)
  end
  if self.scaleDropDown and UIDropDownMenu_SetText then
    UIDropDownMenu_SetText(self.scaleDropDown, self:GetDisplayScaleLabel(label))
  end
  self:UpdateScaleLabel()
end

function addon:EnsureScaleSelected()
  self.db = self:EnsureDatabase()
  if type(self.db.scaleName) == "string" and self.db.scaleName ~= "" then
    local valid = self:ValidateScale(self.db.scaleName)
    if valid then
      self:SetScale(self.db.scaleName)
      return true
    end
  end
  local scales = self:GetScales()
  if not scales[1] then
    return false
  end
  self:SetScale(scales[1].name)
  return true
end
function addon:AddScaleDropdownButton(scale)
  local info = UIDropDownMenu_CreateInfo()
  info.text = scale.label
  info.value = scale.name
  info.func = function(button)
    addon:SetScale(button.value)
  end
  UIDropDownMenu_AddButton(info)
end

function addon:AddScalePageButton(text, offset)
  local info = UIDropDownMenu_CreateInfo()
  info.text = text
  info.keepShownOnClick = 1
  info.func = function()
    addon.scaleMenuOffset = offset
    if DropDownList1 and DropDownList1.Hide then
      DropDownList1:Hide()
    end
    if ToggleDropDownMenu then
      ToggleDropDownMenu(1, nil, addon.scaleDropDown)
    end
  end
  UIDropDownMenu_AddButton(info)
end

function addon:InitializeScaleDropdown()
  local scales = self:GetScales()
  local offset = self.scaleMenuOffset or 1
  if offset < 1 or not scales[offset] then
    offset = 1
    self.scaleMenuOffset = offset
  end
  local maxScaleButtons = self.SCALE_DROPDOWN_PAGE_SIZE
  if offset > 1 then
    maxScaleButtons = maxScaleButtons - 1
    local previousOffset = 1
    if offset > self.SCALE_DROPDOWN_PAGE_SIZE then
      previousOffset = offset - (self.SCALE_DROPDOWN_PAGE_SIZE - 2)
    end
    self:AddScalePageButton("Previous scales...", previousOffset)
  end
  local hasNext = offset + maxScaleButtons <= #scales
  if hasNext then
    maxScaleButtons = maxScaleButtons - 1
  end
  for index = offset, math.min(#scales, offset + maxScaleButtons - 1) do
    self:AddScaleDropdownButton(scales[index])
  end
  if hasNext then
    self:AddScalePageButton("More scales...", offset + maxScaleButtons)
  end
end

function addon:CreateScaleSelector(parent)
  local label = parent:CreateFontString("PawnAuctionSearchScaleLabel", "ARTWORK", "GameFontNormal")
  label:SetPoint(
    "TOPLEFT",
    parent,
    "TOPLEFT",
    self.LEFT_CONTROLS_LEFT_OFFSET,
    self.LEFT_CONTROLS_TOP_OFFSET
  )
  self.scaleLabel = label
  self:AttachHelpTooltip(
    label,
    "Pawn scale",
    "The Pawn scale that will be used to determine the item value"
  )

  local dropdown = CreateFrame(
    "Frame",
    "PawnAuctionSearchScaleDropDown",
    parent,
    "UIDropDownMenuTemplate"
  )
  dropdown:SetPoint("TOPLEFT", label, "BOTTOMLEFT", -16, -4)
  self.scaleDropDown = dropdown
  if UIDropDownMenu_SetWidth then
    UIDropDownMenu_SetWidth(dropdown, self.SCALE_DROPDOWN_WIDTH)
  end
  if UIDropDownMenu_Initialize then
    UIDropDownMenu_Initialize(dropdown, function()
      addon:InitializeScaleDropdown()
    end)
  end
  self:AttachDropdownHelpTooltip(
    dropdown,
    "Pawn scale",
    "The Pawn scale that will be used to determine the item value"
  )
  self:EnsureScaleSelected()
  self:UpdateScaleLabel()
  return dropdown
end

function addon:ValidateScale(scaleName)
  scaleName = scaleName or (self.db and self.db.scaleName)
  if type(scaleName) ~= "string" or scaleName == "" then
    return false, "Choose a Pawn scale or AutoGear before searching."
  end
  if self:IsAutoGearScale(scaleName) then
    if self:IsAutoGearReady() then
      return true, scaleName
    end
    return false, "AutoGear is not installed or is not ready yet."
  end
  if not pawnIsReady() then
    return false, "Pawn is not installed or is not ready yet."
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
  local page = self.scanPage or 0
  local pageIndex = index
  if self.fastScanActive then
    page = math.floor((index - 1) / self.AUCTIONS_PER_PAGE)
    pageIndex = ((index - 1) % self.AUCTIONS_PER_PAGE) + 1
  end


  local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType,
    itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice =
    GetItemInfo(link)
  return {
    index = pageIndex,
    page = page,
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

function addon:GetAuctioneerScanApi()
  local auc = _G.AucAdvanced
  if not auc or not auc.API or not auc.Const then
    return nil
  end
  if type(auc.API.QueryImage) ~= "function" then
    return nil
  end
  return auc.API, auc.Const
end

function addon:GetAuctioneerEquipLoc(equipCode)
  local auc = _G.AucAdvanced
  local encode = auc and auc.Const and auc.Const.EquipEncode
  if not encode then
    return nil
  end
  for equipLoc, code in pairs(encode) do
    if code == equipCode then
      return equipLoc
    end
  end
  return nil
end

function addon:ReadAuctioneerRow(item, index, const, api)
  local unpacked
  if api and type(api.UnpackImageItem) == "function" then
    unpacked = api.UnpackImageItem(item, {})
  end
  local dataFlag = unpacked and unpacked.dataFlag or item[const.FLAG]
  local hiddenFlags = (const.FLAG_UNSEEN or 0) + (const.FLAG_FILTER or 0)
  local band = bit and bit.band or bitand
  if dataFlag and hiddenFlags > 0 and type(band) == "function" then
    if band(dataFlag, hiddenFlags) ~= 0 then
      return nil
    end
  end

  local link = unpacked and unpacked.link or item[const.LINK]
  local itemId = unpacked and unpacked.itemId or item[const.ITEMID]
  if not link and itemId then
    link = "item:" .. tostring(itemId)
  end
  if not link then
    return nil
  end

  local equipCode = unpacked and unpacked.equipPos or item[const.IEQUIP]
  local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType,
    itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice =
    GetItemInfo(link)
  return {
    source = "auctioneer",
    sourceIndex = index,
    name = itemName or (unpacked and unpacked.itemName) or item[const.NAME],
    auctionName = unpacked and unpacked.itemName or item[const.NAME],
    link = itemLink or link,
    count = unpacked and unpacked.stackSize or item[const.COUNT],
    quality = itemRarity or (unpacked and unpacked.quality) or item[const.QUALITY],
    canUse = unpacked and unpacked.canUse or item[const.CANUSE],
    level = itemLevel or (unpacked and unpacked.useLevel) or item[const.ULEVEL],
    minLevel = itemMinLevel,
    minBid = unpacked and unpacked.minBid or item[const.MINBID] or item[const.PRICE] or 0,
    minIncrement = unpacked and unpacked.increment or item[const.MININC] or 0,
    buyoutPrice = unpacked and unpacked.buyoutPrice or item[const.BUYOUT] or 0,
    bidAmount = unpacked and unpacked.curBid or item[const.CURBID] or 0,
    owner = unpacked and unpacked.sellerName or item[const.SELLER],
    itemType = itemType,
    itemSubType = itemSubType,
    itemStackCount = itemStackCount,
    equipLoc = itemEquipLoc or self:GetAuctioneerEquipLoc(equipCode),
    texture = itemTexture or (unpacked and unpacked.texture),
    sellPrice = sellPrice,
    timeLeft = unpacked and unpacked.timeLeft or item[const.TLEFT],
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

function addon:GetBidPrice(row)
  if not row then
    return 0
  end
  if row.bidAmount and row.bidAmount > 0 then
    return row.bidAmount + (row.minIncrement or 0)
  end
  return row.minBid or 0
end

function addon:GetBuyoutPrice(row)
  return row and row.buyoutPrice or 0
end

function addon:GetPrice(row)
  if self.db and self.db.useBuyout and self:GetBuyoutPrice(row) > 0 then
    return self:GetBuyoutPrice(row)
  end
  return self:GetBidPrice(row)
end

function addon:GetPawnValueForLink(link, scaleName)
  if not link or not pawnScoringIsReady() then
    return nil
  end
  local item = PawnGetItemData(link)
  if not item then
    return nil
  end
  local value, unenchantedValue = PawnGetSingleValueFromItem(item, scaleName)
  if self.db and self.db.unenchanted and unenchantedValue then
    return unenchantedValue
  end
  return value or unenchantedValue or 0
end

function addon:GetPawnValueForEquipped(slot, scaleName)
  if not slot or not pawnScoringIsReady() then
    return 0
  end
  local item = PawnGetItemDataForInventorySlot(slot, self.db and self.db.unenchanted, "player")
  if not item then
    return 0
  end
  local value, unenchantedValue = PawnGetSingleValueFromItem(item, scaleName)
  if self.db and self.db.unenchanted and unenchantedValue then
    return unenchantedValue
  end
  return value or unenchantedValue or 0
end

function addon:IsAffordable(row)
  if not row then
    return false
  end
  return self:GetPrice(row) <= GetMoney()
end
function addon:MatchesForceTwoHand(row)
  if not self.db or not self.db.force2h then
    return true
  end
  return row and row.equipLoc == "INVTYPE_2HWEAPON"
end

function addon:MatchesArmorPreference(row)
  local preference = self.db and self.db.armorPreference or ""
  if preference == "" or not row or not self.armorPreferenceEquipLocs[row.equipLoc] then
    return true
  end
  for _, option in ipairs(self.armorPreferenceOptions) do
    if option.key == preference then
      for _, name in ipairs(option.names) do
        if row.itemSubType == name then
          return true
        end
      end
      return false
    end
  end
  return true
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

function addon:IsSlotFilterEnabled(filter)
  for _, slotName in ipairs(filter.slots) do
    if not self:IsSlotEnabled(slotName) then
      return false
    end
  end
  return true
end

function addon:SetSlotFilter(filter, enabled)
  self.db = self:EnsureDatabase()
  self.db.slots = self.db.slots or {}
  for _, slotName in ipairs(filter.slots) do
    self.db.slots[slotName] = enabled and true or false
  end
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

  local hasTitanGrip = playerKnowsSpell(46917)
  local hasTwoHandEquipped = self:IsTwoHandEquipped()

  if row.equipLoc == "INVTYPE_WEAPON" then
    if hasTwoHandEquipped and not hasTitanGrip then
      return singleSlot("MainHandSlot"), "single"
    end
    if not self:CanDualWield() then
      return singleSlot("MainHandSlot"), "single"
    end
    return slots, "bestReplacement"
  end

  if row.equipLoc == "INVTYPE_WEAPONOFFHAND" then
    if not self:CanDualWield() then
      return nil
    end
    if hasTwoHandEquipped and not hasTitanGrip then
      return nil
    end
    return singleSlot("SecondaryHandSlot"), "single"
  end

  if row.equipLoc == "INVTYPE_HOLDABLE" or row.equipLoc == "INVTYPE_SHIELD" then
    if hasTwoHandEquipped then
      return singleSlot("MainHandSlot"), "single"
    end
    return slots, "single"
  end

  if row.equipLoc == "INVTYPE_2HWEAPON" then
    local offhand = slotByName("SecondaryHandSlot")
    if offhand then
      table.insert(slots, offhand)
    end
    if hasTitanGrip then
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

function addon:PrepareScoringSource(scaleName)
  if not self:IsAutoGearScale(scaleName) then
    return true
  end
  AutoGearUpdateEquippedItems()
  return true
end

function addon:GetSlotNameForId(slotId)
  self.slotNamesById = self.slotNamesById or {}
  if self.slotNamesById[slotId] then
    return self.slotNamesById[slotId]
  end
  for slotName in pairs(self.defaults.slots) do
    local id = GetInventorySlotInfo(slotName)
    if id == slotId then
      self.slotNamesById[slotId] = slotName
      return slotName
    end
  end
  return nil
end

function addon:IsAnyAutoGearSlotEnabled(info)
  if not info or not info.validGearSlots then
    return true
  end
  for _, slotId in ipairs(info.validGearSlots) do
    local slotName = self:GetSlotNameForId(slotId)
    if not slotName or self:IsSlotEnabled(slotName) then
      return true
    end
  end
  return false
end

function addon:IsDisplayableUpgrade(delta)
  return delta and delta >= self.MIN_DISPLAY_DELTA
end

function addon:ScoreAutoGearAuction(row)
  local info = AutoGearReadItemInfo(nil, nil, nil, nil, nil, row.link)
  if not info or info.unusable or not info.isGear or not info.shouldShowScoreInTooltip then
    return nil
  end
  if not self:IsAnyAutoGearSlotEnabled(info) then
    return nil
  end
  local score = AutoGearDetermineItemScore(info)
  local _, bestSetScore = AutoGearGetBestSetItems(info)
  local _, _, _, equippedSetScore = AutoGearGetTooltipScoreComparisonInfo(info, false)
  row.value = (score or 0) + (bestSetScore or 0)
  row.equippedValue = equippedSetScore or 0
  row.delta = row.value - row.equippedValue
  if not self:IsDisplayableUpgrade(row.delta) then
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
  if not self:MatchesForceTwoHand(row) then
    return nil
  end
  if not self:MatchesArmorPreference(row) then
    return nil
  end
  if self:IsAutoGearScale(scaleName) then
    return self:ScoreAutoGearAuction(row)
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
  if not self:IsDisplayableUpgrade(row.delta) then
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

local function formatScore(score)
  return string.format("+%.2f", score or 0)
end

local function formatResultBid(addon, result)
  return formatCopper(addon:GetBidPrice(result))
end

local function formatResultBuyout(addon, result)
  local buyout = addon:GetBuyoutPrice(result)
  if buyout and buyout > 0 then
    return formatCopper(buyout)
  end
  return "No buyout"
end

local function formatResultPrices(addon, result)
  local bid = formatCopper(addon:GetBidPrice(result))
  local buyout = addon:GetBuyoutPrice(result)
  if buyout and buyout > 0 then
    return "Bid " .. bid .. " / Buy " .. formatCopper(buyout)
  end
  return "Bid " .. bid .. " / No buyout"
end

local function sortByScore(left, right)
  return (left.score or 0) > (right.score or 0)
end
function addon:SelectAuctionTab(index)
  if not self.auctionTab or index ~= self.auctionTab:GetID() then
    self:CancelActiveScan("Auction tab changed; scan canceled.")
    self:HideMainFrame()
    if AuctionFrameTab_OnClick and _G["AuctionFrameTab" .. tostring(index)] then
      AuctionFrameTab_OnClick(_G["AuctionFrameTab" .. tostring(index)])
    end
    return
  end
  PanelTemplates_SetTab(AuctionFrame, self.auctionTab:GetID())
  if AuctionFrameBrowse then
    AuctionFrameBrowse:Hide()
  end
  if AuctionFrameBid then
    AuctionFrameBid:Hide()
  end
  if AuctionFrameAuctions then
    AuctionFrameAuctions:Hide()
  end
  self:PrepareAuctionFrameChrome()
  self:CreateMainFrame()
  self.mainFrame:Show()
  AuctionFrame.type = "list"
  self:UpdateSearchButton()
end
function addon:SetOption(key, enabled)
  self.db = self:EnsureDatabase()
  self.db[key] = enabled and true or false
end

function addon:SetArmorPreference(value)
  self.db = self:EnsureDatabase()
  self.db.armorPreference = value or ""
  if self.armorDropDown and UIDropDownMenu_SetSelectedValue then
    UIDropDownMenu_SetSelectedValue(self.armorDropDown, self.db.armorPreference)
  end
  if self.armorDropDown and UIDropDownMenu_SetText then
    UIDropDownMenu_SetText(self.armorDropDown, self:GetArmorPreferenceLabel())
  end
end

function addon:GetArmorPreferenceLabel()
  local preference = self.db and self.db.armorPreference or ""
  for _, option in ipairs(self.armorPreferenceOptions) do
    if option.key == preference then
      return option.label
    end
  end
  return "No Preference"
end

local function addOptionCheckButton(addon, parent, option, index, title)
  local check = CreateFrame(
    "CheckButton",
    "PawnAuctionSearchOption" .. index,
    parent,
    "UICheckButtonTemplate"
  )
  local column = math.floor((index - 1) / addon.OPTION_FILTER_ROWS)
  local row = (index - 1) % addon.OPTION_FILTER_ROWS
  check:SetSize(addon.CHECK_BUTTON_SIZE, addon.CHECK_BUTTON_SIZE)
  check:SetPoint(
    "TOPLEFT",
    title,
    "BOTTOMLEFT",
    column * addon.OPTION_FILTER_COLUMN_WIDTH,
    -4 - (row * addon.CHECK_BUTTON_ROW_HEIGHT)
  )
  check:SetChecked(addon.db and addon.db[option.key])
  check.labelText = getCheckButtonText(check) or check:CreateFontString(nil, "ARTWORK")
  check.labelText:SetPoint("LEFT", check, "RIGHT", 0, 0)
  check.labelText:SetText(option.label)
  check:SetScript("OnClick", function(button)
    addon:SetOption(option.key, button:GetChecked())
  end)
  addon:AttachHelpTooltip(check, option.label, option.tip)
  addon:AttachHelpTooltip(check.labelText, option.label, option.tip)
  parent.optionControls[index] = check
  return check
end

function addon:CreateArmorPreferenceSelector(parent, anchor)
  local label = parent:CreateFontString(
    "PawnAuctionSearchArmorPreferenceLabel",
    "ARTWORK",
    "GameFontNormal"
  )
  label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
  label:SetText("Armor Preference")
  self:AttachHelpTooltip(
    label,
    "Armor Preference",
    "Only show the selected armor type in search results.  Filter out all other armor types."
  )

  local dropdown = CreateFrame(
    "Frame",
    "PawnAuctionSearchArmorPreferenceDropDown",
    parent,
    "UIDropDownMenuTemplate"
  )
  dropdown:SetPoint("TOPLEFT", label, "BOTTOMLEFT", -16, -4)
  self.armorDropDown = dropdown
  if UIDropDownMenu_SetWidth then
    UIDropDownMenu_SetWidth(dropdown, self.ARMOR_DROPDOWN_WIDTH)
  end
  if UIDropDownMenu_Initialize then
    UIDropDownMenu_Initialize(dropdown, function()
      for _, option in ipairs(addon.armorPreferenceOptions) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = option.label
        info.value = option.key
        info.func = function(button)
          addon:SetArmorPreference(button.value)
        end
        UIDropDownMenu_AddButton(info)
      end
    end)
  end
  if UIDropDownMenu_SetSelectedValue then
    UIDropDownMenu_SetSelectedValue(dropdown, self.db and self.db.armorPreference or "")
  end
  if UIDropDownMenu_SetText then
    UIDropDownMenu_SetText(dropdown, self:GetArmorPreferenceLabel())
  end
  self:AttachDropdownHelpTooltip(
    dropdown,
    "Armor Preference",
    "Only show the selected armor type in search results.  Filter out all other armor types."
  )
  return dropdown
end

function addon:CreateOptionControls(parent, anchor)
  if parent.optionControls then
    return parent.optionControls
  end
  self.db = self:EnsureDatabase()
  local title = parent:CreateFontString(
    "PawnAuctionSearchOptionsTitle",
    "ARTWORK",
    "GameFontNormal"
  )
  title:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
  title:SetText("Options")
  parent.optionControls = {}
  local options = {
    {
      key = "canUse",
      label = "Useable items only",
      tip = "Only items that your character can use.",
    },
    {
      key = "affordable",
      label = "Only what I can afford",
      tip = "Only show what you can currently afford to buy.",
    },
    {
      key = "useBuyout",
      label = "Use buyout",
      tip = "Use buyout instead of bid when checking auction prices.",
    },
    {
      key = "bestPrice",
      label = "Adjust based on price",
      tip = "Adjust the score returned by the price of the item.  For similar items, "
        .. "the cheaper item will be higher on the list.",
    },
    {
      key = "unenchanted",
      label = "Use unenchanted values",
      tip = "Use unenchanted values for calculations. If not checked, item values "
        .. "will include current enchantements.",
    },
  }
  for index, option in ipairs(options) do
    addOptionCheckButton(self, parent, option, index, title)
  end
  local armorAnchor = parent.optionControls[#parent.optionControls] or title
  parent.optionsBottom = self:CreateArmorPreferenceSelector(parent, armorAnchor)
  self.optionControls = parent.optionControls
  return parent.optionControls
end

local function addSlotFilterCheckButton(addon, parent, filter, index, title, visualIndex)
  visualIndex = visualIndex or index
  local column = math.floor((visualIndex - 1) / addon.SLOT_FILTER_ROWS)
  local row = (visualIndex - 1) % addon.SLOT_FILTER_ROWS
  local check = CreateFrame(
    "CheckButton",
    "PawnAuctionSearchSlotFilter" .. index,
    parent,
    "UICheckButtonTemplate"
  )
  check:SetSize(addon.CHECK_BUTTON_SIZE, addon.CHECK_BUTTON_SIZE)
  check:SetPoint(
    "TOPLEFT",
    title,
    "BOTTOMLEFT",
    column * addon.SLOT_FILTER_COLUMN_WIDTH,
    -4 - (row * addon.CHECK_BUTTON_ROW_HEIGHT)
  )
  check:SetChecked(addon:IsSlotFilterEnabled(filter))
  check.labelText = getCheckButtonText(check) or check:CreateFontString(nil, "ARTWORK")
  check.labelText:SetPoint("LEFT", check, "RIGHT", 0, 0)
  check.labelText:SetText(filter.label)
  check:SetScript("OnClick", function(button)
    addon:SetSlotFilter(filter, button:GetChecked())
  end)
  local tip = "Include this equipment slot when searching for upgrades."
  addon:AttachHelpTooltip(check, filter.label, tip)
  addon:AttachHelpTooltip(check.labelText, filter.label, tip)
  parent.slotControls[index] = check
end

local function addForceTwoHandCheckButton(addon, parent, title, visualIndex)
  visualIndex = visualIndex or 14
  local column = math.floor((visualIndex - 1) / addon.SLOT_FILTER_ROWS)
  local row = (visualIndex - 1) % addon.SLOT_FILTER_ROWS
  local check = CreateFrame(
    "CheckButton",
    "PawnAuctionSearchForceTwoHandOption",
    parent,
    "UICheckButtonTemplate"
  )
  check:SetSize(addon.CHECK_BUTTON_SIZE, addon.CHECK_BUTTON_SIZE)
  check:SetPoint(
    "TOPLEFT",
    title,
    "BOTTOMLEFT",
    column * addon.SLOT_FILTER_COLUMN_WIDTH,
    -4 - (row * addon.CHECK_BUTTON_ROW_HEIGHT)
  )
  check:SetChecked(addon.db and addon.db.force2h)
  check.labelText = getCheckButtonText(check) or check:CreateFontString(nil, "ARTWORK")
  check.labelText:SetPoint("LEFT", check, "RIGHT", 0, 0)
  check.labelText:SetText("Only 2H Weapons")
  check:SetScript("OnClick", function(button)
    addon:SetOption("force2h", button:GetChecked())
  end)
  addon:AttachHelpTooltip(
    check,
    "Only 2H Weapons",
    "When comparing weapons, only consider 2-Handed Weapons."
  )
  addon:AttachHelpTooltip(
    check.labelText,
    "Only 2H Weapons",
    "When comparing weapons, only consider 2-Handed Weapons."
  )
  parent.forceTwoHandControl = check
  addon.forceTwoHandControl = check
end

function addon:CreateSlotFilters(parent)
  if parent.slotControls then
    return parent.slotControls
  end
  local title = parent:CreateFontString(
    "PawnAuctionSearchSlotFilterTitle",
    "ARTWORK",
    "GameFontNormal"
  )
  title:SetPoint(
    "TOPLEFT",
    parent,
    "TOPLEFT",
    self.SLOT_FILTERS_LEFT_OFFSET,
    self.SLOT_FILTERS_TOP_OFFSET
  )
  title:SetText("Slots")
  parent.slotControls = {}
  for index, filter in ipairs(self.slotFilters) do
    local visualIndex = index
    if index > 13 then
      visualIndex = index + 1
    end
    addSlotFilterCheckButton(self, parent, filter, index, title, visualIndex)
  end
  addForceTwoHandCheckButton(self, parent, title, 14)
  self.slotControls = parent.slotControls
  return parent.slotControls
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
  status:SetPoint("TOPLEFT", frame, "TOPLEFT", self.RESULTS_LEFT_OFFSET, self.RESULTS_STATUS_OFFSET)
  status:SetText("Choose a Pawn scale, then search.")
  frame.statusText = status
  self.statusText = status

  local button = CreateFrame("Button", "PawnAuctionSearchButton", frame, "UIPanelButtonTemplate")
  button:SetSize(96, 22)
  button:SetPoint("TOPLEFT", self.scaleDropDown or frame, "BOTTOMLEFT", 16, -28)
  button:SetText("Search")
  button:SetScript("OnClick", function()
    if addon:IsScanning() then
      addon:CancelActiveScan("Scan canceled.")
      addon:UpdateSearchButton()
      return
    end
    addon:StartScan()
  end)
  frame.searchButton = button
  self.searchButton = button

  self:CreateOptionControls(frame, button)
  self:CreateSlotFilters(frame, button)
  self.resultRows = self:CreateResults(frame)
  self.mainFrame = frame
  self:UpdateSearchButton()
  return frame
end

function addon:CreateResultsHeaderAndScroll(parent)
  local header = parent:CreateFontString(
    "PawnAuctionSearchResultsHeader",
    "ARTWORK",
    "GameFontNormal"
  )
  header:SetPoint("TOPLEFT", parent, "TOPLEFT", self.RESULTS_LEFT_OFFSET, self.RESULTS_TOP_OFFSET)
  header:SetText("Item")
  parent.resultsHeader = header
  self.resultsHeader = header

  local scoreHeader = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  scoreHeader:SetPoint("LEFT", header, "LEFT", self.RESULT_DELTA_OFFSET, 0)
  scoreHeader:SetText("Pawn")

  local bidHeader = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  bidHeader:SetPoint("LEFT", header, "LEFT", self.RESULT_BID_PRICE_OFFSET, 0)
  bidHeader:SetText("Bid")

  local buyoutHeader = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  buyoutHeader:SetPoint("LEFT", header, "LEFT", self.RESULT_BUYOUT_PRICE_OFFSET, 0)
  buyoutHeader:SetText("Buyout")

  local scrollFrame = CreateFrame(
    "ScrollFrame",
    "PawnAuctionSearchResultsScrollFrame",
    parent,
    "FauxScrollFrameTemplate"
  )
  scrollFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
  scrollFrame:SetSize(
    self.RESULT_SCROLL_WIDTH,
    self.RESULTS_VISIBLE_ROWS * self.RESULT_ROW_HEIGHT
  )
  scrollFrame:SetScript("OnVerticalScroll", function(frame, offset)
    FauxScrollFrame_OnVerticalScroll(frame, offset, addon.RESULT_ROW_HEIGHT, function()
      addon:UpdateResults()
    end)
  end)
  parent.resultScrollFrame = scrollFrame
  self.resultScrollFrame = scrollFrame
  return scrollFrame
end

function addon:CreateResultRow(parent, scrollFrame, index, previous)
  local row = CreateFrame("Button", "PawnAuctionSearchResult" .. index, parent)
  row:SetSize(self.RESULT_ROW_WIDTH, self.RESULT_ROW_HEIGHT)
  if previous then
    row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, 0)
  else
    row:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
  end
  row:RegisterForClicks("LeftButtonUp")
  row:SetScript("OnClick", function(button)
    addon:HandleResultClick(button.resultIndex)
  end)
  row:SetScript("OnEnter", function(button)
    addon:ShowResultTooltip(button.resultIndex, button)
  end)
  row:SetScript("OnLeave", function()
    if GameTooltip then
      GameTooltip:Hide()
    end
  end)
  row.selectedTexture = row:CreateTexture(nil, "BACKGROUND")
  row.selectedTexture:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  if row.selectedTexture.SetAllPoints then
    row.selectedTexture:SetAllPoints(row)
  end
  row.dividerTexture = row:CreateTexture(nil, "ARTWORK")
  row.dividerTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
  if row.dividerTexture.SetVertexColor then
    row.dividerTexture:SetVertexColor(1, 1, 1, 0.18)
  end
  row.dividerTexture:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
  row.dividerTexture:SetSize(self.RESULT_ROW_WIDTH, 1)
  row.selectedTexture:Hide()
  row.nameText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  row.nameText:SetPoint("LEFT", row, "LEFT", 0, 0)
  row.nameText:SetWidth(self.RESULT_NAME_WIDTH)
  row.deltaText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  row.deltaText:SetPoint("LEFT", row, "LEFT", self.RESULT_DELTA_OFFSET, 0)
  row.deltaText:SetWidth(58)
  if row.deltaText.SetJustifyH then
    row.deltaText:SetJustifyH("RIGHT")
  end
  row.bidText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  row.bidText:SetPoint("LEFT", row, "LEFT", self.RESULT_BID_PRICE_OFFSET, 0)
  row.bidText:SetWidth(82)
  row.buyoutText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  row.buyoutText:SetPoint("LEFT", row, "LEFT", self.RESULT_BUYOUT_PRICE_OFFSET, 0)
  row.buyoutText:SetWidth(92)
  row.bidButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  row.bidButton:Hide()
  row.buyoutButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  row.buyoutButton:Hide()
  row:Hide()
  return row
end

function addon:CreateResultActions(parent)
  local closeAction = CreateFrame(
    "Button",
    "PawnAuctionSearchCloseActionButton",
    parent,
    "UIPanelButtonTemplate"
  )
  closeAction:SetSize(self.ACTION_BUTTON_WIDTH, self.ACTION_BUTTON_HEIGHT)
  local buyoutAction = CreateFrame(
    "Button",
    "PawnAuctionSearchBuyoutActionButton",
    parent,
    "UIPanelButtonTemplate"
  )
  buyoutAction:SetSize(self.ACTION_BUTTON_WIDTH, self.ACTION_BUTTON_HEIGHT)
  local bidAction = CreateFrame(
    "Button",
    "PawnAuctionSearchBidActionButton",
    parent,
    "UIPanelButtonTemplate"
  )
  bidAction:SetSize(self.ACTION_BUTTON_WIDTH, self.ACTION_BUTTON_HEIGHT)

  closeAction:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 12, -26)
  closeAction:SetText("Close")
  closeAction:SetScript("OnClick", function()
    if HideUIPanel then
      HideUIPanel(AuctionFrame)
    elseif AuctionFrame then
      AuctionFrame:Hide()
    end
  end)
  closeAction:Show()
  parent.closeButton = closeAction
  self.closeButton = closeAction

  buyoutAction:SetPoint("RIGHT", closeAction, "LEFT", 0, 0)
  buyoutAction:SetText("Buyout")
  buyoutAction:SetScript("OnClick", function()
    addon:PlaceResultBid(addon:GetActionResultIndex(), true)
  end)
  buyoutAction:Show()
  buyoutAction:Disable()
  parent.buyoutButton = buyoutAction
  self.buyoutButton = buyoutAction

  bidAction:SetPoint("RIGHT", buyoutAction, "LEFT", 0, 0)
  bidAction:SetText("Bid")
  bidAction:SetScript("OnClick", function()
    addon:PlaceResultBid(addon:GetActionResultIndex(), false)
  end)
  bidAction:Show()
  bidAction:Disable()
  parent.bidButton = bidAction
  self.bidButton = bidAction
end

function addon:CreateResults(parent)
  if self.resultRows then
    return self.resultRows
  end
  local rows = {}
  local scrollFrame = self:CreateResultsHeaderAndScroll(parent)
  local previous
  for index = 1, self.RESULTS_VISIBLE_ROWS do
    local row = self:CreateResultRow(parent, scrollFrame, index, previous)
    rows[index] = row
    previous = row
  end
  self:CreateResultActions(parent)
  return rows
end

function addon:SetStatus(message)
  self:CreateMainFrame()
  if self.statusText then
    self.statusText:SetText(message)
  end
  self:UpdateSearchButton()
end

function addon:ShowResultTooltip(resultIndex, owner)
  local result = self.results and self.results[resultIndex]
  if not result or not result.link or not GameTooltip then
    return
  end
  GameTooltip:SetOwner(owner or UIParent, "ANCHOR_RIGHT")
  GameTooltip:ClearLines()
  local liveIndex = result.index
  local live = liveIndex and result.page == self.currentAuctionPage
    and self:CurrentAuctionMatchesResult(liveIndex, result)
  if live and GameTooltip.SetAuctionItem then
    GameTooltip:SetAuctionItem("list", liveIndex)
  else
    GameTooltip:SetHyperlink(result.link)
    if GameTooltip.AddLine then
      GameTooltip:AddLine("Stack: " .. tostring(result.count or 1))
      GameTooltip:AddLine("Bid: " .. formatResultBid(self, result))
      GameTooltip:AddLine("Buyout: " .. formatResultBuyout(self, result))
    end
  end
  GameTooltip:Show()
end

function addon:HandleResultClick(resultIndex)
  local result = self.results and self.results[resultIndex]
  if not result then
    return
  end
  if IsShiftKeyDown and IsShiftKeyDown() and ChatEdit_InsertLink then
    ChatEdit_InsertLink(result.link)
    return
  end
  if IsAltKeyDown and IsAltKeyDown() and QueryAuctionItems then
    QueryAuctionItems(result.auctionName or result.name or "")
    return
  end
  self:SelectResult(resultIndex)
end

function addon:GetActionResultIndex()
  if self.selectedResultIndex and self.results and self.results[self.selectedResultIndex] then
    return self.selectedResultIndex
  end
  self:SetStatus("Select a result before bidding or buying.")
  return nil
end

local function copyAuctionRow(row)
  local copy = {}
  for key, value in pairs(row) do
    copy[key] = value
  end
  return copy
end

local function formatDuration(seconds)
  local minutes = math.floor(seconds / 60)
  local remainder = seconds - minutes * 60
  return string.format("%d:%02d", minutes, remainder)
end

function addon:FinishScan(statusSuffix)
  table.sort(self.results, sortByScore)
  self.scanActive = false
  self.fastScanActive = false
  self.fastScanProcessing = false
  self.fastScanProcessIndex = nil
  self.fastScanProcessTotal = nil
  self.fastScanNextStatus = nil
  self.fastScanWaitElapsed = nil
  self.fastScanLastStatusSecond = nil
  self.fastScanIncomplete = false
  self.fastScanSnapshotMarker = nil
  self.auctioneerScanProcessing = false
  self.auctioneerScanImage = nil
  self.auctioneerScanConst = nil
  self.auctioneerScanIndex = nil
  self.auctioneerScanTotal = nil
  self.auctioneerScanNextStatus = nil
  self.auctioneerScanApi = nil
  local status = "Found " .. tostring(#self.results) .. " upgrade auctions"
  if statusSuffix then
    status = status .. " " .. statusSuffix
  end
  self:SetStatus(status .. ".")
  self:UpdateResults()
end
function addon:ScoreCachedAuctions()
  if not self.auctionCacheComplete or not self.auctionCacheRows then
    return false
  end
  self.results = {}
  for _, cachedRow in ipairs(self.auctionCacheRows) do
    local result = self:ScoreAuction(copyAuctionRow(cachedRow), self.scanScaleName)
    if result then
      table.insert(self.results, result)
    end
  end
  local suffix = "from cached scan (" .. tostring(#self.auctionCacheRows) .. " auctions rescored)"
  self:FinishScan(suffix)
  return true
end

function addon:SetAuctioneerScanProgress(scanned, total)
  self:SetStatus(
    "Auctioneer scan data scoring " .. tostring(scanned) .. " / " .. tostring(total)
      .. " auctions..."
  )
end

function addon:StartAuctioneerScanProcessing(image, const, api)
  self.results = {}
  self.auctioneerScanImage = image
  self.auctioneerScanConst = const
  self.auctioneerScanApi = api
  self.auctioneerScanProcessing = true
  self.auctioneerScanIndex = 1
  self.auctioneerScanTotal = #image
  self.auctioneerScanNextStatus = self.FAST_SCAN_STATUS_INTERVAL
  self:SetAuctioneerScanProgress(0, #image)
end

function addon:ScoreAuctioneerAuctions()
  local auc = _G.AucAdvanced
  local scan = auc and auc.Scan
  if scan and type(scan.IsPaused) == "function" and scan.IsPaused() then
    self.scanActive = false
    self:SetStatus("Auctioneer scanning is paused. Resume Auctioneer, then search again.")
    return true
  end
  if scan and type(scan.IsScanning) == "function" and scan.IsScanning() then
    self.scanActive = false
    self:SetStatus("Auctioneer is scanning. Search again after Auctioneer finishes.")
    return true
  end
  local api, const = self:GetAuctioneerScanApi()
  if not api then
    return false
  end
  local image
  if type(api.GetImageCopy) == "function" then
    image = api.GetImageCopy()
  else
    image = api.QueryImage({})
  end
  if type(image) ~= "table" or #image == 0 then
    return false
  end
  self:StartAuctioneerScanProcessing(image, const, api)
  return true
end

function addon:ProcessAuctioneerScanBatch()
  if not self.auctioneerScanProcessing then
    return false
  end
  local image = self.auctioneerScanImage or {}
  local const = self.auctioneerScanConst
  local api = self.auctioneerScanApi
  local total = self.auctioneerScanTotal or 0
  local startIndex = self.auctioneerScanIndex or 1
  local endIndex = math.min(total, startIndex + self.FAST_SCAN_ROWS_PER_TICK - 1)
  for index = startIndex, endIndex do
    local row = self:ReadAuctioneerRow(image[index], index, const, api)
    if row then
      local result = self:ScoreAuction(row, self.scanScaleName)
      if result then
        table.insert(self.results, result)
      end
    end
  end
  self.auctioneerScanIndex = endIndex + 1
  if endIndex >= total then
    local suffix = "from Auctioneer scan data (" .. tostring(total) .. " auctions rescored)"
    self:FinishScan(suffix)
    return true
  end
  if endIndex >= (self.auctioneerScanNextStatus or 0) then
    self:SetAuctioneerScanProgress(endIndex, total)
    repeat
      self.auctioneerScanNextStatus = (self.auctioneerScanNextStatus or 0)
        + self.FAST_SCAN_STATUS_INTERVAL
    until self.auctioneerScanNextStatus > endIndex
  end
  return true
end

function addon:QueryFastScan()
  local _, canQueryAll = CanSendAuctionQuery()
  if not canQueryAll then
    return false
  end
  self.waitingForQuery = false
  self.waitingPage = nil
  self.fastScanActive = true
  self.fastScanWaitElapsed = 0
  self.fastScanLastStatusSecond = nil
  self.currentQueryPage = 0
  self.currentAuctionPage = 0
  self.auctionCacheRows = {}
  self.auctionCacheComplete = false
  self.fastScanIncomplete = false
  QueryAuctionItems("", "", "", nil, nil, nil, 0, false, -1, true)
  self:SetFastScanWaitingStatus(0)
  return true
end

function addon:SetFastScanWaitingStatus(seconds)
  self.fastScanLastStatusSecond = seconds
  local status = "Fast scan request sent. Waiting for server (" .. formatDuration(seconds) .. ")..."
  self:SetStatus(status)
end

function addon:UpdateFastScanWaitingStatus(elapsed)
  self.fastScanWaitElapsed = (self.fastScanWaitElapsed or 0) + (elapsed or 0)
  local seconds = math.floor(self.fastScanWaitElapsed)
  if seconds ~= self.fastScanLastStatusSecond then
    self:SetFastScanWaitingStatus(seconds)
  end
end

function addon:SetFastScanProgress(scanned, total)
  self:SetStatus(
    "Fast scan scoring " .. tostring(scanned) .. " / " .. tostring(total) .. " auctions..."
  )
end

function addon:StartFastScanProcessing(count)
  self.results = {}
  self.auctionCacheRows = {}
  self.currentAuctionPage = 0
  self.fastScanProcessing = true
  self.fastScanProcessIndex = 1
  self.fastScanProcessTotal = count
  self.fastScanNextStatus = self.FAST_SCAN_STATUS_INTERVAL
  self.fastScanIncomplete = false
  self.fastScanSnapshotMarker = self:GetAuctionSnapshotMarker(count)
  self:SetFastScanProgress(0, count)
end

function addon:HashSnapshotValue(hash, value)
  local text = tostring(value or "")
  for index = 1, string.len(text) do
    hash = (hash * 33 + string.byte(text, index)) % 1000000007
  end
  return (hash * 33 + 1) % 1000000007
end

function addon:GetAuctionSnapshotMarker(count)
  if not count or count <= 0 then
    return "0:0"
  end
  local hash = count
  for index = 1, count do
    local name, _, _, _, _, _, minBid, _, buyout, bid, _, owner = GetAuctionItemInfo("list", index)
    hash = self:HashSnapshotValue(hash, GetAuctionItemLink("list", index))
    hash = self:HashSnapshotValue(hash, name)
    hash = self:HashSnapshotValue(hash, minBid)
    hash = self:HashSnapshotValue(hash, buyout)
    hash = self:HashSnapshotValue(hash, bid)
    hash = self:HashSnapshotValue(hash, owner)
  end
  return tostring(count) .. ":" .. tostring(hash)
end

function addon:IsCompleteAuctionRow(row)
  return row and row.link and row.name and row.itemType ~= nil and row.equipLoc ~= nil
end

function addon:AbortIncompleteFastScan(message)
  self.results = {}
  self.scanActive = false
  self.fastScanActive = false
  self.fastScanProcessing = false
  self.fastScanProcessIndex = nil
  self.fastScanProcessTotal = nil
  self.fastScanNextStatus = nil
  self.fastScanWaitElapsed = nil
  self.fastScanLastStatusSecond = nil
  self.fastScanIncomplete = false
  self.fastScanSnapshotMarker = nil
  self.auctionCacheRows = nil
  self.auctionCacheComplete = false
  self:SetStatus(message)
  self:UpdateResults()
end

function addon:ProcessFastScanBatch()
  if not self.fastScanProcessing then
    return false
  end

  local total = self.fastScanProcessTotal or 0
  local startIndex = self.fastScanProcessIndex or 1
  local endIndex = math.min(total, startIndex + self.FAST_SCAN_ROWS_PER_TICK - 1)
  for index = startIndex, endIndex do
    local row = self:ReadAuctionRow(index)
    if not self:IsCompleteAuctionRow(row) then
      self.fastScanIncomplete = true
    else
      table.insert(self.auctionCacheRows, copyAuctionRow(row))
      local result = self:ScoreAuction(row, self.scanScaleName)
      if result then
        table.insert(self.results, result)
      end
    end
  end

  self.fastScanProcessIndex = endIndex + 1
  if endIndex >= total then
    if self.fastScanIncomplete then
      self:AbortIncompleteFastScan("Fast scan incomplete; item data is still loading. Try again.")
      return true
    end
    self.auctionCacheComplete = true
    self:FinishScan("from fast scan")
    return true
  end

  if endIndex >= (self.fastScanNextStatus or 0) then
    self:SetFastScanProgress(endIndex, total)
    repeat
      self.fastScanNextStatus = (self.fastScanNextStatus or 0) + self.FAST_SCAN_STATUS_INTERVAL
    until self.fastScanNextStatus > endIndex
  end
  return true
end


function addon:QueryAuctionPage(page, status, searchName)
  if not CanSendAuctionQuery("list") then
    self.waitingForQuery = true
    self.waitingPage = page
    self.waitingSearchName = searchName
    self:SetStatus("Auction query is throttled. Waiting to retry...")
    return false
  end
  self.waitingForQuery = false
  self.waitingPage = nil
  self.waitingSearchName = nil
  self.currentQueryPage = page
  QueryAuctionItems(searchName or "", "", "", nil, nil, nil, page, false, -1)
  if status then
    self:SetStatus(status)
  end
  return true
end

function addon:QueryScanPage()
  if not self.scanActive then
    return false
  end
  return self:QueryAuctionPage(
    self.scanPage,
    "Scanning auction house page " .. tostring(self.scanPage + 1) .. "..."
  )
end

function addon:OnUpdate(elapsed)
  self:UpdateSearchButton()
  if self.auctioneerScanProcessing then
    self:ProcessAuctioneerScanBatch()
    return
  end
  if self.fastScanProcessing then
    self:ProcessFastScanBatch()
    return
  end
  if self.fastScanActive then
    self:UpdateFastScanWaitingStatus(elapsed)
    return
  end
  if not self.waitingForQuery then
    return
  end
  if self.pendingSelection then
    local result = self.pendingSelection
    local searchName = result.searchName or result.auctionName or result.name or ""
    self:QueryAuctionPage(result.page or 0, "Loading selected result page...", searchName)
  elseif self.scanActive then
    self:QueryScanPage()
  end
end

function addon:ResetResultScroll()
  if self.resultScrollFrame and FauxScrollFrame_SetOffset then
    FauxScrollFrame_SetOffset(self.resultScrollFrame, 0)
    local scrollBar = _G[self.resultScrollFrame:GetName() .. "ScrollBar"]
    if scrollBar and scrollBar.SetValue then
      scrollBar:SetValue(0)
    end
  end
end

function addon:StartScan()
  self.db = self:EnsureDatabase()
  self:EnsureScaleSelected()
  local valid, scaleOrMessage = self:ValidateScale(self.db and self.db.scaleName)
  if not valid then
    self.scanActive = false
    self:SetStatus(scaleOrMessage)
    return
  end
  if self.scanActive then
    if self.fastScanActive then
      self:SetStatus("Fast scan already in progress...")
    else
      self:SetStatus("Scan already in progress...")
    end
    return
  end
  self.results = {}
  self:ResetResultScroll()
  self.selectedResultIndex = nil
  self.scanActive = true
  self.fastScanActive = false
  self.scanPage = 0
  self.scanScaleName = scaleOrMessage
  self:PrepareScoringSource(self.scanScaleName)
  self:UpdateResults()

  if self:ScoreAuctioneerAuctions() then
    return
  end
  if self:ScoreCachedAuctions() then
    return
  end
  if self:QueryFastScan() then
    return
  end
  self.scanActive = false
  self.fastScanActive = false
  self.auctionCacheRows = nil
  self.auctionCacheComplete = false
  self:SetStatus("Fast scan is not ready or unsupported, and no cached scan is available.")
end

function addon:OnAuctionItemListUpdate()
  self.currentAuctionPage = self.currentQueryPage or self.currentAuctionPage
  if self.pendingSelection then
    self:CompletePendingSelection()
    return
  end
  if self.fastScanProcessing then
    local count, total = GetNumAuctionItems("list")
    local marker = self:GetAuctionSnapshotMarker(count or 0)
    local sameSnapshot = count == total
      and total == self.fastScanProcessTotal
      and marker == self.fastScanSnapshotMarker
    if sameSnapshot then
      return
    end
    self:AbortIncompleteFastScan("Auction list changed; fast scan canceled.")
    return
  end
  if not self.scanActive then
    return
  end
  local count, total = GetNumAuctionItems("list")
  count = count or 0
  total = total or count
  if self.fastScanActive then
    if count ~= total then
      return
    end
    self:StartFastScanProcessing(count)
    return
  end

  self.results = self.results or {}
  self.auctionCacheRows = self.auctionCacheRows or {}
  self.currentAuctionPage = self.scanPage
  for index = 1, count do
    local row = self:ReadAuctionRow(index)
    if row then
      table.insert(self.auctionCacheRows, copyAuctionRow(row))
      local result = self:ScoreAuction(row, self.scanScaleName)
      if result then
        table.insert(self.results, result)
      end
    end
  end

  local scanned = (self.scanPage + 1) * self.AUCTIONS_PER_PAGE
  if scanned < total then
    self.scanPage = self.scanPage + 1
    self:QueryScanPage()
    return
  end

  self.auctionCacheComplete = true
  self:FinishScan()
end

function addon:UpdateResults()
  self:CreateMainFrame()
  local results = self.results or {}
  local displayRows = self.RESULTS_VISIBLE_ROWS
  if self.resultScrollFrame and FauxScrollFrame_Update then
    FauxScrollFrame_Update(
      self.resultScrollFrame,
      #results,
      displayRows,
      self.RESULT_ROW_HEIGHT
    )
  end

  local offset = 0
  if self.resultScrollFrame and FauxScrollFrame_GetOffset then
    offset = FauxScrollFrame_GetOffset(self.resultScrollFrame) or 0
  end
  if self.selectedResultIndex and not results[self.selectedResultIndex] then
    self.selectedResultIndex = nil
  end
  if self.selectedResultIndex then
    local firstVisible = offset + 1
    local lastVisible = offset + displayRows
    if self.selectedResultIndex < firstVisible or self.selectedResultIndex > lastVisible then
      self.selectedResultIndex = nil
    end
  end

  for displayIndex = 1, displayRows do
    local row = self.resultRows[displayIndex]
    local resultIndex = offset + displayIndex
    local result = results[resultIndex]
    if result then
      row.resultIndex = resultIndex
      row.bidButton.resultIndex = resultIndex
      row.buyoutButton.resultIndex = resultIndex
      row.nameText:SetText(result.link or result.name or "")
      row.deltaText:SetText(formatScore(result.score))
      row.bidText:SetText(formatResultBid(self, result))
      row.buyoutText:SetText(formatResultBuyout(self, result))
      if row.selectedTexture then
        if resultIndex == self.selectedResultIndex then
          row.selectedTexture:Show()
          if row.LockHighlight then
            row:LockHighlight()
          end
        else
          row.selectedTexture:Hide()
          if row.UnlockHighlight then
            row:UnlockHighlight()
          end
        end
      end
      row.bidButton:Hide()
      row.buyoutButton:Hide()
      row:Show()
    else
      row.resultIndex = nil
      row.bidButton.resultIndex = nil
      row.buyoutButton.resultIndex = nil
      row.nameText:SetText("")
      row.deltaText:SetText("")
      row.bidText:SetText("")
      row.buyoutText:SetText("")
      if row.selectedTexture then
        row.selectedTexture:Hide()
      end
      if row.UnlockHighlight then
        row:UnlockHighlight()
      end
      row.bidButton:Hide()
      row.buyoutButton:Hide()
      row:Hide()
    end
  end
  if self.bidButton and self.buyoutButton then
    self.bidButton:Show()
    self.buyoutButton:Show()
    if self.selectedResultIndex and results[self.selectedResultIndex] then
      self.bidButton:Enable()
      self.buyoutButton:Enable()
    else
      self.bidButton:Disable()
      self.buyoutButton:Disable()
    end
  end
end

function addon:FindCurrentBrowseIndex(result)
  if result.index and self:CurrentAuctionMatchesResult(result.index, result) then
    return result.index
  end
  local count = GetNumAuctionItems("list") or 0
  for index = 1, count do
    if self:CurrentAuctionMatchesResult(index, result) then
      return index
    end
  end
  return nil
end

function addon:SelectCurrentBrowseResult(result)
  local index = self:FindCurrentBrowseIndex(result)
  if not index then
    return false
  end
  SetSelectedAuctionItem("list", index)
  return true
end

function addon:LoadLiveResult(result, message)
  local page = result.page or 0
  local searchName
  if result.source == "auctioneer" or result.page == nil then
    searchName = result.auctionName or result.name or ""
  end
  result.searchName = searchName
  self.pendingSelection = result
  self:QueryAuctionPage(page, message, searchName)
end

function addon:GetCurrentAuctionBid(index)
  local _, _, _, _, _, _, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner =
    GetAuctionItemInfo("list", index)
  local bid = bidAmount and bidAmount > 0 and bidAmount + (minIncrement or 0) or minBid
  return bid or 0, buyoutPrice or 0, highBidder, owner
end

function addon:CurrentAuctionMatchesResult(index, result)
  local name, _, _, _, _, _, minBid, minIncrement, buyoutPrice, bidAmount, _, owner =
    GetAuctionItemInfo("list", index)
  if not name or GetAuctionItemLink("list", index) ~= result.link then
    return false
  end
  return (minBid or 0) == (result.minBid or 0)
    and (minIncrement or 0) == (result.minIncrement or 0)
    and (buyoutPrice or 0) == (result.buyoutPrice or 0)
    and (bidAmount or 0) == (result.bidAmount or 0)
    and owner == result.owner
end

function addon:ShowBidConfirmation(index, result, buyout, price)
  if not StaticPopup_Show then
    self:SetStatus("Auction confirmation is unavailable; bid canceled.")
    return
  end
  SetSelectedAuctionItem("list", index)
  if AuctionFrame then
    AuctionFrame.type = "list"
  end
  if buyout then
    if AuctionFrame then
      AuctionFrame.buyoutPrice = price
    end
    StaticPopup_Show("BUYOUT_AUCTION")
    self:SetStatus("Confirm buyout for " .. (result.name or "auction result") .. ".")
    return
  end
  if BrowseBidPrice and MoneyInputFrame_SetCopper then
    MoneyInputFrame_SetCopper(BrowseBidPrice, price)
  end
  StaticPopup_Show("BID_AUCTION")
  self:SetStatus("Confirm bid for " .. (result.name or "auction result") .. ".")
end

function addon:PlaceResultBid(resultIndex, buyout)
  local result = self.results and self.results[resultIndex]
  if not result then
    return
  end
  local index
  if result.source == "auctioneer" then
    index = self:FindCurrentBrowseIndex(result)
    if not index then
      self:LoadLiveResult(result, "Loading live auction. Click Bid or Buy again after it loads.")
      return
    end
  else
    if result.page == nil or result.index == nil then
      self:SetStatus("Auction result has no live row. Search again before bidding.")
      return
    end
    if result.page ~= self.currentAuctionPage then
      self:LoadLiveResult(result, "Loading result page. Click Bid or Buy again after it loads.")
      return
    end
    index = result.index
  end
  index = index or result.index
  if not self:CurrentAuctionMatchesResult(index, result) then
    self:SetStatus("Auction result changed. Search again before bidding.")
    return
  end
  local bidPrice, buyoutPrice, highBidder, owner = self:GetCurrentAuctionBid(index)
  if owner == UnitName("player") then
    self:SetStatus("You cannot bid on your own auction.")
    return
  end
  local price = buyout and buyoutPrice or bidPrice
  if buyout and price <= 0 then
    self:SetStatus("Selected auction has no buyout price.")
    return
  end
  if not buyout and highBidder then
    self:SetStatus("You are already the high bidder.")
    return
  end
  if price <= 0 then
    self:SetStatus("Selected auction has no valid bid price.")
    return
  end
  if GetMoney and GetMoney() < price then
    self:SetStatus("You do not have enough money for this auction.")
    return
  end
  if MAXIMUM_BID_PRICE and price > MAXIMUM_BID_PRICE then
    self:SetStatus("Selected auction exceeds the maximum bid price.")
    return
  end
  self:ShowBidConfirmation(index, result, buyout, price)
end

function addon:CompletePendingSelection()
  local result = self.pendingSelection
  self.pendingSelection = nil
  if not result then
    return
  end
  if self:SelectCurrentBrowseResult(result) then
    self:SetStatus("Selected " .. (result.name or "auction result") .. ".")
  else
    self:SetStatus("Auction result is stale. Search again before selecting it.")
  end
end

function addon:SelectResult(resultIndex)
  local result = self.results and self.results[resultIndex]
  if not result then
    return
  end
  self.selectedResultIndex = resultIndex
  self:UpdateResults()
  if result.source == "auctioneer" then
    if self:SelectCurrentBrowseResult(result) then
      return
    end
    self:LoadLiveResult(result, "Loading live auction for selection...")
    return
  end
  if result.page == nil or result.index == nil then
    self:SetStatus("Auction result has no live row. Search again before selecting it.")
    return
  end
  if result.page == self.currentAuctionPage and self:SelectCurrentBrowseResult(result) then
    return
  end
  self:LoadLiveResult(result, "Loading selected result page...")
end

addon:OnLoad()
