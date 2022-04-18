script_name("Management")
script_authors("Ruby Mitchell")
script_version("1.0")

require "lib.moonloader"

local inicfg = require("inicfg")
local ffi = require "ffi"

---- auto-update
local dlstatus = require('moonloader').download_status

update_state = false -- Если переменная == true, значит начнётся обновление.
update_found = false -- Если будет true, будет доступна команда /update.

local script_vers = 1.0
local script_vers_text = "v1.0" -- Название нашей версии. В будущем будем её выводить ползователю.

local update_url = 'https://raw.githubusercontent.com/Dev-Oleksandr/auto-update/main/update.ini' -- Путь к ini файлу. Позже нам понадобиться.
local update_path = getWorkingDirectory() .. "/update.ini"

local script_url = '' -- Путь скрипту.
local script_path = thisScript().path
-----
local Activated = false

local game_keys = require("game.keys")
local sampev = require("lib.samp.events")
local keys = require("vkeys")
local rkeys = require("rkeys")
local imgui = require("imgui")
local simple_imgui = require("imgui")
local fa = require ("fAwesome5")


local fa_font = nil
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })

local screenShot = {
    ffi.cast("void (*__stdcall)()", sampGetBase() + 0x70FC0), -- R1
}

--local renderCreateFont("Times New Roman", 14, require("moonloader").font_flag.BORDER)
local encoding = require("encoding")
encoding.default = "CP1251"
u8 = encoding.UTF8

imgui.ToggleButton = require("imgui_addons").ToggleButton
imgui.HotKey = require("imgui_addons").HotKey
imgui.Spinner = require("imgui_addons").Spinner
imgui.BufferingBar = require("imgui_addons").BufferingBar
--imgui.Checkbox = require("imgui_addons").Checkbox

local tLastKeys = {}

if not doesDirectoryExist('moonloader/Police config') then
    createDirectory('moonloader/Police config')
end

local directIni = getWorkingDirectory() .. "\\Police config\\settings.ini"
local directSobesIni = getWorkingDirectory() .. "\\Police config\\sobes.ini"
local directGnewsIni = getWorkingDirectory() .. "\\Police config\\gnews.ini"
local directHotkeyIni = getWorkingDirectory() .. "\\Police config\\hotkey.ini"
local JsonPathG = getWorkingDirectory()..'\\Police config\\GNews.json'

local img = imgui.CreateTextureFromFile(getGameDirectory() .. "\\moonloader\\Police config\\img.png")
--local picture = imgui.CreateTextureFromFile(getGameDirectory() .. "\\moonloader\\Police config\\picture.png")

if doesFileExist(JsonPathG) then
    local f = io.open(JsonPathG, 'r')
    if f then
        GNews = decodeJson(f:read('a*'))
        f:close()
    end
else
    local f = io.open(JsonPathG, 'w')
    GNews = {
        [1] = {
            text3 = u8'',
            text1 = u8'',
            delay = ''
        },
        [2] = {
            text3 = u8'',
            text1 = u8'',
            delay = ''
        },
        [3] = {
            text3 = u8'',
            text1 = u8'',
            delay = ''
        },
        [4] = {
            text3 = u8'',
            text1 = u8'',
            delay = ''
        },
        [5] = {
            text3 = u8'',
            text1 = u8'',
            delay = ''
        },
        [6] = {
            text3 = u8'',
            text1 = u8'',
            delay = ''
        },
        [7] = {
            text3 = u8'',
            text1 = u8'',
            delay = ''
        },
        [8] = {
            text3 = u8'',
            text1 = u8'',
            delay = ''
        }
    }
    f:write(encodeJson(GNews))
    f:close()
end


if not doesFileExist(directIni) then
    local f = io.open(directIni, "a")
    f:write("[config]\n")
    f:write("prefix=\n")
    f:write("prefix_r=\n")
    f:write("prefix_f=\n")
    f:write("active_prefix=false\n")
    f:write("active_prefix_r=false\n")
    f:write("active_prefix_f=false\n")
    f:write("setPosOverlay=false\n")
    f:write("themeNumber=1\n")
    f:write("styleNumber=1\n")
    f:write("overlay=false\n")
    f:close()
end

if not doesFileExist(directHotkeyIni) then
    local f = io.open(directHotkeyIni, "a")
    f:write("[hotkey]\n")
    f:write("bindClock=[]\n")
    f:write("bindTime=[]\n")
    f:write("bindManag=[]\n")
    f:write("bindLockMyCar=[]\n")
    f:close()
end

local mainIni = inicfg.load(nil, directIni)
local stoneIni = inicfg.save(mainIni, directIni)


local gnewsIni = inicfg.load(nil, directGnewsIni)
local gnewsSave = inicfg.save(gnewsIni, directGnewsIni)

local hotkeyIni = inicfg.load(nil, directHotkeyIni)

local changeInput = true


local mainWindow = {
    v = decodeJson(hotkeyIni.hotkey.bindClock)
}

local timeInfo = {
    v = decodeJson(hotkeyIni.hotkey.bindTime)
}

local managWindow = {
    v = decodeJson(hotkeyIni.hotkey.bindManag)
}

local lockMyCar = {
    v = decodeJson(hotkeyIni.hotkey.bindLockMyCar)
}

local hotkeySave = inicfg.save(hotkeyIni, directHotkeyIni)


local iScreenWidth, iScreenHeight = getScreenResolution()

local text_prefix = imgui.ImBuffer(u8("" .. mainIni.config.prefix), 256)
local text_prefix_r = imgui.ImBuffer(u8("" .. mainIni.config.prefix_r), 256)
local text_prefix_f = imgui.ImBuffer(u8("" .. mainIni.config.prefix_f), 256)


local main_window_state = imgui.ImBool(false)
local overlay = imgui.ImBool(mainIni.config.overlay)
local management_window = imgui.ImBool(false)

local themeNumber = imgui.ImInt(mainIni.config.themeNumber)
local styleNumber = imgui.ImInt(mainIni.config.styleNumber)

local active_prefix = imgui.ImBool(mainIni.config.active_prefix)
local active_prefix_r = imgui.ImBool(mainIni.config.active_prefix_r)
local active_prefix_f = imgui.ImBool(mainIni.config.active_prefix_f)

local SelGnews = imgui.ImInt(0)


local setPosOverlay = imgui.ImBool(mainIni.config.setPosOverlay)

local selectItem = imgui.ImInt(0)

local lastCheck  = 0
local exitGN = false

local CheckMyRang = false
local BlockTextPass = false
local PayDayInfo = false

local pushButton = true

local selected = 0

local GnewsText3 = {}
for i = 1, 8 do 
    GnewsText3Path = GNews[i].text3
    GnewsText3[i] = imgui.ImBuffer(u8''..GnewsText3Path, 2048)
end
local GnewsText1 = {}
for i = 1, 8 do 
    GnewsText1Path = GNews[i].text1
    GnewsText1[i] = imgui.ImBuffer(u8''..GnewsText1Path, 2048)
end
local GnewsDelay = {}
for i = 1, 8 do 
    GnewsDelayPath = GNews[i].delay
    GnewsDelay[i] = imgui.ImBuffer(u8''..GnewsDelayPath, 5)
end

--listGN = {
--    fa.ICON_FA_ANGLE_DOUBLE_DOWN .. u8(" Выберите фракцию ") .. fa.ICON_FA_ANGLE_DOUBLE_DOWN,
--    u8("Правительство"),
--    u8("Emerald Police Departament"),
--    u8("Министерство Обороны"),
--    u8("Health Medicine Ministry"),
--    u8("Средства Массовой Информации"),
--    u8("Лицензионный центр"),
--    u8("Мероприятия")
--}
--arr_gnews = listGN

arr_gnews = {u8'Выберите фракцию', u8'Лицензионный центр', u8'Полиция', u8'Мин. Обороны', u8'Больницы', u8'СМИ', u8'Правительство', u8'Мероприятия'}


function change_tags(text, table)
    for k, v in pairs(table) do
        text = text:gsub("%{"..k.."%}", v)
    end
    return text
end

local text = [[
    Сейчас мой ник - {mynick}
    Мой ID - {myid}
    Сервер, на котором я играю - {server}
    Не существующий тег - {local_tag}
]]
--sampAddChatMessage(change_tags("Привет, я {mynick}, мой ид {myid}", change))

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

        if update_found then -- Если найдено обновление, регистрируем команду /update.
            sampRegisterChatCommand('update' function()  -- Если пользователь напишет команду, начнётся обновление.
                update_state = true -- Если человек пропишет /update, скрипт обновится.
            end)
        else
            sampAddChatMessage('{FFFFFF}Нету доступных обновлений!')
        end

        sampRegisterChatCommand("tools", function()
            main_window_state.v = not main_window_state.v
            imgui.Process = main_window_state.v
        end)

        sampRegisterChatCommand("reload", reload)
        sampRegisterChatCommand("r", function(text) 
            if text ~= "" and text ~= " " then
                if active_prefix_r.v then
                    sampSendChat("/r " .. mainIni.config.prefix_r .. " " .. text, -1)
                else
                    sampSendChat("/r " .. text, -1)
                end
            end
        end)
        sampRegisterChatCommand("f", function(text)
            if text ~= "" and text ~= " " and active_prefix_f.v then 
                sampSendChat("/f " .. mainIni.config.prefix_f .. " " .. text, -1)
            else
                sampSendChat("/f " .. text, -1)
            end
        end)

        sampRegisterChatCommand("setskin", setskin)
        sampRegisterChatCommand("invite", invite)
        sampRegisterChatCommand("division", division)
        sampRegisterChatCommand("uninvite", uninvite)
        sampRegisterChatCommand("uninviteoff", uninviteoff)
        sampRegisterChatCommand("rang", rang)
        sampRegisterChatCommand("fwarn", fwarn)
        sampRegisterChatCommand("fwarnoff", fwarnoff)
        sampRegisterChatCommand("unfwarn", unfwarn)
        sampRegisterChatCommand("black", black)
        sampRegisterChatCommand("offblack", offblack)

        sampRegisterChatCommand("cancel", cancel)
        sampRegisterChatCommand("select", selected_cmd)

        bindClock = rkeys.registerHotKey(mainWindow.v, true, toolsFunc)
        bindTime = rkeys.registerHotKey(timeInfo.v, true, PayDayInfoFunc)
        bindManag = rkeys.registerHotKey(managWindow.v, true, management)
        bindLockMyCar = rkeys.registerHotKey(lockMyCar.v, true, lockMyCarFunc)

    while true do wait(0)

        if mainIni.config.overlay == true then
            simple_imgui.Process = overlay.v
        end


        if main_window_state.v then
            local noCloseWindow = false
            if isKeyJustPressed(0x1B) then
            --  noCloseWindow = isPauseMenuActive()
                main_window_state.v = false
            end
        end
        if update_state then -- Если человек напишет /update и обновлени есть, начнётся скаачивание скрипта.
            downloadUrlToFile(script_url, script_path, function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    sampAddChatMessage("{FFFFFF}Скрипт {32CD32}успешно {FFFFFF}обновлён.", 0xFF0000)
                end
            end)
            break
        end

        change = {
        ["mynick"] = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))):gsub("_", " "),
        ["nRPmynick"] = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))),
        ["myid"] = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)),
        ["server"] = sampGetCurrentServerName(),
        ["ping"] = sampGetPlayerPing(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))),
        ["local_tag"] = mainIni.config.prefix_r,
        ["global_tag"] = mainIni.config.prefix_f,
        ["area"] = calculateZone(getCharCoordinates(PLAYER_PED)),
        ["kvadrat"] = kvadrat(),
        ["city"] = city(),
        ["selectID"] = selectID(),
        ["selectName"] = selectName(),
        ["selectNameRP"] = selectName():gsub("_", " "),
        ["selectInfoOverlay"] = selectInfoOverlay():gsub("_", " "),
}
        myid = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
    end
end

function sampev.onSendChat(message)
    if active_prefix.v then
        if message == ")" or message == "(" or message ==  "))" or message == "((" or message == "xD" or message == ":D" or message == ":d" or message == "XD" then return {message} end
        return{mainIni.config.prefix.." "..message}
    end
end

function sampev.onServerMessage(color, text)
    if string.find(text, "Вы отыграли за час") and PayDayInfo then
        local play_time = string.match(text, "Вы отыграли за час (%d+)")
        if tonumber(play_time) < 1500 then
            local calc = 1500 - play_time
            local last_time = calc / 60
            lua_thread.create(function()
                wait(0)
                sampAddChatMessage(string.format("• {54b030}[PayDay Info] {FFFFFF}Для получения {FFBF00}PayDay{FFFFFF}, вам осталось - {00BFFF}%d {FFFFFF}мин.", last_time), -1)
            end)
        else
            sampAddChatMessage("• {54b030}[PayDay Info] {FFFFFF} Воу! Вы уже отыграли нужное кол-во минут для {FFBF00}PayDay{FFFFFF}. Не забудьте забрать его!", -1)
        end
    end

   --[[ if string.find(text, "Вы отыграли за час") and PayDayInfo then
       -- PayDayInfo = false
        return false
    end]]

end

