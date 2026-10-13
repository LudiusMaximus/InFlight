-- Makes the timer bar part of Blizzard's HUD edit mode, so that its position and
-- its looks can differ from one edit mode layout to the next.
--
-- Blizzard's layouts cannot hold anything but Blizzard's own systems, so the
-- library keeps our copy in InFlightDB and only reads which layout is active.
--
-- A layout's values are overrides on top of the user's own settings, never a
-- replacement for them: everything here goes through InFlight's look table, and
-- db.profile is left alone. See the comment on that table in InFlight.lua.

local LLS = LibStub("LibLayoutSettings-1.0", true)


-- Turns a list of media names into dropdown options, shown the way the settings
-- menu shows them. A list of textures or borders comes in groups, false between
-- them, which becomes a divider.
local function ToOptions(names)
  local options = {}
  for _, name in ipairs(names) do
    if name == false then
      options[#options + 1] = { separator = true }
    else
      options[#options + 1] = { value = name, text = InFlight:MediaDisplayName(name) }
    end
  end
  return options
end

-- Media lists go through InFlight, so that both panels offer the same ones:
-- fonts without those that duplicate another on this client, textures and
-- borders with Blizzard's from BarStyles.lua.
local function FontOptions()
  return ToOptions(InFlight:GetFontList())
end

local function TextureOptions()
  return ToOptions(InFlight:GetTextureList())
end

local function BorderOptions()
  return ToOptions(InFlight:GetBorderList())
end

-- Tries an option on the bar while the mouse rests on it, as the settings menu
-- does too.
local function TryOn(key)
  return function(value)
    InFlight:PreviewLook(key, value)
  end
end


-- The keys a layout may hold, filled in from the settings list below so that the
-- two cannot drift apart. Position is part of every entry.
local layoutKeys


-- Layout specific or not
--------------------------------------------------------------------------------
-- One state, reachable from two places: this, which the settings menu shows as
-- "Layout Specific Settings", and the InFlight checkbox in the layout editor.
-- While it is on, the active layout owns the bar and everything the settings menu
-- changes goes to that layout. While it is off, the bar wears the user's own
-- settings and the settings menu changes those.

------------------------------------
function InFlight:IsLayoutSpecific()
------------------------------------
  return LLS ~= nil and LLS:IsManaged("InFlightBar")
end


---------------------------------
function InFlight:GetLayoutName()
---------------------------------
  -- What the active layout is called, for naming it in the settings menu.
  return LLS and LLS:GetActiveLayoutName() or nil
end


---------------------------------------
function InFlight:CanBeLayoutSpecific()
---------------------------------------
  -- False on a client without an edit mode, under an override layout, the kind
  -- the game forces on the player and never writes to, and on a preset layout
  -- outside the layout editor.
  return LLS ~= nil and LLS:IsSupported() and LLS:CanManage()
end


------------------------------------
function InFlight:IsOnPresetLayout()
------------------------------------
  -- One of Blizzard's preset layouts, which cannot be changed outside the layout
  -- editor, and inside it only by saving it as a new layout.
  return LLS ~= nil and LLS:IsSupported() and LLS:IsPresetActive()
end


-----------------------------------------
function InFlight:ResetLayoutToDefaults()
-----------------------------------------
  -- Puts this layout's own settings back to the defaults in Defaults.lua. The
  -- user's own settings are not touched: this layout is what the settings menu is
  -- editing while it is layout specific, so this layout is what resets.
  if not layoutKeys then
    return
  end

  local defaults = self.defaults.profile
  for _, key in ipairs(layoutKeys) do
    local value = defaults[key]
    if value ~= nil then
      self:SetLookOverride(key, type(value) == "table" and CopyTable(value) or value)
    end
  end

  self:ApplyBarPosition()
  self:UpdateLook()
  self:CaptureEditModeLayout()
end


--------------------------------------------------
function InFlight:CopyLookFromProfile(profileName)
--------------------------------------------------
  -- Puts a set of the user's own settings onto the bar, wherever its settings are
  -- going right now: the layout in the layout editor, and on the settings page
  -- the layout or the user's own settings. Every key a layout may hold is
  -- written, then the library folds the result in. The profile itself is only
  -- read.
  if not layoutKeys then
    return
  end

  local stored = self.db.profiles[profileName]
  local defaults = self.defaults.profile

  for _, key in ipairs(layoutKeys) do
    -- AceDB strips default valued keys out of every profile but the one in use,
    -- so an absent key means the profile is content with the default.
    local value = stored and stored[key]
    if value == nil then
      value = defaults[key]
    end
    if value ~= nil then
      self:SetLook(key, value)
    end
  end

  self:ApplyBarPosition()
  self:UpdateLook()
  self:CaptureEditModeLayout()
end


--------------------------------------------
function InFlight:SetLayoutSpecific(enabled)
--------------------------------------------
  -- Turning it off parks this layout's look rather than dropping it, so turning
  -- it back on brings that look back instead of capturing whatever the bar has
  -- been wearing in the meantime.
  if LLS then
    LLS:SetManaged("InFlightBar", enabled)
  end
end


---------------------------------
function InFlight:SetupEditMode()
---------------------------------
  if not LLS or not LLS:IsSupported() then
    return
  end

  local L = self.L

  InFlightDB.editModeLayouts = InFlightDB.editModeLayouts or {}

  local settings = {
    -- The handful you normally reach for when setting a layout up.
    { key = "height",   name = L["Height"],   type = "slider", minValue = 4,  maxValue = 150,  stepSize = 1 },
    { key = "width",    name = L["Width"],    type = "slider", minValue = 40, maxValue = 1000, stepSize = 5 },
    { key = "fontsize", name = L["FontSize"], type = "slider", minValue = 4,  maxValue = 30,   stepSize = 1 },

    -- Compact mode wins over two lines in UpdateLook, so say so in the dialog
    -- rather than leaving a control that quietly does nothing. The predicate asks
    -- the look table, not the profile, because what matters here is the value
    -- this layout is drawing with.
    { key = "inline",   name = L["CompactMode"], type = "checkbox", refreshOnChange = true },
    { key = "twolines", name = L["TwoLines"],    type = "checkbox", sameRow = true,
      IsDisabled = function() return InFlight:GetLook("inline") end },

    -- Capped exactly like the settings menu popup, and not trimmed there either:
    -- every place the bar draws this puts a space on each side of it, but wanting
    -- a wider gap than that is the user's business, not ours.
    -- Compact mode shows the destination alone, so the separator has nothing to
    -- separate.
    { key = "totext", name = L["ToText"], type = "text", maxLetters = 24,
      IsDisabled = function() return InFlight:GetLook("inline") end },

    { type = "separator" },

    -- The border with what goes with it, then the texture with its colours: the
    -- bar's own, the one it wears when the flight is an unknown length, and
    -- what shows where it is not filled yet. The settings menu has the same
    -- groups.
    { key = "border",  name = L["Border"],  type = "dropdown", options = BorderOptions, OnHover = TryOn("border"),
      refreshOnChange = true },
    -- Only some borders have a background of their own to show.
    { key = "borderbg",    name = L["BorderBackground"], type = "checkbox",
      IsDisabled = function() return not InFlight:BorderHasBackground(InFlight:GetLook("border")) end },
    { key = "bordercolor", name = L["BorderColor"],      type = "color", sameRow = true,
      colorButton = InFlight.colorButtons.bordercolor },

    { type = "separator" },

    { key = "texture", name = L["Texture"], type = "dropdown", options = TextureOptions, OnHover = TryOn("texture") },
    { key = "barcolor",     name = L["BarColor"],        type = "color", colorButton = InFlight.colorButtons.barcolor },
    { key = "unknowncolor", name = L["UnknownColor"],    type = "color", sameRow = true,
      colorButton = InFlight.colorButtons.unknowncolor },
    { key = "backcolor",    name = L["BackgroundColor"], type = "color", colorButton = InFlight.colorButtons.backcolor },

    { type = "separator" },

    { key = "countup", name = L["CountUp"],   type = "checkbox" },
    { key = "fill",    name = L["FillUp"],    type = "checkbox", sameRow = true },
    { key = "spark",   name = L["ShowSpark"], type = "checkbox" },

    { type = "separator" },

    { key = "font",      name = L["Font"],      type = "dropdown", options = FontOptions, OnHover = TryOn("font") },
    { key = "fontcolor", name = L["FontColor"], type = "color" },
    { key = "outline",     name = L["OutlineInfo"], type = "checkbox" },
    { key = "outlinetime", name = L["OutlineTime"], type = "checkbox", sameRow = true },

    -- Reverts this bar alone, the way Blizzard's own dialogs do, and so it sits
    -- where theirs does: above the divider that closes the dialog off. The
    -- library labels it, enables it only when there is something to revert, and
    -- does the reverting.
    { type = "revert" },

    { type = "separator" },

    -- Blizzard puts its own Reset Position below the divider, so this goes there
    -- too. The library labels it, enables it only while the bar is off the spot
    -- GetDefaultPosition names, and does the resetting.
    { type = "resetPosition", tooltip = L["ResetPositionTooltip"] },

    -- The same reset the settings menu offers, which while a layout owns the bar
    -- is this layout's reset. Position included, so this is the wider of the two.
    { type = "button", text = L["ResetToDefaults"], tooltip = L["ResetToDefaultsTooltip"],
      sameRow = true,
      OnClick = function()
        InFlight:ResetToDefaults()
      end },

    { type = "separator" },

    -- Last, because it is the one row that reaches outside this layout. The
    -- sources are every other layout holding a look for the bar, then the user's
    -- own settings: the account wide set, and any character's own set that differs
    -- from it. Rebuilt every time the dialog is drawn, so a layout saved or
    -- deleted in the meantime is listed or gone accordingly.
    { type = "actions", name = L["CopyFrom"], placeholder = L["CopyFromChoose"],
      tooltip = L["CopyFromTooltip"],
      actions = function()
        local sources = {}

        for _, layout in ipairs(LLS:GetStoredLayouts("InFlightBar")) do
          sources[#sources + 1] = {
            text = layout.name,
            OnClick = function() LLS:CopyFrom("InFlightBar", layout.key) end,
          }
        end

        -- On the settings page with no layout owning the bar, the profile in use
        -- is the one being edited, and copying it onto itself would do nothing.
        local editing = not InFlight:IsLayoutSpecific() and InFlight.db:GetCurrentProfile()
        local profiles = {}
        for _, profile in ipairs(InFlight:GetCopyableProfiles()) do
          if profile.name ~= editing then
            profiles[#profiles + 1] = profile
          end
        end

        if #sources > 0 and #profiles > 0 then
          sources[#sources + 1] = { separator = true }
        end

        for _, profile in ipairs(profiles) do
          local name = profile.name
          sources[#sources + 1] = {
            text = profile.accountWide and L["AccountWideSettings"] or name,
            OnClick = function() InFlight:CopyLookFromProfile(name) end,
          }
        end

        return sources
      end },
  }

  -- Two jobs in one pass over the list just built. The keys a layout may hold
  -- come from the list itself, so it and ResetLayoutToDefaults cannot drift
  -- apart, and every row takes its tooltip from the same table the settings menu
  -- reads, so a setting cannot end up described one way here and another there.
  layoutKeys = { "p", "rp", "x", "y" }
  for _, setting in ipairs(settings) do
    if setting.key then
      layoutKeys[#layoutKeys + 1] = setting.key
      setting.tooltip = setting.tooltip or InFlight.tooltips[setting.key]
    end
  end

  LLS:RegisterFrame("InFlightBar", {
    -- The bar is only built when it is first needed, which may be here.
    GetFrame = function() return InFlight:GetBar() end,
    -- Plain, so that it reads like the entries of the edit mode's own panel.
    displayName = "InFlight",
    storage = InFlightDB.editModeLayouts,
    selectionInsets = { left = 8, right = 8, top = 8, bottom = 8 },
    -- The bar shows the route and the time, which the centred name would cover.
    showSelectionLabel = false,
    -- And which the glow's centre fill would sit over, so put the glow behind.
    -- Named rather than stepped down, because the bar's own backdrop is at LOW
    -- and the glow has to go behind that too.
    selectionBehind = "BACKGROUND",

    settings = settings,

    -- This layout owns nothing, so the overrides go and the user's own settings
    -- show through again.
    RestoreOwnSettings = function()
      InFlight:ClearLookOverrides()
    end,

    GetSetting = function(key)
      return InFlight:GetLook(key)
    end,

    SetSetting = function(key, value)
      InFlight:SetLookOverride(key, value)
    end,

    -- A change on the settings page, which goes where one from the settings menu
    -- goes: to the layout while it owns the bar, to the user's own settings
    -- otherwise.
    EditSetting = function(key, value)
      InFlight:SetLook(key, value)
    end,

    EditPosition = function(point, relativePoint, x, y)
      InFlight:SetLook("p", point)
      InFlight:SetLook("rp", relativePoint)
      InFlight:SetLook("x", x)
      InFlight:SetLook("y", y)
      InFlight:ApplyBarPosition()
    end,

    GetPosition = function()
      return InFlight:GetLook("p"), InFlight:GetLook("rp"),
             InFlight:GetLook("x"), InFlight:GetLook("y")
    end,

    -- What the Reset Position button puts back, and what it compares against to
    -- decide whether there is anything to put back.
    GetDefaultPosition = function()
      local defaults = InFlight.defaults.profile
      return defaults.p, defaults.rp, defaults.x, defaults.y
    end,

    SetPosition = function(point, relativePoint, x, y)
      InFlight:SetLookOverride("p", point)
      InFlight:SetLookOverride("rp", relativePoint)
      InFlight:SetLookOverride("x", x)
      InFlight:SetLookOverride("y", y)
      InFlight:ApplyBarPosition()
    end,

    OnChanged = function()
      InFlight:UpdateLook()
    end,

    OnPreview = function(shown)
      InFlight:SetPreview("editMode", shown)
    end,
  })

  self.SetupEditMode = nil
end


----------------------------------------------------
function InFlight:CreateSettingsRows(parent, opener)
----------------------------------------------------
  -- The layout editor's rows, drawn onto the settings page. Nil where there is no
  -- edit mode to have registered them with.
  if not layoutKeys then
    return nil
  end
  return LLS:CreateSettingsFrame("InFlightBar", parent, opener)
end


-----------------------------------------
function InFlight:CaptureEditModeLayout()
-----------------------------------------
  -- A change made in the settings menu is meant to stick, so a layout that owns
  -- the bar has to take it on board. Without this it would put its own value back
  -- the next time it is applied. Layouts that do not own the bar are left alone,
  -- so nothing changes for anyone who never ticked the box.
  if LLS then
    LLS:Capture("InFlightBar")
  end
end
