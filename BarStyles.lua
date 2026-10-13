-- Bar textures and borders made from Blizzard's own art, offered next to the
-- ones LibSharedMedia has. Most are atlases, which LibSharedMedia cannot hold
-- (other addons would hand them to SetTexture as file paths), so InFlight keeps
-- them to itself. Each is drawn the way Blizzard draws it in the part of the UI
-- it comes from, named beside it, unless the comment there says where and why
-- not, and one this client does not have is simply not offered.

local smed = LibStub("LibSharedMedia-3.0")

local unpack = unpack


--------------------------------------------------------------------------------
-- Textures
--------------------------------------------------------------------------------

-- A texture that comes from the same bar as one of the borders below names it,
-- so that the lists can offer the two together.
local textures = {
  -- CastingBarFrame.xml
  { name = "Blizzard Cast Bar",                 atlas = "ui-castingbar-filling-standard",         border = "Blizzard Cast Bar" },
  { name = "Blizzard Cast Bar Channel",         atlas = "ui-castingbar-filling-channel",          border = "Blizzard Cast Bar" },
  { name = "Blizzard Cast Bar Crafting",        atlas = "ui-castingbar-filling-applyingcrafting", border = "Blizzard Cast Bar" },
  -- CastingBarFrame.lua, for a cast that is interrupted or fails, and for one
  -- that cannot be interrupted.
  { name = "Blizzard Cast Bar Interrupted",     atlas = "ui-castingbar-interrupted",              border = "Blizzard Cast Bar" },
  { name = "Blizzard Cast Bar Uninterruptible", atlas = "ui-castingbar-uninterruptable",          border = "Blizzard Cast Bar" },
  -- PVPHonorSystem.xml
  { name = "Blizzard Honor",                    atlas = "_honorsystem-bar-fill" },
  -- The status bar widget
  { name = "Blizzard Junkyard",                 atlas = "junkyard-scorebar-fill-medium",          border = "Blizzard Junkyard" },
  -- Blizzard_MonthlyActivities.xml
  { name = "Blizzard Monthly Activities",       atlas = "activities-bar-fill",                    border = "Blizzard Monthly Activities" },
  -- Blizzard_ScenarioObjectiveTracker.xml
  { name = "Blizzard Mythic+ Timer",            atlas = "ChallengeMode-TimerFill" },
  -- The status bar widget
  { name = "Blizzard War Within",               atlas = "thewarwithin-scenario-barframe-fill-brown", border = "Blizzard War Within" },
  -- The widget's white fill, which the bar colour tints. Its blue, green, red and
  -- yellow fills are little more than this one tinted, so they are left out.
  { name = "Blizzard Widget Bar",               atlas = "widgetstatusbar-fill-white",             border = "Blizzard Widget Bar" },
}


--------------------------------------------------------------------------------
-- Borders
--------------------------------------------------------------------------------
-- A border is made of parts, each drawn in three pieces: two ends kept at their
-- own proportions and a middle that stretches to the bar's width. Every size is
-- in the pixels of Blizzard's art, for a bar `height` pixels high, and the whole
-- border scales with the bar's height over that, so a taller bar gets a larger
-- border rather than a stretched one.
--
-- A part is one of
--   { atlas = name, caps = {left, right}, outset = {left, top, right, bottom} }
--     one atlas, cut `caps` pixels in from each end,
--   { file = path, box = {x0, y0, x1, y1, width, height}, caps = ..., outset = ... }
--     the same for the box of a file `width` by `height` pixels it is drawn in,
--   { file = path, coords = {left, middle, right}, caps = ..., outset = ... }
--     pieces Blizzard cuts from a file itself, each {u0, u1, v0, v1},
--   { left = atlas, center = atlas, right = atlas, offset = x }
--     the status bar widget's way: three atlases at their own size, centred on
--     the bar, the ends `offset` pixels out from it.
-- `outset` is how far the part reaches past the bar on each side. A part is the
-- frame, drawn over the fill in the border colour, unless it is the border's own
-- background: drawn below the fill in the background colour, shaped to fit the
-- frame where InFlight's own background, the bar's texture again, is a plain
-- rectangle. It takes the place of that one unless the user turns it off.
--
-- A border whose ends reach into the bar says how far text at the bar's ends
-- has to keep from them, in art pixels, as textInset. One whose opening does not
-- sit square on the bar says how far the text inside the bar moves up to sit in
-- it, as textOffsetY, down if negative.
--
-- The caps of one-piece art were measured where its outline stops changing,
-- with a little to spare.

