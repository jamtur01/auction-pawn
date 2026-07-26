LUAJIT ?= luajit

.PHONY: test syntax smoke

test: syntax smoke

syntax:
	$(LUAJIT) -bl PawnAuctionSearch.lua /dev/null
	$(LUAJIT) -bl tests/mock_335.lua /dev/null
	$(LUAJIT) -bl tests/smoke.lua /dev/null

smoke:
	$(LUAJIT) tests/smoke.lua
