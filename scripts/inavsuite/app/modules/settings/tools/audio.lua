

local i18n = inavsuite.i18n.get

local S_PAGES = {
    {name = i18n("app.modules.settings.txt_audio_events"), script = "audio_events.lua", image = "audio_events.png"},
    {name = i18n("app.modules.settings.txt_audio_switches"), script = "audio_switches.lua", image = "audio_switches.png"},
    {name = i18n("app.modules.settings.txt_audio_timer"), script = "audio_timer.lua", image = "audio_timer.png"},
}

local function openPage(pidx, title, script)


    inavsuite.tasks.msp.protocol.mspIntervalOveride = nil


    inavsuite.app.triggers.isReady = false
    inavsuite.app.uiState = inavsuite.app.uiStatus.mainMenu

    form.clear()

    inavsuite.app.lastIdx = idx
    inavsuite.app.lastTitle = title
    inavsuite.app.lastScript = script

    -- Clear old icons
    for i in pairs(inavsuite.app.gfx_buttons) do
        if i ~= "settings_dashboard_audio" then
            inavsuite.app.gfx_buttons[i] = nil
        end
    end


    ESC = {}

    -- size of buttons
    if inavsuite.preferences.general.iconsize == nil or inavsuite.preferences.general.iconsize == "" then
        inavsuite.preferences.general.iconsize = 1
    else
        inavsuite.preferences.general.iconsize = tonumber(inavsuite.preferences.general.iconsize)
    end

    local w, h = lcd.getWindowSize()
    local windowWidth = w
    local windowHeight = h
    local padding = inavsuite.app.radio.buttonPadding

    local sc
    local panel



    buttonW = 100
    local x = windowWidth - buttonW - 10

    inavsuite.app.ui.fieldHeader(
        i18n(i18n("app.modules.settings.name") .. " / " .. i18n("app.modules.settings.audio"))
    )

    local buttonW
    local buttonH
    local padding
    local numPerRow

    -- TEXT ICONS
    -- TEXT ICONS
    if inavsuite.preferences.general.iconsize == 0 then
        padding = inavsuite.app.radio.buttonPaddingSmall
        buttonW = (inavsuite.app.lcdWidth - padding) / inavsuite.app.radio.buttonsPerRow - padding
        buttonH = inavsuite.app.radio.navbuttonHeight
        numPerRow = inavsuite.app.radio.buttonsPerRow
    end
    -- SMALL ICONS
    if inavsuite.preferences.general.iconsize == 1 then

        padding = inavsuite.app.radio.buttonPaddingSmall
        buttonW = inavsuite.app.radio.buttonWidthSmall
        buttonH = inavsuite.app.radio.buttonHeightSmall
        numPerRow = inavsuite.app.radio.buttonsPerRowSmall
    end
    -- LARGE ICONS
    if inavsuite.preferences.general.iconsize == 2 then

        padding = inavsuite.app.radio.buttonPadding
        buttonW = inavsuite.app.radio.buttonWidth
        buttonH = inavsuite.app.radio.buttonHeight
        numPerRow = inavsuite.app.radio.buttonsPerRow
    end


    if inavsuite.app.gfx_buttons["settings_dashboard_audio"] == nil then inavsuite.app.gfx_buttons["settings_dashboard_audio"] = {} end
    if inavsuite.preferences.menulastselected["settings_dashboard_audio"] == nil then inavsuite.preferences.menulastselected["settings_dashboard_audio"] = 1 end


    local Menu = assert(inavsuite.compiler.loadfile("app/modules/" .. script))()
    local pages = S_PAGES
    local lc = 0
    local bx = 0



    for pidx, pvalue in ipairs(S_PAGES) do

        if lc == 0 then
            if inavsuite.preferences.general.iconsize == 0 then y = form.height() + inavsuite.app.radio.buttonPaddingSmall end
            if inavsuite.preferences.general.iconsize == 1 then y = form.height() + inavsuite.app.radio.buttonPaddingSmall end
            if inavsuite.preferences.general.iconsize == 2 then y = form.height() + inavsuite.app.radio.buttonPadding end
        end

        if lc >= 0 then bx = (buttonW + padding) * lc end

        if inavsuite.preferences.general.iconsize ~= 0 then
            if inavsuite.app.gfx_buttons["settings_dashboard_audio"][pidx] == nil then inavsuite.app.gfx_buttons["settings_dashboard_audio"][pidx] = lcd.loadMask("app/modules/settings/gfx/" .. pvalue.image) end
        else
            inavsuite.app.gfx_buttons["settings_dashboard_audio"][pidx] = nil
        end

        inavsuite.app.formFields[pidx] = form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.name,
            icon = inavsuite.app.gfx_buttons["settings_dashboard_audio"][pidx],
            options = FONT_S,
            paint = function()
            end,
            press = function()
                inavsuite.preferences.menulastselected["settings_dashboard_audio"] = pidx
                inavsuite.app.ui.progressDisplay(nil,nil,true)
                inavsuite.app.ui.openPage(pidx, pvalue.folder, "settings/tools/" .. pvalue.script)
            end
        })

        if pvalue.disabled == true then inavsuite.app.formFields[pidx]:enable(false) end

        if inavsuite.preferences.menulastselected["settings_dashboard_audio"] == pidx then inavsuite.app.formFields[pidx]:focus() end

        lc = lc + 1

        if lc == numPerRow then lc = 0 end

    end

    inavsuite.app.triggers.closeProgressLoader = true
    collectgarbage()
    return
end

local function event(widget, category, value, x, y)
    -- if close event detected go to section home page
    if category == EVT_CLOSE and value == 0 or value == 35 then
        inavsuite.app.ui.openPage(
            pageIdx,
            i18n("app.modules.settings.name"),
            "settings/settings.lua"
        )
        return true
    end
end


local function onNavMenu()
    inavsuite.app.ui.progressDisplay(nil,nil,true)
        inavsuite.app.ui.openPage(
            pageIdx,
            i18n("app.modules.settings.name"),
            "settings/settings.lua"
        )
        return true
end

inavsuite.app.uiState = inavsuite.app.uiStatus.pages

return {
    pages = pages, 
    openPage = openPage,
    onNavMenu = onNavMenu,
    API = {},
    event = event,
    navButtons = {
        menu   = true,
        save   = false,
        reload = false,
        tool   = false,
        help   = false,
    },    
}
