

local S_PAGES = {
    {name = "@i18n(app.modules.settings.txt_general)@", script = "general.lua", image = "general.png"},
    {name = "@i18n(app.modules.settings.dashboard)@", script = "dashboard.lua", image = "dashboard.png"},
    {name = "@i18n(app.modules.settings.localizations)@", script = "localizations.lua", image = "localizations.png"},
    {name = "@i18n(app.modules.settings.audio)@", script = "audio.lua", image = "audio.png"},
    {name = "@i18n(app.modules.settings.txt_development)@", script = "development.lua", image = "development.png"},
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
        if i ~= "settings" then
            inavsuite.app.gfx_buttons[i] = nil
        end
    end


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

    form.addLine(title)

    local buttonW = 100
    local x = windowWidth - buttonW - 10

    inavsuite.app.formNavigationFields['menu'] = form.addButton(line, {x = x, y = inavsuite.app.radio.linePaddingTop, w = buttonW, h = inavsuite.app.radio.navbuttonHeight}, {
        text = "MENU",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            inavsuite.app.lastIdx = nil
            inavsuite.session.lastPage = nil

            if inavsuite.app.Page and inavsuite.app.Page.onNavMenu then 
                    inavsuite.app.Page.onNavMenu(inavsuite.app.Page) 
            else
                inavsuite.app.ui.progressDisplay(nil,nil,true)
            end
            inavsuite.app.ui.openMainMenu()
        end
    })
    inavsuite.app.formNavigationFields['menu']:focus()

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


    if inavsuite.app.gfx_buttons["settings"] == nil then inavsuite.app.gfx_buttons["settings"] = {} end
    if inavsuite.preferences.menulastselected["settings"] == nil then inavsuite.preferences.menulastselected["settings"] = 1 end


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
            if inavsuite.app.gfx_buttons["settings"][pidx] == nil then inavsuite.app.gfx_buttons["settings"][pidx] = lcd.loadMask("app/modules/settings/gfx/" .. pvalue.image) end
        else
            inavsuite.app.gfx_buttons["settings"][pidx] = nil
        end

        inavsuite.app.formFields[pidx] = form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.name,
            icon = inavsuite.app.gfx_buttons["settings"][pidx],
            options = FONT_S,
            paint = function()
            end,
            press = function()
                inavsuite.preferences.menulastselected["settings"] = pidx
                inavsuite.app.ui.progressDisplay(nil,nil,true)
                inavsuite.app.ui.openPage(pidx, pvalue.folder, "settings/tools/" .. pvalue.script)
            end
        })

        if pvalue.disabled == true then inavsuite.app.formFields[pidx]:enable(false) end

        if inavsuite.preferences.menulastselected["settings"] == pidx then inavsuite.app.formFields[pidx]:focus() end

        lc = lc + 1

        if lc == numPerRow then lc = 0 end

    end

    inavsuite.app.triggers.closeProgressLoader = true
    collectgarbage()
    return
end

inavsuite.app.uiState = inavsuite.app.uiStatus.pages

return {
    pages = pages, 
    openPage = openPage,
    API = {},
}
