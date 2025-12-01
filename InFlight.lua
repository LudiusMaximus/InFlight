-- GLOBALS -> LOCAL
local _G = getfenv(0)
local GetNumRoutes, GetTaxiMapID, GetTime, NumTaxiNodes, TaxiGetNodeSlot, TaxiNodeGetType, TaxiNodeName, UnitOnTaxi
    = GetNumRoutes, GetTaxiMapID, GetTime, NumTaxiNodes, TaxiGetNodeSlot, TaxiNodeGetType, TaxiNodeName, UnitOnTaxi
local abs, floor, format, gsub, ipairs, pairs, print, strjoin, strfind
    = abs, floor, format, gsub, ipairs, pairs, print, strjoin, strfind
local gtt = GameTooltip


-- WARNING if InFlight_Load is still present.
if C_AddOns.IsAddOnLoaded("InFlight_Load") then
  print("|cffff0000\"InFlight_Load\" is no longer required for \"InFlight\". You can disable or remove it.|r")
  C_AddOns.DisableAddOn("InFlight_Load")

  -- Undo InFlight_Load.
  InFlight = nil
end


local InFlight = CreateFrame("Frame", "InFlight")  -- no parent is intentional


-- LIBRARIES
local smed = LibStub("LibSharedMedia-3.0")

-- LOCALIZATION
local L = LibStub("AceLocale-3.0"):GetLocale("InFlight", not debug)
InFlight.L = L



InFlight.newPlayerSaveData = {}

InFlight.debug = false

-- LOCAL VARIABLES
local debug = InFlight.debug
local Print, PrintD = InFlight.Print, InFlight.PrintD
local profile
local taxiSrc, taxiSrcName, taxiDst, taxiDstName, endTime  -- location data
local porttaken, takeoff, inworld, outworld, ontaxi        -- flags
local ratio, endText = 0, "??"                             -- cache variables
local sb, spark, timeText, locText, bord                   -- frame elements
local totalTime, startTime, elapsed, throt = 0, 0, 0, 0    -- throttle variables
local oldTakeTaxiNode

local playerFaction = UnitFactionGroup("player")


-- Used to be local variable "vars = InFlight.db.global[faction]", but now we differentiate between faction-specific and factionless zones.
local function GetDstNodes(src, faction)
  if InFlight.noFactionsZoneNodes[src] then
    return InFlight.db.global["FactionslessZones"][src]
  else
    return InFlight.db.global[faction][src]
  end
end



InFlight:SetScript("OnEvent", function(this, event, ...) this[event](this, ...) end)
InFlight:RegisterEvent("ADDON_LOADED")

-----------------------------------------
function InFlight:ADDON_LOADED()
-----------------------------------------
  self:RegisterEvent("TAXIMAP_OPENED")
  self:SetupInFlight()
  self:LoadBulk()
  self:UnregisterEvent("ADDON_LOADED")
end


-------------------------------------
function InFlight:TAXIMAP_OPENED(...)
-------------------------------------

  -- Flight map might change (Dragon Isles / Zaralek Cavern).
  if FlightMapFrame and not FlightMapFrame.inflight_hook then
    hooksecurefunc(FlightMapFrame, "SetMapID", function()
      InFlight:InitSource(false)
    end)
    FlightMapFrame.inflight_hook = true
  end

  local uiMapSystem = ...
  local isTaxiMap = uiMapSystem == Enum.UIMapSystem.Taxi
  self:InitSource(isTaxiMap)
end






-- Support for flightpaths that are started by gossip options.
local t = {
  [L["Amber Ledge"]]                = {{ find = L["AmberLedgeGossip"],        s = "Amber Ledge",                d = "Transitus Shield (Scenic Route)" }},
  [L["Argent Tournament Grounds"]]  = {{ find = L["ArgentTournamentGossip"],  s = "Argent Tournament Grounds",  d = "Return" }},
  [L["Blackwind Landing"]]          = {{ find = L["BlackwindLandingGossip"],  s = "Blackwind Landing",          d = "Skyguard Outpost" }},
  [L["Caverns of Time"]]            = {{ find = L["CavernsOfTimeGossip"],     s = "Caverns of Time",            d = "Nozdormu's Lair" }},
  [L["Expedition Point"]]           = {{ find = L["ExpeditionPointGossip"],   s = "Expedition Point",           d = "Shatter Point" }},
  [L["Hellfire Peninsula"]]         = {{ find = L["HellfirePeninsulaGossip"], s = "Honor Point",                d = "Shatter Point" }},
  [L["Nighthaven"]]                 = {{ find = L["NighthavenGossipA"],       s = "Nighthaven",                 d = "Rut'theran Village" },
                                      {  find = L["NighthavenGossipH"],       s = "Nighthaven",                 d = "Thunder Bluff" }},
  [L["Old Hillsbrad Foothills"]]    = {{ find = L["OldHillsbradGossip"],      s = "Old Hillsbrad Foothills",    d = "Durnholde Keep" }},
  [L["Reaver's Fall"]]              = {{ find = L["Reaver'sFallGossip"],      s = "Reaver's Fall",              d = "Spinebreaker Post" }},
  [L["Ring of Transference"]]       = {{ find = L["ToBastionGossip1"],        s = "Oribos",                     d = "Bastion" },
                                      {  find = L["ToBastionGossip2"],        s = "Oribos",                     d = "Bastion" }},
  [L["Shatter Point"]]              = {{ find = L["ShatterPointGossip"],      s = "Shatter Point",              d = "Honor Point" }},
  [L["Skyguard Outpost"]]           = {{ find = L["SkyguardOutpostGossip"],   s = "Skyguard Outpost",           d = "Blackwind Landing" }},
  [L["Stormwind City"]]             = {{ find = L["StormwindCityGossip"],     s = "Stormwind City",             d = "Return" }},
  [L["Sun's Reach Harbor"]]         = {{ find = L["SSSAGossip"],              s = "Shattered Sun Staging Area", d = "Return" },
                                      {  find = L["SSSAGossip2"],             s = "Shattered Sun Staging Area", d = "The Sin'loren" }},
  [L["The Sin'loren"]]              = {{ find = L["TheSin'lorenGossip"],      s = "The Sin'loren",              d = "Shattered Sun Staging Area" }},
  [L["Valgarde"]]                   = {{ find = L["ValgardeGossip"],          s = "Valgarde",                   d = "Explorers' League Outpost" }},
}


local function PrepareMiscFlight(buttonText)
  if not buttonText or buttonText == "" then
    return
  end

  local subzone = GetMinimapZoneText()
  local tsz = t[subzone]
  if not tsz then
    return
  end

  local source, destination
  for _, sz in ipairs(tsz) do
    if strfind(buttonText, sz.find, 1, true) then
      source = sz.s
      destination = sz.d
      break
    end
  end

  if source and destination then
    InFlight:StartMiscFlight(source, destination)
  end
end


