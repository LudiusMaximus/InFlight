local L = LibStub("AceLocale-3.0"):NewLocale("InFlight", "zhCN")
if not L then return end

-- Mouseover on the bar itself
L["TooltipOption1"] = "<Shift左键单击>移动"
L["TooltipOption2"] = "<点击右键>的选项"
L["TooltipOption3"] = "<Ctrl键左键单击>将强制关闭"
L["Duration"] = "持续时间："

-- Settings menu: what a change applies to
L["PerCharOptions"] = "字符特定选项"

-- Settings menu: Bar Settings
L["BarOptions"] = "时间条选项"
L["Height"] = "高度"
L["Width"] = "宽度"
L["Texture"] = "时间条纹理"
L["Border"] = "边框"
L["BarColor"] = "时间条颜色"
L["UnknownColor"] = "未知的颜色"
L["BackgroundColor"] = "背景颜色"
L["BorderColor"] = "边框颜色"
L["CountUp"] = "计数"
L["FillUp"] = "填充"
L["ShowSpark"] = "显示闪光"

-- Settings menu: Text Settings
L["TextOptions"] = "文字选项"
L["Font"] = "字体"
L["FontColor"] = "字体颜色"
L["OutlineInfo"] = "描边信息文本"
L["OutlineTime"] = "描边时间文本"
L["CompactMode"] = "紧凑模式"
L["TwoLines"] = "顯示為兩行"
L["ToText"] = "\"到\" 文字"
L["Enter your 'to' text."] = "输入你的'至'文字。"

-- Settings menu: Other
L["ShowChat"] = "聊天信息"
L["ConfirmFlight"] = "确认飞行"
L["ConfirmPopup"] = "乘坐航班到%s？"
L["ResetFlightTimes"] = "重置飞行时间"
L["ExportFlightTimes"] = "导出飞行时间"

-- Chat messages
L["FlightTimeAdded"] = "飞行时间补充："
L["FlightTimeUpdated"] = "飞行时间更新："
L["FlightTimeContribute"] = "%s 飞行时间可供贡献。输入\"/inflight export\"来分享。"

-- Export window
L["ExportMessage"] = "感谢分享您新发现的航线！\n请复制下面的文本到剪贴板 (CTRL-C)，然后将其发布到以下网站之一："
L["Select All"] = "全选"
L["Dismiss"] = "关闭"

-- Parsing
L["DestParse"] = "，.+"

-- Flight points and gossip options, looked up by name while in flight
L["Amber Ledge"] = "琥珀崖"
L["AmberLedgeGossip"] = "我要去永生之盾"
L["Argent Tournament Grounds"] = "银色比武场"
L["ArgentTournamentGossip"] = "跨上角鹰兽，准备作战"
L["Blackwind Landing"] = "黑风码头"
L["BlackwindLandingGossip"] = "送我回天空卫队哨站吧"
L["Caverns of Time"] = "时光之穴"
L["CavernsOfTimeGossip"] = "请带我去主人的巢穴"
L["Durnholde Keep"] = "敦霍尔德城堡"
L["Expedition Point"] = "远征军岗哨"
L["ExpeditionPointGossip"] = "送我去破碎岗哨"
L["Explorers' League Outpost"] = "探险者协会哨站"
L["Hellfire Peninsula"] = "地狱火半岛"
L["HellfirePeninsulaGossip"] = "送我去破碎岗哨"
L["Honor Point"] = "荣耀岗哨"
L["Nighthaven"] = "永夜港"
L["NighthavenGossipA"] = "我想飞往鲁瑟兰村"
L["NighthavenGossipH"] = "我想飞往雷霆崖"
L["Nozdormu's Lair"] = "Nozdormu的巢穴"
L["Old Hillsbrad Foothills"] = "旧希尔斯布莱德丘陵"
L["OldHillsbradGossip"] = "我准备好去敦霍尔德城堡了"
L["Reaver's Fall"] = "机甲残骸"
L["Reaver'sFallGossip"] = "<TODO>"
L["Return"] = "回来"
L["Rut'theran Village"] = "鲁瑟兰村"
L["Shatter Point"] = "破碎岗哨"
L["Shattered Sun Staging Area"] = "破碎残阳基地"
L["ShatterPointGossip"] = "送我到荣耀岗哨去"
L["Skyguard Outpost"] = "天空卫队哨站"
L["SkyguardOutpostGossip"] = "是，我愿意乘坐虚空鳐飞往黑风码头"
L["SSSAGossip"] = "说到行动，我接到命令，要去发动一次空袭"
L["SSSAGossip2"] = "我必须阻止晨锋部队的增援"
L["Stormwind City"] = "暴风城"
L["StormwindCityGossip"] = "我要绕暴风城港口游览一圈"
L["Sun's Reach Harbor"] = "阳湾港口"
L["The Sin'loren"] = "辛洛雷号"
L["TheSin'lorenGossip"] = "骑上龙鹰前往阳湾港"
L["Thunder Bluff"] = "雷霆崖"
L["Transitus Shield (Scenic Route)"] = "永生之盾（观光路线）"
L["Valgarde"] = "瓦加德"
L["ValgardeGossip"] = "带我去探险者协会哨站"
-- The Shadowlands
L["Ring of Transference"] = "<TODO>"
L["ToBastionGossip1"] = "<TODO>"
L["ToBastionGossip2"] = "<TODO>"
L["Oribos"] = "<TODO>"
L["Bastion"] = "<TODO>"