function imgui.OnDrawFrame()
    setstyleandtheme()

    if not main_window_state.v and not management_window.v then
        imgui.SetMouseCursor(-1) imgui.ShowCursor = false imgui.Process = false else imgui.ShowCursor = true
    end
    
    if not overlay.v and not main_window_state.v and not management_window.v then
        imgui.SetMouseCursor(-1) imgui.ShowCursor = false else imgui.ShowCursor = true
    end

    if main_window_state.v then
        if main_window_state.v or management_window.v then
            imgui.ShowCursor = true
        else
            imgui.ShowCursor = false
        end 
        imgui.SetNextWindowSize(imgui.ImVec2(700, 300), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowPos(imgui.ImVec2(iScreenWidth / 2, iScreenHeight / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin("Gnews v." .. thisScript().version, main_window_state, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysUseWindowPadding)
        imgui.BeginChild("menu", imgui.ImVec2(170, 0))
            imgui.SetCursorPos(imgui.ImVec2(0, 20))
            imgui.Image(img, imgui.ImVec2(200, 190))
            if selected == 0 then selected = 1 end
            if imgui.Button(fa.ICON_FA_INFO_CIRCLE .. u8(" Основная информация"), imgui.ImVec2(170, 25)) then selected = 1 end
            if imgui.Button(fa.ICON_FA_COGS .. u8(" Настройки"), imgui.ImVec2(170, 25)) then selected = 2 end
          --  imgui.SetCursorPosX(50)

           -- imgui.Text(u8("v." .. thisScript().version))
           -- imgui.SameLine()
           -- imgui.TextRGB(u8("  Author: {DF2E08}Ruby Mitchell"))
        imgui.EndChild() imgui.SameLine()

        imgui.BeginChild("right", imgui.ImVec2(0, 0), true)
            if selected == 1 then
                imgui.SetCursorPos(imgui.ImVec2(5, 3))

                if imgui.Button(fa.ICON_FA_PUZZLE_PIECE .. u8(" Внешний вид"), imgui.ImVec2(155, 35)) then selected = 21 end
                imgui.SameLine()
                if imgui.Button(fa.ICON_FA_NEWSPAPER .. u8(" Гос.Новости"), imgui.ImVec2(155, 35)) then selected = 22 end
                imgui.SameLine()

                if imgui.Button(fa.ICON_FA_PODCAST .. u8(" Меню руководства"), imgui.ImVec2(187, 35)) then
                    management_window.v = not management_window.v
                    imgui.Process = main_window_state.v or management_window.v
                end

         --       imgui.Separator()

                imgui.SetCursorPos(imgui.ImVec2(5, 45))


                imgui.SetCursorPosY(233)
                imgui.Button(fa.ICON_FA_LIST_ALT .. u8(" Список обновлений"), imgui.ImVec2(150, 35))
                imgui.SameLine()
                if imgui.Button(fa.ICON_FA_CLOUD_DOWNLOAD_ALT .. u8(" Перезапустить скрипт"), imgui.ImVec2(200, 35)) then
                    imgui.OpenPopup("reloadScript")
                end
                if imgui.BeginPopup("reloadScript") then
                    imgui.TextRGB("Вы действительно хотите\nперезапустить скрипт ?")
                    imgui.SetCursorPosX(40)

                    if imgui.Button(u8("Да"), imgui.ImVec2(40, 20)) then
                        imgui.CloseCurrentPopup()
                        sampAddChatMessage("• {FFD700}[Подсказка]{FFFFFF} Вы успешно перезапустили скрипт", -1)
                        reload()
                    end

                    imgui.SameLine()
                    if imgui.Button(u8("Нет"), imgui.ImVec2(40, 20)) then
                        imgui.CloseCurrentPopup()
                    end
                    imgui.EndPopup()
                end

                imgui.SameLine()

                if imgui.Button(fa.ICON_FA_POWER_OFF .. u8(" Выключить скрипт"), imgui.ImVec2(145, 35)) then
                    imgui.OpenPopup("OffScript")
                end

                if imgui.BeginPopup("OffScript") then
                    imgui.TextRGB("Вы действительно хотите\nвыключить модификацию ?")
                    imgui.SetCursorPosX(40)

                    if imgui.Button(u8("Да"), imgui.ImVec2(40, 20)) then
                        imgui.CloseCurrentPopup()
                        sampAddChatMessage("• {FFD700}[Подсказка]{FFFFFF} Чтобы запустить скрипт, вам нужно перезайти в игру", -1)
                        thisScript():unload()
                        showCursor(false, false)
                    end

                    imgui.SameLine()
                    if imgui.Button(u8("Нет"), imgui.ImVec2(40, 20)) then
                        imgui.CloseCurrentPopup()
                    end
                    imgui.EndPopup()
                end
               -- imgui.Button(fa.ICON_FA_METEOR .. u8(" Discord"), imgui.ImVec2(150, 35))
                --imgui.Button(fa.ICON_FA_DISCORD .. u8(" Discord"), imgui.ImVec2(130, 35))

               --imgui.SetCursorPos(imgui.ImVec2(220, 365))
               --imgui.Separator()
               --imgui.SetCursorPos(imgui.ImVec2(200, 370))
               --imgui.SameLine()
               --imgui.Text(u8("Версия скрипта - " .. thisScript().version))
               --imgui.SameLine()
               --imgui.SetCursorPos(imgui.ImVec2(440, 370))

            end

            if selected == 2 then
                imgui.Columns(2, "##settings", false)

                
                imgui.Text(u8("Ваш основной префикс:"))
                imgui.SameLine()
                imgui.TextQuestion(u8("Ваш префикс будет показыватьcя обычном чате."))
                imgui.PushItemWidth(250)
                imgui.InputText(u8"##local_tag", text_prefix)
                imgui.PopItemWidth()
                imgui.SameLine()
                imgui.Checkbox("##box_local_tag", active_prefix)
                
                imgui.Text(u8("Ваш префикс локальной рации (/r):"))
                imgui.SameLine()
                imgui.TextQuestion(u8("Ваш префикс будет показываться в начале Вашего сообщения /r."))
                imgui.PushItemWidth(250)
                imgui.InputText(u8"##r_tag", text_prefix_r)
                imgui.PopItemWidth()
                imgui.SameLine()
                imgui.Checkbox("##box_r_tag", active_prefix_r)

                imgui.Text(u8("Ваш префикс глобальной рации (/f):"))
                imgui.SameLine()
                imgui.TextQuestion(u8("Ваш префикс будет показываться в начале Вашего сообщения /f."))
                imgui.PushItemWidth(250)
                imgui.InputText(u8"##f_tag", text_prefix_f)
                imgui.PopItemWidth()
                imgui.SameLine()    
                imgui.Checkbox("##box_f_tag", active_prefix_f)

                imgui.NextColumn()
                
                imgui.Text(u8("Показ. оверлей:"))
                imgui.SameLine()
                imgui.TextQuestion(u8("Панель с полезной информацией"))
               
                imgui.SameLine(150)
                if imgui.ToggleButton("", overlay) then
                    mainIni.config.overlay = overlay.v
                    inicfg.save(mainIni,directIni)
                end
                
                imgui.Text(u8("Перем. оверлей:"))
                imgui.SameLine()
                                
                imgui.TextQuestion(u8("Возможность перемещать оверлей"))

                imgui.SameLine(150)                
                imgui.ToggleButton("   ", setPosOverlay)

                imgui.Text(u8("Основного меню:"))
               -- imgui.SetCursorPos(imgui.ImVec2(250, 250))
                imgui.SameLine()
                imgui.TextQuestion(u8("Для открытия главного меню скрипта"))
                imgui.SameLine(150)                

                if imgui.HotKey("##1", mainWindow, tLastKeys, 100) then
                    if isKeyJustPressed(0x1B) then
                        mainWindow.v = {}
                    end
                    rkeys.changeHotKey(bindClock, mainWindow.v)
                    hotkeyIni.hotkey.bindClock = encodeJson(mainWindow.v)
                    inicfg.save(hotkeyIni, directHotkeyIni)
                end

                imgui.Text(u8("PayDay:"))
                imgui.SameLine()
                imgui.TextQuestion(u8("Возможность посмотреть, сколько\nосталось отыграть для получения PayDay"))
                imgui.SameLine(150)
                if imgui.HotKey("##2", timeInfo, tLastKeys, 100) then
                    rkeys.changeHotKey(bindTime, timeInfo.v)
                    hotkeyIni.hotkey.bindTime = encodeJson(timeInfo.v)
                    inicfg.save(hotkeyIni, directHotkeyIni)
                end

                imgui.Text(u8("Меню Руководства:"))
                imgui.SameLine()
                imgui.TextQuestion(u8("Чтобы открыть быстрое меню Руководства"))
                imgui.SameLine(150)
                if imgui.HotKey("##3", managWindow, tLastKeys, 100) then
                    rkeys.changeHotKey(bindManag, managWindow.v)
                    hotkeyIni.hotkey.bindManag = encodeJson(managWindow.v)
                    inicfg.save(hotkeyIni, directHotkeyIni)
                end

                imgui.Text(u8("Личный транспорт:"))
                imgui.SameLine()
                imgui.TextQuestion(u8("Чтобы открыть личный транспорт"))
                imgui.SameLine(150)
                if imgui.HotKey("##4", lockMyCar, tLastKeys, 100) then
                    rkeys.changeHotKey(bindLockMyCar, lockMyCar.v)
                    hotkeyIni.hotkey.bindLockMyCar = encodeJson(lockMyCar.v)
                    inicfg.save(hotkeyIni, directHotkeyIni)
                end
                imgui.Columns()

                mainIni.config.prefix = u8:decode(text_prefix.v)
                mainIni.config.prefix_r = u8:decode(text_prefix_r.v)
                mainIni.config.prefix_f = u8:decode(text_prefix_f.v)
                mainIni.config.active_prefix = active_prefix.v
                mainIni.config.active_prefix_r = active_prefix_r.v
                mainIni.config.active_prefix_f = active_prefix_f.v
                inicfg.save(mainIni,directIni)
    end


          if selected == 21 then
                imgui.Columns(2, "##2222", false)

                imgui.RadioButton(u8("Синяя"), themeNumber, 1)
                imgui.RadioButton(u8("Красная"), themeNumber, 2)
                imgui.RadioButton(u8("Коричневая"), themeNumber, 3)
                imgui.RadioButton(u8("Аква"), themeNumber, 4)
                imgui.RadioButton(u8("Чёрная"), themeNumber, 5)
                imgui.RadioButton(u8("Фиолетовая"), themeNumber, 6)
                imgui.RadioButton(u8("Черно-оранжевая"), themeNumber, 7)
                imgui.RadioButton(u8("Светло-темная"), themeNumber, 8)
                imgui.RadioButton(u8("Серая"), themeNumber, 9)
                imgui.NextColumn()
                imgui.RadioButton(u8("Вишневая"), themeNumber, 10)
                imgui.RadioButton(u8("Светло-красная"), themeNumber, 11)
                imgui.RadioButton(u8("Темно-красная"), themeNumber, 12)
                imgui.RadioButton(u8("Монохром"), themeNumber, 13)
                imgui.RadioButton(u8("Ярко-синяя"), themeNumber, 14)
                imgui.RadioButton(u8("Белая"), themeNumber, 15)
                imgui.RadioButton(u8("Салатовая"), themeNumber, 16)
                imgui.RadioButton(u8("Темно-зеленая"), themeNumber, 17)
                imgui.RadioButton(u8("Темно-синяя"), themeNumber, 18)
                imgui.Columns()
                imgui.Separator()
                imgui.Text("")
                imgui.SameLine(235)
                imgui.Text(u8("Стиль"))
                imgui.Separator()
                imgui.Columns(2, "##ll", false)
                imgui.RadioButton(u8("Строгий"), styleNumber, 1)
                imgui.NextColumn()
                imgui.RadioButton(u8("Мягкий"), styleNumber, 2)
                imgui.Columns()
                mainIni.config.themeNumber = themeNumber.v
                mainIni.config.styleNumber = styleNumber.v
                inicfg.save(mainIni,directIni)
            end

            if selected == 22 then
                local lef = 10
                imgui.SetCursorPos(imgui.ImVec2(lef-3, 8))
                imgui.Text(u8'Гос. новости для:') imgui.SameLine()
                imgui.PushItemWidth(153) imgui.SetCursorPosY(7)
                imgui.Combo('##SelGnews', SelGnews, arr_gnews, #arr_gnews)
                for i = 1, 8 do
                    if SelGnews.v == i then
                        imgui.SetCursorPosY(30) imgui.Separator() imgui.SetCursorPos(imgui.ImVec2(lef-3, 38))
                        imgui.Text(u8'3-х строчный /gnews') imgui.SameLine() imgui.SetCursorPosY(34)
                        if imgui.Button(u8'Отправить 3 строки') then
                            lua_thread.create(function()
                                    sampSendChat('/l Вещаю.')
                                    wait(2200)
                                for str in u8:decode(GNews[i].text3):gmatch('[^\n\r]+') do
                                    sampAddChatMessage('/gnews '..str, -1)
                                    wait(GNews[i].delay)
                                end
                                    wait(200)
                                    sampSendChat('/time')
                            end)
                        end imgui.SameLine()
                        imgui.SetCursorPos(imgui.ImVec2(268, 34)) imgui.Text(u8'Задержка:') imgui.SameLine() imgui.PushItemWidth(40)
                        imgui.SetCursorPos(imgui.ImVec2(337, 35))
                        if imgui.InputText(u8'##DelayGnews'..i, GnewsDelay[i]) then
                            GNews[i].delay = GnewsDelay[i].v
                            saveJsonG()
                        end imgui.SetCursorPos(imgui.ImVec2(lef-3, 60))
                        if imgui.InputTextMultiline(u8'##MuiltiGnews'..i, GnewsText3[i], imgui.ImVec2(500, 59)) then
                            GNews[i].text3 = GnewsText3[i].v
                            saveJsonG()
                        end imgui.SetCursorPosY(120)
                        imgui.TextRGB('Напоминание', 2)
                        imgui.PushItemWidth(371) imgui.SetCursorPosX(lef-3)
                        if imgui.InputTextMultiline(u8'##NapomGnews'..i, GnewsText1[i], imgui.ImVec2(500, 59)) then
                            GNews[i].text1 = GnewsText1[i].v
                            saveJsonG()
                        end imgui.SetCursorPosX(lef)
                        if imgui.Button(u8'Напом (Не освобождаю)') then
                            lua_thread.create(function()

                                sampSendChat('/l Вещаю.')
                                    wait(2200)
                                for str in u8:decode(GNews[i].text1):gmatch('[^\n\r]+') do
                                    sampAddChatMessage('/gnews '..str, -1)
                                    wait(GNews[i].delay)
                                end
                                    wait(200)
                                    sampSendChat('/time')


                                --sampSendChat('/l Вещаю, не освобождаю.')
                                --wait(2200)
                                --sampAddChatMessage('/gnews '..u8:decode(GnewsText1[i].v))
                                --wait(200)
                                --sampSendChat('/time')
                            end)
                        end imgui.SameLine() imgui.Text('                   ') imgui.SameLine()
                        if imgui.Button(u8'Напом (Освобождаю)') then
                            lua_thread.create(function()
                                sampSendChat('/l Вещаю.')
                                    wait(2200)
                                for str in u8:decode(GNews[i].text1):gmatch('[^\n\r]+') do
                                    sampAddChatMessage('/gnews '..str, -1)
                                    wait(GNews[i].delay)
                                end
                                    wait(200)
                                    sampSendChat('/time')
                            end)
                        end
                    end
                end
            end

          imgui.EndChild()
        imgui.End()
    end

    if overlay.v then 
        if main_window_state.v or management_window.v then
            imgui.ShowCursor = true
        else
            imgui.ShowCursor = false
        end
        local pos = imgui.GetWindowPos()
        imgui.SetNextWindowPos(imgui.ImVec2(iScreenWidth / 1.15, iScreenHeight / 2.8), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(250, 125), imgui.Cond.FirstUseEver)
        imgui.Begin(u8"Информационная панель", overlays, (not setPosOverlay.v and imgui.WindowFlags.NoMove or 0) + imgui.WindowFlags.NoResize + imgui.WindowFlags.ShowBorders + imgui.WindowFlags.NoCollapse)
        imgui.Text(u8(change_tags("{mynick} [{myid}] | Ping: {ping}", change)))
        imgui.Text(u8(change_tags("Квадрат: {kvadrat}", change)))
        imgui.Text(u8(change_tags("Район: {area}", change)))
        imgui.Separator()
        imgui.Text(u8(change_tags("Игрок: {selectInfoOverlay}", change)))
       -- imgui.Text(pos)
        --imgui.Text(u8(nickNameRP .." [".. myID .."] | Ping: " .. ping))
        --sampSendChat(change_tags(mainIni.config.arrest, change), -1)
        imgui.Separator()
        imgui.SetCursorPos(imgui.ImVec2(70, 105))
        imgui.Text(u8(os.date("%d.%m.%Y %H:%M:%S")))
        imgui.End()
    end

    if management_window.v then
        if main_window_state.v or management_window.v then
            main_window_state.v = false
            imgui.ShowCursor = true
        else
            imgui.ShowCursor = false
        end
        imgui.SetNextWindowPos(imgui.ImVec2(iScreenWidth / 2, iScreenHeight / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(330, 402), imgui.Cond.FirstUseEver)
        imgui.Begin("Management", management_window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysUseWindowPadding + imgui.WindowFlags.NoScrollWithMouse)
        imgui.BeginChild("menu", imgui.ImVec2(0, 0))
        if imgui.Button(u8("Принять в организацию"), imgui.ImVec2(330, 30)) then
            inviteFunc(1)
        end
        if imgui.Button(u8("Уволить из организации"), imgui.ImVec2(330, 30)) then
            uninviteFunc(1)
        end
        if imgui.Button(u8("Уволить из организации (offline)"), imgui.ImVec2(330, 30)) then
            uninviteoffFunc(1)
        end
        if imgui.Button(u8("Изменить ранг"), imgui.ImVec2(330, 30)) then
            rangFunc(1)
        end
        if imgui.Button(u8("Изменить скин"), imgui.ImVec2(330, 30)) then
            setskinFunc(1)
        end
        if imgui.Button(u8("Изменить отдел"), imgui.ImVec2(330, 30)) then
            divisionFunc(1)
        end
        if imgui.Button(u8("Выдать выговор"), imgui.ImVec2(330, 30)) then
            fwarnFunc(1)
        end
        if imgui.Button(u8("Выдать выговор (offline)"), imgui.ImVec2(330, 30)) then
            fwarnoffFunc(1)
        end
        if imgui.Button(u8("Снять выговор"), imgui.ImVec2(330, 30)) then
            unfwarnFunc(1)
        end
        if imgui.Button(u8("Вынести/Занести в Черный Список"), imgui.ImVec2(330, 30)) then
            blackFunc(1)
        end
        if imgui.Button(u8("Вынести/Занести в Черный Список (offline)"), imgui.ImVec2(330, 30)) then
            offblackFunc(1)
        end
        imgui.EndChild()
        imgui.End()
    end
end

function saveJsonG()
    if doesFileExist(JsonPathG) then
      local f = io.open(JsonPathG, 'w+')
      if f then
        f:write(encodeJson(GNews)):close()
      end
    end
end

function imgui.TextQuestion(text)
    imgui.TextDisabled(fa.ICON_FA_QUESTION_CIRCLE)
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(450)
        imgui.TextUnformatted(text)
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

function imgui.ButtonHint(text)
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(450)
        imgui.TextUnformatted(text)
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

function management()
    if not sampIsDialogActive() and not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not main_window_state.v then
        management_window.v = not management_window.v
        imgui.Process = main_window_state or management_window.v
    end
end

function toolsFunc()
    if not sampIsDialogActive() and not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not management_window.v then
        main_window_state.v = not main_window_state.v
        imgui.Process = main_window_state.v
    end
end

function reload()
    lua_thread.create(function()
        thisScript():reload()
        showCursor(false, false)
    end)
end

function PayDayInfoFunc()
    if not sampIsDialogActive() and not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not main_window_state.v  then
        lua_thread.create(function()
            PayDayInfo = true
            sampSendChat("/time")
            PayDayInfo = false
        end)
    end
end

function lockMyCarFunc()
    if not sampIsDialogActive() and not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not main_window_state.v then
        lua_thread.create(function()
            sampSendChat("/lock")
            wait(100)
        end)
    end
end

function sendChat(param)
    sampSendChat(change_tags(param, change))
end

function TimeScreen()
    lua_thread.create(function()
        sampSendChat("/time")
        wait(1000)
        MakeScreenshot()
    end)
end

 -- #####################Команды######################


function division(param)
    lua_thread.create(function()
        local id = tonumber(param)
        if param and id ~= nil then
            if id == myid then
                sendChat("/division {myid}")
            else
                if sampIsPlayerConnected(id) then
                    sampSendChat("/me засунув руку в правый карман, достал телефон")
                    wait(400)
                    sampSendChat("/me открыв приложение организации, нажал на кнопку «Сотрудники»")
                    wait(400)
                    sampSendChat("/me введя имя, фамилию и отдел, нажал на кнопку «Изменить»")
                    wait(400)
                    sampSendChat("/me заблокировав экран, положил телефон в правый карман")
                    wait(2000)
                    sampSendChat("/division " .. id)
                else
                    sampAddChatMessage("• {F31D2F}[Ошибка] {FFFFFF}Игрок с которым вы взаимодействуете не в сети", -1)
                end
            end
        else
            sampAddChatMessage("• {FFD700}[Подсказка] {FFFFFF}Используйте {FF4500}/division [ID]{FFFFFF}, чтобы изменить отдел", -1)
        end
    end)
end

function divisionFunc(param)
    lua_thread.create(function()
        if param == 1 then
            if playerid == nil then
                sampSetChatInputText("/division ")
                sampSetChatInputEnabled(true)
            else
                sampSendChat("/me засунув руку в правый карман, достал телефон")
                wait(400)
                sampSendChat("/me открыв приложение организации, нажал на кнопку «Сотрудники»")
                wait(400)
                sampSendChat("/me введя имя, фамилию и отдел, нажал на кнопку «Изменить»")
                wait(400)
                sampSendChat("/me заблокировав экран, положил телефон в правый карман")
                wait(2000)
                sendChat("/division {selectID}")
            end
        end
    end)
end

function dialog()
    lua_thread.create(function()
            sampSendChat("Здравствуйте!")
            wait(2000)
            sampSendChat("/do Продавец: Здравствуйте, слушаю Вас.")
            wait(2000)
            sampSendChat("Я хотел бы купить у вас маленькую нагрудную камеру.")
            wait(2000)
            sampSendChat("Имеются в наличии?")
            wait(2000)
            sampSendChat("/do Продавец: Да, как раз осталось несколько штук.")
            wait(2000)
            sampSendChat("/do Продавец: Вам нужна только одна?")
            wait(2000)
            sampSendChat("Да, мне одной хватит, сколько будет стоять?")
            wait(2000)
            sampSendChat("/do Продавец: С вас 10.000$.")
            wait(2000)
            sampSendChat("/do У Руби в кармане лежил кошелёк")
            wait(2000)
            sampSendChat("/me достал кошелёк, после открыл его")
            wait(2000)
            sampSendChat("/me достал несколько купюр в сумме 10.000$")
            wait(2000)
            sampSendChat("/me передал деньги продавцу")
            wait(2000)
            sampSendChat("/do Продавец взяла деньги, затем передала камеру")
            wait(2000)
            sampSendChat("/me взял камеру")
            wait(2000)
            sampSendChat("Спасибо, всего хорошего! До свидания.")
    end)
end

function inviteFunc(param)
    lua_thread.create(function()
        if param == 1 then -- в окне management
            if playerid == nil then
                sampSetChatInputText("/invite ")
                sampSetChatInputEnabled(true)
            else
                sampSendChat("/me засунув руку в правый карман, достал телефон")
                wait(400)
                sampSendChat("/me открыв приложение организации, нажал на кнопку «Сотрудники»")
                wait(400)
                sampSendChat("/me введя имя и фамилию, нажал на кнопку «Добавить»")
                wait(400)
                sampSendChat("/me заблокировав экран, положил телефон в правый карман")
                wait(400)
                sampSendChat("/do На плече висит рабочая сумка, в которой лежит чистая форма.")
                wait(400)
                sampSendChat("/me приоткрыв сумку, достал чистую форму")
                wait(400)
                sampSendChat("/todo Вот, ваша форма.*передавая форму человеку напротив")
                wait(2000)
                sampSendChat(change_tags("/invite {selectID}", change), -1)
            end
        end
    end)
end

function invite(param)
     lua_thread.create(function()
        local id = tonumber(param)
        if param and id ~= nil then
            if sampIsPlayerConnected(id) then
                sampSendChat("/me засунув руку в правый карман, достал телефон")
                wait(400)
                sampSendChat("/me открыв приложение организации, нажал на кнопку «Сотрудники»")
                wait(400)
                sampSendChat("/me введя имя и фамилию, нажал на кнопку «Добавить»")
                wait(400)
                sampSendChat("/me заблокировав экран, положил телефон в правый карман")
                wait(400)
                sampSendChat("/do На плече висит рабочая сумка, в которой лежит чистая форма.")
                wait(400)
                sampSendChat("/me приоткрыв сумку, достал чистую форму")
                wait(400)
                sampSendChat("/todo Вот, ваша форма.*передавая форму человеку напротив")
                wait(2000)
                sampSendChat("/invite " .. id)
            else
                sampAddChatMessage("• {F31D2F}[Ошибка] {FFFFFF}Игрок с которым вы взаимодействуете не в сети", -1)
            end
        else
            sampAddChatMessage("• {FFD700}[Подсказка] {FFFFFF}Используйте {FF4500}/invite [ID]{FFFFFF}, чтобы принять во фракцию", -1)
        end
    end)
end

function rangFunc(param)
    lua_thread.create(function()
        if param == 1 then -- в окне management
            if playerid == nil then
                sampSetChatInputText("/rang ")
                sampSetChatInputEnabled(true)
            else
                sampSendChat("/me засунув руку в правый карман, достал телефон")
                wait(400)
                sampSendChat("/me открыв приложение организации, нажал на кнопку «Сотрудники»")
                wait(400)
                sampSendChat("/me введя имя, фамилию и должность, нажал на кнопку «Изменить»")
                wait(400)
                sampSendChat("/me заблокировав экран, положил телефон в правый карман")
                wait(2000)
                sendChat("/rang {selectID}")
             --   sampSendChat(change_tags("/rang {selectID}", change), -1)
            end
        end
    end)
end

function rang(param)
    lua_thread.create(function()
        local id = tonumber(param)
        if param and id ~= nil then
            if sampIsPlayerConnected(id) then
                sampSendChat("/me засунув руку в правый карман, достал телефон")
                wait(400)
                sampSendChat("/me открыв приложение организации, нажал на кнопку «Сотрудники»")
                wait(400)
                sampSendChat("/me введя имя, фамилию и должность, нажал на кнопку «Изменить»")
                wait(400)
                sampSendChat("/me заблокировав экран, положил телефон в правый карман")
                wait(2000)
                sampSendChat("/rang " .. id)
            else
                sampAddChatMessage("• {F31D2F}[Ошибка] {FFFFFF}Игрок с которым вы взаимодействуете не в сети", -1)
            end
        else
            sampAddChatMessage("• {FFD700}[Подсказка] {FFFFFF}Используйте {FF4500}/rang [ID]{FFFFFF}, чтобы изменить ранг", -1)
        end
    end)
end

function uninviteFunc(param)
    lua_thread.create(function()
        if param == 1 then
            wait(100)
            sampSetChatInputText("/uninvite ")
            sampSetChatInputEnabled(true)
        end
    end)
end

function uninvite(param)
    lua_thread.create(function()
        local id, reason = string.match(param, "(%d+) (.+)")
        if param:len() > 0 and id ~= nil and reason ~= nil then
            if sampIsPlayerConnected(id) then
                sampSendChat("/me засунув руку в правый карман, достал телефон")
                wait(400)
                sampSendChat("/me открыв приложение организации, нажал на кнопку «Сотрудники»")
                wait(400)
                sampSendChat("/me введя имя, фамилию и причину, нажал на кнопку «Удалить»")
                wait(400)
                sampSendChat("/me заблокировав экран, положил телефон в правый карман")
                wait(2000)
                sampSendChat("/uninvite " .. id .. " " .. reason)
            else
                sampAddChatMessage("• {F31D2F}[Ошибка] {FFFFFF}Игрок с которым вы взаимодействуете не в сети", -1)
            end
        else
            sampAddChatMessage("• {FFD700}[Подсказка] {FFFFFF}Используйте {FF4500}/uninvite [ID] [Причина]{FFFFFF}, чтобы уволить из организации", -1)
        end
    end)
end

function uninviteoffFunc(param)
    lua_thread.create(function()
        if param == 1 then
            wait(100)
            sampSetChatInputText("/uninviteoff ")
            sampSetChatInputEnabled(true)
        end
    end)
end

function uninviteoff()
    lua_thread.create(function()
        local id, reason = string.match(param, "(.+) (.+)")
        if param:len() > 0 and id ~= nil and reason ~= nil then
            if sampIsPlayerConnected(id) then
                sampSendChat("/me засунув руку в правый карман, достал телефон")
                wait(400)
                sampSendChat("/me открыв приложение организации, нажал на кнопку «Сотрудники»")
                wait(400)
                sampSendChat("/me введя имя, фамилию и причину, нажал на кнопку «Удалить»")
                wait(400)
                sampSendChat("/me заблокировав экран, положил телефон в правый карман")
                wait(2000)
                sampSendChat("/uninviteoff " .. id .. " " .. reason)
            else
                sampAddChatMessage("• {F31D2F}[Ошибка] {FFFFFF}Игрок с которым вы взаимодействуете не в сети", -1)
            end
        else
            sampAddChatMessage("• {FFD700}[Подсказка] {FFFFFF}Используйте {FF4500}/uninviteoff [ID]{FFFFFF}, чтобы уволить из организации [offline]", -1)
        end
    end)
end

function setskinFunc(param)
    lua_thread.create(function()
        if param == 1 then
            if playerid == nil then
                sampSetChatInputText("/setskin ")
                sampSetChatInputEnabled(true)
            else
                sampSendChat("/do На плече висит рабочая сумка, в которой лежит чистая форма.")
                wait(400)
                sampSendChat("/me приоткрыв сумку, достал чистую форму")
                wait(400)
                sampSendChat("/todo Вот, ваша форма.*передавая форму человеку напротив")
                wait(2000)
                sampSendChat(change_tags("/setskin {selectID}", change), -1)
            end
        end
    end)
end

function setskin(param)
    lua_thread.create(function()
        local id = tonumber(param)
        if param and id ~= nil then
            if id == myid then
                sampSendChat("/setskin " .. id)
            else
                if sampIsPlayerConnected(id) then
                   sampSendChat("/do На плече висит рабочая сумка, в которой лежит чистая форма.")
                    wait(400)
                    sampSendChat("/me приоткрыв сумку, достал чистую форму")
                    wait(400)
                    sampSendChat("/todo Вот, ваша форма.*передавая форму человеку напротив")
                    wait(2000)
                    sampSendChat("/setskin " .. id)
                else
                    sampAddChatMessage("• {F31D2F}[Ошибка] {FFFFFF}Игрок с которым вы взаимодействуете не в сети", -1)
                end
            end
        else
            sampAddChatMessage("• {FFD700}[Подсказка] {FFFFFF}Используйте {FF4500}/setskin [ID]{FFFFFF}, чтобы изменить скин", -1)
        end
    end)
end

function unfwarn(param)
    lua_thread.create(function()
        local id, reason = string.match(param, "(%d+) (.+)")
        if param:len() > 0 then
            sampSendChat("/me засунув руку в правый карман, достал телефон")
            wait(400)
            sampSendChat("/me открыв приложение организации, нажал на кнопку «Выговоры»")
            wait(400)
            sampSendChat("/me введя имя, фамилию и причину, нажал на кнопку «Снять»")
            wait(400)
            sampSendChat("/me заблокировав экран, положил телефон в правый карман")
            wait(2000)
            sampSendChat("/unfwarn " .. id .. " " .. reason)
        else
            sampAddChatMessage("• {FFD700}[Подсказка] {FFFFFF}Используйте {FF4500}/unfwarn [ID] [Причина]{FFFFFF}, чтобы снять выговор", -1)
        end
    end)
end

function unfwarnFunc(param)
    lua_thread.create(function()
        if param == 1 then
            wait(100)
            if playerid == nil then
                sampSetChatInputText("/unfwarn")
                sampSetChatInputEnabled(true)
            else
                sampSetChatInputText("/unfwarn " .. playerid)
                sampSetChatInputEnabled(true)
            end
        end
    end)
end

function fwarnFunc(param)
    lua_thread.create(function()
        if param == 1 then
            wait(100)
            if playerid == nil then
                sampSetChatInputText("/fwarn ")
                sampSetChatInputEnabled(true)
            else
                sampSetChatInputText("/fwarn " .. playerid)
                sampSetChatInputEnabled(true)
            end
        end
    end)
end

function fwarnoffFunc(params)
    lua_thread.create(function()
        if param == 1 then
            wait(100)
            if playerid == nil then 
                sampSetChatInputText("/fwarnoff ")
                sampSetChatInputEnabled(true)
            else
                sampSetChatInputText("/fwarnoff " .. playerid)
                sampSetChatInputEnabled(true)
            end
        end
    end)
end

function fwarn(param)
    lua_thread.create(function()
        local id, reason = string.match(param, "(%d+) (.+)")
        if param:len() > 0 and id ~= nil and reason ~= nil then
            if sampIsPlayerConnected(id) then
                sampSendChat("/me засунув руку в правый карман, достал телефон")
                wait(400)
                sampSendChat("/me открыв приложение организации, нажал на кнопку «Выговоры»")
                wait(400)
                sampSendChat("/me введя имя, фамилию и причину, нажал на кнопку «Выдать»")
                wait(400)
                sampSendChat("/me заблокировав экран, положил телефон в правый карман")
                wait(2000)
                sampSendChat("/fwarn " .. id .. " " .. reason)
            else
                sampAddChatMessage("• {F31D2F}[Ошибка] {FFFFFF}Игрок с которым вы взаимодействуете не в сети", -1)
            end
        else
            sampAddChatMessage("• {FFD700}[Подсказка] {FFFFFF}Используйте {FF4500}/fwarn [ID] [Причина]{FFFFFF}, чтобы выдать выговор", -1)
        end
    end)
end

function fwarnoff(param)
    lua_thread.create(function()
        local name, reason = string.match(param, "(.+) (.+)")
        if param:len() > 0 then
            sampSendChat("/me засунув руку в правый карман, достал телефон")
            wait(400)
            sampSendChat("/me открыв приложение организации, нажал на кнопку «Выговоры»")
            wait(400)
            sampSendChat("/me введя имя, фамилию и причину, нажал на кнопку «Выдать»")
            wait(400)
            sampSendChat("/me заблокировав экран, положил телефон в правый карман")
            wait(2000)
            sampSendChat("/fwarnoff " .. name .. " " .. reason)
        else
            sampAddChatMessage("• {FFD700}[Подсказка] {FFFFFF}Используйте {FF4500}/fwarnoff [ID] [Причина]{FFFFFF}, чтобы выдать выговор [offline]", -1)
        end
    end)
end

function black(param)
    lua_thread.create(function()
        local id = tonumber(param)
        if param and id ~= nil then
            if sampIsPlayerConnected(id) then
                sampSendChat("/me засунув руку в правый карман, достал телефон")
                wait(400)
                sampSendChat("/me открыв приложение организации, нажал на кнопку «Чёрный список»")
                wait(400)
                sampSendChat("/me введя имя, фамилию и причину, нажал на кнопку «Подтвердить»")
                wait(400)
                sampSendChat("/me заблокировав экран, положил телефон в правый карман")
                wait(2000)
                sampSendChat("/black " .. id)
            else
                sampAddChatMessage("• {F31D2F}[Ошибка] {FFFFFF}Игрок с которым вы взаимодействуете не в сети", -1)
            end
        else
            sampAddChatMessage("• {FFD700}[Подсказка] {FFFFFF}Используйте {FF4500}/black [ID]{FFFFFF}, чтобы Черный список занести/вынести", -1)
        end
    end)
end

function blackFunc(param)
    lua_thread.create(function()
        if param == 1 then
            wait(100)
            if playerid == nil then
                sampSetChatInputText("/black ")
              sampSetChatInputEnabled(true)
            else
                sampSetChatInputText("/black " .. playerid)
                sampSetChatInputEnabled(true)
            end
        end
    end)
end

function offblack(param)
    lua_thread.create(function()
        if param:len() > 0 then
            sampSendChat("/me засунув руку в правый карман, достал телефон")
            wait(400)
            sampSendChat("/me открыв приложение организации, нажал на кнопку «Чёрный список»")
            wait(400)
            sampSendChat("/me введя имя, фамилию и причину, нажал на кнопку «Подтвердить»")
            wait(400)
            sampSendChat("/me заблокировав экран, положил телефон в правый карман")
            wait(2000)
            sampSendChat("/black " .. param)
        else
            sampAddChatMessage("• {FFD700}[Подсказка] {FFFFFF}Используйте {FF4500}/offblack [ID]{FFFFFF}, чтобы Черный список занести/вынести [offline]", -1)
        end
    end)
end

function offblackFunc(param)
    lua_thread.create(function()
        if param == 1 then
            wait(100)
            sampSetChatInputText("/offblack ")
            sampSetChatInputEnabled(true)
        end
    end)
end

function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig() -- to use "imgui.ImFontConfig.new()" on error
        font_config.MergeMode = true

        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF("moonloader/resource/fonts/fa-solid-900.ttf", 13.0, font_config, fa_glyph_ranges)
    end
end


function selectID()
    local result, target = getCharPlayerIsTargeting(playerHandle)
    if result and isKeyJustPressed(0x31) then 
        result, playerid = sampGetPlayerIdByCharHandle(target) 
        sampAddChatMessage("• {FFD700}[Подсказка] {FFFFFF}Вы начали взаимодействовать с {de6262}" .. sampGetPlayerNickname(playerid), -1)
    end -- Если зажата пкм на игроке и 1, то получаем ID.
    if playerid ~= nil then
        return playerid
    end
end

function selected_cmd(param)
    lua_thread.create(function()
        local id = tonumber(param)
        if param and id ~= nil then
            if sampIsPlayerConnected(id) then
                sampAddChatMessage("• {FFD700}[Подсказка] {FFFFFF}Вы начали взаимодействовать с {de6262}" .. sampGetPlayerNickname(param), -1)
                playerid = id
            else
                sampAddChatMessage("• {F31D2F}[Ошибка] {FFFFFF}Игрок с которым вы взаимодействуете не в сети", -1)
            end
        else
            sampAddChatMessage("• {FFD700}[Подсказка] {FFFFFF}Используйте {FF4500}/select [ID]{FFFFFF}, чтобы взаимодействовать с игроком", -1)
        end
    end)
end

function selectName()
    if playerid ~= nil then
        return sampGetPlayerNickname(playerid)
    else
        return "Неизвестно"
    end
end

function selectInfoOverlay()
    if playerid ~= nil then
        return "{selectName} [{selectID}]"
    else
        return "Неизвестно"
    end
end

function cancel()
    if playerid ~= nil then
        playerid = nil
        sampAddChatMessage(change_tags("• {FFD700}[Подсказка] {FFFFFF}Вы прекратили взаимодействовать с {de6262}{selectName}", change), -1)
    else
        sampAddChatMessage("• {F31D2F}[Ошибка] {FFFFFF}Вы не взаимодействуете с игроком", -1)
    end
end

function city()
    local city = getCityPlayerIsIn(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
    if city == 1 then
        return "Los-Santos"
    elseif city == 2 then
        return "San-Fierro"
    elseif city == 3 then
        return "Las-Venturas"
    else
        return "Неизвестно"
    end
end

function change_tags(text, table)
    for k, v in pairs(table) do
        text = text:gsub("%{"..k.."%}", v)
    end
    return text
end

function kvadrat()
    local KV = {
        [1] = "А",
        [2] = "Б",
        [3] = "В",
        [4] = "Г",
        [5] = "Д",
        [6] = "Ж",
        [7] = "З",
        [8] = "И",
        [9] = "К",
        [10] = "Л",
        [11] = "М",
        [12] = "Н",
        [13] = "О",
        [14] = "П",
        [15] = "Р",
        [16] = "С",
        [17] = "Т",
        [18] = "У",
        [19] = "Ф",
        [20] = "Х",
        [21] = "Ц",
        [22] = "Ч",
        [23] = "Ш",
        [24] = "Я",
    }
    local X, Y, Z = getCharCoordinates(PLAYER_PED)
    X = math.ceil((X + 3000) / 250)
    Y = math.ceil((Y * - 1 + 3000) / 250)
    Y = KV[Y]
    local KVX = (Y.."-"..X)
    return KVX
end

function imgui.TextRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == "SSSSSS" then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == "string" and tonumber(color, 16) or color
        if type(color) ~= "number" then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch("[^\r\n]+") do
            local text, colors_, m = {}, {}, 1
            w = w:gsub("{(......)}", "{%1FF}")
            while w:find("{........}") do
                local n, k = w:find("{........}")
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end
    render_text(text)
end


function check_update() -- Создаём функцию которая будет проверять наличие обновлений при запуске скрипта.
    downloadUrlToFile(update_url, update_path, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            updateIni = inicfg.load(nil, update_path)
            if tonumber(updateIni.info.vers) > script_vers then -- Сверяем версию в скрипте и в ini файле на github
                sampAddChatMessage("{FFFFFF}Имеется {32CD32}новая {FFFFFF}версия скрипта. Версия: {32CD32}"..updateIni.info.vers_text..". {FFFFFF}/update что-бы обновить", 0xFF0000) -- Сообщаем о новой версии.
                update_found == true -- если обновление найдено, ставим переменной значение true
            end
            os.remove(update_path)
        end
    end)
end

function calculateZone(x, y, z)
    local streets = {
        {"Avispa Country Club", -2667.810, -302.135, -28.831, -2646.400, -262.320, 71.169},
        {"Easter Bay Airport", -1315.420, -405.388, 15.406, -1264.400, -209.543, 25.406},
        {"Avispa Country Club", -2550.040, -355.493, 0.000, -2470.040, -318.493, 39.700},
        {"Easter Bay Airport", -1490.330, -209.543, 15.406, -1264.400, -148.388, 25.406},
        {"Garcia", -2395.140, -222.589, -5.3, -2354.090, -204.792, 200.000},
        {"Shady Cabin", -1632.830, -2263.440, -3.0, -1601.330, -2231.790, 200.000},
        {"East Los Santos", 2381.680, -1494.030, -89.084, 2421.030, -1454.350, 110.916},
        {"LVA Freight Depot", 1236.630, 1163.410, -89.084, 1277.050, 1203.280, 110.916},
        {"Blackfield Intersection", 1277.050, 1044.690, -89.084, 1315.350, 1087.630, 110.916},
        {"Avispa Country Club", -2470.040, -355.493, 0.000, -2270.040, -318.493, 46.100},
        {"Temple", 1252.330, -926.999, -89.084, 1357.000, -910.170, 110.916},
        {"Unity Station", 1692.620, -1971.800, -20.492, 1812.620, -1932.800, 79.508},
        {"LVA Freight Depot", 1315.350, 1044.690, -89.084, 1375.600, 1087.630, 110.916},
        {"Los Flores", 2581.730, -1454.350, -89.084, 2632.830, -1393.420, 110.916},
        {"Starfish Casino", 2437.390, 1858.100, -39.084, 2495.090, 1970.850, 60.916},
        {"Easter Bay Chemicals", -1132.820, -787.391, 0.000, -956.476, -768.027, 200.000},
        {"Downtown Los Santos", 1370.850, -1170.870, -89.084, 1463.900, -1130.850, 110.916},
        {"Esplanade East", -1620.300, 1176.520, -4.5, -1580.010, 1274.260, 200.000},
        {"Market Station", 787.461, -1410.930, -34.126, 866.009, -1310.210, 65.874},
        {"Linden Station", 2811.250, 1229.590, -39.594, 2861.250, 1407.590, 60.406},
        {"Montgomery Intersection", 1582.440, 347.457, 0.000, 1664.620, 401.750, 200.000},
        {"Frederick Bridge", 2759.250, 296.501, 0.000, 2774.250, 594.757, 200.000},
        {"Yellow Bell Station", 1377.480, 2600.430, -21.926, 1492.450, 2687.360, 78.074},
        {"Downtown Los Santos", 1507.510, -1385.210, 110.916, 1582.550, -1325.310, 335.916},
        {"Jefferson", 2185.330, -1210.740, -89.084, 2281.450, -1154.590, 110.916},
        {"Mulholland", 1318.130, -910.170, -89.084, 1357.000, -768.027, 110.916},
        {"Avispa Country Club", -2361.510, -417.199, 0.000, -2270.040, -355.493, 200.000},
        {"Jefferson", 1996.910, -1449.670, -89.084, 2056.860, -1350.720, 110.916},
        {"Julius Thruway West", 1236.630, 2142.860, -89.084, 1297.470, 2243.230, 110.916},
        {"Jefferson", 2124.660, -1494.030, -89.084, 2266.210, -1449.670, 110.916},
        {"Julius Thruway North", 1848.400, 2478.490, -89.084, 1938.800, 2553.490, 110.916},
        {"Rodeo", 422.680, -1570.200, -89.084, 466.223, -1406.050, 110.916},
        {"Cranberry Station", -2007.830, 56.306, 0.000, -1922.000, 224.782, 100.000},
        {"Downtown Los Santos", 1391.050, -1026.330, -89.084, 1463.900, -926.999, 110.916},
        {"Redsands West", 1704.590, 2243.230, -89.084, 1777.390, 2342.830, 110.916},
        {"Little Mexico", 1758.900, -1722.260, -89.084, 1812.620, -1577.590, 110.916},
        {"Blackfield Intersection", 1375.600, 823.228, -89.084, 1457.390, 919.447, 110.916},
        {"Los Santos International", 1974.630, -2394.330, -39.084, 2089.000, -2256.590, 60.916},
        {"Beacon Hill", -399.633, -1075.520, -1.489, -319.033, -977.516, 198.511},
        {"Rodeo", 334.503, -1501.950, -89.084, 422.680, -1406.050, 110.916},
        {"Richman", 225.165, -1369.620, -89.084, 334.503, -1292.070, 110.916},
        {"Downtown Los Santos", 1724.760, -1250.900, -89.084, 1812.620, -1150.870, 110.916},
        {"The Strip", 2027.400, 1703.230, -89.084, 2137.400, 1783.230, 110.916},
        {"Downtown Los Santos", 1378.330, -1130.850, -89.084, 1463.900, -1026.330, 110.916},
        {"Blackfield Intersection", 1197.390, 1044.690, -89.084, 1277.050, 1163.390, 110.916},
        {"Conference Center", 1073.220, -1842.270, -89.084, 1323.900, -1804.210, 110.916},
        {"Montgomery", 1451.400, 347.457, -6.1, 1582.440, 420.802, 200.000},
        {"Foster Valley", -2270.040, -430.276, -1.2, -2178.690, -324.114, 200.000},
        {"Blackfield Chapel", 1325.600, 596.349, -89.084, 1375.600, 795.010, 110.916},
        {"Los Santos International", 2051.630, -2597.260, -39.084, 2152.450, -2394.330, 60.916},
        {"Mulholland", 1096.470, -910.170, -89.084, 1169.130, -768.027, 110.916},
        {"Yellow Bell Gol Course", 1457.460, 2723.230, -89.084, 1534.560, 2863.230, 110.916},
        {"The Strip", 2027.400, 1783.230, -89.084, 2162.390, 1863.230, 110.916},
        {"Jefferson", 2056.860, -1210.740, -89.084, 2185.330, -1126.320, 110.916},
        {"Mulholland", 952.604, -937.184, -89.084, 1096.470, -860.619, 110.916},
        {"Aldea Malvada", -1372.140, 2498.520, 0.000, -1277.590, 2615.350, 200.000},
        {"Las Colinas", 2126.860, -1126.320, -89.084, 2185.330, -934.489, 110.916},
        {"Las Colinas", 1994.330, -1100.820, -89.084, 2056.860, -920.815, 110.916},
        {"Richman", 647.557, -954.662, -89.084, 768.694, -860.619, 110.916},
        {"LVA Freight Depot", 1277.050, 1087.630, -89.084, 1375.600, 1203.280, 110.916},
        {"Julius Thruway North", 1377.390, 2433.230, -89.084, 1534.560, 2507.230, 110.916},
        {"Willowfield", 2201.820, -2095.000, -89.084, 2324.000, -1989.900, 110.916},
        {"Julius Thruway North", 1704.590, 2342.830, -89.084, 1848.400, 2433.230, 110.916},
        {"Temple", 1252.330, -1130.850, -89.084, 1378.330, -1026.330, 110.916},
        {"Little Mexico", 1701.900, -1842.270, -89.084, 1812.620, -1722.260, 110.916},
        {"Queens", -2411.220, 373.539, 0.000, -2253.540, 458.411, 200.000},
        {"Las Venturas Airport", 1515.810, 1586.400, -12.500, 1729.950, 1714.560, 87.500},
        {"Richman", 225.165, -1292.070, -89.084, 466.223, -1235.070, 110.916},
        {"Temple", 1252.330, -1026.330, -89.084, 1391.050, -926.999, 110.916},
        {"East Los Santos", 2266.260, -1494.030, -89.084, 2381.680, -1372.040, 110.916},
        {"Julius Thruway East", 2623.180, 943.235, -89.084, 2749.900, 1055.960, 110.916},
        {"Willowfield", 2541.700, -1941.400, -89.084, 2703.580, -1852.870, 110.916},
        {"Las Colinas", 2056.860, -1126.320, -89.084, 2126.860, -920.815, 110.916},
        {"Julius Thruway East", 2625.160, 2202.760, -89.084, 2685.160, 2442.550, 110.916},
        {"Rodeo", 225.165, -1501.950, -89.084, 334.503, -1369.620, 110.916},
        {"Las Brujas", -365.167, 2123.010, -3.0, -208.570, 2217.680, 200.000},
        {"Julius Thruway East", 2536.430, 2442.550, -89.084, 2685.160, 2542.550, 110.916},
        {"Rodeo", 334.503, -1406.050, -89.084, 466.223, -1292.070, 110.916},
        {"Vinewood", 647.557, -1227.280, -89.084, 787.461, -1118.280, 110.916},
        {"Rodeo", 422.680, -1684.650, -89.084, 558.099, -1570.200, 110.916},
        {"Julius Thruway North", 2498.210, 2542.550, -89.084, 2685.160, 2626.550, 110.916},
        {"Downtown Los Santos", 1724.760, -1430.870, -89.084, 1812.620, -1250.900, 110.916},
        {"Rodeo", 225.165, -1684.650, -89.084, 312.803, -1501.950, 110.916},
        {"Jefferson", 2056.860, -1449.670, -89.084, 2266.210, -1372.040, 110.916},
        {"Hampton Barns", 603.035, 264.312, 0.000, 761.994, 366.572, 200.000},
        {"Temple", 1096.470, -1130.840, -89.084, 1252.330, -1026.330, 110.916},
        {"Kincaid Bridge", -1087.930, 855.370, -89.084, -961.950, 986.281, 110.916},
        {"Verona Beach", 1046.150, -1722.260, -89.084, 1161.520, -1577.590, 110.916},
        {"Commerce", 1323.900, -1722.260, -89.084, 1440.900, -1577.590, 110.916},
        {"Mulholland", 1357.000, -926.999, -89.084, 1463.900, -768.027, 110.916},
        {"Rodeo", 466.223, -1570.200, -89.084, 558.099, -1385.070, 110.916},
        {"Mulholland", 911.802, -860.619, -89.084, 1096.470, -768.027, 110.916},
        {"Mulholland", 768.694, -954.662, -89.084, 952.604, -860.619, 110.916},
        {"Julius Thruway South", 2377.390, 788.894, -89.084, 2537.390, 897.901, 110.916},
        {"Idlewood", 1812.620, -1852.870, -89.084, 1971.660, -1742.310, 110.916},
        {"Ocean Docks", 2089.000, -2394.330, -89.084, 2201.820, -2235.840, 110.916},
        {"Commerce", 1370.850, -1577.590, -89.084, 1463.900, -1384.950, 110.916},
        {"Julius Thruway North", 2121.400, 2508.230, -89.084, 2237.400, 2663.170, 110.916},
        {"Temple", 1096.470, -1026.330, -89.084, 1252.330, -910.170, 110.916},
        {"Glen Park", 1812.620, -1449.670, -89.084, 1996.910, -1350.720, 110.916},
        {"Easter Bay Airport", -1242.980, -50.096, 0.000, -1213.910, 578.396, 200.000},
        {"Martin Bridge", -222.179, 293.324, 0.000, -122.126, 476.465, 200.000},
        {"The Strip", 2106.700, 1863.230, -89.084, 2162.390, 2202.760, 110.916},
        {"Willowfield", 2541.700, -2059.230, -89.084, 2703.580, -1941.400, 110.916},
        {"Marina", 807.922, -1577.590, -89.084, 926.922, -1416.250, 110.916},
        {"Las Venturas Airport", 1457.370, 1143.210, -89.084, 1777.400, 1203.280, 110.916},
        {"Idlewood", 1812.620, -1742.310, -89.084, 1951.660, -1602.310, 110.916},
        {"Esplanade East", -1580.010, 1025.980, -6.1, -1499.890, 1274.260, 200.000},
        {"Downtown Los Santos", 1370.850, -1384.950, -89.084, 1463.900, -1170.870, 110.916},
        {"The Mako Span", 1664.620, 401.750, 0.000, 1785.140, 567.203, 200.000},
        {"Rodeo", 312.803, -1684.650, -89.084, 422.680, -1501.950, 110.916},
        {"Pershing Square", 1440.900, -1722.260, -89.084, 1583.500, -1577.590, 110.916},
        {"Mulholland", 687.802, -860.619, -89.084, 911.802, -768.027, 110.916},
        {"Gant Bridge", -2741.070, 1490.470, -6.1, -2616.400, 1659.680, 200.000},
        {"Las Colinas", 2185.330, -1154.590, -89.084, 2281.450, -934.489, 110.916},
        {"Mulholland", 1169.130, -910.170, -89.084, 1318.130, -768.027, 110.916},
        {"Julius Thruway North", 1938.800, 2508.230, -89.084, 2121.400, 2624.230, 110.916},
        {"Commerce", 1667.960, -1577.590, -89.084, 1812.620, -1430.870, 110.916},
        {"Rodeo", 72.648, -1544.170, -89.084, 225.165, -1404.970, 110.916},
        {"Roca Escalante", 2536.430, 2202.760, -89.084, 2625.160, 2442.550, 110.916},
        {"Rodeo", 72.648, -1684.650, -89.084, 225.165, -1544.170, 110.916},
        {"Market", 952.663, -1310.210, -89.084, 1072.660, -1130.850, 110.916},
        {"Las Colinas", 2632.740, -1135.040, -89.084, 2747.740, -945.035, 110.916},
        {"Mulholland", 861.085, -674.885, -89.084, 1156.550, -600.896, 110.916},
        {"King's", -2253.540, 373.539, -9.1, -1993.280, 458.411, 200.000},
        {"Redsands East", 1848.400, 2342.830, -89.084, 2011.940, 2478.490, 110.916},
        {"Downtown", -1580.010, 744.267, -6.1, -1499.890, 1025.980, 200.000},
        {"Conference Center", 1046.150, -1804.210, -89.084, 1323.900, -1722.260, 110.916},
        {"Richman", 647.557, -1118.280, -89.084, 787.461, -954.662, 110.916},
        {"Ocean Flats", -2994.490, 277.411, -9.1, -2867.850, 458.411, 200.000},
        {"Greenglass College", 964.391, 930.890, -89.084, 1166.530, 1044.690, 110.916},
        {"Glen Park", 1812.620, -1100.820, -89.084, 1994.330, -973.380, 110.916},
        {"LVA Freight Depot", 1375.600, 919.447, -89.084, 1457.370, 1203.280, 110.916},
        {"Regular Tom", -405.770, 1712.860, -3.0, -276.719, 1892.750, 200.000},
        {"Verona Beach", 1161.520, -1722.260, -89.084, 1323.900, -1577.590, 110.916},
        {"East Los Santos", 2281.450, -1372.040, -89.084, 2381.680, -1135.040, 110.916},
        {"Caligula's Palace", 2137.400, 1703.230, -89.084, 2437.390, 1783.230, 110.916},
        {"Idlewood", 1951.660, -1742.310, -89.084, 2124.660, -1602.310, 110.916},
        {"Pilgrim", 2624.400, 1383.230, -89.084, 2685.160, 1783.230, 110.916},
        {"Idlewood", 2124.660, -1742.310, -89.084, 2222.560, -1494.030, 110.916},
        {"Queens", -2533.040, 458.411, 0.000, -2329.310, 578.396, 200.000},
        {"Downtown", -1871.720, 1176.420, -4.5, -1620.300, 1274.260, 200.000},
        {"Commerce", 1583.500, -1722.260, -89.084, 1758.900, -1577.590, 110.916},
        {"East Los Santos", 2381.680, -1454.350, -89.084, 2462.130, -1135.040, 110.916},
        {"Marina", 647.712, -1577.590, -89.084, 807.922, -1416.250, 110.916},
        {"Richman", 72.648, -1404.970, -89.084, 225.165, -1235.070, 110.916},
        {"Vinewood", 647.712, -1416.250, -89.084, 787.461, -1227.280, 110.916},
        {"East Los Santos", 2222.560, -1628.530, -89.084, 2421.030, -1494.030, 110.916},
        {"Rodeo", 558.099, -1684.650, -89.084, 647.522, -1384.930, 110.916},
        {"Easter Tunnel", -1709.710, -833.034, -1.5, -1446.010, -730.118, 200.000},
        {"Rodeo", 466.223, -1385.070, -89.084, 647.522, -1235.070, 110.916},
        {"Redsands East", 1817.390, 2202.760, -89.084, 2011.940, 2342.830, 110.916},
        {"The Clown's Pocket", 2162.390, 1783.230, -89.084, 2437.390, 1883.230, 110.916},
        {"Idlewood", 1971.660, -1852.870, -89.084, 2222.560, -1742.310, 110.916},
        {"Montgomery Intersection", 1546.650, 208.164, 0.000, 1745.830, 347.457, 200.000},
        {"Willowfield", 2089.000, -2235.840, -89.084, 2201.820, -1989.900, 110.916},
        {"Temple", 952.663, -1130.840, -89.084, 1096.470, -937.184, 110.916},
        {"Prickle Pine", 1848.400, 2553.490, -89.084, 1938.800, 2863.230, 110.916},
        {"Los Santos International", 1400.970, -2669.260, -39.084, 2189.820, -2597.260, 60.916},
        {"Garver Bridge", -1213.910, 950.022, -89.084, -1087.930, 1178.930, 110.916},
        {"Garver Bridge", -1339.890, 828.129, -89.084, -1213.910, 1057.040, 110.916},
        {"Kincaid Bridge", -1339.890, 599.218, -89.084, -1213.910, 828.129, 110.916},
        {"Kincaid Bridge", -1213.910, 721.111, -89.084, -1087.930, 950.022, 110.916},
        {"Verona Beach", 930.221, -2006.780, -89.084, 1073.220, -1804.210, 110.916},
        {"Verdant Bluffs", 1073.220, -2006.780, -89.084, 1249.620, -1842.270, 110.916},
        {"Vinewood", 787.461, -1130.840, -89.084, 952.604, -954.662, 110.916},
        {"Vinewood", 787.461, -1310.210, -89.084, 952.663, -1130.840, 110.916},
        {"Commerce", 1463.900, -1577.590, -89.084, 1667.960, -1430.870, 110.916},
        {"Market", 787.461, -1416.250, -89.084, 1072.660, -1310.210, 110.916},
        {"Rockshore West", 2377.390, 596.349, -89.084, 2537.390, 788.894, 110.916},
        {"Julius Thruway North", 2237.400, 2542.550, -89.084, 2498.210, 2663.170, 110.916},
        {"East Beach", 2632.830, -1668.130, -89.084, 2747.740, -1393.420, 110.916},
        {"Fallow Bridge", 434.341, 366.572, 0.000, 603.035, 555.680, 200.000},
        {"Willowfield", 2089.000, -1989.900, -89.084, 2324.000, -1852.870, 110.916},
        {"Chinatown", -2274.170, 578.396, -7.6, -2078.670, 744.170, 200.000},
        {"El Castillo del Diablo", -208.570, 2337.180, 0.000, 8.430, 2487.180, 200.000},
        {"Ocean Docks", 2324.000, -2145.100, -89.084, 2703.580, -2059.230, 110.916},
        {"Easter Bay Chemicals", -1132.820, -768.027, 0.000, -956.476, -578.118, 200.000},
        {"The Visage", 1817.390, 1703.230, -89.084, 2027.400, 1863.230, 110.916},
        {"Ocean Flats", -2994.490, -430.276, -1.2, -2831.890, -222.589, 200.000},
        {"Richman", 321.356, -860.619, -89.084, 687.802, -768.027, 110.916},
        {"Green Palms", 176.581, 1305.450, -3.0, 338.658, 1520.720, 200.000},
        {"Richman", 321.356, -768.027, -89.084, 700.794, -674.885, 110.916},
        {"Starfish Casino", 2162.390, 1883.230, -89.084, 2437.390, 2012.180, 110.916},
        {"East Beach", 2747.740, -1668.130, -89.084, 2959.350, -1498.620, 110.916},
        {"Jefferson", 2056.860, -1372.040, -89.084, 2281.450, -1210.740, 110.916},
        {"Downtown Los Santos", 1463.900, -1290.870, -89.084, 1724.760, -1150.870, 110.916},
        {"Downtown Los Santos", 1463.900, -1430.870, -89.084, 1724.760, -1290.870, 110.916},
        {"Garver Bridge", -1499.890, 696.442, -179.615, -1339.890, 925.353, 20.385},
        {"Julius Thruway South", 1457.390, 823.228, -89.084, 2377.390, 863.229, 110.916},
        {"East Los Santos", 2421.030, -1628.530, -89.084, 2632.830, -1454.350, 110.916},
        {"Greenglass College", 964.391, 1044.690, -89.084, 1197.390, 1203.220, 110.916},
        {"Las Colinas", 2747.740, -1120.040, -89.084, 2959.350, -945.035, 110.916},
        {"Mulholland", 737.573, -768.027, -89.084, 1142.290, -674.885, 110.916},
        {"Ocean Docks", 2201.820, -2730.880, -89.084, 2324.000, -2418.330, 110.916},
        {"East Los Santos", 2462.130, -1454.350, -89.084, 2581.730, -1135.040, 110.916},
        {"Ganton", 2222.560, -1722.330, -89.084, 2632.830, -1628.530, 110.916},
        {"Avispa Country Club", -2831.890, -430.276, -6.1, -2646.400, -222.589, 200.000},
        {"Willowfield", 1970.620, -2179.250, -89.084, 2089.000, -1852.870, 110.916},
        {"Esplanade North", -1982.320, 1274.260, -4.5, -1524.240, 1358.900, 200.000},
        {"The High Roller", 1817.390, 1283.230, -89.084, 2027.390, 1469.230, 110.916},
        {"Ocean Docks", 2201.820, -2418.330, -89.084, 2324.000, -2095.000, 110.916},
        {"Last Dime Motel", 1823.080, 596.349, -89.084, 1997.220, 823.228, 110.916},
        {"Bayside Marina", -2353.170, 2275.790, 0.000, -2153.170, 2475.790, 200.000},
        {"King's", -2329.310, 458.411, -7.6, -1993.280, 578.396, 200.000},
        {"El Corona", 1692.620, -2179.250, -89.084, 1812.620, -1842.270, 110.916},
        {"Blackfield Chapel", 1375.600, 596.349, -89.084, 1558.090, 823.228, 110.916},
        {"The Pink Swan", 1817.390, 1083.230, -89.084, 2027.390, 1283.230, 110.916},
        {"Julius Thruway West", 1197.390, 1163.390, -89.084, 1236.630, 2243.230, 110.916},
        {"Los Flores", 2581.730, -1393.420, -89.084, 2747.740, -1135.040, 110.916},
        {"The Visage", 1817.390, 1863.230, -89.084, 2106.700, 2011.830, 110.916},
        {"Prickle Pine", 1938.800, 2624.230, -89.084, 2121.400, 2861.550, 110.916},
        {"Verona Beach", 851.449, -1804.210, -89.084, 1046.150, -1577.590, 110.916},
        {"Robada Intersection", -1119.010, 1178.930, -89.084, -862.025, 1351.450, 110.916},
        {"Linden Side", 2749.900, 943.235, -89.084, 2923.390, 1198.990, 110.916},
        {"Ocean Docks", 2703.580, -2302.330, -89.084, 2959.350, -2126.900, 110.916},
        {"Willowfield", 2324.000, -2059.230, -89.084, 2541.700, -1852.870, 110.916},
        {"King's", -2411.220, 265.243, -9.1, -1993.280, 373.539, 200.000},
        {"Commerce", 1323.900, -1842.270, -89.084, 1701.900, -1722.260, 110.916},
        {"Mulholland", 1269.130, -768.027, -89.084, 1414.070, -452.425, 110.916},
        {"Marina", 647.712, -1804.210, -89.084, 851.449, -1577.590, 110.916},
        {"Battery Point", -2741.070, 1268.410, -4.5, -2533.040, 1490.470, 200.000},
        {"The Four Dragons Casino", 1817.390, 863.232, -89.084, 2027.390, 1083.230, 110.916},
        {"Blackfield", 964.391, 1203.220, -89.084, 1197.390, 1403.220, 110.916},
        {"Julius Thruway North", 1534.560, 2433.230, -89.084, 1848.400, 2583.230, 110.916},
        {"Yellow Bell Gol Course", 1117.400, 2723.230, -89.084, 1457.460, 2863.230, 110.916},
        {"Idlewood", 1812.620, -1602.310, -89.084, 2124.660, -1449.670, 110.916},
        {"Redsands West", 1297.470, 2142.860, -89.084, 1777.390, 2243.230, 110.916},
        {"Doherty", -2270.040, -324.114, -1.2, -1794.920, -222.589, 200.000},
        {"Hilltop Farm", 967.383, -450.390, -3.0, 1176.780, -217.900, 200.000},
        {"Las Barrancas", -926.130, 1398.730, -3.0, -719.234, 1634.690, 200.000},
        {"Pirates in Men's Pants", 1817.390, 1469.230, -89.084, 2027.400, 1703.230, 110.916},
        {"City Hall", -2867.850, 277.411, -9.1, -2593.440, 458.411, 200.000},
        {"Avispa Country Club", -2646.400, -355.493, 0.000, -2270.040, -222.589, 200.000},
        {"The Strip", 2027.400, 863.229, -89.084, 2087.390, 1703.230, 110.916},
        {"Hashbury", -2593.440, -222.589, -1.0, -2411.220, 54.722, 200.000},
        {"Los Santos International", 1852.000, -2394.330, -89.084, 2089.000, -2179.250, 110.916},
        {"Whitewood Estates", 1098.310, 1726.220, -89.084, 1197.390, 2243.230, 110.916},
        {"Sherman Reservoir", -789.737, 1659.680, -89.084, -599.505, 1929.410, 110.916},
        {"El Corona", 1812.620, -2179.250, -89.084, 1970.620, -1852.870, 110.916},
        {"Downtown", -1700.010, 744.267, -6.1, -1580.010, 1176.520, 200.000},
        {"Foster Valley", -2178.690, -1250.970, 0.000, -1794.920, -1115.580, 200.000},
        {"Las Payasadas", -354.332, 2580.360, 2.0, -133.625, 2816.820, 200.000},
        {"Valle Ocultado", -936.668, 2611.440, 2.0, -715.961, 2847.900, 200.000},
        {"Blackfield Intersection", 1166.530, 795.010, -89.084, 1375.600, 1044.690, 110.916},
        {"Ganton", 2222.560, -1852.870, -89.084, 2632.830, -1722.330, 110.916},
        {"Easter Bay Airport", -1213.910, -730.118, 0.000, -1132.820, -50.096, 200.000},
        {"Redsands East", 1817.390, 2011.830, -89.084, 2106.700, 2202.760, 110.916},
        {"Esplanade East", -1499.890, 578.396, -79.615, -1339.890, 1274.260, 20.385},
        {"Caligula's Palace", 2087.390, 1543.230, -89.084, 2437.390, 1703.230, 110.916},
        {"Royal Casino", 2087.390, 1383.230, -89.084, 2437.390, 1543.230, 110.916},
        {"Richman", 72.648, -1235.070, -89.084, 321.356, -1008.150, 110.916},
        {"Starfish Casino", 2437.390, 1783.230, -89.084, 2685.160, 2012.180, 110.916},
        {"Mulholland", 1281.130, -452.425, -89.084, 1641.130, -290.913, 110.916},
        {"Downtown", -1982.320, 744.170, -6.1, -1871.720, 1274.260, 200.000},
        {"Hankypanky Point", 2576.920, 62.158, 0.000, 2759.250, 385.503, 200.000},
        {"K.A.C.C. Military Fuels", 2498.210, 2626.550, -89.084, 2749.900, 2861.550, 110.916},
        {"Harry Gold Parkway", 1777.390, 863.232, -89.084, 1817.390, 2342.830, 110.916},
        {"Bayside Tunnel", -2290.190, 2548.290, -89.084, -1950.190, 2723.290, 110.916},
        {"Ocean Docks", 2324.000, -2302.330, -89.084, 2703.580, -2145.100, 110.916},
        {"Richman", 321.356, -1044.070, -89.084, 647.557, -860.619, 110.916},
        {"Randolph Industrial Estate", 1558.090, 596.349, -89.084, 1823.080, 823.235, 110.916},
        {"East Beach", 2632.830, -1852.870, -89.084, 2959.350, -1668.130, 110.916},
        {"Flint Water", -314.426, -753.874, -89.084, -106.339, -463.073, 110.916},
        {"Blueberry", 19.607, -404.136, 3.8, 349.607, -220.137, 200.000},
        {"Linden Station", 2749.900, 1198.990, -89.084, 2923.390, 1548.990, 110.916},
        {"Glen Park", 1812.620, -1350.720, -89.084, 2056.860, -1100.820, 110.916},
        {"Downtown", -1993.280, 265.243, -9.1, -1794.920, 578.396, 200.000},
        {"Redsands West", 1377.390, 2243.230, -89.084, 1704.590, 2433.230, 110.916},
        {"Richman", 321.356, -1235.070, -89.084, 647.522, -1044.070, 110.916},
        {"Gant Bridge", -2741.450, 1659.680, -6.1, -2616.400, 2175.150, 200.000},
        {"Lil' Probe Inn", -90.218, 1286.850, -3.0, 153.859, 1554.120, 200.000},
        {"Flint Intersection", -187.700, -1596.760, -89.084, 17.063, -1276.600, 110.916},
        {"Las Colinas", 2281.450, -1135.040, -89.084, 2632.740, -945.035, 110.916},
        {"Sobell Rail Yards", 2749.900, 1548.990, -89.084, 2923.390, 1937.250, 110.916},
        {"The Emerald Isle", 2011.940, 2202.760, -89.084, 2237.400, 2508.230, 110.916},
        {"El Castillo del Diablo", -208.570, 2123.010, -7.6, 114.033, 2337.180, 200.000},
        {"Santa Flora", -2741.070, 458.411, -7.6, -2533.040, 793.411, 200.000},
        {"Playa del Seville", 2703.580, -2126.900, -89.084, 2959.350, -1852.870, 110.916},
        {"Market", 926.922, -1577.590, -89.084, 1370.850, -1416.250, 110.916},
        {"Queens", -2593.440, 54.722, 0.000, -2411.220, 458.411, 200.000},
        {"Pilson Intersection", 1098.390, 2243.230, -89.084, 1377.390, 2507.230, 110.916},
        {"Spinybed", 2121.400, 2663.170, -89.084, 2498.210, 2861.550, 110.916},
        {"Pilgrim", 2437.390, 1383.230, -89.084, 2624.400, 1783.230, 110.916},
        {"Blackfield", 964.391, 1403.220, -89.084, 1197.390, 1726.220, 110.916},
        {"'The Big Ear'", -410.020, 1403.340, -3.0, -137.969, 1681.230, 200.000},
        {"Dillimore", 580.794, -674.885, -9.5, 861.085, -404.790, 200.000},
        {"El Quebrados", -1645.230, 2498.520, 0.000, -1372.140, 2777.850, 200.000},
        {"Esplanade North", -2533.040, 1358.900, -4.5, -1996.660, 1501.210, 200.000},
        {"Easter Bay Airport", -1499.890, -50.096, -1.0, -1242.980, 249.904, 200.000},
        {"Fisher's Lagoon", 1916.990, -233.323, -100.000, 2131.720, 13.800, 200.000},
        {"Mulholland", 1414.070, -768.027, -89.084, 1667.610, -452.425, 110.916},
        {"East Beach", 2747.740, -1498.620, -89.084, 2959.350, -1120.040, 110.916},
        {"San Andreas Sound", 2450.390, 385.503, -100.000, 2759.250, 562.349, 200.000},
        {"Shady Creeks", -2030.120, -2174.890, -6.1, -1820.640, -1771.660, 200.000},
        {"Market", 1072.660, -1416.250, -89.084, 1370.850, -1130.850, 110.916},
        {"Rockshore West", 1997.220, 596.349, -89.084, 2377.390, 823.228, 110.916},
        {"Prickle Pine", 1534.560, 2583.230, -89.084, 1848.400, 2863.230, 110.916},
        {"Easter Basin", -1794.920, -50.096, -1.04, -1499.890, 249.904, 200.000},
        {"Leafy Hollow", -1166.970, -1856.030, 0.000, -815.624, -1602.070, 200.000},
        {"LVA Freight Depot", 1457.390, 863.229, -89.084, 1777.400, 1143.210, 110.916},
        {"Prickle Pine", 1117.400, 2507.230, -89.084, 1534.560, 2723.230, 110.916},
        {"Blueberry", 104.534, -220.137, 2.3, 349.607, 152.236, 200.000},
        {"El Castillo del Diablo", -464.515, 2217.680, 0.000, -208.570, 2580.360, 200.000},
        {"Downtown", -2078.670, 578.396, -7.6, -1499.890, 744.267, 200.000},
        {"Rockshore East", 2537.390, 676.549, -89.084, 2902.350, 943.235, 110.916},
        {"San Fierro Bay", -2616.400, 1501.210, -3.0, -1996.660, 1659.680, 200.000},
        {"Paradiso", -2741.070, 793.411, -6.1, -2533.040, 1268.410, 200.000},
        {"The Camel's Toe", 2087.390, 1203.230, -89.084, 2640.400, 1383.230, 110.916},
        {"Old Venturas Strip", 2162.390, 2012.180, -89.084, 2685.160, 2202.760, 110.916},
        {"Juniper Hill", -2533.040, 578.396, -7.6, -2274.170, 968.369, 200.000},
        {"Juniper Hollow", -2533.040, 968.369, -6.1, -2274.170, 1358.900, 200.000},
        {"Roca Escalante", 2237.400, 2202.760, -89.084, 2536.430, 2542.550, 110.916},
        {"Julius Thruway East", 2685.160, 1055.960, -89.084, 2749.900, 2626.550, 110.916},
        {"Verona Beach", 647.712, -2173.290, -89.084, 930.221, -1804.210, 110.916},
        {"Foster Valley", -2178.690, -599.884, -1.2, -1794.920, -324.114, 200.000},
        {"Arco del Oeste", -901.129, 2221.860, 0.000, -592.090, 2571.970, 200.000},
        {"Fallen Tree", -792.254, -698.555, -5.3, -452.404, -380.043, 200.000},
        {"The Farm", -1209.670, -1317.100, 114.981, -908.161, -787.391, 251.981},
        {"The Sherman Dam", -968.772, 1929.410, -3.0, -481.126, 2155.260, 200.000},
        {"Esplanade North", -1996.660, 1358.900, -4.5, -1524.240, 1592.510, 200.000},
        {"Financial", -1871.720, 744.170, -6.1, -1701.300, 1176.420, 300.000},
        {"Garcia", -2411.220, -222.589, -1.14, -2173.040, 265.243, 200.000},
        {"Montgomery", 1119.510, 119.526, -3.0, 1451.400, 493.323, 200.000},
        {"Creek", 2749.900, 1937.250, -89.084, 2921.620, 2669.790, 110.916},
        {"Los Santos International", 1249.620, -2394.330, -89.084, 1852.000, -2179.250, 110.916},
        {"Santa Maria Beach", 72.648, -2173.290, -89.084, 342.648, -1684.650, 110.916},
        {"Mulholland Intersection", 1463.900, -1150.870, -89.084, 1812.620, -768.027, 110.916},
        {"Angel Pine", -2324.940, -2584.290, -6.1, -1964.220, -2212.110, 200.000},
        {"Verdant Meadows", 37.032, 2337.180, -3.0, 435.988, 2677.900, 200.000},
        {"Octane Springs", 338.658, 1228.510, 0.000, 664.308, 1655.050, 200.000},
        {"Come-A-Lot", 2087.390, 943.235, -89.084, 2623.180, 1203.230, 110.916},
        {"Redsands West", 1236.630, 1883.110, -89.084, 1777.390, 2142.860, 110.916},
        {"Santa Maria Beach", 342.648, -2173.290, -89.084, 647.712, -1684.650, 110.916},
        {"Verdant Bluffs", 1249.620, -2179.250, -89.084, 1692.620, -1842.270, 110.916},
        {"Las Venturas Airport", 1236.630, 1203.280, -89.084, 1457.370, 1883.110, 110.916},
        {"Flint Range", -594.191, -1648.550, 0.000, -187.700, -1276.600, 200.000},
        {"Verdant Bluffs", 930.221, -2488.420, -89.084, 1249.620, -2006.780, 110.916},
        {"Palomino Creek", 2160.220, -149.004, 0.000, 2576.920, 228.322, 200.000},
        {"Ocean Docks", 2373.770, -2697.090, -89.084, 2809.220, -2330.460, 110.916},
        {"Easter Bay Airport", -1213.910, -50.096, -4.5, -947.980, 578.396, 200.000},
        {"Whitewood Estates", 883.308, 1726.220, -89.084, 1098.310, 2507.230, 110.916},
        {"Calton Heights", -2274.170, 744.170, -6.1, -1982.320, 1358.900, 200.000},
        {"Easter Basin", -1794.920, 249.904, -9.1, -1242.980, 578.396, 200.000},
        {"Los Santos Inlet", -321.744, -2224.430, -89.084, 44.615, -1724.430, 110.916},
        {"Doherty", -2173.040, -222.589, -1.0, -1794.920, 265.243, 200.000},
        {"Mount Chiliad", -2178.690, -2189.910, -47.917, -2030.120, -1771.660, 576.083},
        {"Fort Carson", -376.233, 826.326, -3.0, 123.717, 1220.440, 200.000},
        {"Foster Valley", -2178.690, -1115.580, 0.000, -1794.920, -599.884, 200.000},
        {"Ocean Flats", -2994.490, -222.589, -1.0, -2593.440, 277.411, 200.000},
        {"Fern Ridge", 508.189, -139.259, 0.000, 1306.660, 119.526, 200.000},
        {"Bayside", -2741.070, 2175.150, 0.000, -2353.170, 2722.790, 200.000},
        {"Las Venturas Airport", 1457.370, 1203.280, -89.084, 1777.390, 1883.110, 110.916},
        {"Blueberry Acres", -319.676, -220.137, 0.000, 104.534, 293.324, 200.000},
        {"Palisades", -2994.490, 458.411, -6.1, -2741.070, 1339.610, 200.000},
        {"North Rock", 2285.370, -768.027, 0.000, 2770.590, -269.740, 200.000},
        {"Hunter Quarry", 337.244, 710.840, -115.239, 860.554, 1031.710, 203.761},
        {"Los Santos International", 1382.730, -2730.880, -89.084, 2201.820, -2394.330, 110.916},
        {"Missionary Hill", -2994.490, -811.276, 0.000, -2178.690, -430.276, 200.000},
        {"San Fierro Bay", -2616.400, 1659.680, -3.0, -1996.660, 2175.150, 200.000},
        {"Restricted Area", -91.586, 1655.050, -50.000, 421.234, 2123.010, 250.000},
        {"Mount Chiliad", -2997.470, -1115.580, -47.917, -2178.690, -971.913, 576.083},
        {"Mount Chiliad", -2178.690, -1771.660, -47.917, -1936.120, -1250.970, 576.083},
        {"Easter Bay Airport", -1794.920, -730.118, -3.0, -1213.910, -50.096, 200.000},
        {"The Panopticon", -947.980, -304.320, -1.1, -319.676, 327.071, 200.000},
        {"Shady Creeks", -1820.640, -2643.680, -8.0, -1226.780, -1771.660, 200.000},
        {"Back o Beyond", -1166.970, -2641.190, 0.000, -321.744, -1856.030, 200.000},
        {"Mount Chiliad", -2994.490, -2189.910, -47.917, -2178.690, -1115.580, 576.083},
        {"Tierra Robada", -1213.910, 596.349, -242.990, -480.539, 1659.680, 900.000},
        {"Flint County", -1213.910, -2892.970, -242.990, 44.615, -768.027, 900.000},
        {"Whetstone", -2997.470, -2892.970, -242.990, -1213.910, -1115.580, 900.000},
        {"Bone County", -480.539, 596.349, -242.990, 869.461, 2993.870, 900.000},
        {"Tierra Robada", -2997.470, 1659.680, -242.990, -480.539, 2993.870, 900.000},
        {"San Fierro", -2997.470, -1115.580, -242.990, -1213.910, 1659.680, 900.000},
        {"Las Venturas", 869.461, 596.349, -242.990, 2997.060, 2993.870, 900.000},
        {"Red County", -1213.910, -768.027, -242.990, 2997.060, 596.349, 900.000},
        {"Los Santos", 44.615, -2892.970, -242.990, 2997.060, -768.027, 900.000}
    }
    if streets == nil then
        return "San Andreas"
    end
    for i, v in ipairs(streets) do
        if (x >= v[2]) and (y >= v[3]) and (z >= v[4]) and (x <= v[5]) and (y <= v[6]) and (z <= v[7]) then
            return v[1]
        end
    end
    return "San Andreas"
end

function theme1()
    colors = imgui.GetStyle().Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    colors[clr.TitleBg] = ImVec4(0.16, 0.29, 0.48, 1)
    colors[clr.TitleBgActive] = ImVec4(0.16, 0.29, 0.48, 1)
    colors[clr.CheckMark] = ImVec4(0.26, 0.59, 0.98, 1)
    colors[clr.SliderGrab] = ImVec4(0.24, 0.52, 0.88, 1)
    colors[clr.SliderGrabActive] = ImVec4(0.26, 0.59, 0.98, 1)
    colors[clr.ButtonHovered] = ImVec4(0.26, 0.59, 0.98, 1)
    colors[clr.Header] = ImVec4(0.26, 0.59, 0.98, 0.31)
    colors[clr.HeaderHovered] = ImVec4(0.26, 0.59, 0.98, 0.8)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.41, 0.41, 1)
    colors[clr.FrameBg] = ImVec4(0.16, 0.29, 0.48, 0.54)
    colors[clr.FrameBgHovered] = ImVec4(0.26, 0.59, 0.98, 0.4)
    colors[clr.FrameBgActive] = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.TitleBgCollapsed] = ImVec4(0, 0, 0, 0.51)
    colors[clr.Button] = ImVec4(0.26, 0.59, 0.98, 0.4)
    colors[clr.ButtonActive] = ImVec4(0.06, 0.53, 0.98, 1)
    colors[clr.HeaderActive] = ImVec4(0.26, 0.59, 0.98, 1)
    colors[clr.Separator] = colors[clr.Border]
    colors[clr.SeparatorHovered] = ImVec4(0.26, 0.59, 0.98, 0.78)
    colors[clr.SeparatorActive] = ImVec4(0.26, 0.59, 0.98, 1)
    colors[clr.ResizeGrip] = ImVec4(0.26, 0.59, 0.98, 0.25)
    colors[clr.ResizeGripHovered] = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.ResizeGripActive] = ImVec4(0.26, 0.59, 0.98, 0.95)
    colors[clr.TextSelectedBg] = ImVec4(0.26, 0.59, 0.98, 0.35)
    colors[clr.Text] = ImVec4(1, 1, 1, 1)
    colors[clr.TextDisabled] = ImVec4(0.5, 0.5, 0.5, 1)
    colors[clr.WindowBg] = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.ChildWindowBg] = ImVec4(1, 1, 1, 0)
    colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg] = colors[clr.PopupBg]
    colors[clr.Border] = ImVec4(0.43, 0.43, 0.5, 0.5)
    colors[clr.BorderShadow] = ImVec4(0, 0, 0, 0)
    colors[clr.MenuBarBg] = ImVec4(0.14, 0.14, 0.14, 1)
    colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab] = ImVec4(0.31, 0.31, 0.31, 1)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.51, 0.51, 0.51, 1)
    colors[clr.CloseButton] = ImVec4(0.41, 0.41, 0.41, 0.5)
    colors[clr.CloseButtonHovered] = ImVec4(0.98, 0.39, 0.36, 1)
    colors[clr.CloseButtonActive] = ImVec4(0.98, 0.39, 0.36, 1)
    colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1)
    colors[clr.PlotLinesHovered] = ImVec4(1, 0.43, 0.35, 1)
    colors[clr.PlotHistogram] = ImVec4(0.9, 0.7, 0, 1)
    colors[clr.PlotHistogramHovered] = ImVec4(1, 0.6, 0, 1)
    colors[clr.ModalWindowDarkening] = ImVec4(0.8, 0.8, 0.8, 0.35)
