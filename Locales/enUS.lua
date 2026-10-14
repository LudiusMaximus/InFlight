local L = LibStub("AceLocale-3.0"):NewLocale("InFlight", "enUS", true, true)
if not L then return end

-- Mouseover on the bar itself
L["TooltipOption1"] = "<Shift Left-Click> to move"
L["TooltipOption2"] = "<Right-Click> for Settings"
L["TooltipOption3"] = "<Ctrl Left-Click> to force close"
L["Duration"] = "Duration: "

-- Settings page in the game's AddOns settings
L["Menu"] = "Menu"
L["ShowPreview"] = "Show Preview"
L["HidePreview"] = "Hide Preview"
L["PreviewTooltip"] = "Puts a made-up flight on the bar, so you can see your settings without flying anywhere."
L["PreviewInFlight"] = "The bar is showing your current flight already."

-- Settings menu: what a change applies to
L["LayoutSpecific"] = "Layout Specific Settings"
L["LayoutSpecificTooltip"] = "Give the current edit mode layout (%1$s) its own InFlight settings. Everything in this menu then changes that layout alone and your own settings are left as they are. Turning it off puts your own settings back on the bar and keeps the layout's for later."
L["LayoutSpecificPreset"] = "%1$s is a preset layout, and preset layouts cannot be changed. To give InFlight layout specific settings, open Edit Mode and save a copy of this layout as one of your own."
L["PerCharOptions"] = "Character Specific Settings"
L["PerCharOptionsTooltip"] = "Keep a separate set of InFlight settings for this character. Turned off, the bar uses your account wide settings, the ones every character shares."
L["PerCharLayoutHint"] = "Layout specific settings belong to the layout and are shared by all your characters. Turn off Layout Specific Settings to change this character's own settings."
L["PerCharDiscardPrompt"] = "This character's settings differ from your account wide settings.\n\nDiscard them, or keep them by replacing the account wide settings your other characters use?"
L["Discard"] = "Discard"
L["KeepForAllCharacters"] = "Keep Account Wide"

-- Settings menu: Bar Settings
L["BarOptions"] = "Bar Settings"
L["Height"] = true
L["HeightTooltip"] = "How tall the bar is."
L["Width"] = true
L["WidthTooltip"] = "How wide the bar is."
L["Border"] = true
L["BorderTooltip"] = "The border drawn around the bar."
L["BorderBackground"] = "Border's Background"
L["BorderBackgroundTooltip"] = "Some borders bring a background of their own, shaped to fit them. Shown, it takes the place of the bar's texture behind the bar, and the background color tints it. Borders without one always show the bar's texture."
L["BorderColor"] = "Border Color"
L["BorderColorTooltip"] = "The color of the border around the bar."
L["Texture"] = true
L["TextureTooltip"] = "The texture used to fill the bar."
L["BarColor"] = "Normal Texture Color"
L["BarColorTooltip"] = "The color of the texture filling the bar."
L["UnknownColor"] = "Unknown Texture Color"
L["UnknownColorTooltip"] = "The color of the bar when the length of the flight is not known. The bar is shown filled without spark. The time always counts up from take-off, even with Count Up off."
L["BackgroundColor"] = "Background Texture Color"
L["BackgroundColorTooltip"] = "The background color of the bar, seen wherever the bar is not filled yet."
L["White"] = true
L["WhiteTooltip"] = "Sets the color to white at full opacity. Many of the Blizzard textures and borders have colors of their own, and any color picked here is laid over theirs rather than replacing it, so white at full opacity is what shows them the way Blizzard drew them."
L["CountUp"] = "Count Up"
L["CountUpTooltip"] = "Show the time that has passed since take-off instead of the time still to go."
L["FillUp"] = "Fill Up"
L["FillUpTooltip"] = "Fill the bar as the flight goes on instead of emptying it."
L["Spark"] = true
L["SparkTooltip"] = "The bright marker at the leading edge of the bar."

