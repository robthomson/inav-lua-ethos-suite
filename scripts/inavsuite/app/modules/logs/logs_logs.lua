local utils = assert(inavsuite.compiler.loadfile("SCRIPTS:/" .. inavsuite.config.baseDir .. "/app/modules/logs/lib/utils.lua"))()
local i18n = inavsuite.i18n.get
local triggerOverRide = false
local triggerOverRideAll = false
local lastServoCountTime = os.clock()
local enableWakeup = false
local wakeupScheduler = os.clock()
local currentDisplayMode

local function getCleanModelName()
    local logdir
    logdir = string.gsub(model.name(), "%s+", "_")
    logdir = string.gsub(logdir, "%W", "_")
    return logdir
end


local function extractHourMinute(filename)
    -- Capture hour and minute from the time-portion (HH-MM-SS) after the underscore
    local hour, minute = filename:match(".-%d%d%d%d%-%d%d%-%d%d_(%d%d)%-(%d%d)%-%d%d")
    if hour and minute then
        return hour .. ":" .. minute
    end
    return nil
end

local function format_date(iso_date)
  local y, m, d = iso_date:match("^(%d+)%-(%d+)%-(%d+)$")
  return os.date("%d %B %Y", os.time{
    year  = tonumber(y),
    month = tonumber(m),
    day   = tonumber(d),
  })
end

local function openPage(pidx, title, script, displaymode)

    -- hard exit on error
    if not inavsuite.utils.ethosVersionAtLeast() then
        return
    end

    if not inavsuite.tasks.active() then

        local buttons = {{
            label = i18n("app.btn_ok"),
            action = function()

                inavsuite.app.triggers.exitAPP = true
                inavsuite.app.dialogs.nolinkDisplayErrorDialog = false
                return true
            end
        }}

        form.openDialog({
            width = nil,
            title = i18n("error"):gsub("^%l", string.upper),
            message = i18n("app.check_bg_task") ,
            buttons = buttons,
            wakeup = function()
            end,
            paint = function()
            end,
            options = TEXT_LEFT
        })

    end


    currentDisplayMode = displaymode

    if inavsuite.tasks.msp then
        inavsuite.tasks.msp.protocol.mspIntervalOveride = nil
    end

    inavsuite.app.triggers.isReady = false
    inavsuite.app.uiState = inavsuite.app.uiStatus.pages

    form.clear()

    inavsuite.app.lastIdx = idx
    inavsuite.app.lastTitle = title
    inavsuite.app.lastScript = script

    local w, h = lcd.getWindowSize()
    local windowWidth = w
    local windowHeight = h
    local padding = inavsuite.app.radio.buttonPadding

    local sc
    local panel

     local logDir = utils.getLogPath()

    local logs = utils.getLogs(logDir)   


    local name = utils.resolveModelName(inavsuite.session.mcu_id or inavsuite.app.activeLogDir)
    inavsuite.app.ui.fieldHeader("Logs / " .. name)

    local buttonW
    local buttonH
    local padding
    local numPerRow

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


    local x = windowWidth - buttonW + 10

    local lc = 0
    local bx = 0

    if inavsuite.app.gfx_buttons["logs_logs"] == nil then inavsuite.app.gfx_buttons["logs_logs"] = {} end
    if inavsuite.preferences.menulastselected["logs"] == nil then inavsuite.preferences.menulastselected["logs_logs"] = 1 end

    if inavsuite.app.gfx_buttons["logs"] == nil then inavsuite.app.gfx_buttons["logs"] = {} end
    if inavsuite.preferences.menulastselected["logs_logs"] == nil then inavsuite.preferences.menulastselected["logs_logs"] = 1 end

    -- Group logs by date
    local groupedLogs = {}
    for _, filename in ipairs(logs) do
        local datePart = filename:match("(%d%d%d%d%-%d%d%-%d%d)_")
        if datePart then
            groupedLogs[datePart] = groupedLogs[datePart] or {}
            table.insert(groupedLogs[datePart], filename)
        end
    end

    -- Sort dates descending
    local dates = {}
    for date,_ in pairs(groupedLogs) do table.insert(dates, date) end
    table.sort(dates, function(a,b) return a > b end)


    if #dates == 0 then

        LCD_W, LCD_H = lcd.getWindowSize()
        local str = i18n("app.modules.logs.msg_no_logs_found")
        local ew = LCD_W
        local eh = LCD_H
        local etsizeW, etsizeH = lcd.getTextSize(str)
        local eposX = ew / 2 - etsizeW / 2
        local eposY = eh / 2 - etsizeH / 2

        local posErr = {w = etsizeW, h = inavsuite.app.radio.navbuttonHeight, x = eposX, y = ePosY}

        line = form.addLine("", nil, false)
        form.addStaticText(line, posErr, str)

    else
        inavsuite.app.gfx_buttons["logs_logs"] = inavsuite.app.gfx_buttons["logs_logs"] or {}
        inavsuite.preferences.menulastselected["logs_logs"] = inavsuite.preferences.menulastselected["logs_logs"] or 1

        for idx, section in ipairs(dates) do

                form.addLine(format_date(section))
                local lc, y = 0, 0

                for pidx, page in ipairs(groupedLogs[section]) do

                            if lc == 0 then
                                y = form.height() + (inavsuite.preferences.general.iconsize == 2 and inavsuite.app.radio.buttonPadding or inavsuite.app.radio.buttonPaddingSmall)
                            end

                            local x = (buttonW + padding) * lc
                            if inavsuite.preferences.general.iconsize ~= 0 then
                                if inavsuite.app.gfx_buttons["logs_logs"][pidx] == nil then inavsuite.app.gfx_buttons["logs_logs"][pidx] = lcd.loadMask("app/modules/logs/gfx/logs.png") end
                            else
                                inavsuite.app.gfx_buttons["logs_logs"][pidx] = nil
                            end

                            inavsuite.app.formFields[pidx] = form.addButton(line, {x = x, y = y, w = buttonW, h = buttonH}, {
                                text = extractHourMinute(page),
                                icon = inavsuite.app.gfx_buttons["logs_logs"][pidx],
                                options = FONT_S,
                                paint = function() end,
                                press = function()
                                    inavsuite.preferences.menulastselected["logs_logs"] = tostring(idx) .. "_" .. tostring(pidx)
                                    inavsuite.app.ui.progressDisplay()
                                    inavsuite.app.ui.openPage(pidx, "Logs", "logs/logs_view.lua", page)                       
                                end
                            })

                            if inavsuite.preferences.menulastselected["logs_logs"] == tostring(idx) .. "_" .. tostring(pidx) then
                                inavsuite.app.formFields[pidx]:focus()
                            end

                            lc = (lc + 1) % numPerRow

                end

        end   

            
    end

    if inavsuite.tasks.msp then
        inavsuite.app.triggers.closeProgressLoader = true
    end
    enableWakeup = true

    return
end

local function event(widget, category, value, x, y)
    if  value == 35 then
        inavsuite.app.ui.openPage(inavsuite.app.lastIdx, inavsuite.app.lastTitle, "logs/logs_dir.lua")
        return true
    end
    return false
end

local function wakeup()

    if enableWakeup == true then

    end

end

local function onNavMenu()

      inavsuite.app.ui.openPage(inavsuite.app.lastIdx, inavsuite.app.lastTitle, "logs/logs_dir.lua")


end

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
    API = {},
}