end

function theme2()
    colors = imgui.GetStyle().Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    colors[clr.TitleBg] = ImVec4(0.48, 0.16, 0.16, 1)
    colors[clr.TitleBgActive] = ImVec4(0.48, 0.16, 0.16, 1)
    colors[clr.CheckMark] = ImVec4(0.98, 0.26, 0.26, 1)
    colors[clr.SliderGrab] = ImVec4(0.88, 0.26, 0.24, 1)
    colors[clr.SliderGrabActive] = ImVec4(0.98, 0.26, 0.26, 1)
    colors[clr.ButtonHovered] = ImVec4(0.98, 0.26, 0.26, 1)
    colors[clr.Header] = ImVec4(0.98, 0.26, 0.26, 0.31)
    colors[clr.HeaderHovered] = ImVec4(0.98, 0.26, 0.26, 0.8)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.41, 0.41, 1)
    colors[clr.FrameBg] = ImVec4(0.48, 0.16, 0.16, 0.54)
    colors[clr.FrameBgHovered] = ImVec4(0.98, 0.26, 0.26, 0.4)
    colors[clr.FrameBgActive] = ImVec4(0.98, 0.26, 0.26, 0.67)
    colors[clr.TitleBgCollapsed] = ImVec4(0, 0, 0, 0.51)
    colors[clr.Button] = ImVec4(0.98, 0.26, 0.26, 0.4)
    colors[clr.ButtonActive] = ImVec4(0.98, 0.06, 0.06, 1)
    colors[clr.HeaderActive] = ImVec4(0.98, 0.26, 0.26, 1)
    colors[clr.Separator] = colors[clr.Border]
    colors[clr.SeparatorHovered] = ImVec4(0.75, 0.1, 0.1, 0.78)
    colors[clr.SeparatorActive] = ImVec4(0.75, 0.1, 0.1, 1)
    colors[clr.ResizeGrip] = ImVec4(0.98, 0.26, 0.26, 0.25)
    colors[clr.ResizeGripHovered] = ImVec4(0.98, 0.26, 0.26, 0.67)
    colors[clr.ResizeGripActive] = ImVec4(0.98, 0.26, 0.26, 0.95)
    colors[clr.TextSelectedBg] = ImVec4(0.98, 0.26, 0.26, 0.35)
    colors[clr.Text] = ImVec4(1, 1, 1, 1)
    colors[clr.TextDisabled] = ImVec4(0.5, 0.5, 0.5, 1)
    colors[clr.WindowBg] = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.ChildWindowBg] = ImVec4(1, 1, 1, 0)
    colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg] = colors[clr.PopupBg]
    colors[clr.Border] = ImVec4(0.43, 0.43, 0.5, 0.5)
    colors[clr.BorderShadow] = ImVec4(0, 0, 0, 0)
    colors[clr.MenuBarBg] = ImVec4(0.14, 0.14, 0.14, 1)
    colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab] = ImVec4(0.31, 0.31, 0.31, 1)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.51, 0.51, 0.51, 1)
    colors[clr.CloseButton] = ImVec4(0.41, 0.41, 0.41, 0.5)
    colors[clr.CloseButtonHovered] = ImVec4(0.98, 0.39, 0.36, 1)
    colors[clr.CloseButtonActive] = ImVec4(0.98, 0.39, 0.36, 1)
    colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1)
    colors[clr.PlotLinesHovered] = ImVec4(1, 0.43, 0.35, 1)
    colors[clr.PlotHistogram] = ImVec4(0.9, 0.7, 0, 1)
    colors[clr.PlotHistogramHovered] = ImVec4(1, 0.6, 0, 1)
    colors[clr.ModalWindowDarkening] = ImVec4(0.8, 0.8, 0.8, 0.35)
