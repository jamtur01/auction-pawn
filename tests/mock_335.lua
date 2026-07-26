local mock = {}

local function wipe_table(t)
  for key in pairs(t) do
    t[key] = nil
  end
end

mock.frames = {}
mock.events = {}
mock.auctions = {}
mock.cvars = {}
mock.money = 1000000

local Frame = {}
Frame.__index = Frame

function Frame:SetScript(script, handler)
  self.scripts[script] = handler
end

function Frame:RegisterEvent(event)
  self.events[event] = true
  mock.events[event] = mock.events[event] or {}
  mock.events[event][self] = true
end

function Frame:SetPoint(...)
  self.point = {...}
end

function Frame:SetSize(width, height)
  self.width = width
  self.height = height
end

function Frame:SetWidth(width)
  self.width = width
end

function Frame:SetHeight(height)
  self.height = height
end

function Frame:SetID(id)
  self.id = id
end

function Frame:GetID()
  return self.id
end

function Frame:SetText(text)
  self.text = text
end

function Frame:GetText()
  return self.text
end

function Frame:Show()
  self.shown = true
end

function Frame:Hide()
  self.shown = false
end

function Frame:IsShown()
  return self.shown
end

function Frame:Enable()
  self.enabled = true
end

function Frame:Disable()
  self.enabled = false
end

function Frame:SetChecked(checked)
  self.checked = checked and true or false
end

function Frame:GetChecked()
  return self.checked
end

function Frame:SetValue(value)
  self.value = value
end

function Frame:GetValue()
  return self.value
end
function Frame:SetAllPoints(frame)
  self.allPoints = frame
end


function Frame:SetOwner(owner, anchor)
  self.owner = owner
  self.anchor = anchor
end

function Frame:ClearLines()
  self.lines = {}
end

function Frame:SetHyperlink(link)
  self.hyperlink = link
  self.lines = {link}
end

function Frame:NumLines()
  return #(self.lines or {})
end

function Frame:AddLine(line)
  self.lines = self.lines or {}
  table.insert(self.lines, line)
end

function Frame:SetAuctionItem(listType, index)
  self.auctionItem = {listType = listType, index = index}
  self.lines = {"auction:" .. tostring(index)}
end

function Frame:SetTexture(texture)
  self.texture = texture
end
function Frame:SetVertexColor(red, green, blue, alpha)
  self.vertexColor = {red, green, blue, alpha}
end


function Frame:SetNormalTexture(texture)
  self.normalTexture = texture
end

function Frame:SetHighlightTexture(texture)
  self.highlightTexture = texture
end

function Frame:SetPushedTexture(texture)
  self.pushedTexture = texture
end

function Frame:SetDisabledTexture(texture)
  self.disabledTexture = texture
end

function Frame:SetBackdrop(backdrop)
  self.backdrop = backdrop
end

function Frame:SetBackdropColor(...)
  self.backdropColor = {...}
end

function Frame:SetBackdropBorderColor(...)
  self.backdropBorderColor = {...}
end

function Frame:SetFont(...)
  self.font = {...}
end

function Frame:SetFontObject(fontObject)
  self.fontObject = fontObject
end

function Frame:SetTextColor(...)
  self.textColor = {...}
end

function Frame:SetVertexColor(...)
  self.vertexColor = {...}
end

function Frame:SetTexCoord(...)
  self.texCoord = {...}
end

function Frame:SetBlendMode(blendMode)
  self.blendMode = blendMode
end

function Frame:SetNormalFontObject(fontObject)
  self.normalFontObject = fontObject
end

function Frame:SetHighlightFontObject(fontObject)
  self.highlightFontObject = fontObject
end

function Frame:SetDisabledFontObject(fontObject)
  self.disabledFontObject = fontObject
end

function Frame:SetAllPoints(target)
  self.allPoints = target or true
end

function Frame:SetFrameStrata(strata)
  self.frameStrata = strata
end

function Frame:SetFrameLevel(level)
  self.frameLevel = level
end

function Frame:EnableMouse(enabled)
  self.mouseEnabled = enabled
end

