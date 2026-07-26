local mock = dofile("tests/mock_335.lua")

local function fail(message)
  error(message, 2)
end

local function assert_equals(actual, expected, message)
  if actual ~= expected then
    fail(message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
  end
end

local function assert_truthy(value, message)
  if not value then
    fail(message)
  end
  return value
end

local function first_value(value)
  if type(value) ~= "table" then
    return value
  end
  if value[1] ~= nil then
    if type(value[1]) == "table" then
      return value[1].Name or value[1].LocalizedName or value[1].name
    end
    return value[1]
  end
  if value.TestScale then
    return "TestScale"
  end
  return value.Name or value.LocalizedName or value.name
end

local function count_values(value)
  if type(value) ~= "table" then
    return value and 1 or 0
  end
  local count = 0
  for _ in pairs(value) do
    count = count + 1
  end
  return count
end

local function find_slot_control(addon, label)
  for _, control in ipairs(addon.slotControls or {}) do
    if control.labelText and control.labelText:GetText() == label then
      return control
    end
  end
  fail("slot control missing: " .. label)
end


local function discover_scales(addon)
  if addon.DiscoverScales then
    return addon:DiscoverScales()
  end
  if addon.GetAvailableScales then
    return addon:GetAvailableScales()
  end
  if addon.GetScales then
    return addon:GetScales()
  end
  fail("PawnAuctionSearch has no scale discovery method")
end

local function start_scan(addon)
  if addon.StartScan then
    addon:StartScan()
    return
  end
  if addon.Scan then
    addon:Scan()
    return
  end
  fail("PawnAuctionSearch has no scan method")
end

local function fire_auction_update(addon)
  if addon.OnAuctionItemListUpdate then
    addon:OnAuctionItemListUpdate()
    return
  end
  mock.fire("AUCTION_ITEM_LIST_UPDATE")
end

local function get_results(addon)
  return addon.results or addon.Results or addon.searchResults or addon.search_results
end

local function result_name(result)
  if type(result) ~= "table" then
    return result
  end
  return result.name or result.itemName or result.item_name or result[1]
end

local function result_delta(result)
  if type(result) ~= "table" then
    return nil
  end
  return result.delta or result.Delta or result.valueDelta or result.value_delta or result[2]
end

local addon_chunk, load_error = loadfile("PawnAuctionSearch.lua")
assert_truthy(addon_chunk, load_error)()
assert_truthy(PawnAuctionSearch, "PawnAuctionSearch exists")
assert_truthy(
  PawnAuctionSearch.frame or PawnAuctionSearch.Frame or PawnAuctionSearch.eventFrame
    or PawnAuctionSearch.auctionFrame,
  "PawnAuctionSearch frame exists"
)

PawnAuctionSearch:InitializeAuctionTab()
assert_equals(AuctionFrame.numTabs, 4, "AuctionFrame tab count")
assert_truthy(AuctionFrameTab4, "AuctionFrameTab4 exists")
assert_equals(AuctionFrameTab4:GetText(), "Pawn", "Pawn tab text")
PawnAuctionSearch:SelectAuctionTab(4)
assert_truthy(PawnAuctionSearch.mainFrame:IsShown(), "Pawn frame shown after selecting tab")
AuctionFrameTab_OnClick(AuctionFrameTab1)
assert_equals(PawnAuctionSearch.mainFrame:IsShown(), false, "Pawn frame hidden on Browse tab")


local scales = discover_scales(PawnAuctionSearch)
assert_equals(count_values(scales), 1, "scale count")
assert_equals(first_value(scales), "TestScale", "scale name")
assert_equals(
  PawnAuctionSearch.scaleDropDown.width,
  PawnAuctionSearch.SCALE_DROPDOWN_WIDTH,
  "scale dropdown width"
)
assert_equals(#PawnAuctionSearch.slotControls, #PawnAuctionSearch.slotFilters, "slot control count")
assert_equals(PawnAuctionSearch.resultRows[1].width, PawnAuctionSearch.RESULT_ROW_WIDTH, "result width")

local fingerControl = find_slot_control(PawnAuctionSearch, "Finger")
fingerControl:SetChecked(false)
fingerControl.scripts.OnClick(fingerControl)
assert_equals(PawnAuctionSearchDB.slots.Finger0Slot, false, "finger 0 disabled")
assert_equals(PawnAuctionSearchDB.slots.Finger1Slot, false, "finger 1 disabled")
assert_equals(
  PawnAuctionSearch:ScoreAuction({
    link = "|cff1eff00|Hitem:1001:0:0:0:0:0:0:0|h[Upgrade Ring]|h|r",
    equipLoc = "INVTYPE_FINGER",
    minBid = 10000,
    minIncrement = 100,
  }, "TestScale"),
  nil,
  "finger result filtered"
)
fingerControl:SetChecked(true)
fingerControl.scripts.OnClick(fingerControl)

PawnAuctionSearchDB = PawnAuctionSearchDB or {}
PawnAuctionSearchDB.scaleName = ""

start_scan(PawnAuctionSearch)
fire_auction_update(PawnAuctionSearch)

local results = get_results(PawnAuctionSearch)
assert_truthy(results, "scan results exist")
assert_equals(#results, 1, "upgrade result count")
assert_equals(result_name(results[1]), "Upgrade Sword", "upgrade result name")
assert_equals(result_delta(results[1]), 20, "upgrade result delta")

PawnAuctionSearch:SelectResult(1)
assert_equals(_G.selectedAuction, 1, "selected auction index")
PawnAuctionSearch.auctionCacheRows = nil



for index = 1, 50 do
  mock.auctions[index] = {
    name = "Downgrade Sword",
    itemId = 1002,
    link = "|cff1eff00|Hitem:1002:0:0:0:0:0:0:0|h[Downgrade Sword]|h|r",
    quality = 2,
    level = 80,
    minBid = 10000,
    minIncrement = 100,
    buyoutPrice = 20000,
    bidAmount = 0,
    owner = "SellerTwo",
    timeLeft = 2,
  }
end
mock.auctions[51] = {
  name = "Upgrade Sword",
  itemId = 1001,
  link = "|cff1eff00|Hitem:1001:0:0:0:0:0:0:0|h[Upgrade Sword]|h|r",
  quality = 2,
  level = 80,
  minBid = 10000,
  minIncrement = 100,
  buyoutPrice = 20000,
  bidAmount = 0,
  owner = "SellerOne",
  timeLeft = 2,
}
mock.currentPage = 0
start_scan(PawnAuctionSearch)
fire_auction_update(PawnAuctionSearch)
assert_equals(#get_results(PawnAuctionSearch), 0, "first page upgrade count")
assert_equals(mock.lastAuctionQuery[7], 1, "next page query")
fire_auction_update(PawnAuctionSearch)
assert_equals(#get_results(PawnAuctionSearch), 1, "paginated upgrade count")
assert_equals(result_name(get_results(PawnAuctionSearch)[1]), "Upgrade Sword", "paginated result")

mock.canQueryAll = true
mock.lastAuctionQuery = nil
mock.currentPage = 0
start_scan(PawnAuctionSearch)
assert_equals(mock.lastAuctionQuery[10], true, "fast scan getAll flag")
fire_auction_update(PawnAuctionSearch)
assert_equals(#get_results(PawnAuctionSearch), 1, "fast scan upgrade count")
assert_equals(#PawnAuctionSearch.auctionCacheRows, 51, "fast scan cache count")
assert_equals(get_results(PawnAuctionSearch)[1].page, 1, "fast scan result fallback page")
assert_equals(get_results(PawnAuctionSearch)[1].index, 1, "fast scan result fallback index")
_G.selectedAuction = nil
PawnAuctionSearch:SelectResult(1)
assert_equals(mock.lastAuctionQuery[7], 1, "fast scan selection page requery")
assert_equals(_G.selectedAuction, nil, "fast scan selection waits for requery")
fire_auction_update(PawnAuctionSearch)
assert_equals(_G.selectedAuction, 1, "fast scan page-local auction selected")


mock.canQueryAll = false
mock.lastAuctionQuery = nil
for index = 1, 51 do
  mock.auctions[index] = {
    name = "Downgrade Sword",
    itemId = 1002,
    link = "|cff1eff00|Hitem:1002:0:0:0:0:0:0:0|h[Downgrade Sword]|h|r",
    quality = 2,
    level = 80,
    minBid = 10000,
    minIncrement = 100,
    buyoutPrice = 20000,
    bidAmount = 0,
    owner = "SellerTwo",
    timeLeft = 2,
  }
end
start_scan(PawnAuctionSearch)
assert_equals(mock.lastAuctionQuery, nil, "cached rescore avoids auction query")
assert_equals(#get_results(PawnAuctionSearch), 1, "cached upgrade count")
assert_equals(result_name(get_results(PawnAuctionSearch)[1]), "Upgrade Sword", "cached result")

PawnAuctionSearch.auctionCacheRows = nil
PawnAuctionSearch.auctionCacheComplete = false
mock.fastScan = false
mock.canQuery = true
mock.lastAuctionQuery = nil
start_scan(PawnAuctionSearch)
mock.canQuery = false
fire_auction_update(PawnAuctionSearch)
assert_equals(PawnAuctionSearch.auctionCacheComplete, false, "partial cache remains invalid")
mock.canQuery = true
mock.lastAuctionQuery = nil
start_scan(PawnAuctionSearch)
assert_equals(mock.lastAuctionQuery[7], 0, "partial cache ignored")
PawnAuctionSearch.scanActive = false
PawnAuctionSearch.waitingForQuery = false
PawnAuctionSearch.auctionCacheRows = nil
mock.fastScan = false

mock.auctions[1] = {
  name = "Upgrade Sword",
  itemId = 1001,
  link = "|cff1eff00|Hitem:1001:0:0:0:0:0:0:0|h[Upgrade Sword]|h|r",
  quality = 2,
  level = 80,
  minBid = 10000,
  minIncrement = 100,
  buyoutPrice = 20000,
  bidAmount = 0,
  owner = "SellerOne",
  timeLeft = 2,
}
for index = 2, 51 do
  mock.auctions[index] = {
    name = "Downgrade Sword",
    itemId = 1002,
    link = "|cff1eff00|Hitem:1002:0:0:0:0:0:0:0|h[Downgrade Sword]|h|r",
    quality = 2,
    level = 80,
    minBid = 10000,
    minIncrement = 100,
    buyoutPrice = 20000,
    bidAmount = 0,
    owner = "SellerTwo",
    timeLeft = 2,
  }
end
mock.currentPage = 0
_G.selectedAuction = nil
start_scan(PawnAuctionSearch)
fire_auction_update(PawnAuctionSearch)
fire_auction_update(PawnAuctionSearch)
assert_equals(result_name(get_results(PawnAuctionSearch)[1]), "Upgrade Sword", "early page result")
PawnAuctionSearch:SelectResult(1)
assert_equals(mock.lastAuctionQuery[7], 0, "selection page requery")
assert_equals(_G.selectedAuction, nil, "selection waits for requery")
fire_auction_update(PawnAuctionSearch)
assert_equals(_G.selectedAuction, 1, "requeried page selected auction")

PawnAuctionSearch.auctionCacheRows = nil

mock.canQuery = false
start_scan(PawnAuctionSearch)
assert_equals(PawnAuctionSearch.scanActive, true, "throttled scan remains active")
mock.canQuery = true
PawnAuctionSearch:OnUpdate(0.1)
assert_equals(mock.lastAuctionQuery[7], 0, "throttled scan retry page")


mock.mainHandItemId = 9002
mock.knownSpells = { [674] = true, [23588] = false, [46917] = false }
local offhandCandidate = {
  index = 1,
  page = 0,
  name = "Offhand Dagger",
  link = "|cff1eff00|Hitem:1003:0:0:0:0:0:0:0|h[Offhand Dagger]|h|r",
  count = 1,
  quality = 2,
  canUse = true,
  level = 80,
  minBid = 10000,
  minIncrement = 100,
  buyoutPrice = 20000,
  bidAmount = 0,
  equipLoc = "INVTYPE_WEAPONOFFHAND",
}
assert_equals(
  PawnAuctionSearch:ScoreAuction(offhandCandidate, "TestScale"),
  nil,
  "offhand weapon excluded with 2H equipped and no Titan Grip"
)
mock.knownSpells[46917] = true
assert_truthy(
  PawnAuctionSearch:ScoreAuction(offhandCandidate, "TestScale"),
  "offhand weapon allowed with Titan Grip"
)

print("smoke ok")