end

function theme3()
    colors = imgui.GetStyle().Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    colors[clr.TitleBg] = ImVec4(0.48, 0.23, 0.16, 1)
    colors[clr.TitleBgActive] = ImVec4(0.48, 0.23, 0.16, 1)
    colors[clr.CheckMark] = ImVec4(0.98, 0.43, 0.26, 1)
    colors[clr.SliderGrab] = ImVec4(0.88, 0.39, 0.24, 1)
    colors[clr.SliderGrabActive] = ImVec4(0.98, 0.43, 0.26, 1)
    colors[clr.ButtonHovered] = ImVec4(0.98, 0.43, 0.26, 1)
    colors[clr.Header] = ImVec4(0.98, 0.43, 0.26, 0.31)
    colors[clr.HeaderHovered] = ImVec4(0.98, 0.43, 0.26, 0.8)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.41, 0.41, 1)
    colors[clr.FrameBg] = ImVec4(0.48, 0.23, 0.16, 0.54)
    colors[clr.FrameBgHovered] = ImVec4(0.98, 0.43, 0.26, 0.4)
    colors[clr.FrameBgActive] = ImVec4(0.98, 0.43, 0.26, 0.67)
    colors[clr.TitleBgCollapsed] = ImVec4(0, 0, 0, 0.51)
    colors[clr.Button] = ImVec4(0.98, 0.43, 0.26, 0.4)
    colors[clr.ButtonActive] = ImVec4(0.98, 0.28, 0.06, 1)
    colors[clr.HeaderActive] = ImVec4(0.98, 0.43, 0.26, 1)
    colors[clr.Separator] = colors[clr.Border]
    colors[clr.SeparatorHovered] = ImVec4(0.75, 0.25, 0.1, 0.78)
    colors[clr.SeparatorActive] = ImVec4(0.75, 0.25, 0.1, 1)
    colors[clr.ResizeGrip] = ImVec4(0.98, 0.43, 0.26, 0.25)
    colors[clr.ResizeGripHovered] = ImVec4(0.98, 0.43, 0.26, 0.67)
    colors[clr.ResizeGripActive] = ImVec4(0.98, 0.43, 0.26, 0.95)
    colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1)
    colors[clr.PlotLinesHovered] = ImVec4(1, 0.5, 0.35, 1)
    colors[clr.TextSelectedBg] = ImVec4(0.98, 0.43, 0.26, 0.35)
    colors[clr.Text] = ImVec4(1, 1, 1, 1)
    colors[clr.TextDisabled] = ImVec4(0.5, 0.5, 0.5, 1)
    colors[clr.WindowBg] = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.ChildWindowBg] = ImVec4(1, 1, 1, 0)
    colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg] = colors[clr.PopupBg]
    colors[clr.Border] = ImVec4(0.43, 0.43, 0.5, 0.5)
    colors[clr.BorderShadow] = ImVec4(0, 0, 0, 0)
    colors[clr.MenuBarBg] = ImVec4(0.14, 0.14, 0.14, 1)
    colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab] = ImVec4(0.31, 0.31, 0.31, 1)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.51, 0.51, 0.51, 1)
    colors[clr.CloseButton] = ImVec4(0.41, 0.41, 0.41, 0.5)
    colors[clr.CloseButtonHovered] = ImVec4(0.98, 0.39, 0.36, 1)
    colors[clr.CloseButtonActive] = ImVec4(0.98, 0.39, 0.36, 1)
    colors[clr.PlotHistogram] = ImVec4(0.9, 0.7, 0, 1)
    colors[clr.PlotHistogramHovered] = ImVec4(1, 0.6, 0, 1)
    colors[clr.ModalWindowDarkening] = ImVec4(0.8, 0.8, 0.8, 0.35)