function Frame:RegisterForClicks(...)
  self.clicks = {...}
end

function Frame:LockHighlight()
  self.highlightLocked = true
end

function Frame:UnlockHighlight()
  self.highlightLocked = false
end

function Frame:CreateTexture(name)
  return mock.create_frame("Texture", name, self)
end

function Frame:CreateFontString(name)
  return mock.create_frame("FontString", name, self)
end

function Frame:GetName()
  return self.name
end

function Frame:SetParent(parent)
  self.parent = parent
end

function mock.create_frame(frameType, name, parent, template)
  local frame = setmetatable({
    type = frameType,
    name = name,
    parent = parent,
    template = template,
    scripts = {},
    events = {},
    shown = true,
    enabled = true,
    id = 0,
    text = "",
    lines = {},
  }, Frame)
  table.insert(mock.frames, frame)
  if name then
    _G[name] = frame
    if template == "AuctionTabTemplate" then
      _G[name .. "Left"] = mock.create_frame("Texture", name .. "Left", frame)
      _G[name .. "Middle"] = mock.create_frame("Texture", name .. "Middle", frame)
      _G[name .. "Right"] = mock.create_frame("Texture", name .. "Right", frame)
      _G[name .. "Text"] = mock.create_frame("FontString", name .. "Text", frame)
    end
    if template == "FauxScrollFrameTemplate" then
      _G[name .. "ScrollBar"] = mock.create_frame("Slider", name .. "ScrollBar", frame)
    end
    if template == "UICheckButtonTemplate" then
      _G[name .. "Text"] = mock.create_frame("FontString", name .. "Text", frame)
    end
  end
  return frame
end

function CreateFrame(frameType, name, parent, template)
  return mock.create_frame(frameType, name, parent, template)
end

function mock.fire(event, ...)
  local frames = mock.events[event]
  if not frames then
    return
  end
  for frame in pairs(frames) do
    local handler = frame.scripts.OnEvent
    if handler then
      handler(frame, event, ...)
    end
  end
end

function PanelTemplates_SetNumTabs(frame, numTabs)
  frame.numTabs = numTabs
end

function PanelTemplates_SetTab(frame, selectedTab)
  frame.selectedTab = selectedTab
end

function PanelTemplates_EnableTab(frame, tab)
  frame.disabledTabs = frame.disabledTabs or {}
  frame.disabledTabs[tab] = nil
end

function PanelTemplates_DisableTab(frame, tab)
  frame.disabledTabs = frame.disabledTabs or {}
  frame.disabledTabs[tab] = true
end

function AuctionFrameTab_OnClick(frame)
  if frame and frame:GetID() then
    PanelTemplates_SetTab(AuctionFrame, frame:GetID())
  end
end

function PanelTemplates_TabResize(frame, padding)
  local name = frame and frame:GetName()
  if name and string.find(name, "^AuctionFrameTab") then
    assert(_G[name .. "Left"], name .. "Left missing")
    assert(_G[name .. "Middle"], name .. "Middle missing")
    assert(_G[name .. "Text"], name .. "Text missing")
  end
  frame.tabPadding = padding
end

function FauxScrollFrame_Update(frame, numItems, numToDisplay, valueStep)
  frame.numItems = numItems
  frame.numToDisplay = numToDisplay
  frame.valueStep = valueStep
end

function FauxScrollFrame_GetOffset(frame)
  return frame.offset or 0
end

function FauxScrollFrame_SetOffset(frame, offset)
  frame.offset = offset
end

function UIDropDownMenu_CreateInfo()
  return {}
end

function UIDropDownMenu_Initialize(frame, initialize)
  frame.initialize = initialize
  if initialize then
    initialize(frame)
  end
end

function UIDropDownMenu_AddButton(info, level)
  table.insert(mock.dropdownButtons, {info = info, level = level})
end

function UIDropDownMenu_SetSelectedValue(frame, value)
  frame.selectedValue = value
end

function UIDropDownMenu_GetSelectedValue(frame)
  return frame.selectedValue
end

function UIDropDownMenu_SetSelectedName(frame, name)
  frame.selectedName = name
