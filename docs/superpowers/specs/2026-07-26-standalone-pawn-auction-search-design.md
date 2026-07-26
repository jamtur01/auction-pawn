# Standalone Pawn Auction Search Design

## Goal

Create a World of Warcraft 3.3.5a standalone addon that adds a Pawn tab to the
Blizzard Auction House. The addon must find auctions for equippable items whose
Pawn score is higher than the player's currently equipped item for the relevant
slot. It must not depend on Auctioneer or Auctioneer SearchUI.

## Current State

The source addon is an Auctioneer plugin:

- `auc-advanced-searcher-pawn.toc` targets interface `80200` and depends on
  `Auc-Advanced Pawn`.
- `SearcherPawn.lua` registers through `AucSearchUI.NewSearcher("Pawn-Ru")`.
- Configuration state comes from Auctioneer SearchUI locals:
  `parent.GetSearchLocals()`.
- The search entry point is `lib.Search(itemData)`, where `itemData` uses
  Auctioneer constants such as `Const.LINK`, `Const.IEQUIP`, `Const.BUYOUT`, and
  `Const.MINBID`.

The reusable part is the Pawn scoring/filtering behavior. The Auctioneer-specific
registration, settings storage, UI builder, result shape, and constants must be
replaced.

## 3.3.5a API Facts

Evidence from `wowgaming/3.3.5-interface-files`:

- The Auction House has three Blizzard tabs wired through
  `AuctionFrameTab_OnClick`, `PanelTemplates_SetNumTabs`, and tab buttons named
  `AuctionFrameTab1..3`.
- Browse search uses `QueryAuctionItems(...)`.
- Browse results are read with `GetNumAuctionItems("list")`,
  `GetAuctionItemInfo("list", index)`, and `GetAuctionItemLink("list", index)`.
- Bid/buyout actions use the selected browse row and Blizzard auction APIs.

Evidence from WotLK Pawn source repositories:

- `PawnGetAllScalesEx()` returns visible scale metadata.
- `PawnDoesScaleExist(scaleName)` validates scale names.
- `PawnGetItemData(link)` parses an item link into Pawn's cached item shape.
- `PawnGetItemDataForInventorySlot(slot, unenchanted, unit)` reads equipped item
  data.
- `PawnGetSingleValueFromItem(item, scaleName)` returns enchanted and
  unenchanted values.

## Addon Shape

Rename the addon to `PawnAuctionSearch` for a clean standalone identity:

- `PawnAuctionSearch.toc`
- `PawnAuctionSearch.xml`
- `PawnAuctionSearch.lua`
- Existing embedded `Localization/` library and localization files may remain if
  they still load cleanly in Lua 5.1.

`.toc` metadata:

- `## Interface: 30300`
- `## Title: Pawn Auction Search`
- `## Dependencies: Pawn`
- No `Auc-*` dependencies.
- Saved variables per character: `PawnAuctionSearchDB`.

The install folder must be named `PawnAuctionSearch` so the 3.3.5a client lists
it at character select.

## UI Design

The addon creates `AuctionFrameTab4` and `PawnAuctionSearchFrame` when the
Blizzard Auction UI is loaded.

Tab behavior:

- Preserve Blizzard tab behavior for Browse, Bids, and Auctions.
- Select tab 4 through a small wrapper around `AuctionFrameTab_OnClick`.
- Hide Blizzard subframes and show `PawnAuctionSearchFrame` when tab 4 is active.
- Restore normal Blizzard textures and state when tabs 1-3 are active.

Controls:

- Pawn scale dropdown.
- Refresh scales button.
- Search/Stop button.
- Checkbox options:
  - usable items only
  - affordable only
  - use buyout instead of bid for affordability and score-per-gold
  - adjust score by price
  - use unenchanted values
  - only 2H weapons
- Armor preference dropdown: no preference, cloth, leather, mail, plate.
- Slot checkboxes matching the current plugin: head, neck, shoulder, back, chest,
  wrist, hands, waist, legs, feet, finger, trinket, weapon, off-hand.

Results:

- Scrollable list of matching auctions.
- Each row shows item link/name, slot, Pawn delta, bid, buyout, owner, and time
  left.
- Clicking a row selects the underlying browse auction when that page is still
  current.
- Buyout/Bid buttons act on the selected matching row through Blizzard APIs.

## Search Flow

The 3.3.5a AH API returns one browse page per query. The addon therefore scans
incrementally instead of trying to fetch the whole AH at once.

1. User selects a Pawn scale and options.
2. Addon validates Pawn availability and selected scale.
3. Addon builds a queue of equipment queries:
   - armor classes/subclasses/inventory types where practical
   - weapon classes/subclasses/inventory types where practical
   - broad fallback equipment searches if class filters are unavailable
4. For each query/page:
   - call `QueryAuctionItems`
   - wait for `AUCTION_ITEM_LIST_UPDATE`
   - read the current page with `GetAuctionItemInfo` and `GetAuctionItemLink`
   - normalize the browse row into an internal auction table
   - filter and score it through Pawn
   - append upgrades to the results list
   - advance page until the page limit or no more results
5. Stop when the queue is empty or the user presses Stop.

The scanner must respect `CanSendAuctionQuery("list")` before each query. If the
server throttles queries, the addon waits and retries instead of spamming.

## Scoring Rules

Reuse the existing plugin semantics unless 3.3.5a forces a replacement:

- A result is an upgrade when the candidate Pawn value is greater than the
  currently equipped value for the matching slot.
- Empty equipped slots have value `0`.
- Rings, trinkets, and one-handed weapons compare against both possible slots.
- 2H weapons compare against main-hand plus off-hand value unless Titan's Grip
  applies.
- Use unenchanted values when that option is set.
- `usable only` uses Blizzard `canUse` from `GetAuctionItemInfo` where possible
  and falls back to tooltip red-line scanning.
- `affordable only` compares player money against bid or buyout according to the
  selected price basis.
- `adjust score by price` sorts/displays the delta per gold using the selected
  price basis.

## Error Handling

Fail loud in chat and in the tab status line for actionable problems:

- Pawn is missing or not initialized.
- No valid Pawn scale is selected.
- Auction House is closed during a scan.
- Auction queries are unavailable for too long.
- Item link is missing or Pawn cannot parse an item.

Per-item parse misses should not spam chat. They may increment a skipped count
shown in the status line.

## Verification

Add an offline LuaJIT smoke harness with Lua 5.1 semantics:

- Load localization and main addon files under mocked 3.3.5a globals.
- Assert AuctionFrame tab 4 is created and selectable.
- Assert Pawn scale discovery populates a dropdown model.
- Assert a mocked auction item with Pawn value above equipped value is included.
- Assert a mocked auction item below equipped value is excluded.
- Assert affordability and slot filters exclude results.

Run:

- `luajit -bl PawnAuctionSearch.lua /dev/null`
- the offline LuaJIT mock smoke test

Manual in-game verification after installation:

1. Folder is `Interface/AddOns/PawnAuctionSearch`.
2. AddOns list shows Pawn Auction Search and Pawn enabled.
3. Open Auction House; tab 4 is `Pawn`.
4. Select a visible Pawn scale.
5. Start scan; results appear only for upgrades.
6. Clicking a result shows its tooltip and selects the auction row when available.