local borders = {
  -- CastingBarFrame.xml: the bar is 208x11, the frame 2 and the background 1
  -- out from it all round.
  { name = "Blizzard Cast Bar", height = 11, textInset = 1, textOffsetY = 0.25,
    { atlas = "ui-castingbar-frame", caps = {8, 8}, outset = {2, 2, 2, 2} },
    { atlas = "ui-castingbar-background", caps = {4, 4}, outset = {1, 1, 1, 1}, background = true } },

  -- The classic CastingBarFrame.xml: a 195x13 bar with the 256x64 border
  -- centred across it. Blizzard has the bar's top at row 28 of the file, which
  -- puts it low in the frame, so here it is centred on the opening between the
  -- rims instead, rows 28 to 36, the rims above and below overlapping it by 2.
  -- Across, the side rims end at columns 34 and 222 and the bar meets them. The
  -- box is where the file actually draws.
  { name = "Blizzard Classic Cast Bar", height = 13,
    { file = [[Interface\CastingBar\UI-CastingBar-Border]], box = {22, 16, 234, 48, 256, 64},
      caps = {16, 16}, outset = {12, 10, 12, 9} } },

  -- Blizzard_MonthlyActivities.xml: a 663x33 bar, the 676x47 border centred
  -- 2 below it and the 664x35 background centred on it.
  { name = "Blizzard Monthly Activities", height = 33, textInset = 1,
    { atlas = "activities-bar-border", caps = {20, 20}, outset = {6.5, 5, 6.5, 9} },
    { atlas = "activities-bar-background", caps = {8, 8}, outset = {0.5, 1, 0.5, 1}, background = true } },

  -- Blizzard_ScenarioObjectiveTracker.xml, the Proving Grounds block: a 177x15
  -- bar with the 184x25 border centred on it.
  { name = "Blizzard Proving Grounds", height = 15, textInset = 2,
    { atlas = "challenges-timerborder", caps = {10, 10}, outset = {3.5, 5, 3.5, 5} } },

  -- GameTooltip.xml: a 215x15 bar, its 9x22 ends 3 out from it.
  { name = "Blizzard Character Skills Bar", height = 15,
    { file = [[Interface\PaperDollInfoFrame\UI-Character-Skills-BarBorder]],
      coords = { {0.007843, 0.043137, 0.193548, 0.774193},
                 {0.113726, 0.1490196, 0.193548, 0.774193},
                 {0.043137, 0.007843, 0.193548, 0.774193} },
      caps = {9, 9}, outset = {3, 3.5, 3, 3.5} } },

  -- Blizzard_AchievementUI.xml: a 212x14 bar, its 16 wide ends reaching 6
  -- past it to the sides and 5 above and below.
  { name = "Blizzard Achievement", height = 14, textInset = 2, textOffsetY = -0.25,
    { file = [[Interface\AchievementFrame\UI-Achievement-ProgressBar-Border]],
      coords = { {0, 0.0625, 0, 0.75}, {0.0625, 0.812, 0, 0.75}, {0.812, 0.8745, 0, 0.75} },
      caps = {16, 16}, outset = {6, 5, 6, 5} } },

  -- Blizzard_UIWidgetTemplateStatusBar: the bar is as high as the kit's fill,
  -- the border 8 out from it and the background 2, unless the kit's own options
  -- say otherwise.
  { name = "Blizzard Widget Bar", height = 15, textInset = 1, textOffsetY = 0.25,
    { left = "widgetstatusbar-borderleft", center = "widgetstatusbar-bordercenter",
      right = "widgetstatusbar-borderright", offset = 8 },
    { left = "widgetstatusbar-bgleft", center = "widgetstatusbar-bgcenter",
      right = "widgetstatusbar-bgright", offset = 2, background = true } },
  -- The tips of its arrows reach 4 into the bar, onto any text at its ends.
  { name = "Blizzard War Within", height = 19, textInset = 3, textOffsetY = 0.5,
    { left = "thewarwithin-scenario-barframe-borderleft", center = "thewarwithin-scenario-barframe-bordercenter",
      right = "thewarwithin-scenario-barframe-borderright", offset = 10 },
    { left = "thewarwithin-scenario-barframe-bgleft", center = "thewarwithin-scenario-barframe-bgcenter",
      right = "thewarwithin-scenario-barframe-bgright", offset = 10, background = true } },
  { name = "Blizzard Junkyard", height = 19,
    { left = "junkyard-scorebar-borderleft", center = "junkyard-scorebar-bordercenter",
      right = "junkyard-scorebar-borderright", offset = 14 },
    { left = "junkyard-scorebar-bgleft", center = "junkyard-scorebar-bgcenter",
      right = "junkyard-scorebar-bgright", offset = 2, background = true } },
  { name = "Blizzard Dastardly Duos", height = 12, textInset = 1, textOffsetY = 0.25,
    { left = "ui-frame-dastardlyduos-progressbar-borderleft", center = "ui-frame-dastardlyduos-progressbar-bordercenter",
      right = "ui-frame-dastardlyduos-progressbar-borderright", offset = 8 },
    { left = "ui-frame-dastardlyduos-progressbar-bgleft", center = "ui-frame-dastardlyduos-progressbar-bgcenter",
      right = "ui-frame-dastardlyduos-progressbar-bgright", offset = 2, background = true } },
}