end

function UIDropDownMenu_GetSelectedName(frame)
  return frame.selectedName
end

function UIDropDownMenu_SetText(frame, text)
  frame.text = text
end

function UIDropDownMenu_SetWidth(frame, width)
  frame.width = width
end

function CloseDropDownMenus()
  mock.dropdownsClosed = true
end

function MoneyInputFrame_SetCopper(frame, amount)
  frame.money = amount
end

function MoneyInputFrame_GetCopper(frame)
  return frame.money or 0
end

function MoneyInputFrame_ResetMoney(frame)
  frame.money = 0
end

function StaticPopup_Show(name)
  mock.staticPopupName = name
end

function FauxScrollFrame_OnVerticalScroll(frame, value, itemHeight, updateFunction)
  local scrollBar = _G[frame:GetName() .. "ScrollBar"]
  if scrollBar then
    scrollBar:SetValue(value)
  end
  frame.offset = math.floor((value / itemHeight) + 0.5)
  if updateFunction then
    updateFunction(frame)
  end
end
function IsShiftKeyDown()
  return mock.shiftKeyDown
end

function IsAltKeyDown()
  return mock.altKeyDown
end

function ChatEdit_InsertLink(link)
  mock.insertedLink = link
end

function SetAuctionsTabShowing(shown)
  mock.auctionsTabShowing = shown
end

function HideUIPanel(frame)
  mock.hiddenPanel = frame
  if frame then
    frame:Hide()
  end
end


function MoneyFrame_Update(frameName, amount)
  local frame = type(frameName) == "table" and frameName or _G[frameName]
  if frame then
    frame.money = amount
  end
end

function GetLocale()
  return "enUS"
end

function RegisterCVar(name, value)
  if mock.cvars[name] == nil then
    mock.cvars[name] = value
  end
end

function GetCVar(name)
  return mock.cvars[name]
end

function UnitName(unit)
  if unit == "player" then
    return "Tester"
  end
  return unit
end

function GetRealmName()
  return "MockRealm"
end

function UnitClass(unit)
  return "Warrior", "WARRIOR"
end

function UnitLevel(unit)
  return 80
end

function GetMoney()
  return mock.money
end

function GetInventorySlotInfo(slotName)
  if slotName == "MainHandSlot" then
    return 16, nil
  end
  if slotName == "SecondaryHandSlot" then
    return 17, nil
  end
  if slotName == "ChestSlot" then
    return 5, nil
  end
  return 0, nil
end

local function inventory_link(itemId, name)
  return "|cff1eff00|Hitem:" .. itemId .. ":0:0:0:0:0:0:0|h[" .. name .. "]|h|r"
end

function GetInventoryItemLink(unit, slotId)
  if unit == "player" and slotId == 16 then
    local itemId = mock.mainHandItemId or 9001
    return inventory_link(itemId, itemId == 9002 and "Equipped Axe" or "Equipped Sword")
  end
  if unit == "player" and slotId == 17 and mock.offHandItemId then
    return inventory_link(mock.offHandItemId, "Equipped Offhand")
  end
  if unit == "player" and slotId == 5 then
    return inventory_link(9003, "Equipped Chest")
  end
  return nil
end

function IsEquippableItem(item)
  return item ~= nil
end

function GetSpellInfo(spell)
  return "Mock Spell", nil, nil
end

function IsSpellKnown(spell)
  return mock.knownSpells and mock.knownSpells[spell] or false
end

function tContains(t, item)
  for _, value in pairs(t) do
    if value == item then
      return true
    end
  end
  return false
end

function getglobal(name)
  return _G[name]
end

function hooksecurefunc(target, method, hook)
  if type(target) == "table" then
    local original = target[method]
    target[method] = function(...)
      local results = {original(...)}
      hook(...)
      return unpack(results)
    end
  else
    local original = _G[target]
    _G[target] = function(...)
      local results = {original(...)}
      method(...)
      return unpack(results)
    end
  end
end

local function auction_link(itemId, name)
  return "|cff1eff00|Hitem:" .. itemId .. ":0:0:0:0:0:0:0|h[" .. name .. "]|h|r"
