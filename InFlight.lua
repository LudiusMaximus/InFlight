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
local LLS = LibStub("LibLayoutSettings-1.0")

-- LOCALIZATION
local L = LibStub("AceLocale-3.0"):GetLocale("InFlight", not debug)
InFlight.L = L



InFlight.newPlayerSaveData = {}

InFlight.debug = false

-- LOCAL VARIABLES
local debug = InFlight.debug
local Print, PrintD = InFlight.Print, InFlight.PrintD
local profile  -- the user's own settings, written only by the settings menu
local look     -- what the bar is drawn from, see below
local taxiSrc, taxiSrcName, taxiDst, taxiDstName, endTime  -- location data
local porttaken, takeoff, inworld, outworld, ontaxi        -- flags
local ratio, endText = 0, "??"                             -- cache variables
local sb, spark, sparkGlow, timeText, locText, bord, back  -- frame elements
local previewActive, previewRequests = nil, {}             -- dummy flight, and who wants it
local totalTime, startTime, elapsed, throt = 0, 0, 0, 0    -- throttle variables
local oldTakeTaxiNode

-- A dropdown option tried on while the mouse rests on it, the way the barber
-- shop tries on a choice: drawn, never stored, so nothing that saves or compares
-- settings ever sees it. The bar reads its size, texture, border, spark, font
-- and font size through Drawn for that, and nothing else goes through it.
local hovered = {}
local function Drawn(key)
  local value = hovered[key]
  if value == nil then
    value = look[key]
  end
  return value
end

-- While a colour picker is open for the known or the unknown fill, "known" or
-- "unknown": the bar shows that fill whatever it is showing otherwise, so that
-- the colour can be judged as it is picked. Drawn only, like hovered.
local pickedFill

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

--------------------------------
function InFlight:ADDON_LOADED()
--------------------------------
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






-- The places gossip flights start from or go to, by AreaTable ID. The client
-- names them in its own language, in exactly the text GetMinimapZoneText
-- returns, and older clients use older names, so they are not translated here.
-- Honor Point has no area of its own and lies in Hellfire Peninsula. It and the
-- other destinations that are no area are translated in the locale files.
local areaIDs = {
  ["Amber Ledge"]                = 4023,
  ["Argent Tournament Grounds"]  = 4658,
  ["Blackwind Landing"]          = 3973,
  ["Caverns of Time"]            = 1941,
  ["Durnholde Keep"]             = 2370,
  ["Expedition Point"]           = 3815,
  ["Explorers' League Outpost"]  = 3997,
  ["Hellfire Peninsula"]         = 3483,
  ["Nighthaven"]                 = 2361,
  ["Old Hillsbrad Foothills"]    = 2367,
  ["Rut'theran Village"]         = 702,
  ["Shatter Point"]              = 3920,
  ["Shattered Sun Staging Area"] = 4085,
  ["Skyguard Outpost"]           = 3964,
  ["Stormwind City"]             = 1519,
  ["Sun's Reach Harbor"]         = 4087,
  ["The Sin'loren"]              = 4082,
  ["Thunder Bluff"]              = 1638,
  ["Valgarde"]                   = 3981,
}

-- The client's name for a place, nil for an area this client does not have.
local function AreaName(place)
  local name = C_Map.GetAreaInfo(areaIDs[place])
  if name and name ~= "" then
    return name
  end
end

-- A place's name for the bar: the client's, else the locale file's, else English.
local function PlaceName(place)
  return areaIDs[place] and AreaName(place) or L[place]
end


-- Support for flightpaths that are started by gossip options, by the area the
-- flight master stands in.
local gossipFlights = {
  ["Amber Ledge"]                = {{ find = L["AmberLedgeGossip"],        s = "Amber Ledge",                d = "Transitus Shield (Scenic Route)" }},
  ["Argent Tournament Grounds"]  = {{ find = L["ArgentTournamentGossip"],  s = "Argent Tournament Grounds",  d = "Return" }},
  ["Blackwind Landing"]          = {{ find = L["BlackwindLandingGossip"],  s = "Blackwind Landing",          d = "Skyguard Outpost" }},
  ["Caverns of Time"]            = {{ find = L["CavernsOfTimeGossip"],     s = "Caverns of Time",            d = "Nozdormu's Lair" }},
  ["Expedition Point"]           = {{ find = L["ExpeditionPointGossip"],   s = "Expedition Point",           d = "Shatter Point" }},
  ["Hellfire Peninsula"]         = {{ find = L["HellfirePeninsulaGossip"], s = "Honor Point",                d = "Shatter Point" }},
  ["Nighthaven"]                 = {{ find = L["NighthavenGossipA"],       s = "Nighthaven",                 d = "Rut'theran Village" },
                                    {  find = L["NighthavenGossipH"],       s = "Nighthaven",                 d = "Thunder Bluff" }},
  ["Old Hillsbrad Foothills"]    = {{ find = L["OldHillsbradGossip"],      s = "Old Hillsbrad Foothills",    d = "Durnholde Keep" }},
  ["Shatter Point"]              = {{ find = L["ShatterPointGossip"],      s = "Shatter Point",              d = "Honor Point" }},
  ["Skyguard Outpost"]           = {{ find = L["SkyguardOutpostGossip"],   s = "Skyguard Outpost",           d = "Blackwind Landing" }},
  ["Stormwind City"]             = {{ find = L["StormwindCityGossip"],     s = "Stormwind City",             d = "Return" }},
  ["Sun's Reach Harbor"]         = {{ find = L["SSSAGossip"],              s = "Shattered Sun Staging Area", d = "Return" },
                                    {  find = L["SSSAGossip2"],             s = "Shattered Sun Staging Area", d = "The Sin'loren" }},
  ["The Sin'loren"]              = {{ find = L["TheSin'lorenGossip"],      s = "The Sin'loren",              d = "Shattered Sun Staging Area" }},
  ["Valgarde"]                   = {{ find = L["ValgardeGossip"],          s = "Valgarde",                   d = "Explorers' League Outpost" }},
}

-- The same flights by the client's name of the area, made on first use.
local gossipFlightsByArea

-- Gossip texts are compared without spaces and with typographic apostrophes
-- made plain, as clients and translations differ in both.
local function Simplify(text)
  return (gsub(gsub(text, "’", "'"), "%s+", ""))
end


local function PrepareMiscFlight(buttonText)
  if not buttonText or buttonText == "" then
    return
  end

  if not gossipFlightsByArea then
    gossipFlightsByArea = {}
    for area, flights in pairs(gossipFlights) do
      local name = AreaName(area)
      if name then
        gossipFlightsByArea[name] = flights
      end
    end
  end

  local tsz = gossipFlightsByArea[GetMinimapZoneText()]
  if not tsz then
    return
  end

  buttonText = Simplify(buttonText)
  local source, destination
  for _, sz in ipairs(tsz) do
    if strfind(buttonText, Simplify(sz.find), 1, true) then
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

-- The spark and the glow some sparks trail behind them go together, which
-- BarStyles.lua sees to.
local function ShowSpark(shown)
  InFlight:ShowSpark(spark, sparkGlow, shown and Drawn("spark") ~= "None")
end

local function PlaceSpark(x)  -- x from the bar's left end
  InFlight:PlaceSpark(spark, sparkGlow, x)
end

-- A colour setting as the four numbers the API takes. AceDB fills every colour
-- in channel by channel, and a layout stores whole ones, so all four are there.
local function RGBA(color)
  return color.r, color.g, color.b, color.a
end

local function ColorText(text, color)  -- with a shadow that fades with it
  text:SetShadowColor(0, 0, 0, color.a)
  text:SetShadowOffset(1, -1)
  text:SetTextColor(RGBA(color))
end

local function SetToUnknown()  -- setup bar for flights with unknown time
  sb:SetMinMaxValues(0, 1)
  sb:SetValue(1)
  sb:SetStatusBarColor(RGBA(look.unknowncolor))
  ShowSpark(false)
end

-- The client loads a font file on demand. The first SetFont for a file returns
-- false and leaves the string on the font it had, and the load only completes on
-- a later frame, so the call has to be repeated. The load lasts for the session,
-- which is why a font only ever misbehaves the first time it is used after a
-- client start and never again after a reload. There is no API to load a font up
-- front, and every size and outline combination becomes available together once
-- the file is in, so there is nothing to avoid, only to wait for.
--
-- The catch is that the pending load is only picked up when the string is laid
-- out again. Repeating SetFont on a string that is otherwise left alone gets
-- false forever, no matter how long it is left. That is why changing any other
-- bar setting, which re-anchors these strings and rewrites their text, was what
-- used to make a newly picked font appear.
--
-- So: ask again, and make the string lay itself out between attempts. Dropping
-- the outline is kept as a cheap safety net, since the right font without one
-- would still beat the wrong font with one.
local fontRetryDelays = { 0.1, 0.25, 0.5, 1, 2, 4, 8 }
local fontRetryToken = 0

-- Returns true once the string carries the configured font, outline or not.
local function ApplyFontTo(fontString, fontPath, size, flags)
  if fontPath and fontString:SetFont(fontPath, size, flags) then
    return true
  end

  -- Not every font takes an outline at every size. The right font without one
  -- beats keeping whatever font happened to be there before.
  if fontPath and flags ~= "" and fontString:SetFont(fontPath, size, "") then
    return true
  end

  -- A string that never got a font at all throws on the next SetText.
  if not fontString:GetFont() then
    fontString:SetFont(STANDARD_TEXT_FONT or GameFontNormal:GetFont(), size, flags)
  end

  -- The pending load is only picked up once the string is laid out again, so give
  -- it a reason to be. Asking again without this never comes good, however long
  -- it is left, which is why changing some other bar setting by hand was what used
  -- to fix it.
  local text = fontString:GetText() or ""
  fontString:SetText(text .. " ")
  fontString:SetText(text)

  return false
