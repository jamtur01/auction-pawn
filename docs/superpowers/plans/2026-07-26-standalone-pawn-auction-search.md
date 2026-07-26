# Standalone Pawn Auction Search Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a 3.3.5a standalone Auction House tab that uses Pawn to list auctions that are upgrades over equipped gear.

**Architecture:** Replace Auctioneer SearchUI integration with a native Blizzard Auction House integration. Keep the scoring behavior from the old plugin, but normalize native AH rows into explicit Lua tables before filtering and scoring. Verify with LuaJIT under a mocked 3.3.5a API surface.

**Tech Stack:** WoW 3.3.5a Lua 5.1 addon APIs, Pawn WotLK APIs, Blizzard AuctionUI APIs, LuaJIT offline smoke tests.

---

## File Structure

- Create `PawnAuctionSearch.toc`: 30300 addon manifest with `Pawn` dependency.
- Create `PawnAuctionSearch.xml`: loads the standalone Lua file and scan tooltip.
- Create `PawnAuctionSearch.lua`: addon namespace, saved-variable defaults, AH tab, controls, scanner, filters, Pawn scoring, and results list.
- Create `tests/mock_335.lua`: minimal 3.3.5a runtime and Pawn/AH mocks.
- Create `tests/smoke.lua`: behavior smoke tests for load, tab registration, scale discovery, and upgrade filtering.
- Create `Makefile`: syntax and smoke-test commands.
- Modify `Localization/localization.en.lua`: standalone addon strings under `PawnAuctionSearch` if localization remains useful.
- Remove `auc-advanced-searcher-pawn.toc`, `SearcherPawn.lua`, and `SearcherPawn.xml` after the standalone replacement is verified.

## Task 1: Add LuaJIT smoke harness

**Files:**
- Create: `tests/mock_335.lua`
- Create: `tests/smoke.lua`
- Create: `Makefile`

- [ ] **Step 1: Create the mocked 3.3.5a runtime**

Create `tests/mock_335.lua` with:

```lua
local mock = {}

local frames = {}
local events = {}
local auctionRows = {}
local selectedAuction = nil
local pendingQuery = nil

_G.frames = frames
_G.events = events
_G.auctionRows = auctionRows
_G.selectedAuction = selectedAuction

function mock.reset()
  for key in pairs(frames) do frames[key] = nil end
  for key in pairs(events) do events[key] = nil end
  auctionRows[1] = {
    name = "Upgrade Sword",
    texture = "Interface\\Icons\\INV_Sword_01",
    count = 1,
    quality = 3,
    canUse = true,
    level = 80,
    minBid = 10000,
    minIncrement = 100,
    buyoutPrice = 20000,
    bidAmount = 0,
    highBidder = nil,
    owner = "Seller",
    timeLeft = 2,
    link = "|cffa335ee|Hitem:50000:0:0:0:0:0:0:0|h[Upgrade Sword]|h|r",
    equipLoc = "INVTYPE_WEAPON",
    type = "Weapon",
    subType = "Swords",
    value = 120,
  }
  auctionRows[2] = {
    name = "Weak Sword",
    texture = "Interface\\Icons\\INV_Sword_02",
    count = 1,
    quality = 2,
    canUse = true,
    level = 80,
    minBid = 10000,
    minIncrement = 100,
    buyoutPrice = 20000,
    bidAmount = 0,
    highBidder = nil,
    owner = "Seller",
    timeLeft = 2,
    link = "|cff0070dd|Hitem:50001:0:0:0:0:0:0:0|h[Weak Sword]|h|r",
    equipLoc = "INVTYPE_WEAPON",
    type = "Weapon",
    subType = "Swords",
    value = 80,
  }
end

local function makeFrame(kind, name, parent)
  local frame = {
    kind = kind,
    name = name,
    parent = parent,
    children = {},
    scripts = {},
    shown = true,
    text = "",
    id = nil,
    points = {},
  }
  function frame:SetScript(script, fn) self.scripts[script] = fn end
  function frame:RegisterEvent(event) events[event] = self end
  function frame:SetPoint(...) self.points[#self.points + 1] = {...} end
  function frame:SetSize(width, height) self.width = width; self.height = height end
  function frame:SetWidth(width) self.width = width end
  function frame:SetHeight(height) self.height = height end
  function frame:SetID(id) self.id = id end
  function frame:GetID() return self.id end
  function frame:SetText(text) self.text = text end
  function frame:GetText() return self.text end
  function frame:Show() self.shown = true end
  function frame:Hide() self.shown = false end
  function frame:IsShown() return self.shown end
  function frame:Enable() self.enabled = true end
  function frame:Disable() self.enabled = false end
  function frame:SetChecked(value) self.checked = value end
  function frame:GetChecked() return self.checked end
  function frame:SetValue(value) self.value = value end
  function frame:GetValue() return self.value end
  function frame:SetNormalTexture(texture) self.normalTexture = texture end
  function frame:SetHighlightTexture(texture) self.highlightTexture = texture end
  function frame:SetPushedTexture(texture) self.pushedTexture = texture end
  function frame:SetDisabledTexture(texture) self.disabledTexture = texture end
  function frame:SetBackdrop(backdrop) self.backdrop = backdrop end
  function frame:SetBackdropColor(...) self.backdropColor = {...} end
  function frame:SetBackdropBorderColor(...) self.backdropBorderColor = {...} end
  function frame:SetFontObject(font) self.font = font end
  function frame:SetJustifyH(justify) self.justifyH = justify end
  function frame:SetVertexColor(...) self.vertexColor = {...} end
  function frame:SetTexture(texture) self.texture = texture end
  function frame:SetOwner(owner, anchor) self.owner = owner; self.anchor = anchor end
  function frame:ClearLines() self.lines = {} end
  function frame:SetHyperlink(link) self.hyperlink = link end
  function frame:NumLines() return 0 end
  frames[name] = frame
  _G[name] = frame
  return frame
end

function CreateFrame(kind, name, parent, template)
  local frame = makeFrame(kind, name, parent)
  frame.template = template
  return frame
end

UIParent = makeFrame("Frame", "UIParent")
WorldFrame = makeFrame("Frame", "WorldFrame")
AuctionFrame = makeFrame("Frame", "AuctionFrame")
AuctionFrameBrowse = makeFrame("Frame", "AuctionFrameBrowse")
AuctionFrameBid = makeFrame("Frame", "AuctionFrameBid")
AuctionFrameAuctions = makeFrame("Frame", "AuctionFrameAuctions")
AuctionFrameTab1 = makeFrame("Button", "AuctionFrameTab1"); AuctionFrameTab1:SetID(1)
AuctionFrameTab2 = makeFrame("Button", "AuctionFrameTab2"); AuctionFrameTab2:SetID(2)
AuctionFrameTab3 = makeFrame("Button", "AuctionFrameTab3"); AuctionFrameTab3:SetID(3)
DEFAULT_CHAT_FRAME = { messages = {}, AddMessage = function(self, msg) self.messages[#self.messages + 1] = msg end }

function PanelTemplates_SetNumTabs(frame, count) frame.numTabs = count end
function PanelTemplates_SetTab(frame, tab) frame.selectedTab = tab end
function PanelTemplates_TabResize(tab, padding) tab.resizePadding = padding end
function FauxScrollFrame_Update(frame, total, display, height) frame.scroll = { total, display, height } end
function FauxScrollFrame_GetOffset(frame) return frame and frame.offset or 0 end
function FauxScrollFrame_SetOffset(frame, offset) frame.offset = offset end
function MoneyFrame_Update(name, value) _G[name] = _G[name] or {}; _G[name].money = value end
function UIDropDownMenu_CreateInfo() return {} end
function UIDropDownMenu_AddButton(info) mock.lastDropdown = mock.lastDropdown or {}; mock.lastDropdown[#mock.lastDropdown + 1] = info end
function UIDropDownMenu_Initialize(frame, init) frame.init = init end
function UIDropDownMenu_SetSelectedValue(frame, value) frame.selectedValue = value end
function UIDropDownMenu_GetSelectedValue(frame) return frame.selectedValue end

function GetLocale() return "enUS" end
function RegisterCVar() end
function GetCVar() return nil end
function UnitName() return "Tester" end
function GetRealmName() return "Realm" end
function UnitClass() return "Warrior", "WARRIOR" end
function UnitLevel() return 80 end
function GetMoney() return 1000000 end
function GetInventorySlotInfo(slot)
  local slots = { MainHandSlot = 16, SecondaryHandSlot = 17 }
  return slots[slot] or 1
end
function GetInventoryItemLink(unit, slot) return "equipped:" .. tostring(slot) end
function IsEquippableItem(link) return true end
function GetSpellInfo(id) if id == 46917 then return nil end; return nil end
function tContains(tbl, value) for _, item in ipairs(tbl) do if item == value then return true end end return false end
function getglobal(name) return _G[name] end
function hooksecurefunc(object, method, fn) object["hook_" .. method] = fn end

ITEM_QUALITY_COLORS = {
  [0] = { r = 0.62, g = 0.62, b = 0.62 },
  [1] = { r = 1, g = 1, b = 1 },
  [2] = { r = 0.12, g = 1, b = 0 },
  [3] = { r = 0, g = 0.44, b = 0.87 },
  [4] = { r = 0.64, g = 0.21, b = 0.93 },
}

function CanSendAuctionQuery() return true end
function QueryAuctionItems(...) pendingQuery = {...} end
function GetNumAuctionItems() return #auctionRows, #auctionRows end
function GetAuctionItemInfo(kind, index)
  local row = auctionRows[index]
  if not row then return nil end
  return row.name, row.texture, row.count, row.quality, row.canUse, row.level,
    row.minBid, row.minIncrement, row.buyoutPrice, row.bidAmount, row.highBidder,
    row.owner
end
function GetAuctionItemLink(kind, index) return auctionRows[index] and auctionRows[index].link end
function GetAuctionItemTimeLeft(kind, index) return auctionRows[index] and auctionRows[index].timeLeft end
function SetSelectedAuctionItem(kind, index) selectedAuction = index; _G.selectedAuction = index end
function PlaceAuctionBid(kind, index, amount) mock.placedBid = { kind = kind, index = index, amount = amount } end

PawnIsInitialized = true
function PawnGetAllScalesEx()
  return { { Name = "TestScale", LocalizedName = "Test Scale", IsVisible = true } }
end
function PawnDoesScaleExist(name) return name == "TestScale" end
function PawnGetItemData(link)
  for _, row in ipairs(auctionRows) do if row.link == link then return { link = link, value = row.value } end end
  return { link = link, value = 100 }
end
function PawnGetItemDataForInventorySlot(slot) return { link = "equipped:" .. tostring(slot), value = 100 } end
function PawnGetSingleValueFromItem(item) return item.value, item.value end

mock.reset()
return mock
```