end

function CanSendAuctionQuery()
  return mock.canQuery ~= false, mock.canQueryAll == true
end

function QueryAuctionItems(...)
  mock.lastAuctionQuery = {...}
  mock.fastScan = select(10, ...) == true
  mock.currentPage = mock.fastScan and 0 or (select(7, ...) or 0)
end

local function currentAuction(index)
  if mock.fastScan then
    return mock.auctions[index]
  end
  return mock.auctions[((mock.currentPage or 0) * 50) + index]
end

function GetNumAuctionItems(listType)
  local total = #mock.auctions
  if mock.fastScan and not mock.forcePagedListUpdate then
    return total, total
  end
  local remaining = total - ((mock.currentPage or 0) * 50)
  if remaining < 0 then
    remaining = 0
  end
  local count = remaining > 50 and 50 or remaining
  return count, total
end

function GetAuctionItemInfo(listType, index)
  local row = currentAuction(index)
  if not row then
    return nil
  end
  return row.name, nil, 1, row.quality, row.canUse ~= false, row.level, row.minBid,
    row.minIncrement, row.buyoutPrice, row.bidAmount, nil, row.owner
end

function GetAuctionItemLink(listType, index)
  local row = currentAuction(index)
  if not row then
    return nil
  end
  return row.link
end

function GetAuctionItemTimeLeft(listType, index)
  local row = currentAuction(index)
  return row and row.timeLeft or nil
end

function SetSelectedAuctionItem(listType, index)
  _G.selectedAuction = index
  mock.selectedAuctionList = listType
end

function PlaceAuctionBid(listType, index, bid)
  mock.placedBid = {listType = listType, index = index, bid = bid}

end

function GetItemInfo(item)
  local itemId = tostring(item):match("item:(%d+)") or tostring(item)
  local items = {
    ["1001"] = { "Upgrade Sword", "Weapon", "Sword", "INVTYPE_WEAPON" },
    ["1002"] = { "Downgrade Sword", "Weapon", "Sword", "INVTYPE_WEAPON" },
    ["1003"] = { "Offhand Dagger", "Weapon", "Dagger", "INVTYPE_WEAPONOFFHAND" },
    ["1004"] = { "Plate Upgrade", "Armor", "Plate", "INVTYPE_CHEST" },
    ["1005"] = { "Cloth Upgrade", "Armor", "Cloth", "INVTYPE_CHEST" },
    ["9001"] = { "Equipped Sword", "Weapon", "Sword", "INVTYPE_WEAPON" },
    ["9002"] = { "Equipped Axe", "Weapon", "Two-Handed Axe", "INVTYPE_2HWEAPON" },
    ["9003"] = { "Equipped Chest", "Armor", "Plate", "INVTYPE_CHEST" },
  }
  local info = items[itemId]
  if not info then
    return nil
  end
  return info[1], auction_link(itemId, info[1]), 2, 80, 80, info[2], info[3], 1,
    info[4], nil, 10000
end

function PawnIsInitialized()
  return true
end

function PawnGetAllScalesEx()
  return {
    {
      Name = "TestScale",
      LocalizedName = "TestScale",
      PerCharacterOptions = {Visible = true},
    },
  }
end

function PawnDoesScaleExist(scaleName)
  return scaleName == "TestScale"
end

function PawnGetItemData(item)
  return {ID = tostring(item):match("item:(%d+)") or tostring(item), Link = item}
end

function PawnGetItemDataForInventorySlot(slotId)
  local link = GetInventoryItemLink("player", slotId)
  if not link then
    return nil
  end
  return PawnGetItemData(link)
end

function PawnGetSingleValueFromItem(item, scaleName)
  local itemId
  if type(item) == "table" then
    itemId = item.ID
  else
    itemId = tostring(item):match("item:(%d+)") or tostring(item)
  end
  local values = {
    ["1001"] = 120,
    ["1002"] = 80,
    ["1003"] = 300,
    ["1004"] = 150,
    ["1005"] = 160,
    ["9001"] = 100,
    ["9002"] = 200,
    ["9003"] = 100,
  }
  return values[itemId] or 0