end

-- Returns true once both strings carry the configured font.
local function ApplyBarFonts()
  -- Fetch hands back the default, or a global override, in place of an unknown
  -- key, and nil only when there is no media table at all. So a wrong key gives a
  -- plausible wrong font rather than an error.
  local fontPath = smed:Fetch("font", Drawn("font"))

  -- Both have to run, so do not let "and" short circuit the second one away.
  local locOk = ApplyFontTo(locText, fontPath, Drawn("fontsize"), look.outline and "OUTLINE" or "")
  local timeOk = ApplyFontTo(timeText, fontPath, Drawn("fontsize"), look.outlinetime and "OUTLINE" or "")

  return locOk and timeOk
end

local function ApplyBarFontsWithRetry()
  if ApplyBarFonts() then
    return
  end

  fontRetryToken = fontRetryToken + 1
  local token = fontRetryToken

  -- One pending timer at a time, each attempt booking the next, rather than the
  -- whole chain queued at once: UpdateLook runs on every step of a slider drag,
  -- and a chain per step would leave hundreds of timers pending for one font.
  -- The delays are counted from this call, so each wait is the gap to the next.
  local function Attempt(index)
    local delay = fontRetryDelays[index]
    if not delay then
      return
    end

    C_Timer.After(delay - (fontRetryDelays[index - 1] or 0), function()
      -- A newer attempt took over.
      if token ~= fontRetryToken then
        return
      end
      if not ApplyBarFonts() then
        Attempt(index + 1)
      end
    end)
  end

  Attempt(1)
end

-- LibSharedMedia offers the client's Korean and Chinese font files to western
-- clients as well, on the strength of a glyph coverage check made in 2012. They
-- no longer earn their place. Measured at size 16 on 12.1.0, "2002 Bold" renders
-- latin and digits pixel identical to Friz Quadrata, "2002" differs only by a
-- third of a pixel per digit, and the three AR files share one latin set between
-- them. Their own scripts do render, but a western client never asks for them.
--
-- Other locales keep the full list, because there these files are the point, and
-- fonts registered by other addons are never touched.
local redundantWesternFonts = {
  ["2002"] = true,
  ["2002 Bold"] = true,
  ["AR CrystalzcuheiGBK Demibold"] = true,
  ["AR ZhongkaiGBK Medium"] = true,
  ["AR ZhongkaiGBK Medium (Combat)"] = true,
}

local nonWesternLocales = { koKR = true, zhCN = true, zhTW = true, ruRU = true }