- [ ] **Step 2: Create the smoke test**

Create `tests/smoke.lua` with:

```lua
local mock = dofile("tests/mock_335.lua")

dofile("PawnAuctionSearch.lua")

local function assertEqual(actual, expected, message)
  if actual ~= expected then
    error(message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

local function assertTruthy(value, message)
  if not value then error(message, 2) end
end

assertTruthy(PawnAuctionSearch, "addon namespace exists")
assertTruthy(PawnAuctionSearch.frame, "addon frame exists")
PawnAuctionSearch:InitializeAuctionTab()
assertEqual(AuctionFrame.numTabs, 4, "auction tab count")
assertEqual(AuctionFrameTab4:GetText(), "Pawn", "auction tab label")

local scales = PawnAuctionSearch:GetScales()
assertEqual(#scales, 1, "visible Pawn scale count")
assertEqual(scales[1].name, "TestScale", "scale name")

PawnAuctionSearchDB.scaleName = "TestScale"
PawnAuctionSearch:StartScan()
PawnAuctionSearch:OnAuctionItemListUpdate()
assertEqual(#PawnAuctionSearch.results, 1, "upgrade result count")
assertEqual(PawnAuctionSearch.results[1].name, "Upgrade Sword", "upgrade result name")
assertEqual(PawnAuctionSearch.results[1].delta, 20, "upgrade delta")

PawnAuctionSearch:SelectResult(1)
assertEqual(_G.selectedAuction, 1, "selected auction index")

print("smoke ok")
```