end

function theme4()
    colors = imgui.GetStyle().Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    colors[clr.TitleBg] = ImVec4(0.16, 0.48, 0.42, 1)
    colors[clr.TitleBgActive] = ImVec4(0.16, 0.48, 0.42, 1)
    colors[clr.CheckMark] = ImVec4(0.26, 0.98, 0.85, 1)
    colors[clr.SliderGrab] = ImVec4(0.24, 0.88, 0.77, 1)
    colors[clr.SliderGrabActive] = ImVec4(0.26, 0.98, 0.85, 1)
    colors[clr.ButtonHovered] = ImVec4(0.26, 0.98, 0.85, 1)
    colors[clr.Header] = ImVec4(0.26, 0.98, 0.85, 0.31)
    colors[clr.HeaderHovered] = ImVec4(0.26, 0.98, 0.85, 0.8)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.41, 0.41, 1)
    colors[clr.FrameBg] = ImVec4(0.16, 0.48, 0.42, 0.54)
    colors[clr.FrameBgHovered] = ImVec4(0.26, 0.98, 0.85, 0.4)
    colors[clr.FrameBgActive] = ImVec4(0.26, 0.98, 0.85, 0.67)
    colors[clr.TitleBgCollapsed] = ImVec4(0, 0, 0, 0.51)
    colors[clr.Button] = ImVec4(0.26, 0.98, 0.85, 0.4)
    colors[clr.ButtonActive] = ImVec4(0.06, 0.98, 0.82, 1)
    colors[clr.HeaderActive] = ImVec4(0.26, 0.98, 0.85, 1)
    colors[clr.Separator] = colors[clr.Border]
    colors[clr.SeparatorHovered] = ImVec4(0.1, 0.75, 0.63, 0.78)
    colors[clr.SeparatorActive] = ImVec4(0.1, 0.75, 0.63, 1)
    colors[clr.ResizeGrip] = ImVec4(0.26, 0.98, 0.85, 0.25)
    colors[clr.ResizeGripHovered] = ImVec4(0.26, 0.98, 0.85, 0.67)
    colors[clr.ResizeGripActive] = ImVec4(0.26, 0.98, 0.85, 0.95)
    colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1)
    colors[clr.PlotLinesHovered] = ImVec4(1, 0.81, 0.35, 1)
    colors[clr.TextSelectedBg] = ImVec4(0.26, 0.98, 0.85, 0.35)
    colors[clr.Text] = ImVec4(1, 1, 1, 1)
    colors[clr.TextDisabled] = ImVec4(0.5, 0.5, 0.5, 1)
    colors[clr.WindowBg] = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.ChildWindowBg] = ImVec4(1, 1, 1, 0)
    colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg] = colors[clr.PopupBg]
    colors[clr.Border] = ImVec4(0.43, 0.43, 0.5, 0.5)
    colors[clr.BorderShadow] = ImVec4(0, 0, 0, 0)
    colors[clr.MenuBarBg] = ImVec4(0.14, 0.14, 0.14, 1)
    colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab] = ImVec4(0.31, 0.31, 0.31, 1)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.51, 0.51, 0.51, 1)
    colors[clr.CloseButton] = ImVec4(0.41, 0.41, 0.41, 0.5)
    colors[clr.CloseButtonHovered] = ImVec4(0.98, 0.39, 0.36, 1)
    colors[clr.CloseButtonActive] = ImVec4(0.98, 0.39, 0.36, 1)
    colors[clr.PlotHistogram] = ImVec4(0.9, 0.7, 0, 1)
    colors[clr.PlotHistogramHovered] = ImVec4(1, 0.6, 0, 1)
    colors[clr.ModalWindowDarkening] = ImVec4(0.8, 0.8, 0.8, 0.35)
