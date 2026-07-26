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
  head = true,
  neck = true,
  shoulder = true,
  back = true,
  chest = true,
  wrist = true,
  hands = true,
  waist = true,
  legs = true,
  feet = true,
  finger = true,
  trinket = true,
  mainHand = true,
  offHand = true,
  weapon = true,
  offhand = true,
  ranged = true,
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
    copyDefaults(self.defaults, PawnAuctionSearchDB)
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
  return {}
end

function addon:StartScan()
end

function addon:OnAuctionItemListUpdate()
end

function addon:SelectResult()
end

addon:OnLoad()