-- For Immersion addon.
if C_AddOns.IsAddOnLoaded("Immersion") then
  local immersionHookFrame = CreateFrame("Frame")
  immersionHookFrame:SetScript("OnEvent", function(_, event)
    if ImmersionFrame and ImmersionFrame.TitleButtons then
      local children = {ImmersionFrame.TitleButtons:GetChildren()}
      for i, child in ipairs(children) do
        if not child.inFlightHook then
          child:HookScript("OnClick", function(this)
            PrepareMiscFlight(this:GetText())
          end)
          child.inFlightHook = true
        end
      end
    end
  end)
  immersionHookFrame:RegisterEvent("GOSSIP_SHOW")
  immersionHookFrame:RegisterEvent("QUEST_GREETING")
  immersionHookFrame:RegisterEvent("QUEST_PROGRESS")

-- Without Immersion addon.
else
  hooksecurefunc(_G.GossipOptionButtonMixin, "OnClick", function(this)
    local elementData = this:GetElementData()
    if elementData.buttonType ~= _G.GOSSIP_BUTTON_TYPE_OPTION then
      return
    end
    PrepareMiscFlight(this:GetText())
  end)
end





-- LOCAL FUNCTIONS
local function FormatTime(secs)  -- simple time format
  if not secs then
    return "??"
  end

  return format(TIMER_MINUTES_DISPLAY, secs / 60, secs % 60)
end

local function ShortenName(name)  -- shorten name to lighten saved variables and display
  return gsub(name, L["DestParse"], "")
end

-- GetTaxiMapID() does not take into account if the map was changed (Dragon Isles / Zaralek Cavern).
local function GetViewedTaxiMapID()
  if FlightMapFrame and FlightMapFrame.GetMapID then
    return FlightMapFrame:GetMapID()
  else
    return GetTaxiMapID()
  end
end

local function GetNodeID(slot)
  local taximapNodes = C_TaxiMap.GetAllTaxiNodes(GetViewedTaxiMapID())
  for _, taxiNodeData in ipairs(taximapNodes) do
    if (slot == taxiNodeData.slotIndex) then
      return taxiNodeData.nodeID
    end
  end
end

local function SetPoints(f, lp, lrt, lrp, lx, ly, rp, rrt, rrp, rx, ry)
  f:ClearAllPoints()
  f:SetPoint(lp, lrt, lrp, lx, ly)
  if rp then
    f:SetPoint(rp, rrt, rrp, rx, ry)
  end
end

local function SetToUnknown()  -- setup bar for flights with unknown time
  sb:SetMinMaxValues(0, 1)
  sb:SetValue(1)
  sb:SetStatusBarColor(profile.unknowncolor.r, profile.unknowncolor.g, profile.unknowncolor.b, profile.unknowncolor.a)
  spark:Hide()
end

