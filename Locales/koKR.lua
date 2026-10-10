local L = LibStub("AceLocale-3.0"):NewLocale("InFlight", "koKR")
if not L then return end

-- Mouseover on the bar itself
L["TooltipOption1"] = "<쉬프트+클릭> 하면 이동합니다"
L["TooltipOption2"] = "<오른쪽-클릭> 하면 설정을 엽니다"
L["TooltipOption3"] = "<Ctrl+클릭> 하면 강제로 닫습니다"
L["Duration"] = "지속시간: "

-- Settings menu: what a change applies to
L["PerCharOptions"] = "캐릭터별 설정"

-- Settings menu: Bar Settings
L["BarOptions"] = "바 설정"
L["Height"] = "높이"
L["Width"] = "길이"
L["Texture"] = "바 텍스처"
L["Border"] = "테두리"
L["BarColor"] = "바 색상"
L["UnknownColor"] = "모르는 경로 색상"
L["BackgroundColor"] = "배경 색상"
L["BorderColor"] = "테두리 색상"
L["CountUp"] = "카운트 업"
L["FillUp"] = "바 채우기"
L["ShowSpark"] = "불꽃 표시"

-- Settings menu: Text Settings
L["TextOptions"] = "글자 설정"
L["Font"] = "글꼴"
L["FontColor"] = "글꼴 색상"
L["OutlineInfo"] = "정보 윤곽선"
L["OutlineTime"] = "시간 윤곽선"
L["CompactMode"] = "간단 모드"
L["TwoLines"] = "두 줄로 표시"
L["ToText"] = "\"~\"숙어"
L["Enter your 'to' text."] = "'행선지' 텍스트를 입력하세요."

-- Settings menu: Other
L["ShowChat"] = "채팅 메시지"
L["ConfirmFlight"] = "경로 확인"
L["ConfirmPopup"] = "%s로 비행할까요?"
L["ResetFlightTimes"] = "비행 시간 초기화"
L["ExportFlightTimes"] = "비행 시간 내보내기"

-- Chat messages
L["FlightTimeAdded"] = "추가 비행 시간 :"
L["FlightTimeUpdated"] = "업데이트 된 비행 시간 :"
L["FlightTimeContribute"] = "%s 비행 시간을 업로드할 수 있습니다. \"/inflight export\"를 입력하여 공유하세요."

-- Export window
L["ExportMessage"] = "새로 발견된 비행 경로를 공유해 주셔서 감사합니다!\n아래 텍스트를 클립보드에 복사(CTRL-C)한 후 다음 웹사이트 중 하나에 게시해 주세요:"
L["Select All"] = "모두 선택"
L["Dismiss"] = "닫기"

-- Parsing
L["DestParse"] = " %- .+"

-- Flight points and gossip options, looked up by name while in flight
L["Amber Ledge"] = "호박석 절벽"
L["AmberLedgeGossip"] = "변위의 보호막으로 가고 싶습니다"
L["Argent Tournament Grounds"] = "은빛십자군 마상시합 광장"
L["ArgentTournamentGossip"] = "히포그리프에 올라타서 전투를 준비합니다"
L["Blackwind Landing"] = "검은바람 비행기지"
L["BlackwindLandingGossip"] = "저를 하늘경비대 전초기지로 보내 주십시오"
L["Caverns of Time"] = "시간의 동굴"
L["CavernsOfTimeGossip"] = "저를 데려다주십시오"
L["Durnholde Keep"] = "던홀드 요새"
L["Expedition Point"] = "원정대 거점"
L["ExpeditionPointGossip"] = "징검다리 거점으로 보내 주십시오"
L["Explorers' League Outpost"] = "탐험가 연맹 전초기지"
L["Hellfire Peninsula"] = "지옥불 반도"
L["HellfirePeninsulaGossip"] = "징검다리 거점으로 보내 주십시오"
L["Honor Point"] = "명예 거점"
L["Nighthaven"] = "밤의 안식처"
L["NighthavenGossipA"] = "루테란 마을로 날아가고 싶습니다"
L["NighthavenGossipH"] = "썬더 블러프로 날아가고 싶어요"
L["Nozdormu's Lair"] = "Nozdormu의 소굴"
L["Old Hillsbrad Foothills"] = "옛 언덕마루 구릉지"
L["OldHillsbradGossip"] = "던홀드 요새로 갈 준비가 끝났습니다"
L["Reaver's Fall"] = "지옥절단기 함락지"
L["Reaver'sFallGossip"] = "<TODO>"
L["Return"] = "돌아오다"
L["Rut'theran Village"] = "루테란 마을"
L["Shatter Point"] = "징검다리 거점"
L["Shattered Sun Staging Area"] = "무너진 태양 집결지"
L["ShatterPointGossip"] = "명예 거점으로 보내 주십시오"
L["Skyguard Outpost"] = "하늘경비대 전초기지"
L["SkyguardOutpostGossip"] = "네, 검은바람 비행기지로 갔으면 합니다"
L["SSSAGossip"] = "작전이라고 하니 말입니다만, 제가 공습 명령을 받았습니다"
L["SSSAGossip2"] = "새벽칼날단의 증원군을 차단하려고 합니다"
L["Stormwind City"] = "스톰윈드"
L["StormwindCityGossip"] = "스톰윈드 항구 주변을 한 바퀴 돌면서 구경했으면 좋겠습니다"
L["Sun's Reach Harbor"] = "태양너울 항구"
L["The Sin'loren"] = "신로렌호"
L["TheSin'lorenGossip"] = "용매를 타고 태양너울까지 이동합니다"
L["Thunder Bluff"] = "썬더 블러프"
L["Transitus Shield (Scenic Route)"] = "변위의 보호막 (시닉 루트)"
L["Valgarde"] = "발가드"
L["ValgardeGossip"] = "탐험가 연맹 전초기지로 보내 주십시오"
-- The Shadowlands
L["Ring of Transference"] = "<TODO>"
L["ToBastionGossip1"] = "<TODO>"
L["ToBastionGossip2"] = "<TODO>"
L["Oribos"] = "<TODO>"
L["Bastion"] = "<TODO>"
