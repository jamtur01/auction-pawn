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
  local name, texture, count, quality, canUse, level, levelColHeader, minBid,
    minIncrement, buyoutPrice, bidAmount, highBidder, owner, saleStatus, itemId =
    GetAuctionItemInfo("list", index)
  local link = GetAuctionItemLink("list", index)
  if not name or not link then
    return nil
  end

  local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType,
    itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice =
    GetItemInfo(link)
  return {
    index = index,
    name = itemName or name,
    auctionName = name,
    link = itemLink or link,
    count = count,
    quality = itemRarity or quality,
    canUse = canUse,
    level = itemLevel or level,
    minLevel = itemMinLevel,
    levelColHeader = levelColHeader,
    minBid = minBid or 0,
    minIncrement = minIncrement or 0,
    buyoutPrice = buyoutPrice or 0,
    bidAmount = bidAmount or 0,
    highBidder = highBidder,
    owner = owner,
    saleStatus = saleStatus,
    itemId = itemId,
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

function addon:GetComparisonSlots(row)
  local slots = self:GetSlotsForEquipLoc(row.equipLoc)
  if not slots or #slots == 0 then
    return nil
  end

  local mode = #slots > 1 and "bestReplacement" or "single"
  if row.equipLoc == "INVTYPE_2HWEAPON" then
    local offhandId = GetInventorySlotInfo("SecondaryHandSlot")
    if offhandId and offhandId > 0 then
      table.insert(slots, { name = "SecondaryHandSlot", id = offhandId })
    end
    if IsSpellKnown(46917) then
      mode = "bestReplacement"
    else
      mode = "combined"
    end
  end
  return slots, mode
end

function addon:GetEquippedComparisonValue(slots, scaleName, mode)
  local value
  for _, slot in ipairs(slots) do
    if self:IsSlotEnabled(slot.name) then
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

function addon:StartScan()
end

function addon:OnAuctionItemListUpdate()
end

function addon:SelectResult()
end

addon:OnLoad()
