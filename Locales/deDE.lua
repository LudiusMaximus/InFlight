local L = LibStub("AceLocale-3.0"):NewLocale("InFlight", "deDE")
if not L then return end

-- Mouseover on the bar itself
L["TooltipOption1"] = "<Umschalttaste+Linksklick> zum Bewegen"
L["TooltipOption2"] = "<Rechtsklick> für Einstellungen"
L["TooltipOption3"] = "<Strg+Linksklick> schließen erzwingen"
L["Duration"] = "Flugdauer: "

-- Settings menu: what a change applies to
L["PerCharOptions"] = "Charakterspezifische Einstellungen"

-- Settings menu: Bar Settings
L["BarOptions"] = "Leisteneinstellungen"
L["Height"] = "Höhe"
L["Width"] = "Breite"
L["Texture"] = "Textur"
L["Border"] = "Rand"
L["BarColor"] = "Farbe der Leiste"
L["UnknownColor"] = "Unbekannt-Farbe"
L["BackgroundColor"] = "Hintergrundfarbe"
L["BorderColor"] = "Randfarbe"
L["CountUp"] = "Hochzählen"
L["FillUp"] = "Auffüllen"
L["ShowSpark"] = "Funken anzeigen"

-- Settings menu: Text Settings
L["TextOptions"] = "Texteinstellungen"
L["Font"] = "Schriftart"
L["FontColor"] = "Schriftfarbe"
L["OutlineInfo"] = "Kontur-Info"
L["OutlineTime"] = "Kontur-Zeitangabe"
L["CompactMode"] = "Kompaktmodus"
L["TwoLines"] = "Zweizeilig"
L["ToText"] = "\"Nach\" Text"
L["Enter your 'to' text."] = "Gib hier deinen 'nach'-Text ein."

-- Settings menu: Other
L["ShowChat"] = "Chat-Nachrichten"
L["ConfirmFlight"] = "Flug bestätigen"
L["ConfirmPopup"] = "Flug nehmen nach\n\n%s ?"
L["ResetFlightTimes"] = "Flugzeiten zurücksetzen"
L["ExportFlightTimes"] = "Flugzeiten exportieren"

-- Chat messages
L["FlightTimeAdded"] = "Flugzeit hinzugefügt:"
L["FlightTimeUpdated"] = "Flugzeit aktualisiert:"
L["FlightTimeContribute"] = "Es stehen %s Flugzeiten zur Verfügung, die zur Verbesserung des Addons beitragen könnten. Gib \"/inflight export\" ein, um sie zu teilen."

-- Export window
L["ExportMessage"] = "Danke, dass du deine neu entdeckten Flugrouten teilen möchtest!\nBitte kopiere den unten stehenden Text in die Zwischenablage (STRG-C) und poste ihn auf einer der folgenden Websites:"
L["Select All"] = "Alles auswählen"
L["Dismiss"] = "Schließen"

-- Parsing
L["DestParse"] = ", .+"

-- Flight points and gossip options, looked up by name while in flight
L["Amber Ledge"] = "Bernsteinflöz"
L["AmberLedgeGossip"] = "Ich möchte Durchgang zum Transitusschild"
L["Argent Tournament Grounds"] = "Argentumturnierplatz"
L["ArgentTournamentGossip"] = "Schwingt Euch auf den Hippogryphen und macht Euch bereit zum Kampf"
L["Blackwind Landing"] = "Schattenwindlager"
L["BlackwindLandingGossip"] = "Bringt mich zum Außenposten der Himmelswache"
L["Caverns of Time"] = "Höhlen der Zeit"
L["CavernsOfTimeGossip"] = "Bringt mich bitte zum Hort des Meisters"
L["Durnholde Keep"] = "Burg Durnholde"
L["Expedition Point"] = "Expeditionsposten"
L["ExpeditionPointGossip"] = "Schickt mich zum Trümmerposten"
L["Explorers' League Outpost"] = "Außenposten der Forscherliga"
L["Hellfire Peninsula"] = "Höllenfeuerhalbinsel"
L["HellfirePeninsulaGossip"] = "Schickt mich zum Trümmerposten"
L["Honor Point"] = "Ehrenposten"
L["Nighthaven"] = "Nachthafen"
L["NighthavenGossipA"] = "Ich würde gerne nach Rut'theran fliegen"
L["NighthavenGossipH"] = "Ich würde gerne nach Donnerfels fliegen"
L["Nozdormu's Lair"] = "Nozdormus Versteck"
L["Old Hillsbrad Foothills"] = "Vorgebirge des Alten Hügellands"
L["OldHillsbradGossip"] = "Ich bin bereit, nach Burg Durnholde zu gehen"
L["Reaver's Fall"] = "Häschersturz"
L["Reaver'sFallGossip"] = "Gebt mir einen Windreiter. Ich werde zum Rückenbrecherposten fliegen"
L["Return"] = "Zurück zum Startpunkt"
L["Rut'theran Village"] = "Rut'theran"
L["Shatter Point"] = "Trümmerposten"
L["Shattered Sun Staging Area"] = "Sammelpunkt der Zerschmetterten Sonne"
L["ShatterPointGossip"] = "Schickt mich zum Ehrenposten"
L["Skyguard Outpost"] = "Außenposten der Himmelswache"
L["SkyguardOutpostGossip"] = "Ja, ich würde gerne zum Schattenwindlager fliegen"
L["SSSAGossip"] = "Wo wir gerade von Kämpfen sprechen, ich habe die Order, einen Luftangriff zu starten"
L["SSSAGossip2"] = "Ich muss die Verstärkung der Dämmerklingen abfangen"
L["Stormwind City"] = "Sturmwind"
L["StormwindCityGossip"] = "Ich möchte durch den Hafen von Sturmwind fliegen"
L["Sun's Reach Harbor"] = "Hafen der Sonnenweiten"
L["The Sin'loren"] = "Die Sin'loren"
L["TheSin'lorenGossip"] = "Fliegt auf dem Drachenfalken in die Sonnenweiten"
L["Thunder Bluff"] = "Donnerfels"
L["Transitus Shield (Scenic Route)"] = "Transitusschild (Freiflug)"
L["Valgarde"] = "Valgarde"
L["ValgardeGossip"] = "Bringt mich zum Außenposten der Forscherliga"
-- The Shadowlands
L["Ring of Transference"] = "Ring der Übertragung"
L["ToBastionGossip1"] = "<TODO>"
L["ToBastionGossip2"] = "Ich muss zurück zur Bastion"
L["Oribos"] = "Oribos"
L["Bastion"] = "Bastion"