-- Settings menu: Text Settings
L["TextOptions"] = "Text Settings"
L["Font"] = true
L["FontTooltip"] = "The font used for the text on the bar."
L["FontSize"] = "Font Size"
L["FontSizeTooltip"] = "The size of the text on the bar."
L["FontColor"] = "Font Color"
L["FontColorTooltip"] = "The color of the text on the bar."
L["OutlineInfo"] = "Outline Info"
L["OutlineInfoTooltip"] = "Outline the route text, which keeps it readable over a light bar."
L["OutlineTime"] = "Outline Time"
L["OutlineTimeTooltip"] = "Outline the timer text."
L["CompactMode"] = "Compact Mode"
L["CompactModeTooltip"] = "Put the destination and the timer side by side on one line inside the bar. The departure point and the \"To\" text are not shown."
L["TwoLines"] = "Two lines"
L["TwoLinesTooltip"] = "Put the departure point and the destination on separate lines above the bar."
L["ToText"] = "\"To\" Text"
L["ToTextTooltip"] = "Shown between the departure point and the destination. A space is added on each side of it."
L["Enter your 'to' text."] = true

-- Settings menu: Other
L["ShowChat"] = "Chat Messages"
L["ShowChatTooltip"] = "Print a message in chat whenever a flight time is learned or corrected."
L["ConfirmFlight"] = "Confirm Flight"
L["ConfirmFlightTooltip"] = "Ask before taking a flight, showing the destination and how long it should take."
L["ConfirmPopup"] = "Take flight to\n\n%s ?"
L["ResetToDefaults"] = "Reset to Defaults"
L["ResetToDefaultsTooltip"] = "Put every setting but the bar's position back to the way the addon ships. This applies to whatever is being edited right now: the layout's settings, this character's, or your account wide ones."
L["ResetFlightTimes"] = "Reset Flight Times"
L["ResetFlightTimesTooltip"] = "Forget every flight time InFlight has recorded and reload the interface. The times that ship with the addon come back."
L["ExportFlightTimes"] = "Export Flight Times"
L["ExportFlightTimesTooltip"] = "Show the flight times you have discovered, ready to copy and share."
L["NoNewFlightTimes"] = "You have not flown any route whose duration InFlight does not already know, so there is nothing to reset or share yet."

-- Layout editor, on top of the settings above
L["ResetPositionTooltip"] = "Put the bar back where the addon places it, leaving every other setting alone."
L["CopyFrom"] = "Copy From"
L["CopyFromChoose"] = "Choose..."
L["CopyFromTooltip"] = "Take the whole look of the bar, position included, from another layout or from your own settings. It arrives here as a change you can still revert, and the source is left as it is."
L["AccountWideSettings"] = "Account Wide Settings"

-- Chat messages
L["FlightTimeAdded"] = "flight time added:"
L["FlightTimeUpdated"] = "flight time updated:"
L["FlightTimeContribute"] = "%s flight times available to contribute. Enter \"/inflight export\" to share."

-- Export window
L["ExportMessage"] = "Thanks for sharing your newly discovered flight paths!\nPlease copy the text below to clipboard (CTRL-C) and post it on one of the following websites:"
L["Select All"] = "Select All"
L["Dismiss"] = "Dismiss"

-- Parsing
L["DestParse"] = ", .+"

-- Gossip options that start a flight, searched for in the option clicked, and the places on those flights that are no area of the game
L["AmberLedgeGossip"] = "I'd like passage to the Transitus Shield"
L["ArgentTournamentGossip"] = "Mount the Hippogryph and prepare for battle"
L["BlackwindLandingGossip"] = "Send me to the Skyguard Outpost"
L["CavernsOfTimeGossip"] = "Please take me to the master's lair"
L["ExpeditionPointGossip"] = "Send me to Shatter Point"
L["HellfirePeninsulaGossip"] = "Send me to Shatter Point"
L["Honor Point"] = true
L["NighthavenGossipA"] = "I'd like to fly to Rut'theran Village"
L["NighthavenGossipH"] = "I'd like to fly to Thunder Bluff"
L["Nozdormu's Lair"] = true
L["OldHillsbradGossip"] = "I'm ready to go to Durnholde Keep"
L["Return"] = true
L["ShatterPointGossip"] = "Send me to Honor Point"
L["SkyguardOutpostGossip"] = "Yes, I'd love a ride to Blackwind Landing"
L["SSSAGossip"] = "Speaking of action, I've been ordered to undertake an air strike"
L["SSSAGossip2"] = "I need to intercept the Dawnblade reinforcements"
L["StormwindCityGossip"] = "I'd like to take a flight around Stormwind Harbor"
L["TheSin'lorenGossip"] = "Ride the dragonhawk to Sun's Reach"
L["Transitus Shield (Scenic Route)"] = true
L["ValgardeGossip"] = "Take me to the Explorers' League Outpost"