end

function DEFAULT_CHAT_FRAME_AddMessage(frame, message)
  table.insert(mock.chatMessages, message)
end

function mock.reset()
  for _, frame in ipairs(mock.frames) do
    if frame.name then
      _G[frame.name] = nil
    end
  end
  wipe_table(mock.events)
  wipe_table(mock.cvars)
  wipe_table(mock.auctions)
  wipe_table(mock.frames)
  mock.dropdownButtons = {}
  mock.chatMessages = {}
  mock.dropdownsClosed = false
  mock.lastAuctionQuery = nil
  mock.currentPage = 0
  mock.canQuery = true
  mock.canQueryAll = false
  mock.fastScan = false
  mock.forcePagedListUpdate = false
  mock.money = 1000000
  mock.placedBid = nil
  mock.mainHandItemId = 9001
  mock.offHandItemId = nil
  mock.knownSpells = {}
  mock.shiftKeyDown = false
  mock.altKeyDown = false
  mock.insertedLink = nil
  mock.auctionsTabShowing = nil
  mock.staticPopupName = nil
  mock.selectedAuctionList = nil
  _G.selectedAuction = nil

  mock.auctions[1] = {
    name = "Upgrade Sword",
    itemId = 1001,
    link = auction_link(1001, "Upgrade Sword"),
    quality = 2,
    level = 80,
    minBid = 10000,
    minIncrement = 100,
    buyoutPrice = 20000,
    bidAmount = 0,
    owner = "SellerOne",
    timeLeft = 2,
  }
  mock.auctions[2] = {
    name = "Downgrade Sword",
    itemId = 1002,
    link = auction_link(1002, "Downgrade Sword"),
    quality = 2,
    level = 80,
    minBid = 10000,
    minIncrement = 100,
    buyoutPrice = 20000,
    bidAmount = 0,
    owner = "SellerTwo",
    timeLeft = 2,
  }

  UIParent = mock.create_frame("Frame", "UIParent", nil)
  WorldFrame = mock.create_frame("Frame", "WorldFrame", nil)
  AuctionFrame = mock.create_frame("Frame", "AuctionFrame", UIParent)
  AuctionFrameBrowse = mock.create_frame("Frame", "AuctionFrameBrowse", AuctionFrame)
  AuctionFrameBid = mock.create_frame("Frame", "AuctionFrameBid", AuctionFrame)
  AuctionFrameAuctions = mock.create_frame("Frame", "AuctionFrameAuctions", AuctionFrame)
  AuctionFrameMoneyFrame = mock.create_frame("Frame", "AuctionFrameMoneyFrame", AuctionFrame)
  AuctionFrameCloseButton = mock.create_frame("Button", "AuctionFrameCloseButton", AuctionFrame)
  BrowseCloseButton = mock.create_frame("Button", "BrowseCloseButton", AuctionFrameBrowse)
  BrowseCloseButton:SetSize(80, 22)
  AuctionFrameTab1 = mock.create_frame("Button", "AuctionFrameTab1", AuctionFrame)
  AuctionFrameTab2 = mock.create_frame("Button", "AuctionFrameTab2", AuctionFrame)
  AuctionFrameTab3 = mock.create_frame("Button", "AuctionFrameTab3", AuctionFrame)
  AuctionFrame.numTabs = 3
  AuctionFrameTab1:SetText("Browse")
  AuctionFrameTab2:SetText("Bids")
  AuctionFrameTab3:SetText("Auctions")
  BrowseBidPrice = mock.create_frame("Frame", "BrowseBidPrice", AuctionFrameBrowse)
  GameTooltip = mock.create_frame("GameTooltip", "GameTooltip", UIParent)
  DEFAULT_CHAT_FRAME = mock.create_frame("Frame", "DEFAULT_CHAT_FRAME", UIParent)
  DEFAULT_CHAT_FRAME.AddMessage = DEFAULT_CHAT_FRAME_AddMessage
end

mock.reset()

return mock