local function GetEstimatedTime(slot)  -- estimates flight times based on hops
  local numRoutes = GetNumRoutes(slot)
  if numRoutes < 2 then
    return
  end

  local taxiNodes = {[1] = taxiSrc, [numRoutes + 1] = GetNodeID(slot)}
  for hop = 2, numRoutes, 1 do
    taxiNodes[hop] = GetNodeID(TaxiGetNodeSlot(slot, hop, true))
  end

  local etimes = { 0 }
  local prevNode = {}
  local nextNode = {}
  local srcNode = 1
  local dstNode = #taxiNodes - 1
  PrintD("|cff208080New Route:|r", taxiSrcName.."("..taxiSrc..") -->", ShortenName(TaxiNodeName(slot)).."("..taxiNodes[#taxiNodes]..") -", #taxiNodes, "hops")
  while srcNode and srcNode < #taxiNodes do
    while dstNode and dstNode > srcNode do
      PrintD("|cff208080Node:|r", taxiNodes[srcNode].."("..srcNode..") -->", taxiNodes[dstNode].."("..dstNode..")")

      local dstNodes = GetDstNodes(taxiNodes[srcNode], playerFaction)
      if dstNodes then
        if not etimes[dstNode] and dstNodes[taxiNodes[dstNode]] then
          etimes[dstNode] = etimes[srcNode] + dstNodes[taxiNodes[dstNode]] * InFlight:KhazAlgarFlightMasterFactor(taxiNodes[dstNode]) * InFlight:RideLikeTheWindFactor()
          PrintD(taxiNodes[dstNode].."("..dstNode..") time:", FormatTime(etimes[srcNode]), "+", FormatTime(dstNodes[taxiNodes[dstNode]]), "=", FormatTime(etimes[dstNode]))
          nextNode[srcNode] = dstNode - 1
          prevNode[dstNode] = srcNode
          srcNode = dstNode
          dstNode = #taxiNodes
        else
          dstNode = dstNode - 1
        end
      else
        srcNode = prevNode[srcNode]
        dstNode = nextNode[srcNode]
      end
    end

    if not etimes[#taxiNodes] then
      PrintD("<<")
      srcNode = prevNode[srcNode]
      dstNode = nextNode[srcNode]
    end
  end

  PrintD(".")
  return etimes[#taxiNodes]
end

local function addDuration(flightTime, estimated)
  if flightTime > 0 then
    gtt:AddLine(L["Duration"]..(estimated and "~" or "")..FormatTime(flightTime), 1, 1, 1)
  else
    gtt:AddLine(L["Duration"].."-:--", 0.8, 0.8, 0.8)
  end

  gtt:Show()
end

local function postTaxiNodeOnButtonEnter(button) -- adds duration info to taxi node tooltips
  local id = button:GetID()
  if TaxiNodeGetType(id) ~= "REACHABLE" then
    return
  end

  local tmpTaxiDst = GetNodeID(id)

  local dstNodes = GetDstNodes(taxiSrc, playerFaction)
  local duration = dstNodes and dstNodes[tmpTaxiDst]
  if duration then
    addDuration(duration * InFlight:KhazAlgarFlightMasterFactor(tmpTaxiDst) * InFlight:RideLikeTheWindFactor())
  else
    addDuration(GetEstimatedTime(id) or 0, true)
  end
end

local function postFlightNodeOnButtonEnter(button) -- adds duration info to flight node tooltips

  if button.taxiNodeData.state ~= Enum.FlightPathState.Reachable or GetTaxiMapID() == 994 then
    return
  end

  local dstNodes = GetDstNodes(taxiSrc, playerFaction)
  local tmpTaxiDst = button.taxiNodeData.nodeID
  local duration = dstNodes and dstNodes[tmpTaxiDst]
  if duration then
    -- gtt:AddLine("NodeID: "..button.taxiNodeData.nodeID, 0.2, 0.8, 0.2) -- TEST
    addDuration(duration * InFlight:KhazAlgarFlightMasterFactor(tmpTaxiDst) * InFlight:RideLikeTheWindFactor())
  else
    -- gtt:AddLine("NodeID: "..button.taxiNodeData.nodeID, 0.2, 0.8, 0.2) -- TEST
    addDuration(GetEstimatedTime(button.taxiNodeData.slotIndex) or 0, true)
  end
end



function InFlight:SetupInFlight()

  SlashCmdList.INFLIGHT = function(arg1)

    if arg1 == "export" then
      if PTR_IssueReporter == nil then
        self:ExportDB()
      else
        print("Only exporting from the live game client. PTR has been unreliable before.")
      end
    else
      self:ShowOptions()
    end

  end
  SLASH_INFLIGHT1 = "/inflight"


  -- Option panel.
  local panel = CreateFrame("Frame")
    
  local t1 = panel:CreateFontString(nil, "ARTWORK")
  t1:SetFontObject(GameFontNormalLarge)
  t1:SetJustifyH("LEFT")
  t1:SetJustifyV("TOP")
  t1:SetPoint("TOPLEFT", 16, -16)
  t1:SetText("|cff0040ffIn|cff00aaffFlight|r")
  panel.tl = t1

  local t2 = panel:CreateFontString(nil, "ARTWORK")
  t2:SetFontObject(GameFontHighlight)
  t2:SetJustifyH("LEFT")
  t2:SetJustifyV("TOP")
  SetPoints(t2, "TOPLEFT", t1, "BOTTOMLEFT", 0, -8, "RIGHT", panel, "RIGHT", -32, 0)
  t2:SetNonSpaceWrap(true)
  local function GetInfo(field)
    return C_AddOns.GetAddOnMetadata("InFlight", field) or "N/A"
  end
  t2:SetFormattedText("|cff00aaffAuthor:|r %s\n|cff00aaffVersion:|r %s\n\n%s|r", GetInfo("Author"), GetInfo("Version"), GetInfo("Notes"))

  local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  b:SetText(_G.GAMEOPTIONS_MENU)
  b:SetWidth(max(120, b:GetTextWidth() + 20))
  b:SetScript("OnClick", InFlight.ShowOptions)
  b:SetPoint("TOPLEFT", t2, "BOTTOMLEFT", -2, -8)
  
  panel.name = "InFlight"
  
  local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  -- Needed to be able to call `Settings.OpenToCategory("InFlight")`
  category.ID = panel.name
  Settings.RegisterAddOnCategory(category)

  InFlight.SetupInFlight = nil
end




----------------------------
function InFlight.Print(...)  -- prefix chat messages
----------------------------
  print("|cff0040ffIn|cff00aaffFlight|r:", ...)
end
Print = InFlight.Print

-----------------------------
function InFlight.PrintD(...)  -- debug print
-----------------------------
  if debug then
    print("|cff00ff40In|cff00aaffFlight|r:", ...)
  end
end
PrintD = InFlight.PrintD

----------------------------------
function InFlight:GetDestination()
----------------------------------
  return taxiDstName
end

---------------------------------
function InFlight:GetFlightTime()
---------------------------------
  return endTime
end

----------------------------
function InFlight:LoadBulk()
----------------------------

  -- SavedVariables
  InFlightDB = InFlightDB or {}

  -- Convert old saved variables
  if not InFlightDB.version then
    InFlightDB.perchar = nil
    InFlightDB.dbinit = nil
    InFlightDB.upload = nil
    local tempDB = InFlightDB
    InFlightDB = { profiles = { Default = tempDB }}
  end

  -- To prevent "compare nil with number" error.
  if not InFlightDB.dbinit then
    InFlightDB.dbinit = 0
  end

  -- Flag to clear player save data, if corrupted data has been introduced into the
  -- player save data from a bug in the game or this addon, and therefore the player
  -- save data needs to be reset.
  -- Duplicates of updated default data will be automatically removed from the player
  -- save data by the metatable
  local resetDB = false

  -- post-cata
  if select(4, GetBuildInfo()) >= 40000 then


    -- Got to reset the user database after fix for factionless zones.
    if InFlightDB.dbinit < 1102004 then
      resetDB = true
      InFlightDB.dbinit = 1102004
    end


    -- Check that this is the right version of the database to avoid corruption.
    if InFlightDB.version ~= "post-cata" then
      -- Used to be called "retail", so we only reset flight points if it was anything else.
      if InFlightDB.version ~= "retail" then
        resetDB = true
      end
      InFlightDB.version = "post-cata"
    end

  -- pre-cata
  else

    if InFlightDB.dbinit ~= 1150 then
      resetDB = true
      InFlightDB.dbinit = 1150
    end

    -- Check that this is the right version of the database to avoid corruption
    if InFlightDB.version ~= "pre-cata" then
      -- Used to be called "classic" or "classic-era", so we only reset flight points if it was anything else.
      if InFlightDB.version ~= "classic" and InFlightDB.version ~= "classic-era" then
        resetDB = true
      end
      InFlightDB.version = "pre-cata"
    end

  end

  if resetDB and not debug then
    InFlightDB.global = nil
    InFlightDB.upload = nil
  end


  if debug then
    for faction, t in pairs(self.defaults.global) do
      local count = 0
      for src, dt in pairs(t) do
        for dst, dtime in pairs(dt) do
          if dst ~= "name" then
            count = count + 1
          end
        end
      end

      PrintD(faction, "|cff208020-|r", count, "|cff208020flights|r")
    end
  end



  -- If player save data (InFlightDB.global) is (almost, +/- 3) the same as stock default data (self.defaults.global),
  -- remove player save data.
  if InFlightDB.global then
    local defaultsGlobal = self.defaults.global

    for faction, factionNodes in pairs(InFlightDB.global) do
      -- print("checking InFlightDB.global", faction)
      for src, destNodes in pairs(factionNodes) do
        -- print("checking InFlightDB.global", faction, src)
        if defaultsGlobal[faction][src] then
          for dst, dtime in pairs(destNodes) do
            -- print(faction, src, dst, dtime)
            if dst ~= "name" and defaultsGlobal[faction][src][dst] and abs(dtime - defaultsGlobal[faction][src][dst]) < 3 then
              -- print("deleting", InFlightDB.global[faction][src][dst])
              InFlightDB.global[faction][src][dst] = nil
            end
          end
        end
        if not next(InFlightDB.global[faction][src]) then
          -- print("deleting", faction, src)
          InFlightDB.global[faction][src] = nil
        end
      end
      if not next(InFlightDB.global[faction]) then
        -- print("deleting", faction)
        InFlightDB.global[faction] = nil
      end
    end


    -- TODO: Remove recently updated flight paths from player save data.


    -- Store new player save data for export.
    local found = 0
    local newPlayerSaveData = InFlight.newPlayerSaveData
    for faction, factionNodes in pairs(InFlightDB.global) do
      for src, destNodes in pairs(factionNodes) do
        for dst, dtime in pairs(destNodes) do
          if (dst ~= "name" and (not defaultsGlobal[faction][src] or not defaultsGlobal[faction][src][dst] or abs(dtime - defaultsGlobal[faction][src][dst]) > 2)) or
             (dst == "name" and (not defaultsGlobal[faction][src] or not defaultsGlobal[faction][src][dst] or dtime ~= defaultsGlobal[faction][src][dst])) then
            newPlayerSaveData[faction] = newPlayerSaveData[faction] or {}
            newPlayerSaveData[faction][src] = newPlayerSaveData[faction][src] or {}
            newPlayerSaveData[faction][src][dst] = dtime
            if dst ~= "name" then
              found = found + 1
            end
          end
        end
      end
    end

    -- Not exporting flight times from PTR. They have been wrong before.
    if PTR_IssueReporter == nil and found > 0 and (not InFlightDB.upload or InFlightDB.upload < time()) then
      Print(format("|cff208020- " .. L["FlightTimeContribute"] .. "|r", "|r" .. found .. "|cff208020"))
      InFlightDB.upload = time() + 604800  -- 1 week in seconds (60 * 60 * 24 * 7)
    end

  end


  -- Free nodes of the opposing faction for garbage collection to save memory.
  if not debug then
    self.defaults.global[playerFaction == "Alliance" and "Horde" or "Alliance"] = nil
  end

  -- Create self.db SavedVariables InFlightDB with Inflight.defaults as defaults.
  self.db = LibStub("AceDB-3.0"):New("InFlightDB", self.defaults, true)
  -- Map to local variable.
  profile = self.db.profile


  oldTakeTaxiNode = TakeTaxiNode
  TakeTaxiNode = function(slot)
    if TaxiNodeGetType(slot) ~= "REACHABLE" then
      return
    end

    -- Don't show timer or record times for Argus map
    if GetTaxiMapID() == 994 then
      return oldTakeTaxiNode(slot)
    end

    -- Attempt to get source flight point if another addon auto-takes the taxi
    -- which can cause this function to run before the TAXIMAP_OPENED function
    if not taxiSrc then
      for i = 1, NumTaxiNodes(), 1 do
        if TaxiNodeGetType(i) == "CURRENT" then
          taxiSrcName = ShortenName(TaxiNodeName(i))
          taxiSrc = GetNodeID(i)
          break
        end
      end

      if not taxiSrc then
        oldTakeTaxiNode(slot)
        return
      end
    end

    taxiDstName = ShortenName(TaxiNodeName(slot))
    taxiDst = GetNodeID(slot)

    if not taxiDst then
      oldTakeTaxiNode(slot)
      return
    end

    local dstNodes = GetDstNodes(taxiSrc, playerFaction)
    if dstNodes and dstNodes[taxiDst] and dstNodes[taxiDst] > 0 then  -- saved variables lookup
      endTime = dstNodes[taxiDst] * InFlight:KhazAlgarFlightMasterFactor(taxiDst) * InFlight:RideLikeTheWindFactor()
      endText = FormatTime(endTime)
    else
      endTime = GetEstimatedTime(slot)
      endText = (endTime and "~" or "")..FormatTime(endTime)
    end

    if profile.confirmflight then  -- confirm flight
      StaticPopupDialogs.INFLIGHTCONFIRM = StaticPopupDialogs.INFLIGHTCONFIRM or {
        button1 = OKAY, button2 = CANCEL,
        OnAccept = function(this, data) InFlight:StartTimer(data) end,
        timeout = 0, exclusive = 1, hideOnEscape = 1,
      }
      StaticPopupDialogs.INFLIGHTCONFIRM.text = format(L["ConfirmPopup"], "|cffffff00"..taxiDstName..(endTime and " ("..endText..")" or "").."|r")

      local dialog = StaticPopup_Show("INFLIGHTCONFIRM")
      if dialog then
        dialog.data = slot
      end
    else  -- just take the flight
      self:StartTimer(slot)
    end
  end

  -- function hooks to detect if a user took a summon
  hooksecurefunc("TaxiRequestEarlyLanding", function()
    porttaken = true
    PrintD("|cffff8080Taxi Early|cff208080, porttaken -|r", porttaken)
  end)

  hooksecurefunc("AcceptBattlefieldPort", function(index, accept)
    porttaken = accept and true
    PrintD("|cffff8080Battlefield port|cff208080, porttaken -|r", porttaken)
  end)

  hooksecurefunc(C_SummonInfo, "ConfirmSummon", function()
    porttaken = true
    PrintD("|cffff8080Summon|cff208080, porttaken -|r", porttaken)
  end)

  hooksecurefunc("CompleteLFGRoleCheck", function(bool)
    porttaken = bool
    PrintD("|cffff8080LFG Role|cff208080, porttaken -|r", porttaken)
  end)

  hooksecurefunc("CompleteLFGReadyCheck", function(bool)
    porttaken = bool
    PrintD("|cffff8080LFG Ready|cff208080, porttaken -|r", porttaken)
  end)

  self:Hide()
  self.LoadBulk = nil
end

---------------------------------------
function InFlight:InitSource(isTaxiMap)  -- cache source location and hook tooltips
---------------------------------------

  -- Remember last source, for when a flight paths spans several maps (Dragon Isles <-> Zaralek Cavern).
  local lastTaxiSrcName = taxiSrcName
  local lastTaxiSrc     = taxiSrc

  taxiSrcName = nil
  taxiSrc = nil

  if isTaxiMap then
    for i = 1, NumTaxiNodes(), 1 do
      local tb = _G["TaxiButton"..i]
      if tb and not tb.inflighted then
        tb:HookScript("OnEnter", postTaxiNodeOnButtonEnter)
        tb.inflighted = true
      end

      if TaxiNodeGetType(i) == "CURRENT" then
        taxiSrcName = ShortenName(TaxiNodeName(i))
        taxiSrc = GetNodeID(i)
      end
    end
  elseif FlightMapFrame and FlightMapFrame.pinPools and FlightMapFrame.pinPools.FlightMap_FlightPointPinTemplate then
    local tb = FlightMapFrame.pinPools.FlightMap_FlightPointPinTemplate
    if tb then
      for flightnode in tb:EnumerateActive() do
        if not flightnode.inflighted then
          flightnode:HookScript("OnEnter", postFlightNodeOnButtonEnter)
          flightnode.inflighted = true
        end

        if flightnode.taxiNodeData.state == Enum.FlightPathState.Current then
          taxiSrcName = ShortenName(flightnode.taxiNodeData.name)
          taxiSrc = flightnode.taxiNodeData.nodeID
        end
      end
    end
  end

  if not taxiSrc then

    local taxiMapID = GetViewedTaxiMapID()

    -- Workaround for Blizzard bug on OutLand Flight Map
    if taxiMapID == 1467 and GetMinimapZoneText() == L["Shatter Point"] then
      taxiSrcName = L["Shatter Point"]
      taxiSrc = "Shatter Point"

    -- Flying between Dragon Isles (2057) and Zaralek Cavern (2175).
    elseif taxiMapID == 2057 or taxiMapID == 2175 then
      taxiSrcName = lastTaxiSrcName
      taxiSrc     = lastTaxiSrc

    else
      print("InFlight could not find taxi source node in flight map", taxiMapID)

    end

  end
end

----------------------------------
function InFlight:StartTimer(slot)  -- lift off
----------------------------------
  Dismount()
  if CanExitVehicle() == 1 then
    VehicleExit()
  end

  -- create the timer bar
  if not sb then
    self:CreateBar()
  end

  -- start the timers and setup statusbar
  if endTime then
    sb:SetMinMaxValues(0, endTime)
    sb:SetValue(profile.fill and 0 or endTime)
    spark:SetPoint("CENTER", sb, "LEFT", profile.fill and 0 or profile.width, 0)
  else
    SetToUnknown()
  end

  InFlight:UpdateLook()
  timeText:SetFormattedText("%s / %s", FormatTime(0), endText)
  sb:Show()
  self:Show()

  porttaken = nil
  elapsed, totalTime, startTime = 0, 0, GetTime()
  takeoff, inworld = true, true
  throt = min(0.2, (endTime or 50) / (profile.width or 1))  -- increases updates for short flights

  self:RegisterEvent("LFG_PROPOSAL_DONE")
  self:RegisterEvent("LFG_PROPOSAL_SUCCEEDED")
  self:RegisterEvent("PLAYER_CONTROL_GAINED")
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterEvent("PLAYER_LEAVING_WORLD")

  if slot then
    oldTakeTaxiNode(slot)
  end
end

-------------------------------------------
function InFlight:StartMiscFlight(src, dst)  -- called from InFlight_Load for special flights
-------------------------------------------
  taxiSrcName = L[src]
  taxiSrc = src
  taxiDstName = L[dst]
  taxiDst = dst

  local dstNodes = GetDstNodes(taxiSrc, playerFaction)
  endTime = dstNodes and dstNodes[dst]
  if endTime then
     endTime = endTime * self:KhazAlgarFlightMasterFactor(taxiSrc) * self:RideLikeTheWindFactor()
  end
  endText = FormatTime(endTime)
  self:StartTimer()
end

do  -- timer bar
  -----------------------------
  function InFlight:CreateBar()
  -----------------------------
    sb = CreateFrame("StatusBar", "InFlightBar", UIParent)
    sb:Hide()
    sb:SetPoint(profile.p, UIParent, profile.rp, profile.x, profile.y)
    sb:SetMovable(true)
    sb:EnableMouse(true)
    sb:SetClampedToScreen(true)
    sb:SetScript("OnMouseUp", function(this, a1)
      if a1 == "RightButton" then
        InFlight:ShowOptions()
      elseif a1 == "LeftButton" and IsControlKeyDown() then
        ontaxi, porttaken = nil, true
      end
    end)
    sb:RegisterForDrag("LeftButton")
    sb:SetScript("OnDragStart", function(this)
      if IsShiftKeyDown() then
        this:StartMoving()
      end
    end)
    sb:SetScript("OnDragStop", function(this)
      this:StopMovingOrSizing()
      local a,b,c,d,e = this:GetPoint()
      profile.p, profile.rp, profile.x, profile.y = a, c, floor(d + 0.5), floor(e + 0.5)
    end)
    sb:SetScript("OnEnter", function(this)
      gtt:SetOwner(this, "ANCHOR_RIGHT")
      gtt:SetText("InFlight", 1, 1, 1)
      gtt:AddLine(L["TooltipOption1"], 0, 1, 0)
      gtt:AddLine(L["TooltipOption2"], 0, 1, 0)
      gtt:AddLine(L["TooltipOption3"], 0, 1, 0)
      gtt:Show()
    end)
    sb:SetScript("OnLeave", function() gtt:Hide() end)

    timeText = sb:CreateFontString(nil, "OVERLAY")
    locText = sb:CreateFontString(nil, "OVERLAY")

    spark = sb:CreateTexture(nil, "OVERLAY")
    spark:Hide()
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetWidth(16)
    spark:SetBlendMode("ADD")

    bord = CreateFrame("Frame", nil, sb, BackdropTemplateMixin and "BackdropTemplate")  -- border/background
    SetPoints(bord, "TOPLEFT", sb, "TOPLEFT", -5, 5, "BOTTOMRIGHT", sb, "BOTTOMRIGHT", 5, -5)
    bord:SetFrameStrata("LOW")

    local function onupdate(this, a1)
      elapsed = elapsed + a1
      if elapsed < throt then
        return
      end

      totalTime = GetTime() - startTime
      elapsed = 0

      if takeoff then  -- check if actually in flight after take off (doesn't happen immediately)
        if UnitOnTaxi("player") then
          takeoff, ontaxi = nil, true
          elapsed, totalTime, startTime = throt - 0.01, 0, GetTime()
        elseif totalTime > 5 then
          sb:Hide()
          this:Hide()
        end

        return
      end

      if ontaxi and not inworld then
        return
      end

      if not UnitOnTaxi("player") then  -- event bug fix
        ontaxi = nil
      end

      if not ontaxi then  -- flight ended
        PrintD("|cff208080porttaken -|r", porttaken)
        if not porttaken and taxiSrc then

          local newPlayerSaveData = InFlight.newPlayerSaveData
          local defaultsGlobal = self.defaults.global

          -- Determine faction for this node.
          local faction = InFlight.noFactionsZoneNodes[taxiSrc] and "FactionslessZones" or playerFaction

          if not defaultsGlobal[faction][taxiSrc] or not defaultsGlobal[faction][taxiSrc]["name"] then
            -- print("Adding", taxiSrcName, "as new node/new name")
            newPlayerSaveData[faction] = newPlayerSaveData[faction] or {}
            newPlayerSaveData[faction][taxiSrc] = newPlayerSaveData[faction][taxiSrc] or {}
            newPlayerSaveData[faction][taxiSrc]["name"] = taxiSrcName
          end



          InFlight.db.global[faction][taxiSrc] = InFlight.db.global[faction][taxiSrc] or { name = taxiSrcName }
          local oldTime = InFlight.db.global[faction][taxiSrc][taxiDst]
          if oldTime then
            oldTime = oldTime * InFlight:KhazAlgarFlightMasterFactor(taxiDst) * InFlight:RideLikeTheWindFactor()
          end
          local newTime = floor(totalTime + 0.5)


          local msg = strjoin(" ", taxiSrcName .. (debug and "(" .. taxiSrc .. ")" or ""), profile.totext, taxiDstName .. (debug and "(" .. taxiDst .. ")" or ""), "|cff208080")
          if not oldTime then
            msg = msg .. L["FlightTimeAdded"] .. "|r " .. FormatTime(newTime)

          elseif abs(newTime - oldTime) > 2 then
            msg = msg .. L["FlightTimeUpdated"] .. "|r " .. FormatTime(oldTime) .. " |cff208080" .. profile.totext .. "|r " .. FormatTime(newTime)

          else
            newTime = oldTime
            msg = nil
          end

          if not defaultsGlobal[faction][taxiSrc] or not defaultsGlobal[faction][taxiSrc][taxiDst] or abs(newTime - defaultsGlobal[faction][taxiSrc][taxiDst]) > 2 then
            -- print("Updating ", newTime, "as new time for", taxiSrcName)
            newPlayerSaveData[faction] = newPlayerSaveData[faction] or {}
            newPlayerSaveData[faction][taxiSrc] = newPlayerSaveData[faction][taxiSrc] or {}
            newPlayerSaveData[faction][taxiSrc][taxiDst] = newTime
          end

          InFlight.db.global[faction][taxiSrc][taxiDst] = floor(newTime / (InFlight:KhazAlgarFlightMasterFactor(taxiDst) * InFlight:RideLikeTheWindFactor()) + 0.5)


          if msg and profile.chatlog then
            Print(msg)
          end
        end

        taxiSrcName = nil
        taxiSrc = nil
        taxiDstName = nil
        taxiDst = nil
        endTime = nil
        endText = FormatTime(endTime)
        sb:Hide()
        this:Hide()

        return
      end

      if endTime then  -- update statusbar if destination time is known
        if totalTime - 2 > endTime then   -- in case the flight is longer than expected
          SetToUnknown()
          endTime = nil
          endText = FormatTime(endTime)
        else
          local curTime = totalTime
          if curTime > endTime then
            curTime = endTime
          elseif curTime < 0 then
            curTime = 0
          end

          local value = profile.fill and curTime or (endTime - curTime)
          sb:SetValue(value)
          spark:SetPoint("CENTER", sb, "LEFT", value * ratio, 0)

          value = profile.countup and curTime or (endTime - curTime)
          timeText:SetFormattedText("%s / %s", FormatTime(value), endText)
        end
      else  -- destination time is unknown, so show that it's timing
        timeText:SetFormattedText("%s / %s", FormatTime(totalTime), endText)
      end
    end

    function self:LFG_PROPOSAL_DONE()
      porttaken = true
      PrintD("|cffff8080Proposal Done|cff208080, porttaken -|r", porttaken)
    end

    function self:LFG_PROPOSAL_SUCCEEDED()
      porttaken = true
      PrintD("|cffff8080Proposal Succeeded|cff208080, porttaken -|r", porttaken)
    end

    function self:PLAYER_LEAVING_WORLD()
      PrintD('PLAYER_LEAVING_WORLD')
      inworld = nil
      outworld = GetTime()
    end

    function self:PLAYER_ENTERING_WORLD()
      PrintD('PLAYER_ENTERING_WORLD')
      inworld = true
      if outworld then
        startTime = startTime - (outworld - GetTime())
      end

      outworld = nil
    end

    function self:PLAYER_CONTROL_GAINED()
      PrintD('PLAYER_CONTROL_GAINED')
      if not inworld then
        return
      end

      if self:IsShown() then
        ontaxi = nil
        onupdate(self, 3)
      end

      self:UnregisterEvent("LFG_PROPOSAL_DONE")
      self:UnregisterEvent("LFG_PROPOSAL_SUCCEEDED")
      self:UnregisterEvent("PLAYER_ENTERING_WORLD")
      self:UnregisterEvent("PLAYER_LEAVING_WORLD")
      self:UnregisterEvent("PLAYER_CONTROL_GAINED")
    end

    self:SetScript("OnUpdate", onupdate)
    self.CreateBar = nil
  end

  ------------------------------
  function InFlight:UpdateLook()
  ------------------------------
    if not sb then
      return
    end

    sb:SetWidth(profile.width)
    sb:SetHeight(profile.height)

    local texture = smed:Fetch("statusbar", profile.texture)
    local borderTexture = smed:Fetch("border", profile.border)
    local inset = (profile.border=="Textured" and 2) or 4
    
    local backcolor = profile.backcolor or {r=0.1, g=0.1, b=0.1, a=0.6}
    local bordercolor = profile.bordercolor or {r=0.6, g=0.6, b=0.6, a=0.8}
    
    
    -- Create fresh backdrop table to ensure proper SetBackdrop behavior
    local newBackdrop = {
      bgFile = texture,
      edgeFile = borderTexture,
      edgeSize = 16,
      insets = { left = inset, right = inset, top = inset, bottom = inset },
    }
    
    bord:SetBackdrop(newBackdrop)
    bord:SetBackdropColor(backcolor.r or 0.1, backcolor.g or 0.1, backcolor.b or 0.1, backcolor.a or 0.6)
    bord:SetBackdropBorderColor(bordercolor.r or 0.6, bordercolor.g or 0.6, bordercolor.b or 0.6, bordercolor.a or 0.8)
    
    sb:SetStatusBarTexture(texture)
    if sb:GetStatusBarTexture() then
      sb:GetStatusBarTexture():SetHorizTile(false)
      sb:GetStatusBarTexture():SetVertTile(false)
    end

    spark:SetHeight(profile.height * 2.4)
    if endTime then  -- in case we're in flight
      ratio = profile.width / endTime
      local barcolor = profile.barcolor or {r=0.5, g=0.5, b=0.8, a=1.0}
      sb:SetStatusBarColor(barcolor.r or 0.5, barcolor.g or 0.5, barcolor.b or 0.8, barcolor.a or 1.0)
      if profile.spark then
        spark:Show()
      else
        spark:Hide()
      end
    else
      SetToUnknown()
    end

    local fontcolor = profile.fontcolor or {r=1.0, g=1.0, b=1.0, a=1.0}
    locText:SetFont(smed:Fetch("font", profile.font), profile.fontsize, profile.outline and "OUTLINE" or nil)
    locText:SetShadowColor(0, 0, 0, fontcolor.a or 1.0)
    locText:SetShadowOffset(1, -1)
    locText:SetTextColor(fontcolor.r or 1.0, fontcolor.g or 1.0, fontcolor.b or 1.0, fontcolor.a or 1.0)

    timeText:SetFont(smed:Fetch("font", profile.font), profile.fontsize, profile.outlinetime and "OUTLINE" or nil)
    timeText:SetShadowColor(0, 0, 0, fontcolor.a or 1.0)
    timeText:SetShadowOffset(1, -1)
    timeText:SetTextColor(fontcolor.r or 1.0, fontcolor.g or 1.0, fontcolor.b or 1.0, fontcolor.a or 1.0)

    if profile.inline then
      timeText:SetJustifyH("RIGHT")
      timeText:SetJustifyV("MIDDLE")
      SetPoints(timeText, "RIGHT", sb, "RIGHT", -4, 0)
      locText:SetJustifyH("LEFT")
      locText:SetJustifyV("MIDDLE")
      SetPoints(locText, "LEFT", sb, "LEFT", 4, 0, "RIGHT", timeText, "LEFT", -2, 0)
      locText:SetText(taxiDstName or "??")
    elseif profile.twolines then
      timeText:SetJustifyH("CENTER")
      timeText:SetJustifyV("MIDDLE")
      SetPoints(timeText, "CENTER", sb, "CENTER", 0, 0)
      locText:SetJustifyH("CENTER")
      locText:SetJustifyV("BOTTOM")
      SetPoints(locText, "TOPLEFT", sb, "TOPLEFT", -24, profile.fontsize*2.5, "BOTTOMRIGHT", sb, "TOPRIGHT", 24, (profile.border=="None" and 1) or 3)
      locText:SetFormattedText("%s %s\n%s", taxiSrcName or "??", profile.totext, taxiDstName or "??")
    else
      timeText:SetJustifyH("CENTER")
      timeText:SetJustifyV("MIDDLE")
      SetPoints(timeText, "CENTER", sb, "CENTER", 0, 0)
      locText:SetJustifyH("CENTER")
      locText:SetJustifyV("BOTTOM")
      SetPoints(locText, "TOPLEFT", sb, "TOPLEFT", -24, profile.fontsize*2.5, "BOTTOMRIGHT", sb, "TOPRIGHT", 24, (profile.border=="None" and 1) or 3)
      locText:SetFormattedText("%s %s %s", taxiSrcName or "??", profile.totext, taxiDstName or "??")
    end
  end
end


-- Register dummy border for styling (allows "Textured" border option without an actual texture file)
smed:Register("border", "Textured", "\\Interface\\None")

-------------------------------
function InFlight.ShowOptions()
-------------------------------
  -- Helper: Open dialog to edit the "to" text separator
  local function ShowToTextDialog()
    StaticPopupDialogs["InFlightToText"] = StaticPopupDialogs["InFlightToText"] or {
      text = L["Enter your 'to' text."],
      button1 = ACCEPT, button2 = CANCEL,
      hasEditBox = 1, maxLetters = 12,
      OnAccept = function(self)
        local editBox = self.editBox or _G[self:GetName() .. "EditBox"]
        profile.totext = strtrim(editBox:GetText())
        InFlight:UpdateLook()
      end,
      OnShow = function(self)
        local editBox = self.editBox or _G[self:GetName() .. "EditBox"]
        editBox:SetText(profile.totext)
        editBox:SetFocus()
      end,
      OnHide = function(self)
        local editBox = self.editBox or _G[self:GetName() .. "EditBox"]
        editBox:SetText("")
      end,
      EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local editBox = parent.editBox or _G[parent:GetName() .. "EditBox"]
        profile.totext = strtrim(editBox:GetText())
        parent:Hide()
        InFlight:UpdateLook()
      end,
      EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
      end,
      timeout = 0, exclusive = 1, whileDead = 1, hideOnEscape = 1,
    }
    StaticPopup_Show("InFlightToText")
  end

  -- Helper: Reset all options to defaults
  local function ResetOptions()
    InFlight.db:ResetProfile()
    if InFlight.db:GetCurrentProfile() ~= "Default" then
      profile.perchar = true
    end
    InFlight:UpdateLook()
  end

  -- Helper: Clear flight time database and reload UI
  local function ResetFlightTimes()
    InFlightDB.dbinit = nil
    InFlightDB.global = {}
    ReloadUI()
  end

  -- Helper: Export flight time data to developers
  local function ExportFlightTimes()
    if PTR_IssueReporter == nil then
      InFlight:ExportDB()
    else
      print("Only exporting from the live game client. PTR has been unreliable before.")
    end
  end

  -- Helper: Toggle per-character profile setting
  local function TogglePerCharProfile()
    local charKey = UnitName("player") .. " - " .. GetRealmName()
    if profile.perchar then
      profile.perchar = false
      InFlight.db:SetProfile(charKey)
      InFlight.db:CopyProfile("Default")
      profile = InFlight.db.profile
      profile.perchar = true
    else
      InFlight.db:SetProfile("Default")
      profile = InFlight.db.profile
      InFlight.db:DeleteProfile(charKey)
    end
    InFlight:UpdateLook()
  end

  -- Helper: Update numeric/string profile values
  local function SetSelect(optionKey, value)
    profile[optionKey] = tonumber(value) or value
    InFlight:UpdateLook()
  end

  -- Helper: Update color values with validation and clamping
  local function SetColor(colorKey, red, green, blue, alpha)
    local colorTable = profile[colorKey]
    if not colorTable then return end
    
    -- Clamp all RGBA values to valid 0-1 range, using current values as fallback
    colorTable.r = math.max(0, math.min(1, tonumber(red) or colorTable.r))
    colorTable.g = math.max(0, math.min(1, tonumber(green) or colorTable.g))
    colorTable.b = math.max(0, math.min(1, tonumber(blue) or colorTable.b))
    colorTable.a = math.max(0, math.min(1, tonumber(alpha) or colorTable.a))
    InFlight:UpdateLook()
  end

  -- Helper: Open color picker for a given color type
  local function OpenColorPicker(colorKey)
    local colorTable = profile[colorKey]
    if not colorTable then return end
    
    local colorInfo = {
      r = colorTable.r, g = colorTable.g, b = colorTable.b, opacity = colorTable.a,
      hasOpacity = true,
      swatchFunc = function()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        local a = ColorPickerFrame:GetColorAlpha()
        SetColor(colorKey, r, g, b, a)
      end,
      opacityFunc = function()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        local a = ColorPickerFrame:GetColorAlpha()
        SetColor(colorKey, r, g, b, a)
      end,
      cancelFunc = function(previousValues)
        if previousValues then
          SetColor(colorKey, previousValues.r, previousValues.g, previousValues.b, previousValues.a)
        end
      end,
    }
    ColorPickerFrame:SetupColorPickerAndShow(colorInfo)
  end

  -- Helper: Create slider submenu with pagination for large ranges
  local function AddFakeSliderSubmenu(parentMenu, sliderLabel, profileKey, minValue, maxValue, stepSize, itemTable)
    local sliderButton = parentMenu:CreateButton(sliderLabel)
    sliderButton:SetOnEnter(function(_, desc) desc:ForceOpenSubmenu() end)

    if itemTable then
      -- For named lists (textures, borders, fonts), display all items directly
      for i = minValue, maxValue, stepSize do
        local itemName = itemTable[i]
        sliderButton:CreateRadio(itemName, 
          function() return profile[profileKey] == itemName end, 
          function() SetSelect(profileKey, itemName); return MenuResponse.Refresh end)
      end
    else
      -- For numeric ranges, paginate into ~20-item submenus to prevent screen overflow
      local itemsPerPage = 20
      local rangeStart = minValue
      local numberFormat = (stepSize >= 1 and "%d") or (stepSize >= 0.1 and "%.1f") or "%.2f"
      
      while rangeStart <= maxValue do
        -- Calculate range end, aiming for ~20 items but respecting the maximum
        local rangeEnd = min(maxValue, rangeStart + (itemsPerPage - 1) * stepSize)
        
        -- Align range end to avoid ugly boundaries
        local alignmentOffset = rangeEnd % (itemsPerPage * stepSize)
        if rangeEnd ~= maxValue and alignmentOffset > 0 then
          rangeEnd = rangeEnd - alignmentOffset
        end

        local pageLabel = format("%s: %d-%d", sliderLabel, rangeStart, rangeEnd)
        local rangeMenu = sliderButton:CreateButton(pageLabel)
        rangeMenu:SetOnEnter(function(_, desc) desc:ForceOpenSubmenu() end)
        
        -- Add all values in this range with the original step size
        for currentValue = rangeStart, rangeEnd, stepSize do
          local value = currentValue  -- Capture in closure to avoid variable capture issues
          rangeMenu:CreateRadio(format(numberFormat, value), 
            function() return floor(100 * (profile[profileKey] or 0)) == floor(100 * value) end, 
            function() SetSelect(profileKey, value); return MenuResponse.Refresh end)
        end
        
        -- Advance to next range or break if we've reached the end
        if rangeEnd >= maxValue then
          break
        end
        rangeStart = rangeEnd + stepSize
      end
    end
  end

  MenuUtil.CreateContextMenu(UIParent, function(_, mainMenu)
    mainMenu:CreateTitle("|cff0040ffIn|cff00aaffFlight|r")
    mainMenu:CreateDivider()

    -- ===== BAR OPTIONS =====
    local barMenu = mainMenu:CreateButton(L["BarOptions"])
    barMenu:SetOnEnter(function(_, desc) desc:ForceOpenSubmenu() end)
    
    barMenu:CreateCheckbox(L["CountUp"], function() return profile.countup end, function() profile.countup = not profile.countup; InFlight:UpdateLook() end)
    barMenu:CreateCheckbox(L["FillUp"], function() return profile.fill end, function() profile.fill = not profile.fill; InFlight:UpdateLook() end)
    barMenu:CreateCheckbox(L["ShowSpark"], function() return profile.spark end, function() profile.spark = not profile.spark; InFlight:UpdateLook() end)
    
    -- Bar dimensions
    AddFakeSliderSubmenu(barMenu, L["Height"], "height", 4, 150, 1, nil)
    AddFakeSliderSubmenu(barMenu, L["Width"], "width", 40, 1000, 5, nil)
    
    -- Bar appearance from LibSharedMedia
    local statusbarList = smed:List("statusbar")
    local borderList = smed:List("border")
    -- Remove broken border textures by rebuilding the table
    local filteredBorderList = {}
    for _, borderName in ipairs(borderList) do
      if borderName ~= "Blizzard Party" then
        table.insert(filteredBorderList, borderName)
      end
    end
    AddFakeSliderSubmenu(barMenu, L["Texture"], "texture", 1, #statusbarList, 1, statusbarList)
    AddFakeSliderSubmenu(barMenu, L["Border"], "border", 1, #filteredBorderList, 1, filteredBorderList)
    
    barMenu:CreateDivider()
    
    -- Bar colors
    barMenu:CreateColorSwatch(L["BackgroundColor"], function() OpenColorPicker("backcolor") end, 
      {r = profile.backcolor.r, g = profile.backcolor.g, b = profile.backcolor.b})
    barMenu:CreateColorSwatch(L["BarColor"], function() OpenColorPicker("barcolor") end, 
      {r = profile.barcolor.r, g = profile.barcolor.g, b = profile.barcolor.b})
    barMenu:CreateColorSwatch(L["UnknownColor"], function() OpenColorPicker("unknowncolor") end, 
      {r = profile.unknowncolor.r, g = profile.unknowncolor.g, b = profile.unknowncolor.b})
    barMenu:CreateColorSwatch(L["BorderColor"], function() OpenColorPicker("bordercolor") end, 
      {r = profile.bordercolor.r, g = profile.bordercolor.g, b = profile.bordercolor.b})
    
    -- ===== TEXT OPTIONS =====
    local textMenu = mainMenu:CreateButton(L["TextOptions"])
    textMenu:SetOnEnter(function(_, desc) desc:ForceOpenSubmenu() end)
    
    textMenu:CreateCheckbox(L["CompactMode"], 
      function() return profile.inline end, 
      function() profile.inline = not profile.inline; InFlight:UpdateLook() end)
    
    textMenu:CreateCheckbox(L["TwoLines"], 
      function() return profile.twolines end, 
      function() profile.twolines = not profile.twolines; InFlight:UpdateLook() end)
    
    textMenu:CreateButton(L["ToText"], function() ShowToTextDialog() end)
    
    -- Font selection from LibSharedMedia
    local fontList = smed:List("font")
    AddFakeSliderSubmenu(textMenu, L["Font"], "font", 1, #fontList, 1, fontList)
    
    -- Font size range (4-30 points)
    AddFakeSliderSubmenu(textMenu, _G.FONT_SIZE, "fontsize", 4, 30, 1, nil)
    
    textMenu:CreateDivider()
    textMenu:CreateColorSwatch(L["FontColor"], function()
      OpenColorPicker("fontcolor")
    end, {r = profile.fontcolor.r, g = profile.fontcolor.g, b = profile.fontcolor.b})

    textMenu:CreateCheckbox(L["OutlineInfo"], 
      function() return profile.outline end, 
      function() profile.outline = not profile.outline; InFlight:UpdateLook() end)
    
    textMenu:CreateCheckbox(L["OutlineTime"], 
      function() return profile.outlinetime end, 
      function() profile.outlinetime = not profile.outlinetime; InFlight:UpdateLook() end)

    mainMenu:CreateDivider()

    -- ===== OTHER OPTIONS =====
    local otherMenu = mainMenu:CreateButton(_G.OTHER)
    otherMenu:SetOnEnter(function(_, desc) desc:ForceOpenSubmenu() end)
    
    otherMenu:CreateCheckbox(L["ShowChat"], 
      function() return profile.chatlog end, 
      function() profile.chatlog = not profile.chatlog; InFlight:UpdateLook() end)
    
    otherMenu:CreateCheckbox(L["ConfirmFlight"], 
      function() return profile.confirmflight end, 
      function() profile.confirmflight = not profile.confirmflight; InFlight:UpdateLook() end)
    
    otherMenu:CreateCheckbox(L["PerCharOptions"], 
      function() return profile.perchar end, 
      function() TogglePerCharProfile() end)
    
    otherMenu:CreateDivider()
    
    otherMenu:CreateButton(L["ResetOptions"], function()
      ResetOptions()
    end)
    
    otherMenu:CreateButton(L["ResetFlightTimes"], function()
      ResetFlightTimes()
    end)
    
    otherMenu:CreateButton(L["ExportFlightTimes"], function()
      ExportFlightTimes()
    end)
  end)
end


