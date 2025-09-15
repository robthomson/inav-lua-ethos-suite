local i18n = inavsuite.i18n.get

local function findMFG()
    local mfgsList = {}

    local mfgdir = "app/modules/esc_tools/mfg/"
    local mfgs_path = mfgdir 

    for _, v in pairs(system.listFiles(mfgs_path)) do

        local init_path = mfgs_path .. v .. '/init.lua'

        local f = os.stat(init_path)
        if f then

            local func, err = inavsuite.compiler.loadfile(init_path)

            if func then
                local mconfig = func()
                if type(mconfig) ~= "table" or not mconfig.toolName then
                    inavsuite.utils.log("Invalid configuration in " .. init_path)
                else
                    mconfig['folder'] = v
                    table.insert(mfgsList, mconfig)
                end
            end
        end
    end

    return mfgsList
end

local function openPage(pidx, title, script)


    inavsuite.tasks.msp.protocol.mspIntervalOveride = nil
    inavsuite.session.escDetails = nil

    inavsuite.app.triggers.isReady = false
    inavsuite.app.uiState = inavsuite.app.uiStatus.mainMenu

    form.clear()

    inavsuite.app.lastIdx = idx
    inavsuite.app.lastTitle = title
    inavsuite.app.lastScript = script

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

    form.addLine(title)

    buttonW = 100
    local x = windowWidth - buttonW - 10

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

            if  inavsuite.app.lastMenu == nil then
                inavsuite.app.ui.openMainMenu()
            else
                inavsuite.app.ui.openMainMenuSub(inavsuite.app.lastMenu)
            end
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


    if inavsuite.app.gfx_buttons["escmain"] == nil then inavsuite.app.gfx_buttons["escmain"] = {} end
    if inavsuite.preferences.menulastselected["escmain"] == nil then inavsuite.preferences.menulastselected["escmain"] = 1 end


    local ESCMenu = assert(inavsuite.compiler.loadfile("app/modules/" .. script))()
    local pages = findMFG()
    local lc = 0
    local bx = 0



    for pidx, pvalue in ipairs(pages) do

        if lc == 0 then
            if inavsuite.preferences.general.iconsize == 0 then y = form.height() + inavsuite.app.radio.buttonPaddingSmall end
            if inavsuite.preferences.general.iconsize == 1 then y = form.height() + inavsuite.app.radio.buttonPaddingSmall end
            if inavsuite.preferences.general.iconsize == 2 then y = form.height() + inavsuite.app.radio.buttonPadding end
        end

        if lc >= 0 then bx = (buttonW + padding) * lc end

        if inavsuite.preferences.general.iconsize ~= 0 then
            if inavsuite.app.gfx_buttons["escmain"][pidx] == nil then inavsuite.app.gfx_buttons["escmain"][pidx] = lcd.loadMask("app/modules/esc_tools/mfg/" .. pvalue.folder .. "/" .. pvalue.image) end
        else
            inavsuite.app.gfx_buttons["escmain"][pidx] = nil
        end

        inavsuite.app.formFields[pidx] = form.addButton(line, {x = bx, y = y, w = buttonW, h = buttonH}, {
            text = pvalue.toolName,
            icon = inavsuite.app.gfx_buttons["escmain"][pidx],
            options = FONT_S,
            paint = function()
            end,
            press = function()
                inavsuite.preferences.menulastselected["escmain"] = pidx
                inavsuite.app.ui.progressDisplay()
                inavsuite.app.ui.openPage(pidx, pvalue.folder, "esc_tools/esc_tool.lua")
            end
        })

        if pvalue.disabled == true then inavsuite.app.formFields[pidx]:enable(false) end

        if inavsuite.preferences.menulastselected["escmain"] == pidx then inavsuite.app.formFields[pidx]:focus() end

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