end

function theme5()
    colors = imgui.GetStyle().Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    colors[clr.TitleBg] = ImVec4(0.1, 0.09, 0.12, 1)
    colors[clr.TitleBgActive] = ImVec4(0.07, 0.07, 0.09, 1)
    colors[clr.CheckMark] = ImVec4(0.8, 0.8, 0.83, 0.31)
    colors[clr.SliderGrab] = ImVec4(0.8, 0.8, 0.83, 0.31)
    colors[clr.SliderGrabActive] = ImVec4(0.06, 0.05, 0.07, 1)
    colors[clr.ButtonHovered] = ImVec4(0.24, 0.23, 0.29, 1)
    colors[clr.Header] = ImVec4(0.1, 0.09, 0.12, 1)
    colors[clr.HeaderHovered] = ImVec4(0.56, 0.56, 0.58, 1)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.56, 0.56, 0.58, 1)
    colors[clr.Text] = ImVec4(0.8, 0.8, 0.83, 1)
    colors[clr.TextDisabled] = ImVec4(0.24, 0.23, 0.29, 1)
    colors[clr.WindowBg] = ImVec4(0.06, 0.05, 0.07, 1)
    colors[clr.ChildWindowBg] = ImVec4(0.07, 0.07, 0.09, 1)
    colors[clr.PopupBg] = ImVec4(0.07, 0.07, 0.09, 1)
    colors[clr.Border] = ImVec4(0.8, 0.8, 0.83, 0.88)
    colors[clr.BorderShadow] = ImVec4(0.92, 0.91, 0.88, 0)
    colors[clr.FrameBg] = ImVec4(0.1, 0.09, 0.12, 1)
    colors[clr.FrameBgHovered] = ImVec4(0.24, 0.23, 0.29, 1)
    colors[clr.FrameBgActive] = ImVec4(0.56, 0.56, 0.58, 1)
    colors[clr.TitleBgCollapsed] = ImVec4(1, 0.98, 0.95, 0.75)
    colors[clr.MenuBarBg] = ImVec4(0.1, 0.09, 0.12, 1)
    colors[clr.ScrollbarBg] = ImVec4(0.1, 0.09, 0.12, 1)
    colors[clr.ScrollbarGrab] = ImVec4(0.8, 0.8, 0.83, 0.31)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.06, 0.05, 0.07, 1)
    colors[clr.ComboBg] = ImVec4(0.19, 0.18, 0.21, 1)
    colors[clr.Button] = ImVec4(0.1, 0.09, 0.12, 1)
    colors[clr.ButtonActive] = ImVec4(0.56, 0.56, 0.58, 1)
    colors[clr.HeaderActive] = ImVec4(0.06, 0.05, 0.07, 1)
    colors[clr.ResizeGrip] = ImVec4(0, 0, 0, 0)
    colors[clr.ResizeGripHovered] = ImVec4(0.56, 0.56, 0.58, 1)
    colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1)
    colors[clr.CloseButton] = ImVec4(0.4, 0.39, 0.38, 0.16)
    colors[clr.CloseButtonHovered] = ImVec4(0.4, 0.39, 0.38, 0.39)
    colors[clr.CloseButtonActive] = ImVec4(0.4, 0.39, 0.38, 1)
    colors[clr.PlotLines] = ImVec4(0.4, 0.39, 0.38, 0.63)
    colors[clr.PlotLinesHovered] = ImVec4(0.25, 1, 0, 1)
    colors[clr.PlotHistogram] = ImVec4(0.4, 0.39, 0.38, 0.63)
    colors[clr.PlotHistogramHovered] = ImVec4(0.25, 1, 0, 1)
    colors[clr.TextSelectedBg] = ImVec4(0.25, 1, 0, 0.43)
    colors[clr.ModalWindowDarkening] = ImVec4(1, 0.98, 0.95, 0.73)
end

function theme6()
    colors = imgui.GetStyle().Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    colors[clr.TitleBg] = ImVec4(0.41, 0.19, 0.63, 0.78)
    colors[clr.TitleBgActive] = ImVec4(0.41, 0.19, 0.63, 0.78)
    colors[clr.CheckMark] = ImVec4(0.56, 0.61, 1, 1)
    colors[clr.SliderGrab] = ImVec4(0.41, 0.19, 0.63, 0.24)
    colors[clr.SliderGrabActive] = ImVec4(0.41, 0.19, 0.63, 1)
    colors[clr.ButtonHovered] = ImVec4(0.41, 0.19, 0.63, 0.86)
    colors[clr.Header] = ImVec4(0.41, 0.19, 0.63, 0.76)
    colors[clr.HeaderHovered] = ImVec4(0.41, 0.19, 0.63, 0.86)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.19, 0.63, 0.78)
    colors[clr.WindowBg] = ImVec4(0.14, 0.12, 0.16, 1)
    colors[clr.ChildWindowBg] = ImVec4(0.3, 0.2, 0.39, 0)
    colors[clr.PopupBg] = ImVec4(0.05, 0.05, 0.1, 0.9)
    colors[clr.Border] = ImVec4(0.89, 0.85, 0.92, 0.3)
    colors[clr.BorderShadow] = ImVec4(0, 0, 0, 0)
    colors[clr.FrameBg] = ImVec4(0.3, 0.2, 0.39, 1)
    colors[clr.FrameBgHovered] = ImVec4(0.41, 0.19, 0.63, 0.68)
    colors[clr.FrameBgActive] = ImVec4(0.41, 0.19, 0.63, 1)
    colors[clr.TitleBgCollapsed] = ImVec4(0.41, 0.19, 0.63, 0.35)
    colors[clr.MenuBarBg] = ImVec4(0.3, 0.2, 0.39, 0.57)
    colors[clr.ScrollbarBg] = ImVec4(0.3, 0.2, 0.39, 1)
    colors[clr.ScrollbarGrab] = ImVec4(0.41, 0.19, 0.63, 0.31)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.41, 0.19, 0.63, 1)
    colors[clr.ComboBg] = ImVec4(0.3, 0.2, 0.39, 1)
    colors[clr.Button] = ImVec4(0.41, 0.19, 0.63, 0.44)
    colors[clr.ButtonActive] = ImVec4(0.64, 0.33, 0.94, 1)
    colors[clr.HeaderActive] = ImVec4(0.41, 0.19, 0.63, 1)
    colors[clr.ResizeGrip] = ImVec4(0.41, 0.19, 0.63, 0.2)
    colors[clr.ResizeGripHovered] = ImVec4(0.41, 0.19, 0.63, 0.78)
    colors[clr.ResizeGripActive] = ImVec4(0.41, 0.19, 0.63, 1)
    colors[clr.CloseButton] = ImVec4(1, 1, 1, 0.75)
    colors[clr.CloseButtonHovered] = ImVec4(0.88, 0.74, 1, 0.59)
    colors[clr.CloseButtonActive] = ImVec4(0.88, 0.85, 0.92, 1)
    colors[clr.PlotLines] = ImVec4(0.89, 0.85, 0.92, 0.63)
    colors[clr.PlotLinesHovered] = ImVec4(0.41, 0.19, 0.63, 1)
    colors[clr.PlotHistogram] = ImVec4(0.89, 0.85, 0.92, 0.63)
    colors[clr.PlotHistogramHovered] = ImVec4(0.41, 0.19, 0.63, 1)
    colors[clr.TextSelectedBg] = ImVec4(0.41, 0.19, 0.63, 0.43)
    colors[clr.ModalWindowDarkening] = ImVec4(0.2, 0.2, 0.2, 0.35)
end

function theme7()
    colors = imgui.GetStyle().Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    colors[clr.TitleBg] = ImVec4(0.8, 0.33, 0, 1)
    colors[clr.TitleBgActive] = ImVec4(0.8, 0.33, 0, 1)
    colors[clr.CheckMark] = ImVec4(1, 0.42, 0, 0.53)
    colors[clr.SliderGrab] = ImVec4(1, 0.42, 0, 0.53)
    colors[clr.SliderGrabActive] = ImVec4(1, 0.42, 0, 1)
    colors[clr.ButtonHovered] = ImVec4(0.24, 0.23, 0.29, 1)
    colors[clr.Header] = ImVec4(0.1, 0.09, 0.12, 1)
    colors[clr.HeaderHovered] = ImVec4(0.56, 0.56, 0.58, 1)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.56, 0.56, 0.58, 1)
    colors[clr.Text] = ImVec4(0.8, 0.8, 0.83, 1)
    colors[clr.TextDisabled] = ImVec4(0.24, 0.23, 0.29, 1)
    colors[clr.WindowBg] = ImVec4(0.06, 0.05, 0.07, 1)
    colors[clr.ChildWindowBg] = ImVec4(0.07, 0.07, 0.09, 1)
    colors[clr.PopupBg] = ImVec4(0.07, 0.07, 0.09, 1)
    colors[clr.Border] = ImVec4(0.8, 0.8, 0.83, 0.88)
    colors[clr.BorderShadow] = ImVec4(0.92, 0.91, 0.88, 0)
    colors[clr.FrameBg] = ImVec4(0.1, 0.09, 0.12, 1)
    colors[clr.FrameBgHovered] = ImVec4(0.24, 0.23, 0.29, 1)
    colors[clr.FrameBgActive] = ImVec4(0.56, 0.56, 0.58, 1)
    colors[clr.TitleBgCollapsed] = ImVec4(1, 0.98, 0.95, 0.75)
    colors[clr.MenuBarBg] = ImVec4(0.1, 0.09, 0.12, 1)
    colors[clr.ScrollbarBg] = ImVec4(0.1, 0.09, 0.12, 1)
    colors[clr.ScrollbarGrab] = ImVec4(0.8, 0.8, 0.83, 0.31)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.06, 0.05, 0.07, 1)
    colors[clr.ComboBg] = ImVec4(0.19, 0.18, 0.21, 1)
    colors[clr.Button] = ImVec4(0.1, 0.09, 0.12, 1)
    colors[clr.ButtonActive] = ImVec4(0.56, 0.56, 0.58, 1)
    colors[clr.HeaderActive] = ImVec4(0.06, 0.05, 0.07, 1)
    colors[clr.ResizeGrip] = ImVec4(0, 0, 0, 0)
    colors[clr.ResizeGripHovered] = ImVec4(0.56, 0.56, 0.58, 1)
    colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1)
    colors[clr.CloseButton] = ImVec4(0.4, 0.39, 0.38, 0.16)
    colors[clr.CloseButtonHovered] = ImVec4(0.4, 0.39, 0.38, 0.39)
    colors[clr.CloseButtonActive] = ImVec4(0.4, 0.39, 0.38, 1)
    colors[clr.PlotLines] = ImVec4(0.4, 0.39, 0.38, 0.63)
    colors[clr.PlotLinesHovered] = ImVec4(0.25, 1, 0, 1)
    colors[clr.PlotHistogram] = ImVec4(0.4, 0.39, 0.38, 0.63)
    colors[clr.PlotHistogramHovered] = ImVec4(0.25, 1, 0, 1)
    colors[clr.TextSelectedBg] = ImVec4(0.25, 1, 0, 0.43)
    colors[clr.ModalWindowDarkening] = ImVec4(1, 0.98, 0.95, 0.73)
end

