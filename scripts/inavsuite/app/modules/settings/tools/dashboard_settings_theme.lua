local i18n = inavsuite.i18n.get


local enableWakeup = false
local prevConnectedState = nil
local page

local function openPage(idx, title, script, source, folder,themeScript)
    -- Initialize global UI state and clear form data
    inavsuite.app.uiState = inavsuite.app.uiStatus.pages
    inavsuite.app.triggers.isReady = false
    inavsuite.app.formFields = {}
    inavsuite.app.formLines = {}
    inavsuite.app.lastLabel = nil

    inavsuite.app.dashboardEditingTheme = source .. "/" .. folder

    -- Load the module
    local modulePath =  themeScript

    page = assert(inavsuite.compiler.loadfile(modulePath))(idx)

    -- load up the menu
    local w, h = lcd.getWindowSize()
    local windowWidth = w
    local windowHeight = h
    local padding = inavsuite.app.radio.buttonPadding

    local sc
    local panel   

    form.clear()

    --form.addLine("../ " .. i18n("app.modules.settings.dashboard") .. " / " .. i18n("app.modules.settings.name") .. " / " .. title)
    form.addLine( i18n("app.modules.settings.name") .. " / " .. title)
    buttonW = 100
    local x = windowWidth - (buttonW * 2) - 15

    inavsuite.app.formNavigationFields['menu'] = form.addButton(line, {x = x, y = inavsuite.app.radio.linePaddingTop, w = buttonW, h = inavsuite.app.radio.navbuttonHeight}, {
        text = i18n("app.navigation_menu"),
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()
            inavsuite.app.lastIdx = nil
            inavsuite.session.lastPage = nil

            if inavsuite.app.Page and inavsuite.app.Page.onNavMenu then inavsuite.app.Page.onNavMenu(inavsuite.app.Page) end


            inavsuite.app.ui.openPage(
                pageIdx,
                i18n("app.modules.settings.dashboard"),
                "settings/tools/dashboard_settings.lua"
            )
        end
    })
    inavsuite.app.formNavigationFields['menu']:focus()


    local x = windowWidth - buttonW - 10
    inavsuite.app.formNavigationFields['save'] = form.addButton(line, {x = x, y = inavsuite.app.radio.linePaddingTop, w = buttonW, h = inavsuite.app.radio.navbuttonHeight}, {
        text = "SAVE",
        icon = nil,
        options = FONT_S,
        paint = function()
        end,
        press = function()

                local buttons = {
                    {
                        label  = i18n("app.btn_ok_long"),
                        action = function()
                            local msg = i18n("app.modules.profile_select.save_prompt_local")
                            inavsuite.app.ui.progressDisplaySave(msg:gsub("%?$", "."))
                            if page.write then
                                page.write()
                            end    
                            -- update dashboard theme
                            inavsuite.widgets.dashboard.reload_themes()
                            inavsuite.app.triggers.closeSave = true
                            return true
                        end,
                    },
                    {
                        label  = i18n("app.modules.profile_select.cancel"),
                        action = function()
                            return true
                        end,
                    },
                }

                form.openDialog({
                    width   = nil,
                    title   = i18n("app.modules.profile_select.save_settings"),
                    message = i18n("app.modules.profile_select.save_prompt_local"),
                    buttons = buttons,
                    wakeup  = function() end,
                    paint   = function() end,
                    options = TEXT_LEFT,
                })

        end
    })
    inavsuite.app.formNavigationFields['menu']:focus()

    
    inavsuite.app.uiState = inavsuite.app.uiStatus.pages
    enableWakeup = true

    
    -- If the Page has its own openPage function, use it and return early
    if page.configure then
        page.configure(idx, title, script, extra1, extra2, extra3, extra5, extra6)
        inavsuite.utils.reportMemoryUsage(title)
        inavsuite.app.triggers.closeProgressLoader = true
        return
    end

end

local function event(widget, category, value, x, y)
    -- if close event detected go to section home page
    if category == EVT_CLOSE and value == 0 or value == 35 then
        inavsuite.app.ui.openPage(
            pageIdx,
            i18n("app.modules.settings.dashboard"),
            "settings/tools/dashboard.lua"
        )
        return true
    end

    if page.event then
        page.event()
    end

end

local function onNavMenu()
    inavsuite.app.ui.progressDisplay(nil,nil,true)
        inavsuite.app.ui.openPage(
            pageIdx,
            i18n("app.modules.settings.dashboard"),
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

    if page.wakeup then
        page.wakeup()
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
