

local themesBasePath = "SCRIPTS:/" .. inavsuite.config.baseDir .. "/widgets/dashboard/themes/"
local themesUserPath = "SCRIPTS:/" .. inavsuite.config.preferences .. "/dashboard/"

local enableWakeup = false
local prevConnectedState = nil

local function openPage(pidx, title, script)
    -- Get the installed themes
    local themeList = inavsuite.widgets.dashboard.listThemes()

    inavsuite.app.dashboardEditingTheme = nil
    enableWakeup = true
    inavsuite.app.triggers.closeProgressLoader = true
    form.clear()

    -- Clear old icons
    for i in pairs(inavsuite.app.gfx_buttons) do
        if i ~= "settings_dashboard_themes" then
            inavsuite.app.gfx_buttons[i] = nil
        end
    end   


    inavsuite.app.lastIdx    = pageIdx
    inavsuite.app.lastTitle  = title
    inavsuite.app.lastScript = script

    inavsuite.app.ui.fieldHeader(
        "@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.dashboard)@" .. " / " .. "@i18n(app.modules.settings.dashboard_settings)@"
    )

    -- Icon/button layout settings
    local buttonW, buttonH, padding, numPerRow
    if inavsuite.preferences.general.iconsize == 0 then
        padding = inavsuite.app.radio.buttonPaddingSmall
        buttonW = (inavsuite.app.lcdWidth - padding) / inavsuite.app.radio.buttonsPerRow - padding
        buttonH = inavsuite.app.radio.navbuttonHeight
        numPerRow = inavsuite.app.radio.buttonsPerRow
    elseif inavsuite.preferences.general.iconsize == 1 then
        padding = inavsuite.app.radio.buttonPaddingSmall
        buttonW = inavsuite.app.radio.buttonWidthSmall
        buttonH = inavsuite.app.radio.buttonHeightSmall
        numPerRow = inavsuite.app.radio.buttonsPerRowSmall
    else
        padding = inavsuite.app.radio.buttonPadding
        buttonW = inavsuite.app.radio.buttonWidth
        buttonH = inavsuite.app.radio.buttonHeight
        numPerRow = inavsuite.app.radio.buttonsPerRow
    end

    -- Image cache table for theme icons
    if inavsuite.app.gfx_buttons["settings_dashboard_themes"] == nil then
        inavsuite.app.gfx_buttons["settings_dashboard_themes"] = {}
    end
    if inavsuite.preferences.menulastselected["settings_dashboard_themes"] == nil then
        inavsuite.preferences.menulastselected["settings_dashboard_themes"] = 1
    end

    local lc, bx, y = 0, 0, 0

    local n  = 0
    
    for idx, theme in ipairs(themeList) do

        if theme.configure then

            if lc == 0 then
                if inavsuite.preferences.general.iconsize == 0 then y = form.height() + inavsuite.app.radio.buttonPaddingSmall end
                if inavsuite.preferences.general.iconsize == 1 then y = form.height() + inavsuite.app.radio.buttonPaddingSmall end
                if inavsuite.preferences.general.iconsize == 2 then y = form.height() + inavsuite.app.radio.buttonPadding end
            end
            if lc >= 0 then bx = (buttonW + padding) * lc end

            -- Only load image once per theme index
            if inavsuite.app.gfx_buttons["settings_dashboard_themes"][idx] == nil then

                local icon  
                if theme.source == "system" then
                    icon = themesBasePath .. theme.folder .. "/icon.png"
                else 
                    icon = themesUserPath .. theme.folder .. "/icon.png"
                end    
                inavsuite.app.gfx_buttons["settings_dashboard_themes"][idx] = lcd.loadMask(icon)
            end

            inavsuite.app.formFields[idx] = form.addButton(nil, {x = bx, y = y, w = buttonW, h = buttonH}, {
                text = theme.name,
                icon = inavsuite.app.gfx_buttons["settings_dashboard_themes"][idx],
                options = FONT_S,
                paint = function() end,
                press = function()
                    -- Optional: your action when pressing a theme
                    -- Example: inavsuite.app.ui.loadTheme(theme.folder)
                    inavsuite.preferences.menulastselected["settings_dashboard_themes"] = idx
                inavsuite.app.ui.progressDisplay(nil,nil,true)
                    local configure = theme.configure
                    local source = theme.source
                    local folder = theme.folder

                    local themeScript
                    if theme.source == "system" then
                        themeScript = themesBasePath .. folder .. "/" .. configure 
                    else 
                        themeScript = themesUserPath .. folder .. "/" .. configure 
                    end    

                    local wrapperScript = "settings/tools/dashboard_settings_theme.lua"

                    inavsuite.app.ui.openPage(idx, theme.name, wrapperScript, source, folder,themeScript)               
                end
            })

            if not theme.configure then
                inavsuite.app.formFields[idx]:enable(false)
            end


            --local currState = (inavsuite.session.isConnected and inavsuite.session.mcu_id) and true or false 
            if inavsuite.preferences.menulastselected["settings_dashboard_themes"] == idx then
                inavsuite.app.formFields[idx]:focus()
            end

            lc = lc + 1
            n = lc + 1
            if lc == numPerRow then lc = 0 end
        end   
    end

    if n == 0 then
        local w, h = lcd.getWindowSize()
        local msg = "@i18n(app.modules.settings.no_themes_available_to_configure)@"
        local tw, th = lcd.getTextSize(msg)
        local x = w / 2 - tw / 2
        local y = h / 2 - th / 2
        local btnH = inavsuite.app.radio.navbuttonHeight
        form.addStaticText(nil, { x = x, y = y, w = tw, h = btnH }, msg)
    end

    inavsuite.app.triggers.closeProgressLoader = true
    collectgarbage()
    enableWakeup = true
    return
end


inavsuite.app.uiState = inavsuite.app.uiStatus.pages

local function event(widget, category, value, x, y)
    -- if close event detected go to section home page
    if category == EVT_CLOSE and value == 0 or value == 35 then
        inavsuite.app.ui.openPage(
            pageIdx,
            "@i18n(app.modules.settings.dashboard)@",
            "settings/tools/dashboard.lua"
        )
        return true
    end
end

local function onNavMenu()
    inavsuite.app.ui.progressDisplay(nil,nil,true)
    inavsuite.app.ui.openPage(
        pageIdx,
        "@i18n(app.modules.settings.dashboard)@",
        "settings/tools/dashboard.lua"
    )
        return true
end

local function wakeup()
    if not enableWakeup then
        return
    end

    -- current combined state: true only if both are truthy
    local currState = (inavsuite.session.isConnected and inavsuite.session.mcu_id) and true or false

    -- only update if state has changed
    if currState ~= prevConnectedState then
        -- we cant be here anymore... jump to previous page
        if currState == false then
            onNavMenu()
        end
        -- remember for next time
        prevConnectedState = currState
    end
end

return {
    pages = pages, 
    openPage = openPage,
    API = {},
    navButtons = {
        menu   = true,
        save   = false,
        reload = false,
        tool   = false,
        help   = false,
    }, 
    event = event,
    onNavMenu = onNavMenu,
    wakeup = wakeup,
}