--------------------------------------------------------------------------------
-- Looking them up
--------------------------------------------------------------------------------

local textureByName, borderByName = {}, {}
for _, entry in ipairs(textures) do
  textureByName[entry.name] = entry
end
for _, entry in ipairs(borders) do
  borderByName[entry.name] = entry
end

local function AtlasExists(atlas)
  return C_Texture.GetAtlasInfo(atlas) ~= nil
end

local function PartExists(part)
  if part.atlas then
    return AtlasExists(part.atlas)
  elseif part.left then
    return AtlasExists(part.left) and AtlasExists(part.center) and AtlasExists(part.right)
  end
  return true  -- a file, which every client has
end

local function BorderExists(border)
  for _, part in ipairs(border) do
    if not PartExists(part) then
      return false
    end
  end
  return true
end

-- Media names as the settings show them. LibSharedMedia names its own after
-- Blizzard, and these follow suit, so nearly every name would open on the same
-- word. The names themselves stay as they are, as they are what is stored and
-- what LibSharedMedia knows them by. None is translated: every addon reading
-- LibSharedMedia shows the same ones.
local displayNames = {
  ["Blizzard"] = "Status Bar",  -- TargetingFrame\UI-StatusBar, the unit frames' bar
}

----------------------------------------
function InFlight:MediaDisplayName(name)
----------------------------------------
  return displayNames[name] or name:match("^Blizzard (.+)") or name
end

-- Sorts names into the order given, a list of them, and those it does not name
-- after them by the name they are shown under: other addons' media, say.
local function Sorter(order)
  local position = {}
  for i, name in ipairs(order or {}) do
    position[name] = i
  end
  return function(a, b)
    local i, j = position[a], position[b]
    if i and j then
      return i < j
    elseif i or j then
      return i ~= nil
    end
    return InFlight:MediaDisplayName(a):lower() < InFlight:MediaDisplayName(b):lower()
  end
end