-------------------------------
function InFlight:GetFontList()  -- the fonts worth offering on this client
-------------------------------
  local fonts = smed:List("font")
  if nonWesternLocales[GetLocale()] then
    return fonts
  end

  local offered = {}
  for _, name in ipairs(fonts) do
    if not redundantWesternFonts[name] then
      offered[#offered + 1] = name
    end
  end
  return offered
end

-- How far up the bar's text moves for each font, as a share of the font size,
-- down if negative. Letters sit higher or lower in their line from one font to
-- the next, and by as much more as the font is larger, so a share holds at every
-- size where pixels would not: 0.05 is a pixel at size 20. These are the fonts
-- LibSharedMedia registers itself, on every client. Any other, another addon's
-- say, is not moved.
local fontOffsets = {
  ["2002"] = 0,
  ["2002 Bold"] = 0,
  ["AR CrystalzcuheiGBK Demibold"] = 0,
  ["AR ZhongkaiGBK Medium"] = 0,
  ["AR ZhongkaiGBK Medium (Combat)"] = 0,
  ["Arial Narrow"] = -0.05,
  ["Friz Quadrata TT"] = -0.075,
  ["MoK"] = 0,
  ["Morpheus"] = 0,
  ["Nimrod MT"] = -0.05,
  ["Skurri"] = -0.1,
  -- koKR
  ["굵은 글꼴"] = 0,
  ["기본 글꼴"] = 0,
  ["데미지 글꼴"] = 0,
  ["퀘스트 글꼴"] = 0,
  -- zhCN and zhTW, which share 聊天 as a name
  ["伤害数字"] = 0,
  ["默认"] = 0,
  ["聊天"] = 0,
  ["提示訊息"] = 0,
  ["傷害數字"] = 0,
  ["預設"] = 0,
}

-- How far up the text in that font at that size moves, in pixels.
-----------------------------------------
function InFlight:FontOffsetY(name, size)
-----------------------------------------
  return (fontOffsets[name] or 0) * size
end


-- Sample flight for the preview. Two real flight points, picked at the
-- median length of the 731 names in the defaults, so that the preview shows the
-- bar carrying about as much text as it usually will.
local previewTotal, previewDone = 90, 54
local previewSrcName, previewDstName = "Menethil Harbor", "Nethergarde Keep"

local function SetToPreview()  -- fill the bar with the preview's dummy flight
  -- The spark rides the filled edge, so it takes the bar's value rather than the
  -- elapsed time, which are the same thing only when Fill Up is on.
  local value = look.fill and previewDone or previewTotal - previewDone
  sb:SetMinMaxValues(0, previewTotal)
  sb:SetValue(value)
  sb:SetStatusBarColor(RGBA(look.barcolor))
  PlaceSpark(Drawn("width") * value / previewTotal)
  ShowSpark(true)
end

-- The unknown fill is for a flight of unknown length, unless a colour picker is
-- open for the other fill.
local function ShowsUnknown()
  if pickedFill then
    return pickedFill == "unknown"
  end
  return not previewActive and not endTime
end

-- The time text, matching the fill: beside the unknown one the time flown up to
-- "??", beside a known one the time to go, or flown with Count Up, of its length.
local function ShowTime(flown, total, totalText)
  if ShowsUnknown() then
    timeText:SetFormattedText("%s / %s", FormatTime(flown), FormatTime(nil))
  elseif not total then
    -- A flight of unknown length wearing the preview's known fill.
    ShowTime(previewDone, previewTotal)
  else
    timeText:SetFormattedText("%s / %s",
      FormatTime(look.countup and flown or total - flown), totalText or FormatTime(total))
  end
end

local function ShowFill()  -- the fill the bar shows now, known or unknown
  if ShowsUnknown() then
    SetToUnknown()
  elseif previewActive or not endTime then
    -- The preview, or the preview's flight standing in for one of unknown length.
    SetToPreview()
  else
    ratio = Drawn("width") / endTime
    sb:SetMinMaxValues(0, endTime)
    sb:SetStatusBarColor(RGBA(look.barcolor))
    ShowSpark(true)
  end
  -- The bar may have been showing another fill, so a flight's own value and time
  -- go back on with the next update, which this makes the very next frame.
  elapsed = throt
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

  -- Intermediate hops of cross-map routes cannot always be resolved to a node ID,
  -- because GetNodeID only searches the currently viewed taxi map. Without every
  -- node ID the per-hop durations cannot be summed, so skip the estimate (caller
  -- falls back to "-:--") instead of erroring on a nil node below.
  for hop = 1, numRoutes + 1, 1 do
    if not taxiNodes[hop] then
      return
    end
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
      self:ShowSettings()
    end

  end
  SLASH_INFLIGHT1 = "/inflight"


  -- The addon settings panel. It scrolls, because with the bar's settings on it
  -- the page is taller than the settings window.
  local panel = CreateFrame("Frame")
  -- Hidden until the settings window shows it. It only calls Show, which does
  -- nothing to a frame that is already shown, so OnShow would never run the
  -- first time the page is opened.
  panel:Hide()

  local scroll = CreateFrame("ScrollFrame", nil, panel, "ScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 0, -4)
  scroll:SetPoint("BOTTOMRIGHT", -28, 4)
  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(1, 1)
  scroll:SetScrollChild(content)

  local t1 = content:CreateFontString(nil, "ARTWORK")
  t1:SetFontObject(GameFontNormalLarge)
  t1:SetJustifyH("LEFT")
  t1:SetJustifyV("TOP")
  t1:SetPoint("TOPLEFT", 16, -12)
  t1:SetText("|cff0040ffIn|cff00aaffFlight|r")

  local t2 = content:CreateFontString(nil, "ARTWORK")
  t2:SetFontObject(GameFontHighlight)
  t2:SetJustifyH("LEFT")
  t2:SetJustifyV("TOP")
  SetPoints(t2, "TOPLEFT", t1, "BOTTOMLEFT", 0, -8, "RIGHT", content, "RIGHT", -16, 0)
  t2:SetNonSpaceWrap(true)
  local function GetInfo(field)
    return C_AddOns.GetAddOnMetadata("InFlight", field) or "N/A"
  end
  t2:SetFormattedText("|cff00aaffAuthor:|r %s\n|cff00aaffVersion:|r %s\n\n%s|r", GetInfo("Author"), GetInfo("Version"), GetInfo("Notes"))

  -- The settings menu, the same one right-clicking the bar opens.
  local menuButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
  menuButton:SetText(L["Menu"])
  menuButton:SetWidth(max(120, menuButton:GetTextWidth() + 20))
  menuButton:SetScript("OnClick", InFlight.ShowSettings)
  menuButton:SetPoint("TOPLEFT", t2, "BOTTOMLEFT", -2, -8)

  -- A made-up flight on the bar, to see the settings without flying anywhere.
  -- Greyed out while a real flight is on the bar, which shows them already.
  local previewButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
  previewButton:SetPoint("LEFT", menuButton, "RIGHT", 8, 0)
  previewButton:SetMotionScriptsWhileDisabled(true)
  -- Wide enough for either label, so that it does not change size when clicked.
  previewButton:SetText(L["HidePreview"])
  local labelWidth = previewButton:GetTextWidth()
  previewButton:SetText(L["ShowPreview"])
  previewButton:SetWidth(max(120, labelWidth + 20, previewButton:GetTextWidth() + 20))

  local function RefreshPreviewButton()
    previewButton:SetEnabled(not InFlight:IsShown())
    previewButton:SetText(previewRequests.settings and L["HidePreview"] or L["ShowPreview"])
  end

  previewButton:SetScript("OnClick", function()
    InFlight:SetPreview("settings", not previewRequests.settings)
    RefreshPreviewButton()
  end)
  previewButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(GameTooltip, self:GetText())
    GameTooltip_AddNormalLine(GameTooltip, L["PreviewTooltip"], true)
    if not self:IsEnabled() then
      GameTooltip_AddBlankLineToTooltip(GameTooltip)
      GameTooltip_AddErrorLine(GameTooltip, L["PreviewInFlight"], true)
    end
    GameTooltip:Show()
  end)
  previewButton:SetScript("OnLeave", GameTooltip_Hide)

  -- The InFlight frame runs only while a real flight does, so its showing and
  -- hiding is a flight starting and ending, which may happen with the page open.
  -- Taking off also ends the preview, which the label has to follow.
  InFlight:HookScript("OnShow", RefreshPreviewButton)
  InFlight:HookScript("OnHide", RefreshPreviewButton)

  -- Below the buttons and a divider, the same rows the layout editor shows for
  -- the bar. They change whatever the settings menu changes, and their Revert
  -- Changes goes back to how the bar looked when the page was opened. Drawn when
  -- the page is first opened, because the edit mode registration needs the saved
  -- variables. The library places its rows 26 in from its frame's left edge and
  -- the buttons sit 2 left of the text above them, hence the offset that lines
  -- the row labels up with that text.
  local rows, divider

  -- The scroll range has to reach the last thing shown, which is only laid out
  -- by the frame after the page shows or changes.
  local function FitContent()
    local last = rows and rows:IsShown() and rows or menuButton
    local top, bottom = content:GetTop(), last:GetBottom()
    if top and bottom then
      content:SetHeight(top - bottom + 16)
    end
  end

  -- A scroll child takes no size from anchors, so it follows the scroll frame's
  -- width by hand. The text above the buttons wraps to it.
  scroll:HookScript("OnSizeChanged", function(_, width)
    content:SetWidth(width)
    C_Timer.After(0, FitContent)
  end)

  -- The rows only show while the bar does, as a flight or the preview, because
  -- what they change is how it looks.
  local function ShowRowsWithBar()
    local shown = InFlight:GetBar():IsShown()
    rows:SetShown(shown)
    divider:SetShown(shown)
    C_Timer.After(0, FitContent)
  end

  panel:SetScript("OnShow", function()
    if not rows then
      -- Opened by the whole page, so that the rows hiding and showing with the
      -- bar does not move the point their Revert Changes goes back to.
      rows = InFlight:CreateSettingsRows(content, panel)
      if rows then
        -- 32 down leaves the divider 16 and 8 either side of it.
        rows:SetPoint("TOPLEFT", menuButton, "BOTTOMLEFT", 2 - 26, -32)

        -- The divider the library draws between rows, centred over them the
        -- way it centres its own.
        divider = content:CreateTexture(nil, "ARTWORK")
        divider:SetTexture([[Interface\FriendsFrame\UI-FriendsFrame-OnlineDivider]])
        divider:SetSize(330, 16)
        divider:SetPoint("BOTTOM", rows, "TOP", 0, 8)

        local bar = InFlight:GetBar()
        bar:HookScript("OnShow", ShowRowsWithBar)
        bar:HookScript("OnHide", ShowRowsWithBar)
      end
    end
    if rows then
      ShowRowsWithBar()
    end
    RefreshPreviewButton()
    InFlight:SetBarAboveSettings(true)
  end)

  -- The preview belongs to this page, so leaving the page takes it away, and the
  -- bar goes back below the rest of the interface.
  panel:SetScript("OnHide", function()
    InFlight:SetPreview("settings", false)
    InFlight:SetBarAboveSettings(false)
  end)

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

-- The profile defaults each settings version replaced, the keys whose default
-- changed and what it was before. Version 1 is everything up to 12.0.011.
local replacedDefaults = {
  [1] = {
    countup = true,
    texture = "Blizzard",
    width = 300,
    height = 14,
    border = "Blizzard Dialog",
    barcolor = { r = 0.5, g = 0.5, b = 0.8, a = 1.0, },
    unknowncolor = { r = 0.2, g = 0.2, b = 0.4, a = 1.0, },
    backcolor = { r = 0.1, g = 0.1, b = 0.1, a = 0.6, },
    bordercolor = { r = 0.6, g = 0.6, b = 0.6, a = 0.8, },
    inline = false,
    totext = " >--In Route To--> ",
    font = "2002 Bold",  -- outside Russian clients replaced, see RepairFont
    fontsize = 12,
    outline = false,
    outlinetime = false,
  },
}
local settingsVersion = #replacedDefaults + 1

-- AceDB leaves out of the saved variables every value that matches its default,
-- so a value missing from a profile stands for whatever the default was when it
-- was saved. A changed default would therefore change the bar of everyone who
-- never touched that setting. So every existing profile first gets the defaults
-- it was saved under written in as its own values, and settingsVersion records
-- which defaults the profiles have been brought past.
--
-- This has to run before AceDB fills the new defaults in, because until then an
-- absent value can only mean the old default. AceDB strips a colour channel by
-- channel, so a colour can be stored in part, and its missing channels are
-- filled in the same way. Values that match the new defaults are left out again
-- at logout, as usual.
--
-- A fresh install never had the old defaults, and neither has a profile made
-- from now on, so only the profiles there are now are brought along.
-----------------------------------------------
function InFlight:MigrateSettings(freshInstall)
-----------------------------------------------
  if freshInstall then
    InFlightDB.settingsVersion = settingsVersion
  end

  -- A profile that only ever held defaults may never have been saved at all.
  -- It was on the old defaults all the same.
  local profiles = InFlightDB.profiles or {}
  InFlightDB.profiles = profiles
  if (InFlightDB.settingsVersion or 1) < settingsVersion then
    profiles.Default = profiles.Default or {}
    for _, name in pairs(InFlightDB.profileKeys or {}) do
      profiles[name] = profiles[name] or {}
    end
  end

  for version = InFlightDB.settingsVersion or 1, settingsVersion - 1 do
    for _, savedProfile in pairs(profiles) do
      for key, old in pairs(replacedDefaults[version]) do
        local saved = savedProfile[key]
        if type(old) == "table" then
          if type(saved) ~= "table" then
            saved = {}
            savedProfile[key] = saved
          end
          for channel, value in pairs(old) do
            if saved[channel] == nil then
              saved[channel] = value
            end
          end
        -- Builds made while the "to" text was on its way to its new default
        -- already wrote the old one in, and left this flag behind.
        elseif saved == nil and not (key == "totext" and InFlightDB.totextMigrated) then
          savedProfile[key] = old
        end
      end
    end
  end

  InFlightDB.settingsVersion = settingsVersion
  InFlightDB.totextMigrated = nil
end

----------------------------
function InFlight:LoadBulk()
----------------------------

  -- SavedVariables. Whether there were any is worth knowing before they are
  -- created, because the conversion below gives even a brand new install a
  -- Default profile, which then looks exactly like an old one nobody changed.
  local freshInstall = InFlightDB == nil
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

  -- Every era gets its own database, because the eras do not share flight times.
  -- Ratchet to Orgrimmar takes 210 seconds on Classic Era, where the trip goes via
  -- The Crossroads, and 101 seconds on TBC Classic, where it is direct.
  -- Everlook to Marshal's Stand takes 641 seconds on TBC Classic and 815 on retail.
  --
  -- Raise the dbinit of an era to wipe the databases of that era once. All four
  -- had to be raised here, because times measured before the speed boost fix were
  -- stored with the boost included, and because the pre-Cataclysm defaults have
  -- been split up by era.
  local buildInterface = select(4, GetBuildInfo())
  local dbVersion, dbinitVersion
  if buildInterface >= 40000 then
    dbVersion, dbinitVersion = "post-cata", 1200010
  elseif buildInterface >= 30000 then
    dbVersion, dbinitVersion = "wrath", 1200010
  elseif buildInterface >= 20000 then
    dbVersion, dbinitVersion = "tbc", 1200010
  else
    dbVersion, dbinitVersion = "classic-era", 1200010
  end

  if InFlightDB.dbinit ~= dbinitVersion then
    resetDB = true
    InFlightDB.dbinit = dbinitVersion
  end

  -- Check that this is the right version of the database to avoid corruption.
  if InFlightDB.version ~= dbVersion then
    resetDB = true
    InFlightDB.version = dbVersion
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

  self:MigrateSettings(freshInstall)

  -- Create self.db SavedVariables InFlightDB with Inflight.defaults as defaults.
  self.db = LibStub("AceDB-3.0"):New("InFlightDB", self.defaults, true)
  -- Map to local variable.
  profile = self.db.profile

  -- What the bar is drawn from: the active edit mode layout's overrides on top,
  -- falling through to the user's own settings for every key the layout does not
  -- set. A layout never writes to db.profile, so the profile always holds what
  -- the user chose, whatever a layout happens to be painting over it.
  --
  -- Everything that draws the bar reads look. Everything in the settings menu
  -- reads and writes profile. That is the whole rule, and it is the reason there
  -- is no shadow copy of the settings to keep in sync.
  look = setmetatable({}, {__index = function(_, key) return profile[key] end})

  -- Media names that look like a number used to be stored as one, which matches
  -- no LibSharedMedia entry, so Fetch silently handed back the default instead.
  -- The font named "2002" was the one this bit.
  local function RepairMediaKeys(t)
    if type(t) ~= "table" then
      return
    end
    for _, key in ipairs({"font", "texture", "border"}) do
      if type(t[key]) == "number" then
        t[key] = tostring(t[key])
      end
    end
  end

  -- The spark used to be on or off, before there was more than one to pick.
  local function RepairSpark(t)
    if type(t) == "table" and type(t.spark) == "boolean" then
      t.spark = t.spark and "Classic" or "None"
    end
  end

  -- "2002 Bold", the old default font, is left out of the font list on western
  -- clients, where it draws the same as Friz Quadrata. Korean and Chinese
  -- clients have no font of that name at all: LibSharedMedia registers it only
  -- for western and Russian ones, so there it has always drawn as the client's
  -- default font. Either way a bar set to it gets the client's default instead,
  -- Friz Quadrata on a western client. It looks no different, and the font
  -- lists then have it selected. Only on a Russian client is it a font of its
  -- own, and kept.
  local function RepairFont(t)
    if type(t) == "table" and t.font == "2002 Bold" and GetLocale() ~= "ruRU" then
      t.font = smed:GetDefault("font")
    end
  end

  local function Repair(t)
    RepairMediaKeys(t)
    RepairSpark(t)
    RepairFont(t)
  end

  -- The profile in use, whichever table that turns out to be, and then every
  -- stored one so that switching profiles does not bring the problem back.
  Repair(profile)
  if InFlightDB.profiles then
    for _, savedProfile in pairs(InFlightDB.profiles) do
      Repair(savedProfile)
    end
  end

  -- Every edit mode layout holds its own copy of these settings and lays them
  -- over the profile whenever the layout is applied, so repairing only the
  -- profile would leave the old value to come back through the override.
  if InFlightDB.editModeLayouts then
    for _, layout in pairs(InFlightDB.editModeLayouts) do
      Repair(layout.settings)
    end
  end


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

    if look.confirmflight then  -- confirm flight
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

  -- Needs self.db, so it cannot happen in SetupInFlight.
  if self.SetupEditMode then
    self:SetupEditMode()
  end

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
    if taxiMapID == 1467 and GetMinimapZoneText() == PlaceName("Shatter Point") then
      taxiSrcName = PlaceName("Shatter Point")
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
  -- A real flight always wins over the preview, and ends every request for it.
  previewActive = nil
  wipe(previewRequests)

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
    sb:SetValue(look.fill and 0 or endTime)
    PlaceSpark(look.fill and 0 or Drawn("width"))
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
  throt = min(0.2, (endTime or 50) / (look.width or 1))  -- increases updates for short flights

  self:RegisterEvent("LFG_PROPOSAL_DONE")
  self:RegisterEvent("LFG_PROPOSAL_SUCCEEDED")
  self:RegisterEvent("PLAYER_CONTROL_GAINED")
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterEvent("PLAYER_LEAVING_WORLD")

  -- Remember the flight, so that a UI reload during it loses neither the bar nor
  -- the measurement. Only reloads can be recovered, see InFlight:RecoverFlight.
  self:RememberFlight()

  if slot then
    oldTakeTaxiNode(slot)
  end
end


----------------------------------
function InFlight:RememberFlight()
----------------------------------
  if not self.db then
    return
  end

  -- This must not go into db.global. That table is walked as pure flight time data,
  -- once to drop times that duplicate the defaults and once to collect the export,
  -- and both loops take every key in it for a faction. db.char is simply a scope
  -- that is out of their way. Nothing here relies on it being per character: a
  -- reload cannot change the character, and a logout is not recovered anyway.
  --
  -- The expected duration is kept as it was worked out at take off rather than
  -- worked out again. An estimate from the route's hops needs the flight map open,
  -- and its text carries the "~" that says it is one.
  self.db.char.inTransit = taxiSrc and {
    src = taxiSrc,
    srcName = taxiSrcName,
    dst = taxiDst,
    dstName = taxiDstName,
    startTime = startTime,
    endTime = endTime,
    endText = endText,
    airborne = ontaxi and true or nil,
  } or nil
end


----------------------------------------------
function InFlight:RecoverFlight(isReloadingUi)  -- pick a flight back up after a UI reload
----------------------------------------------
  local saved = self.db and self.db.char.inTransit
  if not saved then
    return
  end
  self.db.char.inTransit = nil

  -- Only a reload keeps the character in the world, so only then has the flight kept
  -- going and GetTime() kept running. After a logout the flight is paused while
  -- GetTime() is not, and no API tells us how much of the flight is left.
  if not isReloadingUi or not UnitOnTaxi("player") then
    return
  end

  -- Before take off the clock still includes the delay between clicking the flight
  -- master and lifting off, which would end up in the measured flight time.
  if not saved.airborne then
    return
  end

  -- A restarted client resets GetTime(), which makes the stored time meaningless.
  local flown = GetTime() - saved.startTime
  if flown < 0 then
    return
  end

  taxiSrc, taxiSrcName = saved.src, saved.srcName
  taxiDst, taxiDstName = saved.dst, saved.dstName
  endTime, endText = saved.endTime, saved.endText

  if not sb then
    self:CreateBar()
  end

  if endTime then
    sb:SetMinMaxValues(0, endTime)
  else
    SetToUnknown()
  end

  self:UpdateLook()
  sb:Show()
  self:Show()

  -- Continue the flight rather than start one: there is no take off left to wait for.
  porttaken, takeoff = nil, nil
  ontaxi, inworld = true, true
  elapsed, totalTime, startTime = 0, flown, saved.startTime
  throt = min(0.2, (endTime or 50) / (look.width or 1))

  self:RegisterEvent("LFG_PROPOSAL_DONE")
  self:RegisterEvent("LFG_PROPOSAL_SUCCEEDED")
  self:RegisterEvent("PLAYER_CONTROL_GAINED")
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterEvent("PLAYER_LEAVING_WORLD")

  -- Store it again, so that a second reload during the same flight also works.
  self:RememberFlight()

  PrintD("|cff208080Recovered flight after reload,|r", FormatTime(flown), "|cff208080flown|r")
end


-- InFlight's own PLAYER_ENTERING_WORLD handler only exists while a flight is running,
-- so recovery needs a frame of its own. Only the first event after loading matters.
local recoverFrame = CreateFrame("Frame")
recoverFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
recoverFrame:SetScript("OnEvent", function(this, event, isInitialLogin, isReloadingUi)
  this:UnregisterEvent("PLAYER_ENTERING_WORLD")
  InFlight:RecoverFlight(isReloadingUi)
end)

-------------------------------------------
function InFlight:StartMiscFlight(src, dst)  -- called for flights started by a gossip option
-------------------------------------------
  taxiSrcName = PlaceName(src)
  taxiSrc = src
  taxiDstName = PlaceName(dst)
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
    sb:SetPoint(look.p, UIParent, look.rp, look.x, look.y)
    sb:SetMovable(true)
    sb:EnableMouse(true)
    sb:SetClampedToScreen(true)
    sb:SetScript("OnMouseUp", function(this, a1)
      if a1 == "RightButton" then
        InFlight:ShowSettings()
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
      -- Meant to stick, just like a change made in the settings menu.
      InFlight:SetLook("p", a)
      InFlight:SetLook("rp", c)
      InFlight:SetLook("x", floor(d + 0.5))
      InFlight:SetLook("y", floor(e + 0.5))
      InFlight:CaptureEditModeLayout()
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

    -- Above the spark and its glow, which are OVERLAY at sublevels 0 and 1.
    timeText = sb:CreateFontString(nil, "OVERLAY")
    timeText:SetDrawLayer("OVERLAY", 2)
    locText = sb:CreateFontString(nil, "OVERLAY")
    locText:SetDrawLayer("OVERLAY", 2)

    -- Their art is set by UpdateLook, from the spark picked.
    spark = sb:CreateTexture(nil, "OVERLAY")
    spark:Hide()
    sparkGlow = sb:CreateTexture()
    sparkGlow:Hide()

    bord = CreateFrame("Frame", nil, sb, BackdropTemplateMixin and "BackdropTemplate")  -- LibSharedMedia border
    SetPoints(bord, "TOPLEFT", sb, "TOPLEFT", -5, 5, "BOTTOMRIGHT", sb, "BOTTOMRIGHT", 5, -5)
    bord:SetFrameStrata("LOW")

    -- What shows where the bar is not yet full: the bar's own texture in the
    -- background colour, a pixel larger all round, unless the border brings a
    -- background of its own.
    back = sb:CreateTexture(nil, "BACKGROUND")
    SetPoints(back, "TOPLEFT", sb, "TOPLEFT", -1, 1, "BOTTOMRIGHT", sb, "BOTTOMRIGHT", 1, -1)

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
          -- Take off resets the clock, so the stored flight has to follow.
          InFlight:RememberFlight()
        elseif totalTime > 5 then
          InFlight.db.char.inTransit = nil
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



          -- Stored times are always without speed boosts, while measured times include them.
          local speedFactor = InFlight:KhazAlgarFlightMasterFactor(taxiDst) * InFlight:RideLikeTheWindFactor()

          InFlight.db.global[faction][taxiSrc] = InFlight.db.global[faction][taxiSrc] or { name = taxiSrcName }
          local oldTime = InFlight.db.global[faction][taxiSrc][taxiDst]
          if oldTime then
            oldTime = oldTime * speedFactor
          end
          local newTime = floor(totalTime + 0.5)


          local msg = strjoin(" ", taxiSrcName .. (debug and "(" .. taxiSrc .. ")" or ""), look.totext, taxiDstName .. (debug and "(" .. taxiDst .. ")" or ""), "|cff208080")
          if not oldTime then
            msg = msg .. L["FlightTimeAdded"] .. "|r " .. FormatTime(newTime)

          elseif abs(newTime - oldTime) > 2 then
            msg = msg .. L["FlightTimeUpdated"] .. "|r " .. FormatTime(oldTime) .. " |cff208080" .. look.totext .. "|r " .. FormatTime(newTime)

          else
            newTime = oldTime
            msg = nil
          end

          -- Compare and export without the speed boost, because that is how defaults are stored.
          local newBaseTime = floor(newTime / speedFactor + 0.5)

          if not defaultsGlobal[faction][taxiSrc] or not defaultsGlobal[faction][taxiSrc][taxiDst] or abs(newBaseTime - defaultsGlobal[faction][taxiSrc][taxiDst]) > 2 then
            -- print("Updating ", newBaseTime, "as new time for", taxiSrcName)
            newPlayerSaveData[faction] = newPlayerSaveData[faction] or {}
            newPlayerSaveData[faction][taxiSrc] = newPlayerSaveData[faction][taxiSrc] or {}
            newPlayerSaveData[faction][taxiSrc][taxiDst] = newBaseTime
          end

          InFlight.db.global[faction][taxiSrc][taxiDst] = newBaseTime


          if msg and look.chatlog then
            Print(msg)
          end
        end

        taxiSrcName = nil
        taxiSrc = nil
        taxiDstName = nil
        taxiDst = nil
        endTime = nil
        endText = FormatTime(endTime)
        InFlight.db.char.inTransit = nil
        sb:Hide()
        this:Hide()

        return
      end

      if endTime then  -- update statusbar if destination time is known
        if totalTime - 2 > endTime then   -- in case the flight is longer than expected
          endTime = nil
          endText = FormatTime(endTime)
          ShowFill()
        else
          local curTime = totalTime
          if curTime > endTime then
            curTime = endTime
          elseif curTime < 0 then
            curTime = 0
          end

          -- Not while a colour picker has the bar showing the unknown fill.
          if not ShowsUnknown() then
            local value = look.fill and curTime or (endTime - curTime)
            sb:SetValue(value)
            PlaceSpark(value * ratio)
          end

          ShowTime(curTime, endTime, endText)
        end
      else  -- destination time is unknown, so show that it's timing
        ShowTime(totalTime)
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
        -- The stored flight has to follow, or a reload later in the same flight
        -- would measure from before the loading screen and count it as flying.
        self:RememberFlight()
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

    sb:SetWidth(Drawn("width"))
    sb:SetHeight(Drawn("height"))

    -- The texture is a LibSharedMedia file or one of Blizzard's atlases from
    -- BarStyles.lua. An atlas leaves its own texture coordinates behind, so a
    -- file has to put the whole texture back.
    local texture, isAtlas = self:GetBarTextureAsset(Drawn("texture"))
    if isAtlas then
      back:SetAtlas(texture)
    else
      back:SetTexture(texture)
      back:SetTexCoord(0, 1, 0, 1)
    end
    back:SetVertexColor(RGBA(look.backcolor))

    -- A border of Blizzard's art is drawn by BarStyles.lua, which says how far
    -- above the bar it reaches, whether it drew a background of its own, how far
    -- its ends reach into the bar, and how far up the text in the bar sits in its
    -- opening. Any other is a LibSharedMedia edge, of which "None" reaches
    -- nowhere and the rest a few pixels above, with whatever room for the text
    -- BarStyles.lua gives it.
    local border = Drawn("border")
    local borderTop, ownBackground, borderInset, borderOffsetY =
      self:DrawBarBorder(sb, border, look.bordercolor, look.backcolor, look.borderbg)
    if borderTop then
      bord:SetBackdrop(nil)
    else
      bord:SetBackdrop({ edgeFile = smed:Fetch("border", border), edgeSize = 16 })
      bord:SetBackdropBorderColor(RGBA(look.bordercolor))
      borderTop = border == "None" and 0 or 2
      borderInset, borderOffsetY = self:MediaBorderTextOffsets(border)
    end
    back:SetShown(not ownBackground)

    sb:SetStatusBarTexture(texture)
    if sb:GetStatusBarTexture() then
      sb:GetStatusBarTexture():SetHorizTile(false)
      sb:GetStatusBarTexture():SetVertTile(false)
    end

    self:StyleSpark(spark, sparkGlow, Drawn("spark"), Drawn("height"))
    ShowFill()

    ApplyBarFontsWithRetry()

    ColorText(locText, look.fontcolor)
    ColorText(timeText, look.fontcolor)

    -- The preview shows names of its own rather than writing them into the
    -- flight's variables, which a flight master opened during the preview would
    -- then fill in for real and ending the preview would wipe out again.
    local srcName = previewActive and previewSrcName or taxiSrcName or "??"
    local dstName = previewActive and previewDstName or taxiDstName or "??"

    -- The font's own offset moves all of the text, the border's only the text in
    -- the bar.
    local fontOffsetY = self:FontOffsetY(Drawn("font"), Drawn("fontsize"))
    local insideY = borderOffsetY + fontOffsetY
    local aboveTop = borderTop + Drawn("fontsize") * 2.5 + fontOffsetY
    local aboveBottom = borderTop + 1 + fontOffsetY

    if look.inline then
      timeText:SetJustifyH("RIGHT")
      timeText:SetJustifyV("MIDDLE")
      SetPoints(timeText, "RIGHT", sb, "RIGHT", -4 - borderInset, insideY)
      locText:SetJustifyH("LEFT")
      locText:SetJustifyV("MIDDLE")
      SetPoints(locText, "LEFT", sb, "LEFT", 4 + borderInset, insideY, "RIGHT", timeText, "LEFT", -2, 0)
      locText:SetText(dstName)
    elseif look.twolines then
      timeText:SetJustifyH("CENTER")
      timeText:SetJustifyV("MIDDLE")
      SetPoints(timeText, "CENTER", sb, "CENTER", 0, insideY)
      locText:SetJustifyH("CENTER")
      locText:SetJustifyV("BOTTOM")
      SetPoints(locText, "TOPLEFT", sb, "TOPLEFT", -24, aboveTop, "BOTTOMRIGHT", sb, "TOPRIGHT", 24, aboveBottom)
      locText:SetFormattedText("%s %s\n%s", srcName, look.totext, dstName)
    else
      timeText:SetJustifyH("CENTER")
      timeText:SetJustifyV("MIDDLE")
      SetPoints(timeText, "CENTER", sb, "CENTER", 0, insideY)
      locText:SetJustifyH("CENTER")
      locText:SetJustifyV("BOTTOM")
      SetPoints(locText, "TOPLEFT", sb, "TOPLEFT", -24, aboveTop, "BOTTOMRIGHT", sb, "TOPRIGHT", 24, aboveBottom)
      locText:SetFormattedText("%s %s %s", srcName, look.totext, dstName)
    end

    -- Down here, because the time text has no font until this function sets one,
    -- which is why nothing else writes text before that point either.
    if previewActive then
      ShowTime(previewDone, previewTotal)
    end
  end

  --------------------------
  function InFlight:GetBar()  -- the timer bar, created on first use
  --------------------------
    if not sb then
      self:CreateBar()
    end
    return sb
  end

  --------------------------------------------
  function InFlight:SetBarAboveSettings(above)  -- while the settings page is open
  --------------------------------------------
    -- The settings window is at HIGH, so the bar goes one up to DIALOG to be
    -- watched while it is changed. The colour picker is at DIALOG too, but as a
    -- top level frame it is raised above the bar when it opens. The border, a
    -- strata below the bar normally, goes a level below it within DIALOG.
    self:GetBar()
    if above then
      sb:SetFrameStrata("DIALOG")
      bord:SetFrameStrata("DIALOG")
      bord:SetFrameLevel(max(0, sb:GetFrameLevel() - 1))
    else
      sb:SetFrameStrata("MEDIUM")
      bord:SetFrameStrata("LOW")
    end
  end

  ------------------------------------
  function InFlight:ApplyBarPosition()
  ------------------------------------
    if not sb then
      return
    end
    sb:ClearAllPoints()
    sb:SetPoint(look.p, UIParent, look.rp, look.x, look.y)
  end

  ----------------------------------------------
  function InFlight:SetPreview(requester, shown)  -- dummy flight for edit mode and the settings page
  ----------------------------------------------
    -- Shown while anyone still wants it, so that edit mode closing does not take
    -- it away from the settings page, or the other way round.
    previewRequests[requester] = shown or nil
    if next(previewRequests) then
      if previewActive or takeoff or ontaxi then
        return
      end
      self:GetBar()
      previewActive = true
      self:UpdateLook()
      sb:Show()

    elseif previewActive then
      previewActive = nil
      sb:Hide()
    end
  end
end


-- Profiles, for the parts of the addon that have to compare or copy them
--------------------------------------------------------------------------------

-- Compares two stored profiles setting by setting. AceDB strips default valued
-- keys out of every profile that is not the current one, so comparing the two
-- tables outright would report a difference for every setting neither of them
-- has ever touched. Both sides fall back to the default instead.
local function ProfilesDiffer(mine, theirs, defaults, skip)
  for key, default in pairs(defaults) do
    if not (skip and skip[key]) then
      local mineValue = mine and mine[key]
      local theirValue = theirs and theirs[key]
      if mineValue == nil then mineValue = default end
      if theirValue == nil then theirValue = default end

      if type(mineValue) == "table" and type(theirValue) == "table" then
        if ProfilesDiffer(mineValue, theirValue, default) then
          return true
        end
      elseif mineValue ~= theirValue then
        return true
      end
    end
  end
  return false
end

-- perchar says which profile is in use rather than how the bar looks, so it is
-- never what makes two profiles differ.
local profileCompareSkip = { perchar = true }


------------------------------------------------------------
function InFlight:ProfileDiffersFromAccountWide(profileName)
------------------------------------------------------------
  local stored = self.db.profiles
  if not stored or not stored[profileName] then
    return false
  end
  return ProfilesDiffer(stored[profileName], stored["Default"],
    self.defaults.profile, profileCompareSkip)
end


---------------------------------------
function InFlight:GetCopyableProfiles()
---------------------------------------
  -- The account wide settings always, because every character has them, and then
  -- any character's own settings that actually say something different. A profile
  -- identical to the account wide one would be an entry that copies nothing.
  local found = { { name = "Default", accountWide = true } }

  for _, name in ipairs(self.db:GetProfiles()) do
    if name ~= "Default" and self:ProfileDiffersFromAccountWide(name) then
      found[#found + 1] = { name = name }
    end
  end

  return found
end


----------------------------------
function InFlight:ProfileChanged()  -- another set of the user's own settings is in use
----------------------------------
  -- The profile itself was swapped or wiped, rather than one setting in it
  -- changing. A layout's overrides are untouched by that, so a layout owning the
  -- bar has nothing new to capture, but capturing is also what tells the
  -- settings page to show the new values.
  profile = self.db.profile
  self:ApplyBarPosition()
  self:UpdateLook()
  self:CaptureEditModeLayout()
end


-- The bar's position, which Reset to Defaults leaves alone. Reset Position is
-- there for that.
InFlight.positionKeys = { p = true, rp = true, x = true, y = true }

-- Whether a value is the default for its key, a colour channel by channel.
--------------------------------------------
function InFlight:IsDefaultValue(key, value)
--------------------------------------------
  local default = self.defaults.profile[key]
  if type(default) ~= "table" then
    return value == default
  end
  if type(value) ~= "table" then
    return false
  end
  for channel, defaultChannel in pairs(default) do
    if value[channel] ~= defaultChannel then
      return false
    end
  end
  return true
end

-----------------------------------
function InFlight:ResetToDefaults()
-----------------------------------
  -- Resets whatever the settings are editing right now: the active layout's own
  -- settings, or the user's own, which are account wide or character specific
  -- depending on the other checkbox. Shared by the settings menu, the settings
  -- page and the layout editor, which all edit the same thing. The position is
  -- kept.
  if self:IsLayoutSpecific() then
    self:ResetLayoutToDefaults()
    return
  end

  local position = {}
  for key in pairs(self.positionKeys) do
    position[key] = self.db.profile[key]
  end
  self.db:ResetProfile()
  for key, value in pairs(position) do
    self.db.profile[key] = value
  end
  if self.db:GetCurrentProfile() ~= "Default" then
    self.db.profile.perchar = true
  end
  self:ProfileChanged()
end

-- Whether Reset to Defaults would change nothing, so that it can be greyed out
-- the way Reset Position is.
--------------------------------
function InFlight:IsAtDefaults()
--------------------------------
  if self:IsLayoutSpecific() then
    return self:LayoutIsAtDefaults()
  end
  for key in pairs(self.defaults.profile) do
    if not self.positionKeys[key] and key ~= "perchar" and not self:IsDefaultValue(key, self.db.profile[key]) then
      return false
    end
  end
  return true
end


-- The look table, reached from outside this file
--------------------------------------------------------------------------------
-- The bar is drawn from look, which is the active layout's overrides falling
-- through to profile. These are the only ways in, so that the two tables cannot
-- be confused for one another anywhere else.

------------------------------
function InFlight:GetLook(key)  -- the value the bar is currently drawn with
------------------------------
  return look[key]
end

----------------------------------------
function InFlight:PreviewLook(key, value)  -- try a dropdown option on the bar
----------------------------------------
  -- A value of nil gives that key's option up again, and no key at all every
  -- option being tried on.
  if key == nil then
    if next(hovered) == nil then
      return
    end
    wipe(hovered)
  elseif hovered[key] == value then
    return
  else
    hovered[key] = value
  end
  self:UpdateLook()
end

-- Which fill a colour picker shows on the bar while it is open. The background
-- is seen only beside the known fill, as the unknown one fills the whole bar.
local pickedFills = { barcolor = "known", backcolor = "known", unknowncolor = "unknown" }

-----------------------------------------------
function InFlight:ShowPickedFill(colorKey, open)  -- while a colour picker is open for colorKey
-----------------------------------------------
  pickedFill = open and pickedFills[colorKey] or nil
  self:UpdateLook()
end


---------------------------------------------
function InFlight:SetLookOverride(key, value)  -- a layout's own value for this key
---------------------------------------------
  look[key] = value
end


--------------------------------------
function InFlight:ClearLookOverrides()  -- back to the user's own settings
--------------------------------------
  wipe(look)
  self:ApplyBarPosition()
  self:UpdateLook()
end


-------------------------------------
function InFlight:SetLook(key, value)  -- a setting changed outside the layout editor
-------------------------------------
  -- Where the change lands is what the "Layout Specific Settings" checkbox
  -- decides: the layout that owns the bar, or the user's own settings. A change
  -- never goes to both, so nothing is rewritten behind the user's back.
  if self:IsLayoutSpecific() then
    look[key] = type(value) == "table" and CopyTable(value) or value
  else
    profile[key] = value
    -- No layout owns the bar, so no override should be masking this. Cleared
    -- rather than assumed, so the invariant holds either way.
    look[key] = nil
  end
end


-- One tooltip per setting, keyed the way the settings themselves are, so that the
-- settings menu and the layout editor cannot end up describing the same setting
-- differently. Entries that are not settings are looked up by name where they
-- are created.
InFlight.tooltips = {
  countup      = L["CountUpTooltip"],
  fill         = L["FillUpTooltip"],
  spark        = L["SparkTooltip"],
  height       = L["HeightTooltip"],
  width        = L["WidthTooltip"],
  texture      = L["TextureTooltip"],
  border       = L["BorderTooltip"],
  borderbg     = L["BorderBackgroundTooltip"],
  bordercolor  = L["BorderColorTooltip"],
  backcolor    = L["BackgroundColorTooltip"],
  barcolor     = L["BarColorTooltip"],
  unknowncolor = L["UnknownColorTooltip"],

  inline       = L["CompactModeTooltip"],
  twolines     = L["TwoLinesTooltip"],
  totext       = L["ToTextTooltip"],
  font         = L["FontTooltip"],
  fontsize     = L["FontSizeTooltip"],
  fontcolor    = L["FontColorTooltip"],
  outline      = L["OutlineInfoTooltip"],
  outlinetime  = L["OutlineTimeTooltip"],

  chatlog       = L["ShowChatTooltip"],
  confirmflight = L["ConfirmFlightTooltip"],
}

-- A White button on the colour picker for the colours laid over the bar's art,
-- whichever of the settings menu and the layout editor opens it. Many of the
-- Blizzard textures and borders are coloured already, and only show as drawn
-- untinted.
local white = { text = L["White"], tooltip = L["WhiteTooltip"], color = { r = 1, g = 1, b = 1, a = 1 } }
InFlight.colorButtons = {
  bordercolor  = white,
  barcolor     = white,
  unknowncolor = white,
  backcolor    = white,
}


-- The colour picker takes the place of the settings menu, which closes as it
-- opens. Where the menu stood and which submenu was open is kept here, and the
-- menu comes back like that once the picker is done with, whether by OK or by
-- Cancel.
local reopenMenu

--------------------------------
function InFlight.ShowSettings()
--------------------------------
  -- The menu, once open, and its submenus by name, for reopening it.
  local rootMenu
  local submenuNames, submenus = {}, {}

  -- Helper: Redraw the bar and let the edit mode layout, if one owns the bar,
  -- take the change on board. Everything in this menu is meant to stick.
  local function UpdateLook()
    InFlight:UpdateLook()
    InFlight:CaptureEditModeLayout()
  end

  -- Helper: Read the value this menu is editing. Layout specific or not, that is
  -- the value the bar is wearing, so the menu and the bar always agree.
  local function Get(key)
    return InFlight:GetLook(key)
  end

  -- Helper: Change one setting and show the result
  local function Set(key, value)
    InFlight:SetLook(key, value)
    UpdateLook()
  end

  -- Helper: Flip one of the user's own boolean settings
  local function Toggle(key)
    Set(key, not Get(key))
  end

  local tips = InFlight.tooltips

  -- Helper: A checkbox for one setting, carrying the same tooltip the layout
  -- editor shows for it
  local function AddCheckbox(menu, label, key)
    local entry = menu:CreateCheckbox(label,
      function() return Get(key) end,
      function() Toggle(key) end)

    if tips[key] then
      entry:SetTitleAndTextTooltip(label, tips[key])
    end
    return entry
  end

  -- Helper: Open dialog to edit the "to" text separator
  local function ShowToTextDialog()
    StaticPopupDialogs["InFlightToText"] = StaticPopupDialogs["InFlightToText"] or {
      text = L["Enter your 'to' text."],
      button1 = ACCEPT, button2 = CANCEL,
      hasEditBox = 1, maxLetters = 24,
      OnAccept = function(self)
        local editBox = self.editBox or _G[self:GetName() .. "EditBox"]
        Set("totext", editBox:GetText())
      end,
      OnShow = function(self)
        local editBox = self.editBox or _G[self:GetName() .. "EditBox"]
        editBox:SetText(Get("totext"))
        editBox:SetFocus()
      end,
      OnHide = function(self)
        local editBox = self.editBox or _G[self:GetName() .. "EditBox"]
        editBox:SetText("")
      end,
      EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local editBox = parent.editBox or _G[parent:GetName() .. "EditBox"]
        -- Read before the hide, whose OnHide empties the box.
        local text = editBox:GetText()
        parent:Hide()
        Set("totext", text)
      end,
      EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
      end,
      timeout = 0, exclusive = 1, whileDead = 1, hideOnEscape = 1,
    }
    StaticPopup_Show("InFlightToText")
  end

  -- Helper: Clear flight time database and reload UI
  local function ResetFlightTimes()
    InFlightDB.dbinit = nil
    InFlightDB.global = {}
    ReloadUI()
  end

  -- Helper: whether this player has recorded anything the addon does not
  -- already ship. newPlayerSaveData is filled at load from everything in the
  -- saved variables that differs from the shipped defaults, and grows again as
  -- flights are timed, so this answers for the session as it goes.
  local function HasNewFlightData()
    return next(InFlight.newPlayerSaveData) ~= nil
  end

  -- Helper: Export flight time data to developers
  local function ExportFlightTimes()
    if PTR_IssueReporter == nil then
      InFlight:ExportDB()
    else
      print("Only exporting from the live game client. PTR has been unreliable before.")
    end
  end

  -- Helper: Give this character's own profile up, keeping its settings for
  -- everyone or throwing them away
  local function DropCharProfile(charKey, keepSettings)
    InFlight.db:SetProfile("Default")
    if keepSettings then
      -- CopyProfile resets the destination before it deep copies, so nothing of
      -- the old account wide settings is left behind.
      InFlight.db:CopyProfile(charKey)
    end
    profile = InFlight.db.profile
    profile.perchar = false

    for _, name in ipairs(InFlight.db:GetProfiles()) do
      if name == charKey then
        InFlight.db:DeleteProfile(charKey)
        break
      end
    end
    InFlight:ProfileChanged()
  end

  -- Helper: Ask before one set of settings is lost for the other
  local function ShowPerCharDialog(charKey)
    -- Shaped like Blizzard's own GAME_SETTINGS_APPLY_DEFAULTS: two opposed
    -- actions with Cancel between them. Escape calls OnCancel directly, so Cancel
    -- is the button whose handler does nothing.
    --
    -- Callbacks by index rather than the old OnAlt for the third button, which
    -- Blizzard keeps only "temporarily for backward compatibility" and would
    -- leave Keep Account Wide doing nothing the day it goes.
    StaticPopupDialogs["InFlightPerChar"] = StaticPopupDialogs["InFlightPerChar"] or {
      text = L["PerCharDiscardPrompt"],
      button1 = L["Discard"],
      button2 = CANCEL,
      button3 = L["KeepForAllCharacters"],
      selectCallbackByIndex = true,
      OnAccept = function(_, data) DropCharProfile(data, false) end,
      OnCancel = function() end,
      OnButton3 = function(_, data) DropCharProfile(data, true) end,
      timeout = 0, exclusive = 1, whileDead = 1, hideOnEscape = 1,
    }
    StaticPopup_Show("InFlightPerChar", nil, nil, charKey)
  end

  -- Helper: Toggle per-character profile setting. Returns the menu's response.
  local function TogglePerCharProfile()
    local charKey = UnitName("player") .. " - " .. GetRealmName()
    if profile.perchar then
      -- Disabling: the character's own settings are about to go, so ask what
      -- should become of them first, unless there is nothing to lose.
      if InFlight:ProfileDiffersFromAccountWide(charKey) then
        ShowPerCharDialog(charKey)
        -- The question is the popup's now, and the menu behind it would only
        -- show the box still ticked while it waits for an answer.
        return MenuResponse.CloseAll
      else
        DropCharProfile(charKey, false)
      end
    else
      -- Enabling: copy current Default settings into char profile, then switch to it
      InFlight.db:SetProfile(charKey)
      InFlight.db:CopyProfile("Default")
      profile = InFlight.db.profile
      profile.perchar = true
      InFlight:ProfileChanged()
    end
  end

  -- Helper: Update color values with validation and clamping
  local function SetColor(colorKey, red, green, blue, alpha)
    local current = Get(colorKey)
    if not current then return end

    -- Clamped to 0-1, falling back to the current value for anything unreadable,
    -- and built as a fresh table rather than edited in place, because the old one
    -- may also be what a layout is holding as its override for this key.
    Set(colorKey, {
      r = math.max(0, math.min(1, tonumber(red) or current.r)),
      g = math.max(0, math.min(1, tonumber(green) or current.g)),
      b = math.max(0, math.min(1, tonumber(blue) or current.b)),
      a = math.max(0, math.min(1, tonumber(alpha) or current.a)),
    })
  end

  -- Helper: Open color picker for a given color type
  local function OpenColorPicker(colorKey)
    local colorTable = Get(colorKey)
    if not colorTable then return end

    -- Through the library, so that the picker is the one the layout editor
    -- shows, White button included. Its going is also when the menu comes back.
    LLS:ShowColorPicker({
      color = colorTable,
      colorButton = InFlight.colorButtons[colorKey],
      OnPick = function(r, g, b, a) SetColor(colorKey, r, g, b, a) end,
      OnPicker = function(open)
        InFlight:ShowPickedFill(colorKey, open)
        if not open and reopenMenu then
          InFlight.ShowSettings()
        end
      end,
    })
  end

  -- Helper: A color swatch for one setting, carrying the same tooltip the layout
  -- editor shows for it
  local function AddColorSwatch(menu, label, key)
    local color = Get(key)
    local entry = menu:CreateColorSwatch(label,
      function()
        -- In screen pixels, as the menu that comes back may be scaled otherwise.
        local scale = rootMenu:GetEffectiveScale()
        reopenMenu = { submenu = submenuNames[menu],
          left = rootMenu:GetLeft() * scale, top = rootMenu:GetTop() * scale }
        OpenColorPicker(key)
      end,
      {r = color.r, g = color.g, b = color.b})

    if tips[key] then
      entry:SetTitleAndTextTooltip(label, tips[key])
    end
    return entry
  end

  -- Helper: Try a list option on the bar while the mouse rests on it, the way
  -- the layout editor's dropdowns do. Closing the menu gives it up too.
  local function TryOnHover(radio, profileKey, value)
    radio:HookOnEnter(function() InFlight:PreviewLook(profileKey, value) end)
    radio:HookOnLeave(function() InFlight:PreviewLook(profileKey, nil) end)
  end

  -- Helper: Create slider submenu with pagination for large ranges
  local function AddFakeSliderSubmenu(parentMenu, sliderLabel, profileKey, minValue, maxValue, stepSize, itemTable)
    local sliderButton = parentMenu:CreateButton(sliderLabel)

    -- Tooltip first, submenu hooked on after it. SetTitleAndTextTooltip installs
    -- an OnEnter of its own and SetOnEnter replaces rather than adds, so the
    -- other way round the tooltip quietly threw the force-open away: the tooltip
    -- appeared at once and the submenu was left waiting out the hover delay,
    -- unlike the top level ones, which carry no tooltip to lose it to.
    if tips[profileKey] then
      sliderButton:SetTitleAndTextTooltip(sliderLabel, tips[profileKey])
    end
    sliderButton:HookOnEnter(function(_, desc) desc:ForceOpenSubmenu() end)

    local itemsPerPage = 20

    if itemTable then
      -- For named lists (textures, borders, fonts), check if pagination is needed
      local totalItems = maxValue - minValue + 1

      if totalItems <= itemsPerPage then
        -- Display all items directly if 20 or fewer
        for i = minValue, maxValue, stepSize do
          local itemName = itemTable[i]
          -- A list of textures or borders comes in groups, false between them.
          if itemName == false then
            sliderButton:CreateDivider()
          else
            TryOnHover(sliderButton:CreateRadio(InFlight:MediaDisplayName(itemName),
              function() return Get(profileKey) == itemName end,
              function() Set(profileKey, itemName); return MenuResponse.Refresh end), profileKey, itemName)
          end
        end
      else
        -- Paginate into submenus if more than 20 items
        local rangeStart = minValue

        while rangeStart <= maxValue do
          local rangeEnd = min(maxValue, rangeStart + itemsPerPage - 1)

          local pageLabel = format("%s: %d-%d", sliderLabel, rangeStart, rangeEnd)
          local rangeMenu = sliderButton:CreateButton(pageLabel)
          rangeMenu:SetOnEnter(function(_, desc) desc:ForceOpenSubmenu() end)

          for i = rangeStart, rangeEnd, stepSize do
            local itemName = itemTable[i]
            -- A divider is only worth drawing between two entries of the page.
            if itemName == false then
              if i ~= rangeStart and i ~= rangeEnd then
                rangeMenu:CreateDivider()
              end
            else
              TryOnHover(rangeMenu:CreateRadio(InFlight:MediaDisplayName(itemName),
                function() return Get(profileKey) == itemName end,
                function() Set(profileKey, itemName); return MenuResponse.Refresh end), profileKey, itemName)
            end
          end

          if rangeEnd >= maxValue then
            break
          end
          rangeStart = rangeEnd + stepSize
        end
      end
    else
      -- For numeric ranges, paginate into ~20-item submenus to prevent screen overflow
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
          TryOnHover(rangeMenu:CreateRadio(format(numberFormat, value),
            function() return floor(100 * (Get(profileKey) or 0)) == floor(100 * value) end,
            function() Set(profileKey, value); return MenuResponse.Refresh end), profileKey, value)
        end

        -- Advance to next range or break if we've reached the end
        if rangeEnd >= maxValue then
          break
        end
        rangeStart = rangeEnd + stepSize
      end
    end
  end

  rootMenu = MenuUtil.CreateContextMenu(UIParent, function(_, mainMenu)
    mainMenu:CreateTitle("|cff0040ffIn|cff00aaffFlight|r")
    mainMenu:CreateDivider()

    -- ===== WHAT IS BEING EDITED =====
    -- First, because between them these two say what everything below applies
    -- to: this layout, this character, or every character.

    -- The same state as the InFlight box in the layout editor. Absent where there
    -- is no layout to give the bar to, an override layout for instance. Greyed
    -- out on a preset layout, which the layout editor only lets you change by
    -- saving it as a new layout, so that it cannot end up in a state the layout
    -- editor itself could never reach.
    if InFlight:CanBeLayoutSpecific() or InFlight:IsOnPresetLayout() then
      local layoutSpecific = mainMenu:CreateCheckbox(L["LayoutSpecific"],
        function() return InFlight:IsLayoutSpecific() end,
        function() InFlight:SetLayoutSpecific(not InFlight:IsLayoutSpecific()) end)
      layoutSpecific:SetEnabled(function() return InFlight:CanBeLayoutSpecific() end)

      -- Named rather than described as "the current layout", so that there is no
      -- doubt which one is about to get its own settings. Read at hover time, so
      -- that it is still right if the layout changed under an open menu.
      layoutSpecific:SetTooltip(function(tooltip)
        GameTooltip_SetTitle(tooltip, L["LayoutSpecific"])
        GameTooltip_AddNormalLine(tooltip,
          format(L["LayoutSpecificTooltip"], InFlight:GetLayoutName() or ""), true)
        if InFlight:IsOnPresetLayout() and not InFlight:CanBeLayoutSpecific() then
          GameTooltip_AddBlankLineToTooltip(tooltip)
          GameTooltip_AddErrorLine(tooltip,
            format(L["LayoutSpecificPreset"], InFlight:GetLayoutName() or ""), true)
        end
      end)
    end

    -- While the layout owns the bar you are editing an entry the layout holds for
    -- every character, so character specific is not merely inapplicable, it is
    -- false, and it says so rather than inviting the reading that a change here is
    -- for this character and this layout both. The real setting is untouched in
    -- the profile and shows again the moment the layout stops owning the bar.
    local perChar = mainMenu:CreateCheckbox(L["PerCharOptions"],
      function() return not InFlight:IsLayoutSpecific() and profile.perchar end,
      function() return TogglePerCharProfile() end)

    perChar:SetEnabled(function() return not InFlight:IsLayoutSpecific() end)
    perChar:SetTooltip(function(tooltip)
      GameTooltip_SetTitle(tooltip, L["PerCharOptions"])
      -- While the layout owns the bar this box is greyed and says why, which is
      -- more use than describing a setting that is not in play.
      GameTooltip_AddNormalLine(tooltip,
        InFlight:IsLayoutSpecific() and L["PerCharLayoutHint"] or L["PerCharOptionsTooltip"], true)
    end)

    mainMenu:CreateDivider()

    -- ===== BAR OPTIONS =====
    local barMenu = mainMenu:CreateButton(L["BarOptions"])
    barMenu:SetOnEnter(function(_, desc) desc:ForceOpenSubmenu() end)
    submenuNames[barMenu], submenus.bar = "bar", barMenu

    -- Shape first, then the border with everything that goes with it, then the
    -- texture with its colours, the same groups the layout editor has.
    AddFakeSliderSubmenu(barMenu, L["Height"], "height", 4, 150, 1, nil)
    AddFakeSliderSubmenu(barMenu, L["Width"], "width", 40, 1000, 5, nil)

    barMenu:CreateDivider()

    -- LibSharedMedia's borders and textures with Blizzard's from BarStyles.lua.
    local borderList = InFlight:GetBorderList()
    AddFakeSliderSubmenu(barMenu, L["Border"], "border", 1, #borderList, 1, borderList)
    -- Only some borders have a background of their own to show.
    AddCheckbox(barMenu, L["BorderBackground"], "borderbg"):SetEnabled(function()
      return InFlight:BorderHasBackground(InFlight:GetLook("border"))
    end)
    AddColorSwatch(barMenu, L["BorderColor"], "bordercolor")

    barMenu:CreateDivider()

    local textureList = InFlight:GetTextureList()
    AddFakeSliderSubmenu(barMenu, L["Texture"], "texture", 1, #textureList, 1, textureList)
    AddColorSwatch(barMenu, L["BarColor"], "barcolor")
    AddColorSwatch(barMenu, L["UnknownColor"], "unknowncolor")
    AddColorSwatch(barMenu, L["BackgroundColor"], "backcolor")

    barMenu:CreateDivider()

    -- How the bar behaves during a flight.
    AddCheckbox(barMenu, L["CountUp"], "countup")
    AddCheckbox(barMenu, L["FillUp"], "fill")
    local sparkList = InFlight:GetSparkList()
    AddFakeSliderSubmenu(barMenu, L["Spark"], "spark", 1, #sparkList, 1, sparkList)

    -- ===== TEXT OPTIONS =====
    local textMenu = mainMenu:CreateButton(L["TextOptions"])
    textMenu:SetOnEnter(function(_, desc) desc:ForceOpenSubmenu() end)
    submenuNames[textMenu], submenus.text = "text", textMenu

    -- The face and its size, then how it is drawn, then what is written with it.
    local fontList = InFlight:GetFontList()
    AddFakeSliderSubmenu(textMenu, L["Font"], "font", 1, #fontList, 1, fontList)
    AddFakeSliderSubmenu(textMenu, L["FontSize"], "fontsize", 4, 30, 1, nil)

    textMenu:CreateDivider()

    AddColorSwatch(textMenu, L["FontColor"], "fontcolor")
    AddCheckbox(textMenu, L["OutlineInfo"], "outline")
    AddCheckbox(textMenu, L["OutlineTime"], "outlinetime")

    textMenu:CreateDivider()

    AddCheckbox(textMenu, L["CompactMode"], "inline")

    -- Compact mode wins over both of these in UpdateLook, so grey them out rather
    -- than leaving controls that quietly do nothing, exactly as the layout editor
    -- does. SetEnabled takes a predicate, and a checkbox refreshes the menu when
    -- it is clicked, so the two follow compact mode as it is toggled.
    local function NotCompact()
      return not Get("inline")
    end

    local twoLines = AddCheckbox(textMenu, L["TwoLines"], "twolines")
    twoLines:SetEnabled(NotCompact)

    local toText = textMenu:CreateButton(L["ToText"], function() ShowToTextDialog() end)
    toText:SetEnabled(NotCompact)
    toText:SetTitleAndTextTooltip(L["ToText"], tips.totext)

    mainMenu:CreateDivider()

    -- ===== OTHER OPTIONS =====
    local otherMenu = mainMenu:CreateButton(_G.OTHER)
    otherMenu:SetOnEnter(function(_, desc) desc:ForceOpenSubmenu() end)

    AddCheckbox(otherMenu, L["ShowChat"], "chatlog")
    AddCheckbox(otherMenu, L["ConfirmFlight"], "confirmflight")

    otherMenu:CreateDivider()

    local resetToDefaults = otherMenu:CreateButton(L["ResetToDefaults"], function()
      InFlight:ResetToDefaults()
    end)
    resetToDefaults:SetEnabled(function() return not InFlight:IsAtDefaults() end)
    resetToDefaults:SetTitleAndTextTooltip(L["ResetToDefaults"], L["ResetToDefaultsTooltip"])

    otherMenu:CreateDivider()

    -- Both of these act on flight times the addon does not already ship, so with
    -- none recorded there is nothing to export and nothing a reset would take
    -- away. Greyed out rather than left there to do nothing, and the tooltip
    -- says why rather than leaving the player to guess.
    local function FlightTimeTooltip(title, description)
      return function(tooltip)
        GameTooltip_SetTitle(tooltip, title)
        GameTooltip_AddNormalLine(tooltip, description, true)
        if not HasNewFlightData() then
          GameTooltip_AddBlankLineToTooltip(tooltip)
          GameTooltip_AddErrorLine(tooltip, L["NoNewFlightTimes"], true)
        end
      end
    end

    local resetTimes = otherMenu:CreateButton(L["ResetFlightTimes"], function()
      ResetFlightTimes()
    end)
    resetTimes:SetEnabled(HasNewFlightData)
    resetTimes:SetTooltip(FlightTimeTooltip(L["ResetFlightTimes"], L["ResetFlightTimesTooltip"]))

    local exportTimes = otherMenu:CreateButton(L["ExportFlightTimes"], function()
      ExportFlightTimes()
    end)
    exportTimes:SetEnabled(HasNewFlightData)
    exportTimes:SetTooltip(FlightTimeTooltip(L["ExportFlightTimes"], L["ExportFlightTimesTooltip"]))
  end)

  if not rootMenu then
    reopenMenu = nil
    return
  end

  -- Whatever was being tried on is given up with the menu, picked or not.
  rootMenu:SetClosedCallback(function() InFlight:PreviewLook() end)

  -- Back from the colour picker: where it stood, with the submenu it had open.
  local reopen = reopenMenu
  reopenMenu = nil
  if reopen then
    local scale = rootMenu:GetEffectiveScale()
    rootMenu:ClearAllPoints()
    rootMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", reopen.left / scale, reopen.top / scale)
    if submenus[reopen.submenu] then
      submenus[reopen.submenu]:ForceOpenSubmenu()
    end
  end
end