- [ ] **Step 3: Add the Makefile**

Create `Makefile` with:

```make
LUAJIT ?= luajit

.PHONY: test syntax smoke

test: syntax smoke

syntax:
	$(LUAJIT) -bl PawnAuctionSearch.lua /dev/null
	$(LUAJIT) -bl tests/mock_335.lua /dev/null
	$(LUAJIT) -bl tests/smoke.lua /dev/null

smoke:
	$(LUAJIT) tests/smoke.lua
```

- [ ] **Step 4: Run the smoke test and confirm it fails before implementation**

Run: `make test`

Expected: fails because `PawnAuctionSearch.lua` does not exist yet.

- [ ] **Step 5: Commit the failing harness**

Run:

```bash
git add Makefile tests/mock_335.lua tests/smoke.lua
git commit -m "test: add LuaJIT smoke harness"
```

## Task 2: Add standalone addon shell

**Files:**
- Create: `PawnAuctionSearch.toc`
- Create: `PawnAuctionSearch.xml`
- Create: `PawnAuctionSearch.lua`

- [ ] **Step 1: Create the 3.3.5a manifest**

Create `PawnAuctionSearch.toc` with:

```text
## Interface: 30300
## Title: Pawn Auction Search
## Notes: Finds Auction House equipment upgrades using Pawn scales.
## Author: Xit_Draka, ShadowVall, mgotovtsev, James Turnbull
## Dependencies: Pawn
## SavedVariablesPerCharacter: PawnAuctionSearchDB
## Version: 0.1.0

Localization\Localization.xml
PawnAuctionSearch.xml
```

- [ ] **Step 2: Create the XML loader**

Create `PawnAuctionSearch.xml` with:

```xml
<Ui xmlns="http://www.blizzard.com/wow/ui/"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.blizzard.com/wow/ui/ ..\FrameXML\UI.xsd">
  <Script file="PawnAuctionSearch.lua"/>
  <GameTooltip name="PawnAuctionSearchTooltip" inherits="GameTooltipTemplate">
    <Scripts>
      <OnLoad>
        self:SetOwner(WorldFrame, "ANCHOR_NONE");
      </OnLoad>
    </Scripts>
  </GameTooltip>
</Ui>
```

- [ ] **Step 3: Create the addon namespace and defaults**

Create `PawnAuctionSearch.lua` with the initial shell:

```lua
local ADDON_NAME = "PawnAuctionSearch"
local TAB_LABEL = "Pawn"
local AUCTIONS_PER_PAGE = 50

PawnAuctionSearch = {}
local addon = PawnAuctionSearch

local defaults = {
  scaleName = nil,
  canUse = false,
  affordable = false,
  useBuyout = true,
  bestPrice = false,
  unenchanted = true,
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
  },
}

local slotCache = {}
local equipLocSlots = {
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
  INVTYPE_2HWEAPON = { "MainHandSlot", "SecondaryHandSlot" },
  INVTYPE_WEAPONMAINHAND = { "MainHandSlot" },
  INVTYPE_WEAPONOFFHAND = { "SecondaryHandSlot" },
  INVTYPE_SHIELD = { "SecondaryHandSlot" },
  INVTYPE_HOLDABLE = { "SecondaryHandSlot" },
  INVTYPE_RANGED = { "MainHandSlot" },
  INVTYPE_THROWN = { "MainHandSlot" },
  INVTYPE_RANGEDRIGHT = { "MainHandSlot" },
  INVTYPE_RELIC = { "SecondaryHandSlot" },
}

local function copyDefaults(target, source)
  for key, value in pairs(source) do
    if type(value) == "table" then
      if type(target[key]) ~= "table" then target[key] = {} end
      copyDefaults(target[key], value)
    elseif target[key] == nil then
      target[key] = value
    end
  end
end

local function chat(message)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99PawnAuctionSearch:|r " .. message)
  end
end

function addon:OnLoad()
  self.frame = CreateFrame("Frame", ADDON_NAME .. "EventFrame")
  self.frame:SetScript("OnEvent", function(_, event, arg1) self:OnEvent(event, arg1) end)
  self.frame:RegisterEvent("ADDON_LOADED")
  self.frame:RegisterEvent("AUCTION_HOUSE_SHOW")
  self.frame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
  self.results = {}
  self.scan = nil
end

function addon:OnEvent(event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
    PawnAuctionSearchDB = PawnAuctionSearchDB or {}
    copyDefaults(PawnAuctionSearchDB, defaults)
  elseif event == "AUCTION_HOUSE_SHOW" then
    self:InitializeAuctionTab()
  elseif event == "AUCTION_ITEM_LIST_UPDATE" then
    self:OnAuctionItemListUpdate()
  end
end

addon:OnLoad()
```

- [ ] **Step 4: Run syntax check**

Run: `make syntax`

Expected: `PawnAuctionSearch.lua`, `tests/mock_335.lua`, and `tests/smoke.lua` bytecode successfully.

- [ ] **Step 5: Commit addon shell**

Run:

```bash
git add PawnAuctionSearch.toc PawnAuctionSearch.xml PawnAuctionSearch.lua
git commit -m "feat: add standalone addon shell"
```

## Task 3: Implement Pawn scoring and auction normalization

**Files:**
- Modify: `PawnAuctionSearch.lua`
- Test: `tests/smoke.lua`

- [ ] **Step 1: Extend the smoke assertions**

Keep the existing `tests/smoke.lua` assertions from Task 1. They already verify scale loading, upgrade inclusion, downgrade exclusion, and selected result behavior.

- [ ] **Step 2: Add Pawn scale helpers**

Append to `PawnAuctionSearch.lua`:

```lua
function addon:GetScales()
  local scales = {}
  if type(PawnGetAllScalesEx) ~= "function" then return scales end
  local pawnScales = PawnGetAllScalesEx() or {}
  for _, scale in ipairs(pawnScales) do
    if scale.IsVisible then
      scales[#scales + 1] = {
        name = scale.Name,
        label = scale.LocalizedName or scale.Name,
      }
    end
  end
  return scales
end

function addon:ValidateScale()
  local scaleName = PawnAuctionSearchDB and PawnAuctionSearchDB.scaleName
  if not scaleName or scaleName == "" then return false, "Select a Pawn scale." end
  if type(PawnDoesScaleExist) ~= "function" then return false, "Pawn is not ready." end
  if not PawnDoesScaleExist(scaleName) then return false, "Selected Pawn scale is missing." end
  return true, scaleName
end
```

- [ ] **Step 3: Add auction normalization**

Append to `PawnAuctionSearch.lua`:

```lua
local function getItemEquipLoc(link)
  local _, _, _, _, _, itemType, itemSubType, _, equipLoc = GetItemInfo(link)
  return itemType, itemSubType, equipLoc
end

function addon:ReadAuctionRow(index)
  local name, texture, count, quality, canUse, level, minBid, minIncrement,
    buyoutPrice, bidAmount, highBidder, owner = GetAuctionItemInfo("list", index)
  if not name then return nil end
  local link = GetAuctionItemLink("list", index)
  if not link then return nil end
  local itemType, itemSubType, equipLoc = getItemEquipLoc(link)
  return {
    index = index,
    name = name,
    texture = texture,
    count = count or 1,
    quality = quality or 1,
    canUse = canUse,
    level = level or 0,
    minBid = minBid or 0,
    minIncrement = minIncrement or 0,
    buyoutPrice = buyoutPrice or 0,
    bidAmount = bidAmount or 0,
    highBidder = highBidder,
    owner = owner,
    timeLeft = GetAuctionItemTimeLeft("list", index),
    link = link,
    itemType = itemType,
    itemSubType = itemSubType,
    equipLoc = equipLoc,
  }
end
```

- [ ] **Step 4: Add slot and value helpers**

Append to `PawnAuctionSearch.lua`:

```lua
local function getSlotId(slotName)
  if not slotCache[slotName] then
    slotCache[slotName] = GetInventorySlotInfo(slotName)
  end
  return slotCache[slotName]
end

local function getCandidateSlots(equipLoc)
  local names = equipLocSlots[equipLoc]
  if not names then return nil end
  local slots = {}
  for _, slotName in ipairs(names) do
    if PawnAuctionSearchDB.slots[slotName] then
      slots[#slots + 1] = getSlotId(slotName)
    end
  end
  if #slots == 0 then return nil end
  return slots
end

function addon:GetPawnValueForLink(link, scaleName)
  local item = PawnGetItemData(link)
  if not item then return nil end
  local value, unenchantedValue = PawnGetSingleValueFromItem(item, scaleName)
  if PawnAuctionSearchDB.unenchanted and unenchantedValue then return unenchantedValue end
  return value or unenchantedValue or 0
end

function addon:GetPawnValueForEquipped(slot, scaleName)
  local item = PawnGetItemDataForInventorySlot(slot, PawnAuctionSearchDB.unenchanted, "player")
  if not item then return 0 end
  local value, unenchantedValue = PawnGetSingleValueFromItem(item, scaleName)
  if PawnAuctionSearchDB.unenchanted and unenchantedValue then return unenchantedValue end
  return value or unenchantedValue or 0
end
```

- [ ] **Step 5: Add filtering and scoring**

Append to `PawnAuctionSearch.lua`:

```lua
function addon:IsAffordable(row)
  if not PawnAuctionSearchDB.affordable then return true end
  local price = row.minBid
  if PawnAuctionSearchDB.useBuyout then price = row.buyoutPrice end
  return price and price > 0 and GetMoney() >= price
end

function addon:ScoreAuction(row, scaleName)
  if PawnAuctionSearchDB.canUse and not row.canUse then return nil end
  if not self:IsAffordable(row) then return nil end
  if not row.equipLoc or not IsEquippableItem(row.link) then return nil end
  local slots = getCandidateSlots(row.equipLoc)
  if not slots then return nil end
  local candidateValue = self:GetPawnValueForLink(row.link, scaleName)
  if not candidateValue then return nil end
  local bestDelta = nil
  for _, slot in ipairs(slots) do
    local equippedValue = self:GetPawnValueForEquipped(slot, scaleName)
    local delta = candidateValue - equippedValue
    if delta > 0 and (not bestDelta or delta > bestDelta) then bestDelta = delta end
  end
  if not bestDelta then return nil end
  row.delta = bestDelta
  row.score = bestDelta
  if PawnAuctionSearchDB.bestPrice then
    local price = PawnAuctionSearchDB.useBuyout and row.buyoutPrice or row.minBid
    if price and price > 0 then row.score = (10000 * bestDelta) / price end
  end
  return row
end
```

- [ ] **Step 6: Patch the test mock for `GetItemInfo`**

Add this function to `tests/mock_335.lua` after `GetAuctionItemTimeLeft`:

```lua
function GetItemInfo(link)
  for _, row in ipairs(auctionRows) do
    if row.link == link then
      return row.name, row.link, row.quality, row.level, 80, row.type, row.subType,
        1, row.equipLoc
    end
  end
  return nil
end
```

- [ ] **Step 7: Run smoke test**

Run: `make test`

Expected: fails until scanner methods from Task 4 are added; syntax must pass.

- [ ] **Step 8: Commit scoring helpers**

Run:

```bash
git add PawnAuctionSearch.lua tests/mock_335.lua tests/smoke.lua
git commit -m "feat: add Pawn auction scoring"
```

## Task 4: Implement native Auction House tab and scanner

**Files:**
- Modify: `PawnAuctionSearch.lua`
- Test: `tests/smoke.lua`

- [ ] **Step 1: Add tab creation**

Append to `PawnAuctionSearch.lua`:

```lua
function addon:InitializeAuctionTab()
  if self.tabInitialized or not AuctionFrame then return end
  local tab = CreateFrame("Button", "AuctionFrameTab4", AuctionFrame, "AuctionTabTemplate")
  tab:SetID(4)
  tab:SetText(TAB_LABEL)
  tab:SetPoint("TOPLEFT", AuctionFrameTab3, "TOPRIGHT", -8, 0)
  PanelTemplates_TabResize(tab, 0)
  tab:SetScript("OnClick", function(button) addon:SelectAuctionTab(button:GetID()) end)
  self.tab = tab
  PanelTemplates_SetNumTabs(AuctionFrame, 4)
  self:CreateMainFrame()
  self.tabInitialized = true
end

function addon:SelectAuctionTab(index)
  if index ~= 4 then return end
  PanelTemplates_SetTab(AuctionFrame, 4)
  AuctionFrameBrowse:Hide()
  AuctionFrameBid:Hide()
  AuctionFrameAuctions:Hide()
  self.mainFrame:Show()
  AuctionFrame.type = "list"
end
```

- [ ] **Step 2: Add main frame and status controls**

Append to `PawnAuctionSearch.lua`:

```lua
function addon:CreateMainFrame()
  local frame = CreateFrame("Frame", "PawnAuctionSearchFrame", AuctionFrame)
  frame:SetPoint("TOPLEFT", AuctionFrame, "TOPLEFT", 20, -70)
  frame:SetSize(720, 360)
  frame:Hide()

  local status = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  status:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
  status:SetText("Select a Pawn scale, then search for upgrades.")
  frame.status = status

  local search = CreateFrame("Button", "PawnAuctionSearchButton", frame, "UIPanelButtonTemplate")
  search:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -10)
  search:SetSize(120, 22)
  search:SetText("Search")
  search:SetScript("OnClick", function() addon:StartScan() end)
  frame.search = search

  self.mainFrame = frame
  self:CreateResults(frame)
end
```

- [ ] **Step 3: Add result frame creation**

Append to `PawnAuctionSearch.lua`:

```lua
function addon:CreateResults(parent)
  self.resultRows = {}
  for i = 1, 10 do
    local row = CreateFrame("Button", "PawnAuctionSearchResult" .. i, parent)
    row:SetSize(680, 20)
    if i == 1 then
      row:SetPoint("TOPLEFT", parent.search, "BOTTOMLEFT", 0, -20)
    else
      row:SetPoint("TOPLEFT", self.resultRows[i - 1], "BOTTOMLEFT", 0, -2)
    end
    row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", row, "LEFT", 0, 0)
    row:SetScript("OnClick", function(button) addon:SelectResult(button.resultIndex) end)
    self.resultRows[i] = row
  end
end
```

- [ ] **Step 4: Add scan lifecycle**

Append to `PawnAuctionSearch.lua`:

```lua
function addon:StartScan()
  local ok, scaleOrError = self:ValidateScale()
  if not ok then
    self:SetStatus(scaleOrError)
    chat(scaleOrError)
    return
  end
  self.results = {}
  self.scan = { scaleName = scaleOrError, page = 0, active = true }
  self:SetStatus("Searching current Auction House page...")
  if CanSendAuctionQuery("list") then
    QueryAuctionItems("", "", "", nil, nil, nil, self.scan.page, false, -1)
  else
    self:SetStatus("Auction query is throttled. Try again shortly.")
  end
end

function addon:OnAuctionItemListUpdate()
  if not self.scan or not self.scan.active then return end
  local numBatchAuctions = GetNumAuctionItems("list")
  for index = 1, numBatchAuctions do
    local row = self:ReadAuctionRow(index)
    if row then
      local scored = self:ScoreAuction(row, self.scan.scaleName)
      if scored then self.results[#self.results + 1] = scored end
    end
  end
  self.scan.active = false
  self:SetStatus("Found " .. tostring(#self.results) .. " upgrades on this page.")
  self:UpdateResults()
end

function addon:SetStatus(message)
  if self.mainFrame and self.mainFrame.status then self.mainFrame.status:SetText(message) end
end
```

- [ ] **Step 5: Add result rendering and selection**

Append to `PawnAuctionSearch.lua`:

```lua
function addon:UpdateResults()
  if not self.resultRows then return end
  for i, button in ipairs(self.resultRows) do
    local result = self.results[i]
    if result then
      button.resultIndex = i
      local buyout = result.buyoutPrice or 0
      button.text:SetText(result.link .. "  +" .. string.format("%.2f", result.delta) ..
        "  Buyout: " .. tostring(buyout))
      button:Show()
    else
      button.resultIndex = nil
      button.text:SetText("")
      button:Hide()
    end
  end
end

function addon:SelectResult(resultIndex)
  local result = self.results[resultIndex]
  if not result then return end
  SetSelectedAuctionItem("list", result.index)
end
```

- [ ] **Step 6: Run the smoke test**

Run: `make test`

Expected: `smoke ok`.

- [ ] **Step 7: Commit native AH tab and scanner**

Run:

```bash
git add PawnAuctionSearch.lua tests/smoke.lua
git commit -m "feat: add native auction tab scanner"
```

## Task 5: Remove Auctioneer plugin artifacts and verify package

**Files:**
- Remove: `auc-advanced-searcher-pawn.toc`
- Remove: `SearcherPawn.lua`
- Remove: `SearcherPawn.xml`
- Modify: `docs/superpowers/specs/2026-07-26-standalone-pawn-auction-search-design.md` only if implementation intentionally differs from the spec.

- [ ] **Step 1: Remove old Auctioneer files**

Run:

```bash
git rm auc-advanced-searcher-pawn.toc SearcherPawn.lua SearcherPawn.xml
```

- [ ] **Step 2: Run verification**

Run: `make test`

Expected: `smoke ok` and all LuaJIT bytecode checks pass.

- [ ] **Step 3: Check worktree status**

Run: `git status --short`

Expected: only the three removed files staged.

- [ ] **Step 4: Commit cleanup**

Run:

```bash
git commit -m "refactor: remove Auctioneer plugin files"
```

## Task 6: Final review and push

**Files:**
- No expected file changes unless review finds issues.

- [ ] **Step 1: Run final verification**

Run: `make test`

Expected: `smoke ok`.

- [ ] **Step 2: Confirm branch name**

Run: `git branch --show-current`

Expected: `main`.

- [ ] **Step 3: Request code review**

Dispatch a code reviewer with:

- Base SHA: commit before Task 1.
- Head SHA: current HEAD.
- Requirements: native AH tab, 30300 standalone, Pawn dependency only, no Auctioneer shim, smoke test.

- [ ] **Step 4: Fix review findings**

If the reviewer reports Critical or Important findings, fix them, run `make test`, and commit the fix with a focused message.

- [ ] **Step 5: Push to target repo**

Run:

```bash
git push origin main
```

Expected: branch `main` updates on `https://github.com/jamtur01/auction-pawn.git`.