-- Groups of names, each sorted as order says, in one list with false between
-- them, where the settings draw a divider. Empty groups are left out.
local function Grouped(order, ...)
  local sorter = Sorter(order)
  local list = {}
  for i = 1, select("#", ...) do
    local group = select(i, ...)
    if #group > 0 then
      table.sort(group, sorter)
      if #list > 0 then
        list[#list + 1] = false
      end
      for _, name in ipairs(group) do
        list[#list + 1] = name
      end
    end
  end
  return list
end

-- Whether a border brings a background of its own.
local function HasBackground(border)
  if border and BorderExists(border) then
    for _, part in ipairs(border) do
      if part.background then
        return true
      end
    end
  end
  return false
end

-- Both lists are offered in an order of their own rather than by name. A name
-- an order does not list, another addon's, follows the ones it does in its
-- group.
local textureOrder = {
  "Blizzard Cast Bar", "Blizzard Cast Bar Channel", "Blizzard Cast Bar Crafting", "Blizzard Cast Bar Interrupted",
  "Blizzard Cast Bar Uninterruptible", "Blizzard Widget Bar", "Blizzard Monthly Activities", "Blizzard War Within",
  "Blizzard Junkyard",
  "Blizzard", "Blizzard Character Skills Bar", "Blizzard Raid Bar", "Blizzard Honor", "Blizzard Mythic+ Timer",
}

local borderOrder = {
  "Blizzard Cast Bar", "Blizzard Widget Bar", "Blizzard Dastardly Duos", "Blizzard Monthly Activities",
  "Blizzard War Within", "Blizzard Junkyard",
  "Blizzard Tooltip", "Blizzard Chat Bubble", "Blizzard Character Skills Bar",
  "Blizzard Proving Grounds", "Blizzard Achievement", "Blizzard Achievement Wood", "Blizzard Dialog",
  "Blizzard Classic Cast Bar",
}

-- textInset and textOffsetY for LibSharedMedia's borders, which have no entry
-- above. Their edge does not scale with the bar, so these are screen pixels.
local mediaBorderText = {
  ["None"] = { textInset = 1 },
}

-- How far text at the bar's ends keeps from a LibSharedMedia border, and how far
-- up the text in the bar moves for it.
----------------------------------------------
function InFlight:MediaBorderTextOffsets(name)
----------------------------------------------
  local text = mediaBorderText[name]
  return text and text.textInset or 0, text and text.textOffsetY or 0
end

-- The textures and borders on offer on this client, in the order the settings
-- show them: first the borders with a background of their own, which come as
-- complete bars, with the textures from those same bars. Then the rest,
-- LibSharedMedia's and ours alike, and last the plainest of all, a texture of
-- one colour and no border at all.
----------------------------------
function InFlight:GetTextureList()
----------------------------------
  local matching, rest, plain = {}, {}, {}
  for _, name in ipairs(smed:List("statusbar")) do
    if name == "Solid" then
      plain[#plain + 1] = name
    else
      rest[#rest + 1] = name
    end
  end
  for _, entry in ipairs(textures) do
    if AtlasExists(entry.atlas) then
      local group = HasBackground(borderByName[entry.border]) and matching or rest
      group[#group + 1] = entry.name
    end
  end
  return Grouped(textureOrder, matching, rest, plain)
end

---------------------------------
function InFlight:GetBorderList()
---------------------------------
  -- "Blizzard Party" is broken as a border, and "Blizzard Dialog Gold" is little
  -- more than "Blizzard Dialog" in the border colour.
  local skip = { ["Blizzard Party"] = true, ["Blizzard Dialog Gold"] = true }
  local complete, rest, plain = {}, {}, {}
  for _, name in ipairs(smed:List("border")) do
    if name == "None" then
      plain[#plain + 1] = name
    elseif not skip[name] then
      rest[#rest + 1] = name
    end
  end
  for _, entry in ipairs(borders) do
    if BorderExists(entry) then
      local group = HasBackground(entry) and complete or rest
      group[#group + 1] = entry.name
    end
  end
  return Grouped(borderOrder, complete, rest, plain)
end

-- The art of a bar texture, and whether it is an atlas rather than a file. A
-- name this client has no atlas for goes to LibSharedMedia, which hands back its
-- default for a name it does not know either.
------------------------------------------
function InFlight:GetBarTextureAsset(name)
------------------------------------------
  local entry = textureByName[name]
  if entry and AtlasExists(entry.atlas) then
    return entry.atlas, true
  end
  return smed:Fetch("statusbar", name), false
end

--------------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------------

-- The three pieces of a part, each {file, u0, u1, v0, v1}, with the widths of
-- the two ends and how far the part reaches past the bar, all in art pixels.
local function Resolve(part, height)
  if part.atlas then
    local info = C_Texture.GetAtlasInfo(part.atlas)
    local file = info.file or info.filename
    local u0, u1, v0, v1 = info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord
    local perPixel = (u1 - u0) / info.width
    local a, b = u0 + part.caps[1] * perPixel, u1 - part.caps[2] * perPixel
    return { {file, u0, a, v0, v1}, {file, a, b, v0, v1}, {file, b, u1, v0, v1} }, part.caps, part.outset

  elseif part.box then
    local x0, y0, x1, y1, fileWidth, fileHeight = unpack(part.box)
    local u0, u1, v0, v1 = x0 / fileWidth, x1 / fileWidth, y0 / fileHeight, y1 / fileHeight
    local a, b = (x0 + part.caps[1]) / fileWidth, (x1 - part.caps[2]) / fileWidth
    return { {part.file, u0, a, v0, v1}, {part.file, a, b, v0, v1}, {part.file, b, u1, v0, v1} }, part.caps, part.outset

  elseif part.coords then
    local pieces = {}
    for i, coords in ipairs(part.coords) do
      pieces[i] = { part.file, unpack(coords) }
    end
    return pieces, part.caps, part.outset

  else
    local pieces, sizes = {}, {}
    for i, atlas in ipairs({ part.left, part.center, part.right }) do
      local info = C_Texture.GetAtlasInfo(atlas)
      pieces[i] = { info.file or info.filename, info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord }
      sizes[i] = info
    end
    -- Centred on the bar at the ends' own height.
    local reach = (sizes[1].height - height) / 2
    return pieces, { sizes[1].width, sizes[3].width }, { part.offset, reach, part.offset, reach }
  end
end

-- Three textures for each part a border can have, made on first use.
local pieceTextures = {}

local function PieceTextures(bar, index)
  local set = pieceTextures[index]
  if not set then
    set = {}
    for i = 1, 3 do
      set[i] = bar:CreateTexture()
    end
    pieceTextures[index] = set
  end
  return set
end

-- Whether the border of that name brings a background of its own.
-------------------------------------------
function InFlight:BorderHasBackground(name)
-------------------------------------------
  return HasBackground(borderByName[name])
end

-- Draws the border of that name around the bar, with its own background if it
-- has one and ownBackground says so, or takes ours away if it is not one of
-- ours. Returns how far above the bar it reaches, whether it drew a background,
-- how far text at the bar's ends has to keep from them and how far the text in
-- the bar moves up, nothing if it is not one of ours.
--------------------------------------------------------------------------------
function InFlight:DrawBarBorder(bar, name, frameColor, backColor, ownBackground)
--------------------------------------------------------------------------------
  local border = borderByName[name]
  if border and not BorderExists(border) then
    border = nil
  end

  local scale = border and bar:GetHeight() / border.height
  local width = bar:GetWidth()
  local top, hasBackground = 0, false

  for index = 1, math.max(#pieceTextures, border and #border or 0) do
    local part = border and border[index]
    if part and part.background and not ownBackground then
      part = nil
    end
    if not part then
      for _, texture in ipairs(pieceTextures[index] or {}) do
        texture:Hide()
      end
    else
      local pieces, caps, outset = Resolve(part, border.height)
      local color = part.background and backColor or frameColor
      local left, right = caps[1] * scale, caps[2] * scale

      -- A bar narrower than the two ends squeezes them rather than letting them
      -- overlap.
      local span = width + (outset[1] + outset[3]) * scale
      if left + right > span then
        left, right = left * span / (left + right), right * span / (left + right)
      end

      local set = PieceTextures(bar, index)
      for i, piece in ipairs(pieces) do
        local texture = set[i]
        -- A background below the fill, a frame above it but under the bar's
        -- text, which is OVERLAY at sublevel 0.
        if part.background then
          texture:SetDrawLayer("BACKGROUND", 0)
        else
          texture:SetDrawLayer("OVERLAY", -1)
        end
        texture:SetTexture(piece[1])
        texture:SetTexCoord(piece[2], piece[3], piece[4], piece[5])
        texture:SetVertexColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
        texture:ClearAllPoints()
        texture:Show()
      end

      local x0, x1 = -outset[1] * scale, outset[3] * scale
      local y0, y1 = outset[2] * scale, -outset[4] * scale
      set[1]:SetPoint("TOPLEFT", bar, "TOPLEFT", x0, y0)
      set[1]:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", x0, y1)
      set[1]:SetWidth(left)
      set[3]:SetPoint("TOPRIGHT", bar, "TOPRIGHT", x1, y0)
      set[3]:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", x1, y1)
      set[3]:SetWidth(right)
      set[2]:SetPoint("TOPLEFT", set[1], "TOPRIGHT")
      set[2]:SetPoint("BOTTOMRIGHT", set[3], "BOTTOMLEFT")

      top = math.max(top, outset[2] * scale)
      hasBackground = hasBackground or part.background or false
    end
  end

  if border then
    return top, hasBackground, (border.textInset or 0) * scale, (border.textOffsetY or 0) * scale
  end
end
