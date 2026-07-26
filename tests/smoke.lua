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
local function has_slot_control(addon, label)
  for _, control in ipairs(addon.slotControls or {}) do
    if control.labelText and control.labelText:GetText() == label then
      return true
    end
  end
  return false
end


local function find_option_control(addon, label)
  for _, control in ipairs(addon.optionControls or {}) do
    if control.labelText and control.labelText:GetText() == label then
      return control
    end
  end
  fail("option control missing: " .. label)
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

local function finish_fast_scan_processing(addon)
  local guard = 0
  while addon.fastScanProcessing do
    guard = guard + 1
    if guard > 1000 then
      fail("fast scan processing did not finish")
    end
    addon:OnUpdate(0.1)
  end
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
assert_truthy(AuctionFrameTabPawnAuctionSearch, "Pawn unique tab exists")
assert_equals(AuctionFrameTab4, AuctionFrameTabPawnAuctionSearch, "Pawn indexed tab alias exists")
assert_equals(AuctionFrameTabPawnAuctionSearch:GetText(), "Pawn", "Pawn tab text")
PawnAuctionSearch:SelectAuctionTab(AuctionFrameTabPawnAuctionSearch:GetID())
assert_truthy(PawnAuctionSearch.mainFrame:IsShown(), "Pawn frame shown after selecting tab")
assert_equals(AuctionFrameMoneyFrame:IsShown(), true, "Pawn tab keeps money frame visible")
assert_equals(mock.auctionsTabShowing, false, "Pawn tab hides owner chrome")
AuctionFrameTab_OnClick(AuctionFrameTab1)
assert_equals(PawnAuctionSearch.mainFrame:IsShown(), false, "Pawn frame hidden on Browse tab")
assert_equals(AuctionFrameMoneyFrame:IsShown(), true, "Browse tab restores money frame")
assert_truthy(AuctionFrameCloseButton, "AuctionFrame top close button remains present")