function theme8()
    colors = imgui.GetStyle().Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    colors[clr.TitleBg] = ImVec4(0.46, 0.46, 0.46, 1)
    colors[clr.TitleBgActive] = ImVec4(0.46, 0.46, 0.46, 1)
    colors[clr.CheckMark] = ImVec4(0.99, 0.99, 0.99, 0.52)
    colors[clr.SliderGrab] = ImVec4(1, 1, 1, 0.42)
    colors[clr.SliderGrabActive] = ImVec4(0.76, 0.76, 0.76, 1)
    colors[clr.ButtonHovered] = ImVec4(0.68, 0.68, 0.68, 1)
    colors[clr.Header] = ImVec4(0.72, 0.72, 0.72, 0.54)
    colors[clr.HeaderHovered] = ImVec4(0.92, 0.92, 0.95, 0.77)
    colors[clr.ScrollbarGrabHovered] = ImVec4(1, 1, 1, 0.79)
    colors[clr.Text] = ImVec4(0.9, 0.9, 0.9, 1)
    colors[clr.TextDisabled] = ImVec4(1, 1, 1, 1)
    colors[clr.WindowBg] = ImVec4(0, 0, 0, 1)
    colors[clr.ChildWindowBg] = ImVec4(0, 0, 0, 1)
    colors[clr.PopupBg] = ImVec4(0, 0, 0, 1)
    colors[clr.Border] = ImVec4(0.82, 0.77, 0.78, 1)
    colors[clr.BorderShadow] = ImVec4(0.35, 0.35, 0.35, 0.66)
    colors[clr.FrameBg] = ImVec4(1, 1, 1, 0.28)
    colors[clr.FrameBgHovered] = ImVec4(0.68, 0.68, 0.68, 0.67)
    colors[clr.FrameBgActive] = ImVec4(0.79, 0.73, 0.73, 0.62)
    colors[clr.TitleBgCollapsed] = ImVec4(0, 0, 0, 1)
    colors[clr.MenuBarBg] = ImVec4(0, 0, 0, 0.8)
    colors[clr.ScrollbarBg] = ImVec4(0, 0, 0, 0.6)
    colors[clr.ScrollbarGrab] = ImVec4(1, 1, 1, 0.87)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.8, 0.5, 0.5, 0.4)
    colors[clr.ComboBg] = ImVec4(0.24, 0.24, 0.24, 0.99)
    colors[clr.Button] = ImVec4(0.51, 0.51, 0.51, 0.6)
    colors[clr.ButtonActive] = ImVec4(0.67, 0.67, 0.67, 1)
    colors[clr.HeaderActive] = ImVec4(0.82, 0.82, 0.82, 0.8)
    colors[clr.Separator] = ImVec4(0.73, 0.73, 0.73, 1)
    colors[clr.SeparatorHovered] = ImVec4(0.81, 0.81, 0.81, 1)
    colors[clr.SeparatorActive] = ImVec4(0.74, 0.74, 0.74, 1)
    colors[clr.ResizeGrip] = ImVec4(0.8, 0.8, 0.8, 0.3)
    colors[clr.ResizeGripHovered] = ImVec4(0.95, 0.95, 0.95, 0.6)
    colors[clr.ResizeGripActive] = ImVec4(1, 1, 1, 0.9)
    colors[clr.CloseButton] = ImVec4(0.45, 0.45, 0.45, 0.5)
    colors[clr.CloseButtonHovered] = ImVec4(0.7, 0.7, 0.9, 0.6)
    colors[clr.CloseButtonActive] = ImVec4(0.7, 0.7, 0.7, 1)
    colors[clr.PlotLines] = ImVec4(1, 1, 1, 1)
    colors[clr.PlotLinesHovered] = ImVec4(1, 1, 1, 1)
    colors[clr.PlotHistogram] = ImVec4(1, 1, 1, 1)
    colors[clr.PlotHistogramHovered] = ImVec4(1, 1, 1, 1)
    colors[clr.TextSelectedBg] = ImVec4(1, 1, 1, 0.35)
    colors[clr.ModalWindowDarkening] = ImVec4(0.88, 0.88, 0.88, 0.35)
end

function theme9()
    colors = imgui.GetStyle().Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    colors[clr.TitleBg] = ImVec4(0.2, 0.25, 0.3, 1)
    colors[clr.TitleBgActive] = ImVec4(0.2, 0.25, 0.3, 1)
    colors[clr.CheckMark] = ImVec4(0.28, 0.56, 1, 1)
    colors[clr.SliderGrab] = ImVec4(0.28, 0.56, 1, 1)
    colors[clr.SliderGrabActive] = ImVec4(0.37, 0.61, 1, 1)
    colors[clr.ButtonHovered] = ImVec4(0.28, 0.56, 1, 1)
    colors[clr.Header] = ImVec4(0.26, 0.59, 0.98, 0.8)
    colors[clr.HeaderHovered] = ImVec4(0.26, 0.59, 0.98, 0.7)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1)
    colors[clr.Text] = ImVec4(0.95, 0.96, 0.98, 1)
    colors[clr.TextDisabled] = ImVec4(0.36, 0.42, 0.47, 1)
    colors[clr.WindowBg] = ImVec4(0.11, 0.15, 0.17, 1)
    colors[clr.ChildWindowBg] = ImVec4(0.15, 0.18, 0.22, 1)
    colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.Border] = ImVec4(0.43, 0.43, 0.5, 0.5)
    colors[clr.BorderShadow] = ImVec4(0, 0, 0, 0)
    colors[clr.FrameBg] = ImVec4(0.2, 0.25, 0.29, 1)
    colors[clr.FrameBgHovered] = ImVec4(0.12, 0.2, 0.28, 1)
    colors[clr.FrameBgActive] = ImVec4(0.09, 0.12, 0.14, 1)
    colors[clr.TitleBgCollapsed] = ImVec4(0, 0, 0, 0.51)
    colors[clr.MenuBarBg] = ImVec4(0.15, 0.18, 0.22, 1)
    colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.39)
    colors[clr.ScrollbarGrab] = ImVec4(0.2, 0.25, 0.29, 1)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.09, 0.21, 0.31, 1)
    colors[clr.ComboBg] = ImVec4(0.2, 0.25, 0.29, 1)
    colors[clr.Button] = ImVec4(0.2, 0.25, 0.29, 1)
    colors[clr.ButtonActive] = ImVec4(0.06, 0.53, 0.98, 1)
    colors[clr.HeaderActive] = ImVec4(0.26, 0.59, 0.98, 1)
    colors[clr.ResizeGrip] = ImVec4(0.26, 0.59, 0.98, 0.25)
    colors[clr.ResizeGripHovered] = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1)
    colors[clr.CloseButton] = ImVec4(0.4, 0.39, 0.38, 0.16)
    colors[clr.CloseButtonHovered] = ImVec4(0.4, 0.39, 0.38, 0.39)
    colors[clr.CloseButtonActive] = ImVec4(0.4, 0.39, 0.38, 1)
    colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1)
    colors[clr.PlotLinesHovered] = ImVec4(1, 0.43, 0.35, 1)
    colors[clr.PlotHistogram] = ImVec4(0.9, 0.7, 0, 1)
    colors[clr.PlotHistogramHovered] = ImVec4(1, 0.6, 0, 1)
    colors[clr.TextSelectedBg] = ImVec4(0.25, 1, 0, 0.43)
    colors[clr.ModalWindowDarkening] = ImVec4(0.2, 0.2, 0.2, 0.35)
end

function theme10()
    colors = imgui.GetStyle().Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    colors[clr.TitleBg] = ImVec4(0.502, 0.075, 0.256, 1)
    colors[clr.TitleBgActive] = ImVec4(0.502, 0.075, 0.256, 1)
    colors[clr.CheckMark] = ImVec4(0.71, 0.22, 0.27, 1)
    colors[clr.SliderGrab] = ImVec4(0.47, 0.77, 0.83, 0.14)
    colors[clr.SliderGrabActive] = ImVec4(0.71, 0.22, 0.27, 1)
    colors[clr.ButtonHovered] = ImVec4(0.455, 0.198, 0.301, 0.86)
    colors[clr.Header] = ImVec4(0.455, 0.198, 0.301, 0.76)
    colors[clr.HeaderHovered] = ImVec4(0.455, 0.198, 0.301, 0.86)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.455, 0.198, 0.301, 0.78)
    colors[clr.Text] = ImVec4(0.86, 0.93, 0.89, 0.78)
    colors[clr.TextDisabled] = ImVec4(0.86, 0.93, 0.89, 0.28)
    colors[clr.WindowBg] = ImVec4(0.13, 0.14, 0.17, 1)
    colors[clr.ChildWindowBg] = ImVec4(0.2, 0.22, 0.27, 0.58)
    colors[clr.PopupBg] = ImVec4(0.2, 0.22, 0.27, 0.9)
    colors[clr.Border] = ImVec4(0.31, 0.31, 1, 0)
    colors[clr.BorderShadow] = ImVec4(0, 0, 0, 0)
    colors[clr.FrameBg] = ImVec4(0.2, 0.22, 0.27, 1)
    colors[clr.FrameBgHovered] = ImVec4(0.455, 0.198, 0.301, 0.78)
    colors[clr.FrameBgActive] = ImVec4(0.455, 0.198, 0.301, 1)
    colors[clr.TitleBgCollapsed] = ImVec4(0.2, 0.22, 0.27, 0.75)
    colors[clr.MenuBarBg] = ImVec4(0.2, 0.22, 0.27, 0.47)
    colors[clr.ScrollbarBg] = ImVec4(0.2, 0.22, 0.27, 1)
    colors[clr.ScrollbarGrab] = ImVec4(0.09, 0.15, 0.1, 1)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.455, 0.198, 0.301, 1)
    colors[clr.Button] = ImVec4(0.47, 0.77, 0.83, 0.14)
    colors[clr.ButtonActive] = ImVec4(0.455, 0.198, 0.301, 1)
    colors[clr.HeaderActive] = ImVec4(0.502, 0.075, 0.256, 1)
    colors[clr.ResizeGrip] = ImVec4(0.47, 0.77, 0.83, 0.04)
    colors[clr.ResizeGripHovered] = ImVec4(0.455, 0.198, 0.301, 0.78)
    colors[clr.ResizeGripActive] = ImVec4(0.455, 0.198, 0.301, 1)
    colors[clr.PlotLines] = ImVec4(0.86, 0.93, 0.89, 0.63)
    colors[clr.PlotLinesHovered] = ImVec4(0.455, 0.198, 0.301, 1)
    colors[clr.PlotHistogram] = ImVec4(0.86, 0.93, 0.89, 0.63)
    colors[clr.PlotHistogramHovered] = ImVec4(0.455, 0.198, 0.301, 1)
    colors[clr.TextSelectedBg] = ImVec4(0.455, 0.198, 0.301, 0.43)
    colors[clr.ModalWindowDarkening] = ImVec4(0.2, 0.22, 0.27, 0.73)
end

function theme11()
    colors = imgui.GetStyle().Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    colors[clr.TitleBg] = ImVec4(0.47, 0.22, 0.22, 1)
    colors[clr.TitleBgActive] = ImVec4(0.47, 0.22, 0.22, 1)
    colors[clr.CheckMark] = ImVec4(1, 1, 1, 1)
    colors[clr.SliderGrab] = ImVec4(0.71, 0.39, 0.39, 1)
    colors[clr.SliderGrabActive] = ImVec4(0.84, 0.66, 0.66, 1)
    colors[clr.ButtonHovered] = ImVec4(0.71, 0.39, 0.39, 0.65)
    colors[clr.Header] = ImVec4(0.71, 0.39, 0.39, 0.54)
    colors[clr.HeaderHovered] = ImVec4(0.84, 0.66, 0.66, 0.65)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.41, 0.41, 1)
    colors[clr.Text] = ImVec4(1, 1, 1, 1)
    colors[clr.TextDisabled] = ImVec4(0.73, 0.75, 0.74, 1)
    colors[clr.WindowBg] = ImVec4(0.09, 0.09, 0.09, 0.94)
    colors[clr.ChildWindowBg] = ImVec4(0, 0, 0, 0)
    colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.Border] = ImVec4(0.2, 0.2, 0.2, 0.5)
    colors[clr.BorderShadow] = ImVec4(0, 0, 0, 0)
    colors[clr.FrameBg] = ImVec4(0.71, 0.39, 0.39, 0.54)
    colors[clr.FrameBgHovered] = ImVec4(0.84, 0.66, 0.66, 0.4)
    colors[clr.FrameBgActive] = ImVec4(0.84, 0.66, 0.66, 0.67)
    colors[clr.TitleBgCollapsed] = ImVec4(0.47, 0.22, 0.22, 0.67)
    colors[clr.MenuBarBg] = ImVec4(0.34, 0.16, 0.16, 1)
    colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab] = ImVec4(0.31, 0.31, 0.31, 1)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.51, 0.51, 0.51, 1)
    colors[clr.Button] = ImVec4(0.47, 0.22, 0.22, 0.65)
    colors[clr.ButtonActive] = ImVec4(0.2, 0.2, 0.2, 0.5)
    colors[clr.HeaderActive] = ImVec4(0.84, 0.66, 0.66, 0)
    colors[clr.Separator] = ImVec4(0.43, 0.43, 0.5, 0.5)
    colors[clr.SeparatorHovered] = ImVec4(0.71, 0.39, 0.39, 0.54)
    colors[clr.SeparatorActive] = ImVec4(0.71, 0.39, 0.39, 0.54)
    colors[clr.ResizeGrip] = ImVec4(0.71, 0.39, 0.39, 0.54)
    colors[clr.ResizeGripHovered] = ImVec4(0.84, 0.66, 0.66, 0.66)
    colors[clr.ResizeGripActive] = ImVec4(0.84, 0.66, 0.66, 0.66)
    colors[clr.CloseButton] = ImVec4(0.41, 0.41, 0.41, 1)
    colors[clr.CloseButtonHovered] = ImVec4(0.98, 0.39, 0.36, 1)
    colors[clr.CloseButtonActive] = ImVec4(0.98, 0.39, 0.36, 1)
    colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1)
    colors[clr.PlotLinesHovered] = ImVec4(1, 0.43, 0.35, 1)
    colors[clr.PlotHistogram] = ImVec4(0.9, 0.7, 0, 1)
    colors[clr.PlotHistogramHovered] = ImVec4(1, 0.6, 0, 1)
    colors[clr.TextSelectedBg] = ImVec4(0.26, 0.59, 0.98, 0.35)
    colors[clr.ModalWindowDarkening] = ImVec4(0.8, 0.8, 0.8, 0.35)
end

function theme12()
    colors = imgui.GetStyle().Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    colors[clr.TitleBg] = ImVec4(0.14, 0.14, 0.14, 1)
    colors[clr.TitleBgActive] = ImVec4(0.14, 0.14, 0.14, 1)
    colors[clr.CheckMark] = ImVec4(1, 0.28, 0.28, 1)
    colors[clr.SliderGrab] = ImVec4(1, 0.28, 0.28, 1)
    colors[clr.SliderGrabActive] = ImVec4(1, 0.28, 0.28, 1)
    colors[clr.ButtonHovered] = ImVec4(1, 0.39, 0.39, 1)
    colors[clr.Header] = ImVec4(1, 0.28, 0.28, 1)
    colors[clr.HeaderHovered] = ImVec4(1, 0.39, 0.39, 1)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1)
    colors[clr.Text] = ImVec4(0.95, 0.96, 0.98, 1)
    colors[clr.TextDisabled] = ImVec4(0.29, 0.29, 0.29, 1)
    colors[clr.WindowBg] = ImVec4(0.14, 0.14, 0.14, 1)
    colors[clr.ChildWindowBg] = ImVec4(0.12, 0.12, 0.12, 1)
    colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.Border] = ImVec4(0.14, 0.14, 0.14, 1)
    colors[clr.BorderShadow] = ImVec4(1, 1, 1, 0.1)
    colors[clr.FrameBg] = ImVec4(0.22, 0.22, 0.22, 1)
    colors[clr.FrameBgHovered] = ImVec4(0.18, 0.18, 0.18, 1)
    colors[clr.FrameBgActive] = ImVec4(0.09, 0.12, 0.14, 1)
    colors[clr.TitleBgCollapsed] = ImVec4(0, 0, 0, 0.51)
    colors[clr.MenuBarBg] = ImVec4(0.2, 0.2, 0.2, 1)
    colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.39)
    colors[clr.ScrollbarGrab] = ImVec4(0.36, 0.36, 0.36, 1)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.24, 0.24, 0.24, 1)
    colors[clr.ComboBg] = ImVec4(0.24, 0.24, 0.24, 1)
    colors[clr.Button] = ImVec4(1, 0.28, 0.28, 1)
    colors[clr.ButtonActive] = ImVec4(1, 0.21, 0.21, 1)
    colors[clr.HeaderActive] = ImVec4(1, 0.21, 0.21, 1)
    colors[clr.ResizeGrip] = ImVec4(1, 0.28, 0.28, 1)
    colors[clr.ResizeGripHovered] = ImVec4(1, 0.39, 0.39, 1)
    colors[clr.ResizeGripActive] = ImVec4(1, 0.19, 0.19, 1)
    colors[clr.CloseButton] = ImVec4(0.4, 0.39, 0.38, 0.16)
    colors[clr.CloseButtonHovered] = ImVec4(0.4, 0.39, 0.38, 0.39)
    colors[clr.CloseButtonActive] = ImVec4(0.4, 0.39, 0.38, 1)
    colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1)
    colors[clr.PlotLinesHovered] = ImVec4(1, 0.43, 0.35, 1)
    colors[clr.PlotHistogram] = ImVec4(1, 0.21, 0.21, 1)
    colors[clr.PlotHistogramHovered] = ImVec4(1, 0.18, 0.18, 1)
    colors[clr.TextSelectedBg] = ImVec4(1, 0.32, 0.32, 1)
    colors[clr.ModalWindowDarkening] = ImVec4(0.26, 0.26, 0.26, 0.6)
end

function theme13()
    colors = imgui.GetStyle().Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    colors[clr.TitleBg] = ImVec4(0, 1, 1, 0.27)
    colors[clr.TitleBgActive] = ImVec4(0, 1, 1, 0.27)
    colors[clr.CheckMark] = ImVec4(0, 1, 1, 0.68)
    colors[clr.SliderGrab] = ImVec4(0, 1, 1, 0.36)
    colors[clr.SliderGrabActive] = ImVec4(0, 1, 1, 0.76)
    colors[clr.ButtonHovered] = ImVec4(0.01, 1, 1, 0.43)
    colors[clr.Header] = ImVec4(0, 1, 1, 0.33)
    colors[clr.HeaderHovered] = ImVec4(0, 1, 1, 0.42)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0, 1, 1, 0.74)
    colors[clr.Text] = ImVec4(0, 1, 1, 1)
    colors[clr.TextDisabled] = ImVec4(0, 0.4, 0.41, 1)
    colors[clr.WindowBg] = ImVec4(0, 0, 0, 1)
    colors[clr.ChildWindowBg] = ImVec4(0, 0, 0, 0)
    colors[clr.Border] = ImVec4(0, 1, 1, 0.65)
    colors[clr.BorderShadow] = ImVec4(0, 0, 0, 0)
    colors[clr.FrameBg] = ImVec4(0.44, 0.8, 0.8, 0.18)
    colors[clr.FrameBgHovered] = ImVec4(0.44, 0.8, 0.8, 0.27)
    colors[clr.FrameBgActive] = ImVec4(0.44, 0.81, 0.86, 0.66)
    colors[clr.TitleBgCollapsed] = ImVec4(0, 0, 0, 0.54)
    colors[clr.MenuBarBg] = ImVec4(0, 0, 0, 0.2)
    colors[clr.ScrollbarBg] = ImVec4(0.22, 0.29, 0.3, 0.71)
    colors[clr.ScrollbarGrab] = ImVec4(0, 1, 1, 0.44)
    colors[clr.ScrollbarGrabActive] = ImVec4(0, 1, 1, 1)
    colors[clr.ComboBg] = ImVec4(0.16, 0.24, 0.22, 0.6)
    colors[clr.Button] = ImVec4(0, 0.65, 0.65, 0.46)
    colors[clr.ButtonActive] = ImVec4(0, 1, 1, 0.62)
    colors[clr.HeaderActive] = ImVec4(0, 1, 1, 0.54)
    colors[clr.ResizeGrip] = ImVec4(0, 1, 1, 0.54)
    colors[clr.ResizeGripHovered] = ImVec4(0, 1, 1, 0.74)
    colors[clr.ResizeGripActive] = ImVec4(0, 1, 1, 1)
    colors[clr.CloseButton] = ImVec4(0, 0.78, 0.78, 0.35)
    colors[clr.CloseButtonHovered] = ImVec4(0, 0.78, 0.78, 0.47)
    colors[clr.CloseButtonActive] = ImVec4(0, 0.78, 0.78, 1)
    colors[clr.PlotLines] = ImVec4(0, 1, 1, 1)
    colors[clr.PlotLinesHovered] = ImVec4(0, 1, 1, 1)
    colors[clr.PlotHistogram] = ImVec4(0, 1, 1, 1)
    colors[clr.PlotHistogramHovered] = ImVec4(0, 1, 1, 1)
    colors[clr.TextSelectedBg] = ImVec4(0, 1, 1, 0.22)
    colors[clr.ModalWindowDarkening] = ImVec4(0.04, 0.1, 0.09, 0.51)
