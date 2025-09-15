-- Load utility functions
local utils = assert(inavsuite.compiler.loadfile("SCRIPTS:/" .. inavsuite.config.baseDir .. "/app/modules/logs/lib/utils.lua"))()

-- Wakeup control flag
local enableWakeup = false

-- Build and display the Logs directory selection page
local function openPage(idx, title, script)
    inavsuite.app.activeLogDir = nil
    if not inavsuite.utils.ethosVersionAtLeast() then return end

    -- Reset any running MSP task overrides
    if inavsuite.tasks.msp then
        inavsuite.tasks.msp.protocol.mspIntervalOveride = nil
    end

    -- Initialize page state
    inavsuite.app.triggers.isReady = false
    inavsuite.app.uiState = inavsuite.app.uiStatus.pages
    form.clear()

    inavsuite.app.lastIdx = idx
    inavsuite.app.lastTitle = title
    inavsuite.app.lastScript = script

    -- UI layout settings
    local w, h = lcd.getWindowSize()
    local prefs = inavsuite.preferences.general
    local radio = inavsuite.app.radio
    local icons = prefs.iconsize
    local padding, btnW, btnH, perRow

    if icons == 0 then
        padding = radio.buttonPaddingSmall
        btnW = (inavsuite.app.lcdWidth - padding) / radio.buttonsPerRow - padding
        btnH = radio.navbuttonHeight
        perRow = radio.buttonsPerRow
    elseif icons == 1 then
        padding = radio.buttonPaddingSmall
        btnW, btnH = radio.buttonWidthSmall, radio.buttonHeightSmall
        perRow = radio.buttonsPerRowSmall
    else -- icons == 2
        padding = radio.buttonPadding
        btnW, btnH = radio.buttonWidth, radio.buttonHeight
        perRow = radio.buttonsPerRow
    end

    inavsuite.app.ui.fieldHeader("Logs")

    local logDir = utils.getLogPath()
    local folders = utils.getLogsDir(logDir)

    -- Show message if no logs exist
    if #folders == 0 then
        local msg = "@i18n(app.modules.logs.msg_no_logs_found)@"
        local tw, th = lcd.getTextSize(msg)
        local x = w / 2 - tw / 2
        local y = h / 2 - th / 2
        form.addStaticText(nil, { x = x, y = y, w = tw, h = btnH }, msg)
    else
        -- Display buttons for each log directory
        local x, y, col = 0, form.height() + padding, 0
        inavsuite.app.gfx_buttons.logs = inavsuite.app.gfx_buttons.logs or {}

        for i, item in ipairs(folders) do
            if col >= perRow then
                col, y = 0, y + btnH + padding
            end

            local modelName = utils.resolveModelName(item.foldername)

            if icons ~= 0 then
                inavsuite.app.gfx_buttons.logs[i] = inavsuite.app.gfx_buttons.logs[i] or lcd.loadMask("app/modules/logs/gfx/folder.png")
            else
                inavsuite.app.gfx_buttons.logs[i] = nil
            end

            local btn = form.addButton(nil, {
                x = col * (btnW + padding), y = y, w = btnW, h = btnH
            }, {
                text = modelName,
                options = FONT_S,
                icon = inavsuite.app.gfx_buttons.logs[i],
                press = function()
                    inavsuite.preferences.menulastselected.logs = i
                    inavsuite.app.ui.progressDisplay()
                    inavsuite.app.activeLogDir = item.foldername
                    inavsuite.utils.log("Opening logs for: " .. item.foldername, "info")
                    inavsuite.app.ui.openPage(i, "Logs", "logs/logs_logs.lua")
                end
            })

            btn:enable(true)

            if inavsuite.preferences.menulastselected.logs_folder == i then
                btn:focus()
            end

            col = col + 1
        end
    end

    if inavsuite.tasks.msp then
        inavsuite.app.triggers.closeProgressLoader = true
    end

    enableWakeup = true
end

-- Handle form navigation or keypress events
local function event(widget, category, value)
    if value == 35 or category == 3 then
        inavsuite.app.ui.openMainMenu()
        return true
    end
    return false
end

-- Background wakeup handler (placeholder for future logic)
local function wakeup()
    if enableWakeup then
        -- Future periodic update logic
    end
end

-- Navigation menu handler
local function onNavMenu()
    inavsuite.app.ui.openMainMenu()
end

-- Module export
return {
    event = event,
    openPage = openPage,
    wakeup = wakeup,
    onNavMenu = onNavMenu,
    navButtons = {
        menu = true,
        save = false,
        reload = false,
        tool = false,
        help = true
    },
    API = {}
}