local scales = discover_scales(PawnAuctionSearch)
assert_equals(#PawnAuctionSearch.optionControls, 5, "option control count")
assert_equals(#PawnAuctionSearch.slotFilters, 15, "equipment slot filter count")
assert_equals(has_slot_control(PawnAuctionSearch, "Shirt"), false, "shirt slot hidden")
assert_equals(has_slot_control(PawnAuctionSearch, "Tabard"), false, "tabard slot hidden")
assert_truthy(PawnAuctionSearch.forceTwoHandControl, "force 2H slot-column control exists")
PawnAuctionSearch.forceTwoHandControl:SetChecked(true)
PawnAuctionSearch.forceTwoHandControl.scripts.OnClick(PawnAuctionSearch.forceTwoHandControl)
assert_equals(PawnAuctionSearchDB.force2h, true, "force 2H control persists")
PawnAuctionSearch.forceTwoHandControl:SetChecked(false)
PawnAuctionSearch.forceTwoHandControl.scripts.OnClick(PawnAuctionSearch.forceTwoHandControl)
assert_equals(PawnAuctionSearchDB.force2h, false, "force 2H control clears")
assert_equals(PawnAuctionSearchDB.useBuyout, false, "use buyout defaults off")
local buyoutControl = find_option_control(PawnAuctionSearch, "Use buyout")
assert_equals(buyoutControl.width, PawnAuctionSearch.CHECK_BUTTON_SIZE, "option check width")
assert_equals(buyoutControl.height, PawnAuctionSearch.CHECK_BUTTON_SIZE, "option check height")
assert_equals(
  buyoutControl.labelText,
  _G.PawnAuctionSearchOption3Text,
  "option uses native check label"
)
assert_equals(
  buyoutControl.tooltipText,
  "Use buyout instead of bid when checking auction prices.",
  "option help tooltip"
)
buyoutControl:SetChecked(true)
buyoutControl.scripts.OnClick(buyoutControl)
assert_equals(PawnAuctionSearchDB.useBuyout, true, "use buyout option persists")
buyoutControl:SetChecked(false)
buyoutControl.scripts.OnClick(buyoutControl)
assert_equals(PawnAuctionSearchDB.useBuyout, false, "use bid option persists")
assert_equals(count_values(scales), 1, "scale count")
assert_equals(first_value(scales), "TestScale", "scale name")
assert_equals(
  PawnAuctionSearch.scaleDropDown.width,
  PawnAuctionSearch.SCALE_DROPDOWN_WIDTH,
  "scale dropdown width"
)
assert_equals(
  PawnAuctionSearch.scaleLabel.point[5],
  PawnAuctionSearch.LEFT_CONTROLS_TOP_OFFSET,
  "scale header starts below top frame edge"
)
assert_equals(
  PawnAuctionSearch.armorDropDown.width,
  PawnAuctionSearch.ARMOR_DROPDOWN_WIDTH,
  "armor dropdown width"
)
assert_equals(PawnAuctionSearch.scaleDropDown.text, "TestScale", "scale dropdown text set")
assert_equals(
  PawnAuctionSearch.scaleDropDown.selectedValue,
  "TestScale",
  "scale dropdown value set"
)
assert_equals(
  PawnAuctionSearch:GetDisplayScaleLabel("Rogue: assassination"),
  "Rogue: assass.",
  "long scale labels are shortened for display"
)
assert_truthy(
  string.len(PawnAuctionSearch:GetDisplayScaleLabel("Death Knight: Unholy")) <= 14,
  "long class scale labels stay capped"
)
assert_equals(
  PawnAuctionSearch.armorDropDown.selectedValue,
  "",
  "armor dropdown selected value set"
)
assert_equals(
  PawnAuctionSearchSlotFilterTitle.point[5],
  PawnAuctionSearch.SLOT_FILTERS_TOP_OFFSET,
  "slot grid starts below top frame edge"
)
assert_equals(
  #PawnAuctionSearch.slotControls,
  #PawnAuctionSearch.slotFilters,
  "slot control count"
)
assert_equals(
  PawnAuctionSearch.resultRows[1].width,
  PawnAuctionSearch.RESULT_ROW_WIDTH,
  "result width"
)
assert_equals(
  #PawnAuctionSearch.resultRows,
  PawnAuctionSearch.RESULTS_VISIBLE_ROWS,
  "visible result row count"
)
assert_equals(
  PawnAuctionSearch.statusText.point[2],
  PawnAuctionSearch.mainFrame,
  "status is anchored to content frame"
)
assert_equals(
  PawnAuctionSearch.statusText.point[4],
  PawnAuctionSearch.RESULTS_LEFT_OFFSET,
  "status starts in result pane"
)
assert_truthy(PawnAuctionSearch.resultScrollFrame, "result scroll frame exists")
assert_equals(
  PawnAuctionSearch.resultScrollFrame.width,
  PawnAuctionSearch.RESULT_SCROLL_WIDTH,
  "result scroll frame keeps scrollbar gutter"
)
assert_equals(
  PawnAuctionSearch.statusText.point[5],
  PawnAuctionSearch.RESULTS_STATUS_OFFSET,
  "status has a dedicated line above results"
)
assert_equals(
  PawnAuctionSearch.resultsHeader.point[5],
  PawnAuctionSearch.RESULTS_TOP_OFFSET,
  "results start below status"
)
assert_equals(
  PawnAuctionSearch.resultsHeader.point[4],
  PawnAuctionSearch.RESULTS_LEFT_OFFSET,
  "results start in right pane"
)
assert_truthy(
  PawnAuctionSearch.RESULTS_LEFT_OFFSET + PawnAuctionSearch.RESULT_SCROLL_WIDTH <= 727,
  "result pane reserves 3.3.5a FauxScrollFrame scrollbar gutter"
)
assert_truthy(
  PawnAuctionSearch.RESULT_ROW_WIDTH + 31 <= PawnAuctionSearch.RESULT_SCROLL_WIDTH,
  "result rows do not cover scrollbar buttons"
)
assert_truthy(
  PawnAuctionSearch.RESULT_BUYOUT_PRICE_OFFSET + PawnAuctionSearch.resultRows[1].buyoutText.width
    <= PawnAuctionSearch.RESULT_ROW_WIDTH,
  "buyout price column stays inside result row"
)
assert_equals(
  PawnAuctionSearch.resultRows[1].dividerTexture.width,
  PawnAuctionSearch.RESULT_ROW_WIDTH,
  "result row divider spans row"
)
assert_equals(PawnAuctionSearch.closeButton.width, 80, "Close action uses AuctionUI width")
assert_equals(PawnAuctionSearch.closeButton.height, 22, "Close action uses AuctionUI height")
assert_equals(PawnAuctionSearch.closeButton.text, "Close", "Close action label is explicit")
assert_equals(PawnAuctionSearch.closeButton.shown, true, "Close action is always visible")
assert_equals(
  PawnAuctionSearch.closeButton.point[1],
  "BOTTOMRIGHT",
  "Close action anchors to visible bottom edge"
)
assert_equals(PawnAuctionSearch.closeButton.point[4], 12, "Close action fills right gap")
assert_equals(PawnAuctionSearch.closeButton.point[5], -26, "Close action sits in bottom row")
assert_equals(
  PawnAuctionSearch.buyoutButton.point[2],
  PawnAuctionSearch.closeButton,
  "Buyout action sits left of Close"
)
assert_equals(
  PawnAuctionSearch.bidButton.point[2],
  PawnAuctionSearch.buyoutButton,
  "Bid action sits left of Buyout"
)
local actionButtonWidth = PawnAuctionSearch.ACTION_BUTTON_WIDTH * 3
assert_truthy(actionButtonWidth <= PawnAuctionSearch.RESULT_ROW_WIDTH, "all actions fit row")
local resultBottom = 72 - PawnAuctionSearch.RESULTS_TOP_OFFSET + 12 + 8
  + (PawnAuctionSearch.RESULTS_VISIBLE_ROWS * PawnAuctionSearch.RESULT_ROW_HEIGHT)
  + 6
  + PawnAuctionSearch.ACTION_BUTTON_HEIGHT
assert_truthy(resultBottom <= 435, "result list leaves bottom controls visible")
PawnAuctionSearch.closeButton.scripts.OnClick(PawnAuctionSearch.closeButton)
assert_equals(mock.hiddenPanel, AuctionFrame, "Close action hides AuctionFrame")
AuctionFrame:Show()
for _, control in ipairs(PawnAuctionSearch.slotControls) do
  local titleTop = control.point[2].point[5]
  local bottom = titleTop + control.point[5] - PawnAuctionSearch.CHECK_BUTTON_SIZE
  assert_truthy(bottom > PawnAuctionSearch.statusText.point[5], "slot grid clears status")
end
local forceTwoHandTitleTop = PawnAuctionSearch.forceTwoHandControl.point[2].point[5]
local forceTwoHandBottom = forceTwoHandTitleTop
  + PawnAuctionSearch.forceTwoHandControl.point[5]
  - PawnAuctionSearch.CHECK_BUTTON_SIZE
assert_truthy(
  forceTwoHandBottom > PawnAuctionSearch.statusText.point[5],
  "force 2H control clears status"
)

local fingerControl = find_slot_control(PawnAuctionSearch, "Finger")
mock.canQuery = false
PawnAuctionSearch:OnUpdate(0)
assert_equals(PawnAuctionSearch.searchButton.enabled, false, "search disables while throttled")
mock.canQuery = true
PawnAuctionSearch:OnUpdate(0)
assert_equals(PawnAuctionSearch.searchButton.enabled, true, "search enables when query ready")
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

mock.canQueryAll = true

start_scan(PawnAuctionSearch)
assert_equals(
  PawnAuctionSearch.statusText.text,
  "Fast scan request sent. Waiting for server (0:00)...",
  "fast scan waiting starts"
)
PawnAuctionSearch:OnUpdate(65)
assert_equals(
  PawnAuctionSearch.statusText.text,
  "Fast scan request sent. Waiting for server (1:05)...",
  "fast scan waiting timer"
)
fire_auction_update(PawnAuctionSearch)
assert_equals(
  PawnAuctionSearch.statusText.text,
  "Fast scan scoring 0 / 2 auctions...",
  "fast scan progress starts"
)
finish_fast_scan_processing(PawnAuctionSearch)

local results = get_results(PawnAuctionSearch)
assert_truthy(results, "scan results exist")
assert_equals(#results, 1, "upgrade result count")
assert_equals(result_name(results[1]), "Upgrade Sword", "upgrade result name")
assert_equals(result_delta(results[1]), 20, "upgrade result delta")
assert_equals(PawnAuctionSearch.resultRows[1].deltaText.text, "+20.00", "pawn score formatted")
assert_equals(PawnAuctionSearch.resultRows[1].bidText.text, "1g 0s 0c", "bid price shown")
assert_equals(PawnAuctionSearch.resultRows[1].buyoutText.text, "2g 0s 0c", "buyout price shown")
assert_equals(PawnAuctionSearch.bidButton.shown, true, "Bid action visible before selection")
assert_equals(PawnAuctionSearch.buyoutButton.shown, true, "Buyout action visible before selection")
assert_equals(PawnAuctionSearch.bidButton.enabled, false, "Bid action disabled before selection")
assert_equals(
  PawnAuctionSearch.buyoutButton.enabled,
  false,
  "Buyout action disabled before selection"
)
PawnAuctionSearch.resultRows[1].scripts.OnEnter(PawnAuctionSearch.resultRows[1])
assert_equals(GameTooltip.auctionItem.index, 1, "live result hover uses auction tooltip")
PawnAuctionSearch.resultRows[1].scripts.OnLeave(PawnAuctionSearch.resultRows[1])
mock.shiftKeyDown = true
PawnAuctionSearch.resultRows[1].scripts.OnClick(PawnAuctionSearch.resultRows[1])
mock.shiftKeyDown = false
assert_equals(mock.insertedLink, results[1].link, "shift-click links result")
PawnAuctionSearch.resultRows[1].scripts.OnLeave(PawnAuctionSearch.resultRows[1])
PawnAuctionSearch.resultRows[1].scripts.OnClick(PawnAuctionSearch.resultRows[1])
assert_equals(PawnAuctionSearch.bidButton.shown, true, "selected row shows action buttons")
assert_equals(PawnAuctionSearch.bidButton.enabled, true, "selected row enables Bid action")
assert_equals(PawnAuctionSearch.buyoutButton.enabled, true, "selected row enables Buyout action")
assert_equals(
  PawnAuctionSearch.resultRows[1].selectedTexture.shown,
  true,
  "selected row shows highlight"
)
assert_equals(PawnAuctionSearch.resultRows[1].highlightLocked, true, "selected row locks highlight")
mock.staticPopupName = nil
PawnAuctionSearch.bidButton.scripts.OnClick(PawnAuctionSearch.bidButton)
assert_equals(_G.selectedAuction, 1, "bid action selects verified row")
assert_equals(mock.placedBid, nil, "bid action waits for confirmation popup")
assert_equals(mock.staticPopupName, "BID_AUCTION", "bid action opens confirmation")
assert_equals(BrowseBidPrice.money, 10000, "bid action sets confirmation price")
mock.placedBid = nil
results[1].buyoutPrice = 0
mock.auctions[1].buyoutPrice = 0
PawnAuctionSearch:UpdateResults()
assert_equals(
  PawnAuctionSearch.resultRows[1].buyoutText.text,
  "No buyout",
  "missing buyout shown explicitly"
)
mock.staticPopupName = nil
PawnAuctionSearch.buyoutButton.scripts.OnClick(PawnAuctionSearch.buyoutButton)
assert_equals(mock.placedBid, nil, "missing buyout does not spend")
assert_equals(mock.staticPopupName, nil, "missing buyout does not open confirmation")
mock.auctions[1].buyoutPrice = 20000
results[1].buyoutPrice = 20000
PawnAuctionSearch:UpdateResults()
mock.staticPopupName = nil
mock.placedBid = nil
PawnAuctionSearch.buyoutButton.scripts.OnClick(PawnAuctionSearch.buyoutButton)
assert_equals(mock.placedBid, nil, "buyout action waits for confirmation popup")
assert_equals(mock.staticPopupName, "BUYOUT_AUCTION", "buyout action opens confirmation")
assert_equals(AuctionFrame.buyoutPrice, 20000, "buyout action sets confirmation price")
mock.placedBid = nil
mock.auctions[1].buyoutPrice = 30000
mock.staticPopupName = nil
PawnAuctionSearch.buyoutButton.scripts.OnClick(PawnAuctionSearch.buyoutButton)
assert_equals(mock.placedBid, nil, "changed auction row blocks buyout")
assert_equals(mock.staticPopupName, nil, "changed auction row blocks confirmation")
mock.auctions[1].buyoutPrice = 20000
PawnAuctionSearchDB.canUse = true
results[1].canUse = false
assert_equals(
  PawnAuctionSearch:ScoreAuction(results[1], "TestScale"),
  nil,
  "can-use filter excludes unusable"
)
results[1].canUse = true
PawnAuctionSearchDB.canUse = false
PawnAuctionSearchDB.force2h = true
assert_equals(
  PawnAuctionSearch:ScoreAuction(results[1], "TestScale"),
  nil,
  "force 2h excludes one-hand"
)
PawnAuctionSearchDB.force2h = false
local plateRow = {
  link = "|cff1eff00|Hitem:1004:0:0:0:0:0:0:0|h[Plate Upgrade]|h|r",
  equipLoc = "INVTYPE_CHEST",
  itemType = "Armor",
  itemSubType = "Plate",
  canUse = true,
  minBid = 10000,
  minIncrement = 100,
  buyoutPrice = 20000,
  bidAmount = 0,
}
local clothRow = {
  link = "|cff1eff00|Hitem:1005:0:0:0:0:0:0:0|h[Cloth Upgrade]|h|r",
  equipLoc = "INVTYPE_CHEST",
  itemType = "Armor",
  itemSubType = "Cloth",
  canUse = true,
  minBid = 10000,
  minIncrement = 100,
  buyoutPrice = 20000,
  bidAmount = 0,
}
PawnAuctionSearchDB.armorPreference = "plate"
assert_truthy(PawnAuctionSearch:ScoreAuction(plateRow, "TestScale"), "armor preference keeps plate")
assert_equals(
  PawnAuctionSearch:ScoreAuction(clothRow, "TestScale"),
  nil,
  "armor preference excludes cloth"
)
PawnAuctionSearchDB.force2h = true
assert_equals(
  PawnAuctionSearch:ScoreAuction(plateRow, "TestScale"),
  nil,
  "force 2h excludes armor"
)
PawnAuctionSearchDB.force2h = false
PawnAuctionSearchDB.armorPreference = ""

PawnAuctionSearch:SelectResult(1)
assert_equals(_G.selectedAuction, 1, "selected auction index")
PawnAuctionSearch.auctionCacheRows = nil
PawnAuctionSearch.auctionCacheComplete = false



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
mock.canQueryAll = false
mock.lastAuctionQuery = nil
PawnAuctionSearch.auctionCacheRows = nil
PawnAuctionSearch.auctionCacheComplete = false
start_scan(PawnAuctionSearch)
assert_equals(mock.lastAuctionQuery, nil, "unavailable fast scan does not page query")
assert_equals(PawnAuctionSearch.scanActive, false, "unavailable fast scan stops")
assert_equals(
  PawnAuctionSearch.statusText.text,
  "Fast scan is not ready or unsupported, and no cached scan is available.",
  "unavailable fast scan status"
)

PawnAuctionSearch.auctionCacheRows = nil
PawnAuctionSearch.auctionCacheComplete = false

mock.canQueryAll = true
mock.lastAuctionQuery = nil
mock.currentPage = 0
start_scan(PawnAuctionSearch)
assert_equals(mock.lastAuctionQuery[10], true, "fast scan getAll flag")
mock.lastAuctionQuery = nil
start_scan(PawnAuctionSearch)
assert_equals(mock.lastAuctionQuery, nil, "active fast scan is not restarted")
PawnAuctionSearch:SelectAuctionTab(1)
assert_equals(PawnAuctionSearch.scanActive, false, "leaving tab cancels active scan")
assert_equals(PawnAuctionSearch.auctionCacheComplete, false, "leaving tab invalidates cache")
start_scan(PawnAuctionSearch)
assert_equals(mock.lastAuctionQuery[10], true, "fresh fast scan after tab change")
mock.fire("AUCTION_HOUSE_CLOSED")
assert_equals(PawnAuctionSearch.scanActive, false, "auction close cancels scan")
assert_equals(PawnAuctionSearch.auctionCacheComplete, false, "closed scan cache remains invalid")
start_scan(PawnAuctionSearch)
assert_equals(mock.lastAuctionQuery[10], true, "fresh fast scan after close")
mock.forcePagedListUpdate = true
fire_auction_update(PawnAuctionSearch)
assert_equals(
  PawnAuctionSearch.fastScanProcessing,
  false,
  "ordinary update does not start fast processing"
)
assert_equals(PawnAuctionSearch.scanActive, true, "ordinary update keeps fast scan waiting")
assert_equals(
  PawnAuctionSearch.auctionCacheComplete,
  false,
  "ordinary update leaves cache incomplete"
)
assert_equals(#PawnAuctionSearch.auctionCacheRows, 0, "ordinary update leaves cache empty")
mock.forcePagedListUpdate = false
PawnAuctionSearch.FAST_SCAN_ROWS_PER_TICK = 10
fire_auction_update(PawnAuctionSearch)
assert_equals(
  PawnAuctionSearch.statusText.text,
  "Fast scan scoring 0 / 51 auctions...",
  "fast scan progress for all rows"
)
PawnAuctionSearch:OnUpdate(0.1)
assert_equals(PawnAuctionSearch.fastScanProcessIndex, 11, "fast scan batch advances")
mock.auctions[20].owner = "ChangedSeller"
fire_auction_update(PawnAuctionSearch)
assert_equals(
  PawnAuctionSearch.fastScanProcessing,
  false,
  "same-size list mutation cancels fast scan"
)
assert_equals(
  PawnAuctionSearch.auctionCacheComplete,
  false,
  "mutated fast scan leaves cache incomplete"
)
mock.auctions[20].owner = "SellerTwo"
start_scan(PawnAuctionSearch)
fire_auction_update(PawnAuctionSearch)
PawnAuctionSearch:OnUpdate(0.1)
finish_fast_scan_processing(PawnAuctionSearch)
PawnAuctionSearch.FAST_SCAN_ROWS_PER_TICK = 250
assert_equals(#get_results(PawnAuctionSearch), 1, "fast scan upgrade count")
assert_equals(#PawnAuctionSearch.auctionCacheRows, 51, "fast scan cache count")
assert_equals(get_results(PawnAuctionSearch)[1].page, 1, "fast scan result fallback page")
assert_equals(get_results(PawnAuctionSearch)[1].index, 1, "fast scan result fallback index")
_G.selectedAuction = nil
mock.placedBid = nil
mock.lastAuctionQuery = nil
PawnAuctionSearch.currentAuctionPage = 0
PawnAuctionSearch.resultRows[1].scripts.OnClick(PawnAuctionSearch.resultRows[1])
PawnAuctionSearch.bidButton.scripts.OnClick(PawnAuctionSearch.bidButton)
assert_equals(mock.lastAuctionQuery[7], 1, "fast scan bid loads result page")
assert_equals(mock.placedBid, nil, "fast scan bid waits for explicit second click")
fire_auction_update(PawnAuctionSearch)
assert_equals(_G.selectedAuction, 1, "fast scan bid page load selects auction")
assert_equals(mock.placedBid, nil, "fast scan page load does not bid")
PawnAuctionSearch.bidButton.scripts.OnClick(PawnAuctionSearch.bidButton)
assert_equals(mock.placedBid, nil, "fast scan bid second click waits for confirmation")
assert_equals(mock.staticPopupName, "BID_AUCTION", "fast scan bid opens confirmation")
assert_equals(BrowseBidPrice.money, 10000, "fast scan bid sets confirmation price")

mock.canQueryAll = true
mock.lastAuctionQuery = nil
start_scan(PawnAuctionSearch)
assert_equals(mock.lastAuctionQuery, nil, "complete cache avoids available fast scan")
assert_equals(#get_results(PawnAuctionSearch), 1, "complete cache rescore count")
assert_equals(
  PawnAuctionSearch.statusText.text,
  "Found 1 upgrade auctions from cached scan (51 auctions rescored).",
  "cached scan status shows row count"
)
local completeCacheRows = PawnAuctionSearch.auctionCacheRows
mock.canQuery = false
PawnAuctionSearch.currentAuctionPage = 0
_G.selectedAuction = nil
PawnAuctionSearch:SelectResult(1)
assert_equals(PawnAuctionSearch.waitingForQuery, true, "selection page waits when throttled")
mock.fire("AUCTION_HOUSE_CLOSED")
assert_equals(PawnAuctionSearch.auctionCacheComplete, true, "selection close preserves cache")
assert_equals(PawnAuctionSearch.auctionCacheRows, completeCacheRows, "selection close keeps rows")
mock.canQuery = true
local auctioneerConst = {
  LINK = 1,
  IEQUIP = 5,
  PRICE = 6,
  TLEFT = 7,
  NAME = 9,
  COUNT = 11,
  QUALITY = 12,
  CANUSE = 13,
  ULEVEL = 14,
  MINBID = 15,
  MININC = 16,
  BUYOUT = 17,
  CURBID = 18,
  SELLER = 20,
  ITEMID = 23,
  FLAG = 24,
  FLAG_DIRTY = 1,
  FLAG_UNSEEN = 2,
  FLAG_FILTER = 4,
  EquipEncode = { INVTYPE_WEAPON = 13 },
}
local auctioneerImage = {
  {
    [auctioneerConst.LINK] = "|cff1eff00|Hitem:1001:0:0:0:0:0:0:0|h[Upgrade Sword]|h|r",
    [auctioneerConst.IEQUIP] = 13,
    [auctioneerConst.PRICE] = 10000,
    [auctioneerConst.TLEFT] = 2,
    [auctioneerConst.NAME] = "Upgrade Sword",
    [auctioneerConst.COUNT] = 1,
    [auctioneerConst.QUALITY] = 2,
    [auctioneerConst.CANUSE] = true,
    [auctioneerConst.ULEVEL] = 80,
    [auctioneerConst.MINBID] = 10000,
    [auctioneerConst.MININC] = 100,
    [auctioneerConst.BUYOUT] = 20000,
    [auctioneerConst.CURBID] = 0,
    [auctioneerConst.SELLER] = "AuctioneerSeller",
    [auctioneerConst.ITEMID] = 1001,
  },
  {
    [auctioneerConst.LINK] = "|cff1eff00|Hitem:1002:0:0:0:0:0:0:0|h[Downgrade Sword]|h|r",
    [auctioneerConst.IEQUIP] = 13,
    [auctioneerConst.PRICE] = 10000,
    [auctioneerConst.TLEFT] = 2,
    [auctioneerConst.NAME] = "Downgrade Sword",
    [auctioneerConst.COUNT] = 1,
    [auctioneerConst.QUALITY] = 2,
    [auctioneerConst.CANUSE] = true,
    [auctioneerConst.ULEVEL] = 80,
    [auctioneerConst.MINBID] = 10000,
    [auctioneerConst.MININC] = 100,
    [auctioneerConst.BUYOUT] = 20000,
    [auctioneerConst.CURBID] = 0,
    [auctioneerConst.SELLER] = "AuctioneerSeller",
    [auctioneerConst.ITEMID] = 1002,
    [auctioneerConst.FLAG] = auctioneerConst.FLAG_UNSEEN,
  },
}
local auctioneerIsScanning = false
local auctioneerIsPaused = false
_G.AucAdvanced = {
  Const = auctioneerConst,
  Scan = {
    IsScanning = function()
      return auctioneerIsScanning
    end,
    IsPaused = function()
      return auctioneerIsPaused
    end,
  },
  API = {
    QueryImage = function()
      fail("Auctioneer scoring must use GetImageCopy for batched processing")
    end,
    GetImageCopy = function()
      return auctioneerImage
    end,
    UnpackImageItem = function(item, storage)
      storage.link = item[auctioneerConst.LINK]
      storage.equipPos = item[auctioneerConst.IEQUIP]
      storage.price = item[auctioneerConst.PRICE]
      storage.timeLeft = item[auctioneerConst.TLEFT]
      storage.itemName = item[auctioneerConst.NAME]
      storage.stackSize = item[auctioneerConst.COUNT]
      storage.quality = item[auctioneerConst.QUALITY]
      storage.canUse = item[auctioneerConst.CANUSE]
      storage.useLevel = item[auctioneerConst.ULEVEL]
      storage.minBid = item[auctioneerConst.MINBID]
      storage.increment = item[auctioneerConst.MININC]
      storage.buyoutPrice = item[auctioneerConst.BUYOUT]
      storage.curBid = item[auctioneerConst.CURBID]
      storage.sellerName = item[auctioneerConst.SELLER]
      storage.itemId = item[auctioneerConst.ITEMID]
      storage.dataFlag = item[auctioneerConst.FLAG]
      return storage
    end,
  },
}
bit = {
  band = function(left, right)
    local result = 0
    local bitValue = 1
    while left > 0 or right > 0 do
      if left % 2 == 1 and right % 2 == 1 then
        result = result + bitValue
      end
      left = math.floor(left / 2)
      right = math.floor(right / 2)
      bitValue = bitValue * 2
    end
    return result
  end,
}
PawnAuctionSearch.auctionCacheRows = nil
PawnAuctionSearch.auctionCacheComplete = false
mock.canQueryAll = false
mock.lastAuctionQuery = nil
start_scan(PawnAuctionSearch)
assert_equals(mock.lastAuctionQuery, nil, "Auctioneer scan data avoids live query")
assert_equals(
  PawnAuctionSearch.statusText.text,
  "Auctioneer scan data scoring 0 / 2 auctions...",
  "Auctioneer scan progress starts"
)
PawnAuctionSearch:OnUpdate(0.1)
assert_equals(#get_results(PawnAuctionSearch), 1, "Auctioneer scan data result count")
assert_equals(get_results(PawnAuctionSearch)[1].source, "auctioneer", "Auctioneer source marked")
assert_equals(
  PawnAuctionSearch.statusText.text,
  "Found 1 upgrade auctions from Auctioneer scan data (2 auctions rescored).",
  "Auctioneer scan status shows source"
)
assert_equals(PawnAuctionSearch.bidButton.shown, true, "Auctioneer Bid action visible")
assert_equals(PawnAuctionSearch.buyoutButton.shown, true, "Auctioneer Buyout action visible")
assert_equals(
  PawnAuctionSearch.bidButton.enabled,
  false,
  "Auctioneer Bid disabled before selection"
)
assert_equals(
  PawnAuctionSearch.buyoutButton.enabled,
  false,
  "Auctioneer Buyout disabled before selection"
)
PawnAuctionSearch.resultRows[1].scripts.OnEnter(PawnAuctionSearch.resultRows[1])
assert_equals(
  GameTooltip.hyperlink,
  get_results(PawnAuctionSearch)[1].link,
  "Auctioneer row hover tooltip"
)
mock.auctions[1] = {
  name = "Upgrade Sword",
  itemId = 1001,
  link = get_results(PawnAuctionSearch)[1].link,
  quality = 2,
  level = 80,
  minBid = 10000,
  minIncrement = 100,
  buyoutPrice = 20000,
  bidAmount = 0,
  owner = "AuctioneerSeller",
  timeLeft = 2,
}
PawnAuctionSearch.pendingSelection = nil
mock.lastAuctionQuery = nil
PawnAuctionSearch.resultRows[1].scripts.OnClick(PawnAuctionSearch.resultRows[1])
assert_equals(mock.lastAuctionQuery[1], "Upgrade Sword", "Auctioneer row queries live item name")
assert_equals(
  PawnAuctionSearch.pendingSelection,
  get_results(PawnAuctionSearch)[1],
  "Auctioneer row waits for live match"
)
fire_auction_update(PawnAuctionSearch)
assert_equals(_G.selectedAuction, 1, "Auctioneer live query selects exact auction")
mock.staticPopupName = nil
mock.placedBid = nil
PawnAuctionSearch.buyoutButton.scripts.OnClick(PawnAuctionSearch.buyoutButton)
assert_equals(mock.placedBid, nil, "Auctioneer buyout waits for confirmation popup")
assert_equals(mock.staticPopupName, "BUYOUT_AUCTION", "Auctioneer buyout opens confirmation")
assert_equals(AuctionFrame.buyoutPrice, 20000, "Auctioneer buyout sets confirmation price")
auctioneerIsScanning = true
start_scan(PawnAuctionSearch)
assert_equals(
  PawnAuctionSearch.statusText.text,
  "Auctioneer is scanning. Search again after Auctioneer finishes.",
  "Auctioneer active scan blocks cached image use"
)
auctioneerIsScanning = false
auctioneerIsPaused = true
start_scan(PawnAuctionSearch)
assert_equals(
  PawnAuctionSearch.statusText.text,
  "Auctioneer scanning is paused. Resume Auctioneer, then search again.",
  "Auctioneer paused scan blocks cached image use"
)
auctioneerIsPaused = false
bit = nil
_G.AucAdvanced = nil
PawnAuctionSearch.auctionCacheRows = completeCacheRows
PawnAuctionSearch.auctionCacheComplete = true



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

PawnAuctionSearch.auctionCacheRows = {
  { link = "|cff1eff00|Hitem:1001:0:0:0:0:0:0:0|h[Upgrade Sword]|h|r" },
}
PawnAuctionSearch.auctionCacheComplete = false
mock.canQueryAll = false
mock.lastAuctionQuery = nil
start_scan(PawnAuctionSearch)
assert_equals(mock.lastAuctionQuery, nil, "partial cache does not start page scan")
assert_equals(PawnAuctionSearch.scanActive, false, "partial cache scan stops")

PawnAuctionSearch.auctionCacheRows = nil
PawnAuctionSearch.auctionCacheComplete = false
mock.canQueryAll = true
mock.auctions[1].link = nil
mock.lastAuctionQuery = nil
start_scan(PawnAuctionSearch)
fire_auction_update(PawnAuctionSearch)
finish_fast_scan_processing(PawnAuctionSearch)
assert_equals(
  PawnAuctionSearch.auctionCacheComplete,
  false,
  "incomplete fast scan invalidates cache"
)
assert_equals(PawnAuctionSearch.scanActive, false, "incomplete fast scan stops")
assert_equals(#get_results(PawnAuctionSearch), 0, "incomplete fast scan discards results")


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

PawnAuctionSearch.results = {}
for index = 1, 15 do
  PawnAuctionSearch.results[index] = {
    name = "Scroll Result " .. tostring(index),
    score = index,
    minBid = 10000,
    minIncrement = 100,
    buyoutPrice = 0,
    bidAmount = 0,
  }
end
FauxScrollFrame_SetOffset(PawnAuctionSearch.resultScrollFrame, 5)
PawnAuctionSearch:UpdateResults()
assert_equals(PawnAuctionSearch.resultScrollFrame.numItems, 15, "scroll tracks result count")
assert_equals(
  PawnAuctionSearch.resultScrollFrame.numToDisplay,
  PawnAuctionSearch.RESULTS_VISIBLE_ROWS,
  "scroll tracks visible rows"
)
assert_equals(PawnAuctionSearch.resultRows[1].resultIndex, 6, "scroll offset maps result index")
assert_equals(
  PawnAuctionSearch.resultRows[1].nameText.text,
  "Scroll Result 6",
  "scroll offset renders result"
)
PawnAuctionSearch.auctionCacheRows = {}
PawnAuctionSearch.auctionCacheComplete = true
FauxScrollFrame_SetOffset(PawnAuctionSearch.resultScrollFrame, 7)
start_scan(PawnAuctionSearch)
assert_equals(
  FauxScrollFrame_GetOffset(PawnAuctionSearch.resultScrollFrame),
  0,
  "new search resets result scroll offset"
)

print("smoke ok")