end

function theme14()
    colors = imgui.GetStyle().Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    colors[clr.TitleBg] = ImVec4(0, 0.45, 1, 0.82)
    colors[clr.TitleBgActive] = ImVec4(0, 0.45, 1, 0.82)
    colors[clr.CheckMark] = ImVec4(0, 0.49, 1, 0.59)
    colors[clr.SliderGrab] = ImVec4(0, 0.49, 1, 0.59)
    colors[clr.SliderGrabActive] = ImVec4(0, 0.39, 1, 0.71)
    colors[clr.ButtonHovered] = ImVec4(0, 0.49, 1, 0.71)
    colors[clr.Header] = ImVec4(0, 0.49, 1, 0.78)
    colors[clr.HeaderHovered] = ImVec4(0, 0.49, 1, 0.71)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0, 0.33, 1, 0.84)
    colors[clr.Text] = ImVec4(0, 0, 0, 0.51)
    colors[clr.TextDisabled] = ImVec4(0.24, 0.24, 0.24, 1)
    colors[clr.WindowBg] = ImVec4(1, 1, 1, 1)
    colors[clr.ChildWindowBg] = ImVec4(0.96, 0.96, 0.96, 1)
    colors[clr.PopupBg] = ImVec4(0.92, 0.92, 0.92, 1)
    colors[clr.Border] = ImVec4(0.86, 0.86, 0.86, 1)
    colors[clr.BorderShadow] = ImVec4(0, 0, 0, 0)
    colors[clr.FrameBg] = ImVec4(0.88, 0.88, 0.88, 1)
    colors[clr.FrameBgHovered] = ImVec4(0.82, 0.82, 0.82, 1)
    colors[clr.FrameBgActive] = ImVec4(0.76, 0.76, 0.76, 1)
    colors[clr.TitleBgCollapsed] = ImVec4(0, 0.45, 1, 0.82)
    colors[clr.MenuBarBg] = ImVec4(0, 0.37, 0.78, 1)
    colors[clr.ScrollbarBg] = ImVec4(0, 0, 0, 0)
    colors[clr.ScrollbarGrab] = ImVec4(0, 0.35, 1, 0.78)
    colors[clr.ScrollbarGrabActive] = ImVec4(0, 0.31, 1, 0.88)
    colors[clr.ComboBg] = ImVec4(0.92, 0.92, 0.92, 1)
    colors[clr.Button] = ImVec4(0, 0.49, 1, 0.59)
    colors[clr.ButtonActive] = ImVec4(0, 0.49, 1, 0.78)
    colors[clr.HeaderActive] = ImVec4(0, 0.49, 1, 0.78)
    colors[clr.ResizeGrip] = ImVec4(0, 0.39, 1, 0.59)
    colors[clr.ResizeGripHovered] = ImVec4(0, 0.27, 1, 0.59)
    colors[clr.ResizeGripActive] = ImVec4(0, 0.25, 1, 0.63)
    colors[clr.CloseButton] = ImVec4(0, 0.35, 0.96, 0.71)
    colors[clr.CloseButtonHovered] = ImVec4(0, 0.31, 0.88, 0.69)
    colors[clr.CloseButtonActive] = ImVec4(0, 0.25, 0.88, 0.67)
    colors[clr.PlotLines] = ImVec4(0, 0.39, 1, 0.75)
    colors[clr.PlotLinesHovered] = ImVec4(0, 0.39, 1, 0.75)
    colors[clr.PlotHistogram] = ImVec4(0, 0.39, 1, 0.75)
    colors[clr.PlotHistogramHovered] = ImVec4(0, 0.35, 0.92, 0.78)
    colors[clr.TextSelectedBg] = ImVec4(0, 0.47, 1, 0.59)
    colors[clr.ModalWindowDarkening] = ImVec4(0.2, 0.2, 0.2, 0.35)
end

function theme15()
    colors = imgui.GetStyle().Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    colors[clr.TitleBg] = ImVec4(0.82, 0.82, 0.82, 1)
    colors[clr.TitleBgActive] = ImVec4(0.82, 0.82, 0.82, 1)
    colors[clr.CheckMark] = ImVec4(0.26, 0.59, 0.98, 1)
    colors[clr.SliderGrab] = ImVec4(0.24, 0.52, 0.88, 1)
    colors[clr.SliderGrabActive] = ImVec4(0.26, 0.59, 0.98, 1)
    colors[clr.ButtonHovered] = ImVec4(0.26, 0.59, 0.98, 1)
    colors[clr.Header] = ImVec4(0.26, 0.59, 0.98, 0.31)
    colors[clr.HeaderHovered] = ImVec4(0.26, 0.59, 0.98, 0.8)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.59, 0.59, 0.59, 1)
    colors[clr.Text] = ImVec4(0, 0, 0, 1)
    colors[clr.TextDisabled] = ImVec4(0.6, 0.6, 0.6, 1)
    colors[clr.WindowBg] = ImVec4(0.94, 0.94, 0.94, 0.94)
    colors[clr.ChildWindowBg] = ImVec4(0, 0, 0, 0)
    colors[clr.PopupBg] = ImVec4(1, 1, 1, 0.94)
    colors[clr.Border] = ImVec4(0, 0, 0, 0.39)
    colors[clr.BorderShadow] = ImVec4(1, 1, 1, 0.1)
    colors[clr.FrameBg] = ImVec4(1, 1, 1, 0.94)
    colors[clr.FrameBgHovered] = ImVec4(0.26, 0.59, 0.98, 0.4)
    colors[clr.FrameBgActive] = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.TitleBgCollapsed] = ImVec4(1, 1, 1, 0.51)
    colors[clr.MenuBarBg] = ImVec4(0.86, 0.86, 0.86, 1)
    colors[clr.ScrollbarBg] = ImVec4(0.98, 0.98, 0.98, 0.53)
    colors[clr.ScrollbarGrab] = ImVec4(0.69, 0.69, 0.69, 1)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.49, 0.49, 0.49, 1)
    colors[clr.ComboBg] = ImVec4(0.86, 0.86, 0.86, 0.99)
    colors[clr.Button] = ImVec4(0.26, 0.59, 0.98, 0.4)
    colors[clr.ButtonActive] = ImVec4(0.06, 0.53, 0.98, 1)
    colors[clr.HeaderActive] = ImVec4(0.26, 0.59, 0.98, 1)
    colors[clr.ResizeGrip] = ImVec4(1, 1, 1, 0.5)
    colors[clr.ResizeGripHovered] = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.ResizeGripActive] = ImVec4(0.26, 0.59, 0.98, 0.95)
    colors[clr.CloseButton] = ImVec4(0.59, 0.59, 0.59, 0.5)
    colors[clr.CloseButtonHovered] = ImVec4(0.98, 0.39, 0.36, 1)
    colors[clr.CloseButtonActive] = ImVec4(0.98, 0.39, 0.36, 1)
    colors[clr.PlotLines] = ImVec4(0.39, 0.39, 0.39, 1)
    colors[clr.PlotLinesHovered] = ImVec4(1, 0.43, 0.35, 1)
    colors[clr.PlotHistogram] = ImVec4(0.9, 0.7, 0, 1)
    colors[clr.PlotHistogramHovered] = ImVec4(1, 0.6, 0, 1)
    colors[clr.TextSelectedBg] = ImVec4(0.26, 0.59, 0.98, 0.35)
    colors[clr.ModalWindowDarkening] = ImVec4(0.2, 0.2, 0.2, 0.35)
end

function theme16()
    colors = imgui.GetStyle().Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    colors[clr.TitleBg] = ImVec4(0.42, 0.48, 0.16, 1)
    colors[clr.TitleBgActive] = ImVec4(0.42, 0.48, 0.16, 1)
    colors[clr.CheckMark] = ImVec4(0.85, 0.98, 0.26, 1)
    colors[clr.SliderGrab] = ImVec4(0.77, 0.88, 0.24, 1)
    colors[clr.SliderGrabActive] = ImVec4(0.85, 0.98, 0.26, 1)
    colors[clr.ButtonHovered] = ImVec4(0.85, 0.98, 0.26, 1)
    colors[clr.Header] = ImVec4(0.85, 0.98, 0.26, 0.31)
    colors[clr.HeaderHovered] = ImVec4(0.85, 0.98, 0.26, 0.8)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.41, 0.41, 1)
    colors[clr.FrameBg] = ImVec4(0.42, 0.48, 0.16, 0.54)
    colors[clr.FrameBgHovered] = ImVec4(0.85, 0.98, 0.26, 0.4)
    colors[clr.FrameBgActive] = ImVec4(0.85, 0.98, 0.26, 0.67)
    colors[clr.TitleBgCollapsed] = ImVec4(0, 0, 0, 0.51)
    colors[clr.Button] = ImVec4(0.85, 0.98, 0.26, 0.4)
    colors[clr.ButtonActive] = ImVec4(0.82, 0.98, 0.06, 1)
    colors[clr.HeaderActive] = ImVec4(0.85, 0.98, 0.26, 1)
    colors[clr.Separator] = colors[clr.Border]
    colors[clr.SeparatorHovered] = ImVec4(0.63, 0.75, 0.1, 0.78)
    colors[clr.SeparatorActive] = ImVec4(0.63, 0.75, 0.1, 1)
    colors[clr.ResizeGrip] = ImVec4(0.85, 0.98, 0.26, 0.25)
    colors[clr.ResizeGripHovered] = ImVec4(0.85, 0.98, 0.26, 0.67)
    colors[clr.ResizeGripActive] = ImVec4(0.85, 0.98, 0.26, 0.95)
    colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1)
    colors[clr.PlotLinesHovered] = ImVec4(1, 0.81, 0.35, 1)
    colors[clr.TextSelectedBg] = ImVec4(0.85, 0.98, 0.26, 0.35)
    colors[clr.Text] = ImVec4(1, 1, 1, 1)
    colors[clr.TextDisabled] = ImVec4(0.5, 0.5, 0.5, 1)
    colors[clr.WindowBg] = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.ChildWindowBg] = ImVec4(1, 1, 1, 0)
    colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg] = colors[clr.PopupBg]
    colors[clr.Border] = ImVec4(0.43, 0.43, 0.5, 0.5)
    colors[clr.BorderShadow] = ImVec4(0, 0, 0, 0)
    colors[clr.MenuBarBg] = ImVec4(0.14, 0.14, 0.14, 1)
    colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab] = ImVec4(0.31, 0.31, 0.31, 1)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.51, 0.51, 0.51, 1)
    colors[clr.CloseButton] = ImVec4(0.41, 0.41, 0.41, 0.5)
    colors[clr.CloseButtonHovered] = ImVec4(0.98, 0.39, 0.36, 1)
    colors[clr.CloseButtonActive] = ImVec4(0.98, 0.39, 0.36, 1)
    colors[clr.PlotHistogram] = ImVec4(0.9, 0.7, 0, 1)
    colors[clr.PlotHistogramHovered] = ImVec4(1, 0.6, 0, 1)
    colors[clr.ModalWindowDarkening] = ImVec4(0.8, 0.8, 0.8, 0.35)
end

function theme17()
    colors = imgui.GetStyle().Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    colors[clr.TitleBg] = ImVec4(0, 0.74, 0.36, 1)
    colors[clr.TitleBgActive] = ImVec4(0, 0.74, 0.36, 1)
    colors[clr.CheckMark] = ImVec4(0, 0.69, 0.33, 1)
    colors[clr.SliderGrab] = ImVec4(0, 0.69, 0.33, 1)
    colors[clr.SliderGrabActive] = ImVec4(0, 0.77, 0.37, 1)
    colors[clr.ButtonHovered] = ImVec4(0, 0.82, 0.39, 1)
    colors[clr.Header] = ImVec4(0, 0.69, 0.33, 1)
    colors[clr.HeaderHovered] = ImVec4(0, 0.76, 0.37, 0.57)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0, 0.82, 0.39, 1)
    colors[clr.Text] = ImVec4(0.9, 0.9, 0.9, 1)
    colors[clr.TextDisabled] = ImVec4(0.6, 0.6, 0.6, 1)
    colors[clr.WindowBg] = ImVec4(0.08, 0.08, 0.08, 1)
    colors[clr.ChildWindowBg] = ImVec4(0.1, 0.1, 0.1, 1)
    colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 1)
    colors[clr.Border] = ImVec4(0.7, 0.7, 0.7, 0.4)
    colors[clr.BorderShadow] = ImVec4(0, 0, 0, 0)
    colors[clr.FrameBg] = ImVec4(0.15, 0.15, 0.15, 1)
    colors[clr.FrameBgHovered] = ImVec4(0.19, 0.19, 0.19, 0.71)
    colors[clr.FrameBgActive] = ImVec4(0.34, 0.34, 0.34, 0.79)
    colors[clr.TitleBgCollapsed] = ImVec4(0, 0.69, 0.33, 0.5)
    colors[clr.MenuBarBg] = ImVec4(0.2, 0.2, 0.2, 1)
    colors[clr.ScrollbarBg] = ImVec4(0.16, 0.16, 0.16, 1)
    colors[clr.ScrollbarGrab] = ImVec4(0, 0.69, 0.33, 1)
    colors[clr.ScrollbarGrabActive] = ImVec4(0, 1, 0.48, 1)
    colors[clr.ComboBg] = ImVec4(0.2, 0.2, 0.2, 0.99)
    colors[clr.Button] = ImVec4(0, 0.69, 0.33, 1)
    colors[clr.ButtonActive] = ImVec4(0, 0.87, 0.42, 1)
    colors[clr.HeaderActive] = ImVec4(0, 0.88, 0.42, 0.89)
    colors[clr.Separator] = ImVec4(1, 1, 1, 0.4)
    colors[clr.SeparatorHovered] = ImVec4(1, 1, 1, 0.6)
    colors[clr.SeparatorActive] = ImVec4(1, 1, 1, 0.8)
    colors[clr.ResizeGrip] = ImVec4(0, 0.69, 0.33, 1)
    colors[clr.ResizeGripHovered] = ImVec4(0, 0.76, 0.37, 1)
    colors[clr.ResizeGripActive] = ImVec4(0, 0.86, 0.41, 1)
    colors[clr.CloseButton] = ImVec4(0, 0.82, 0.39, 1)
    colors[clr.CloseButtonHovered] = ImVec4(0, 0.88, 0.42, 1)
    colors[clr.CloseButtonActive] = ImVec4(0, 1, 0.48, 1)
    colors[clr.PlotLines] = ImVec4(0, 0.69, 0.33, 1)
    colors[clr.PlotLinesHovered] = ImVec4(0, 0.74, 0.36, 1)
    colors[clr.PlotHistogram] = ImVec4(0, 0.69, 0.33, 1)
    colors[clr.PlotHistogramHovered] = ImVec4(0, 0.8, 0.38, 1)
    colors[clr.TextSelectedBg] = ImVec4(0, 0.69, 0.33, 0.72)
    colors[clr.ModalWindowDarkening] = ImVec4(0.17, 0.17, 0.17, 0.48)
end

function theme18()
    colors = imgui.GetStyle().Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    colors[clr.TitleBg] = ImVec4(0, 0.52, 0.74, 1)
    colors[clr.TitleBgActive] = ImVec4(0, 0.52, 0.74, 1)
    colors[clr.CheckMark] = ImVec4(0.13, 0.65, 0.87, 1)
    colors[clr.SliderGrab] = ImVec4(0, 0.52, 0.74, 1)
    colors[clr.SliderGrabActive] = ImVec4(0, 0.52, 0.74, 1)
    colors[clr.ButtonHovered] = ImVec4(1, 0.39, 0.39, 1)
    colors[clr.Header] = ImVec4(0, 0.52, 0.74, 0.6)
    colors[clr.HeaderHovered] = ImVec4(0, 0.52, 0.74, 0.43)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1)
    colors[clr.Text] = ImVec4(0.95, 0.96, 0.98, 1)
    colors[clr.TextDisabled] = ImVec4(0.29, 0.29, 0.29, 1)
    colors[clr.WindowBg] = ImVec4(0.14, 0.14, 0.14, 1)
    colors[clr.ChildWindowBg] = ImVec4(0.12, 0.12, 0.12, 1)
    colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.Border] = ImVec4(0.14, 0.14, 0.14, 0.4)
    colors[clr.BorderShadow] = ImVec4(1, 1, 1, 0.1)
    colors[clr.FrameBg] = ImVec4(0.2, 0.2, 0.2, 1)
    colors[clr.FrameBgHovered] = ImVec4(0, 0.52, 0.74, 0.4)
    colors[clr.FrameBgActive] = ImVec4(0, 0.52, 0.74, 0.9)
    colors[clr.TitleBgCollapsed] = ImVec4(0, 0.52, 0.74, 0.79)
    colors[clr.MenuBarBg] = ImVec4(0.2, 0.2, 0.2, 1)
    colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.39)
    colors[clr.ScrollbarGrab] = ImVec4(0, 0.52, 0.74, 0.8)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.24, 0.24, 0.24, 1)
    colors[clr.ComboBg] = ImVec4(0.24, 0.24, 0.24, 1)
    colors[clr.Button] = ImVec4(0, 0.52, 0.74, 0.8)
    colors[clr.ButtonHovered] = ImVec4(0, 0.52, 0.74, 0.63)
    colors[clr.ButtonActive] = ImVec4(0, 0.52, 0.74, 1)
    colors[clr.HeaderActive] = ImVec4(0, 0.52, 0.74, 0.8)
    colors[clr.ResizeGrip] = ImVec4(0, 0.52, 0.74, 0.8)
    colors[clr.ResizeGripHovered] = ImVec4(0, 0.52, 0.74, 0.63)
    colors[clr.ResizeGripActive] = ImVec4(0, 0.52, 0.74, 1)
    colors[clr.CloseButton] = ImVec4(0.4, 0.39, 0.38, 0.16)
    colors[clr.CloseButtonHovered] = ImVec4(0.4, 0.39, 0.38, 0.39)
    colors[clr.CloseButtonActive] = ImVec4(0.4, 0.39, 0.38, 1)
    colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1)
    colors[clr.PlotLinesHovered] = ImVec4(1, 0.43, 0.35, 1)
    colors[clr.PlotHistogram] = ImVec4(0, 0.52, 0.74, 1)
    colors[clr.PlotHistogramHovered] = ImVec4(1, 0.18, 0.18, 1)
    colors[clr.TextSelectedBg] = ImVec4(1, 0.32, 0.32, 1)
    colors[clr.ModalWindowDarkening] = ImVec4(0.26, 0.26, 0.26, 0.6)
end

function easystyle()
    imgui.SwitchContext()

    style = imgui.GetStyle()
    colors = style.Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(4, 4)
    style.WindowRounding = 7
    style.ChildWindowRounding = 0
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 4
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 13
    style.ScrollbarRounding = 10
    style.GrabMinSize = 8
    style.GrabRounding = 10
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
end

function strongstyle()
    imgui.SwitchContext()

    style = imgui.GetStyle()
    colors = style.Colors
    clr = imgui.Col
    ImVec2 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(4, 4)
    style.WindowRounding = 0
    style.ChildWindowRounding = 0
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 13
    style.ScrollbarRounding = 0
    style.GrabMinSize = 8
    style.GrabRounding = 0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
end

function setstyleandtheme()
    if styleNumber.v == 1 then strongstyle() end
    if styleNumber.v == 2 then easystyle() end
    if themeNumber.v == 1 then theme1() end
    if themeNumber.v == 2 then theme2() end
    if themeNumber.v == 3 then theme3() end
    if themeNumber.v == 4 then theme4() end
    if themeNumber.v == 5 then theme5() end
    if themeNumber.v == 6 then theme6() end
    if themeNumber.v == 7 then theme7() end
    if themeNumber.v == 8 then theme8() end
    if themeNumber.v == 9 then theme9() end
    if themeNumber.v == 10 then theme10() end 
    if themeNumber.v == 11 then theme11() end
    if themeNumber.v == 12 then theme12() end
    if themeNumber.v == 13 then theme13() end
    if themeNumber.v == 14 then theme14() end
    if themeNumber.v == 15 then theme15() end
    if themeNumber.v == 16 then theme16() end
    if themeNumber.v == 17 then theme17() end
    if themeNumber.v == 18 then theme18() end
end