local i18n = inavsuite.i18n.get

-- Local config table for in-memory edits
local config = {}

local function sensorNameMap(sensorList)
    local nameMap = {}
    for _, sensor in ipairs(sensorList) do
        nameMap[sensor.key] = sensor.name
    end
    return nameMap
end

local function openPage(pageIdx, title, script)
    enableWakeup = true
    if not inavsuite.app.navButtons then inavsuite.app.navButtons = {} end
    inavsuite.app.triggers.closeProgressLoader = true
    form.clear()

    inavsuite.app.lastIdx    = pageIdx
    inavsuite.app.lastTitle  = title
    inavsuite.app.lastScript = script

    inavsuite.app.ui.fieldHeader(
        i18n("app.modules.settings.name") .. " / " .. i18n("app.modules.settings.audio") .. " / " .. i18n("app.modules.settings.txt_audio_switches")
    )
    inavsuite.app.formLineCnt = 0

    local formFieldCount = 0

    local function sortSensorListByName(sensorList)
        table.sort(sensorList, function(a, b)
            return a.name:lower() < b.name:lower()
        end)
        return sensorList
    end

    local sensorList = sortSensorListByName(inavsuite.tasks.telemetry.listSwitchSensors())

    -- Prepare working config as a shallow copy of switches preferences
    local saved = inavsuite.preferences.switches or {}
    for k, v in pairs(saved) do
        config[k] = v
    end

    for i, v in ipairs(sensorList) do
        formFieldCount = formFieldCount + 1
        inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
        inavsuite.app.formLines[inavsuite.app.formLineCnt] = form.addLine(v.name or "unknown")

        inavsuite.app.formFields[formFieldCount] = form.addSwitchField(
            inavsuite.app.formLines[inavsuite.app.formLineCnt],
            nil,
            function()
                local value = config[v.key]
                if value then
                    local scategory, smember = value:match("([^,]+),([^,]+)")
                    if scategory and smember then
                        local source = system.getSource({ category = tonumber(scategory), member = tonumber(smember) })
                        return source
                    end
                end
                return nil
            end,
            function(newValue)
                if newValue then
                    local cat_member = newValue:category() .. "," .. newValue:member()
                    config[v.key] = cat_member
                else
                    config[v.key] = nil
                end
            end
        )
    end

    -- Always enable all fields and Save
    for i, field in ipairs(inavsuite.app.formFields) do
        if field and field.enable then field:enable(true) end
    end
    inavsuite.app.navButtons.save = true
end

local function onNavMenu()
    inavsuite.app.ui.progressDisplay(nil,nil,true)
    inavsuite.app.ui.openPage(
        pageIdx,
        i18n("app.modules.settings.name"),
        "settings/tools/audio.lua"
    )
end

local function onSaveMenu()
    local buttons = {
        {
            label  = i18n("app.btn_ok_long"),
            action = function()
                local msg = i18n("app.modules.profile_select.save_prompt_local")
                inavsuite.app.ui.progressDisplaySave(msg:gsub("%?$", "."))
                for key, value in pairs(config) do
                    inavsuite.preferences.switches[key] = value
                end
                inavsuite.ini.save_ini_file(
                    "SCRIPTS:/" .. inavsuite.config.preferences .. "/preferences.ini",
                    inavsuite.preferences
                )
                inavsuite.tasks.events.switches.resetSwitchStates()
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

local function event(widget, category, value, x, y)
    -- if close event detected go to section home page
    if category == EVT_CLOSE and value == 0 or value == 35 then
        inavsuite.app.ui.openPage(
            pageIdx,
            i18n("app.modules.settings.name"),
            "settings/tools/audio.lua"
        )
        return true
    end
end

return {
    event      = event,
    openPage   = openPage,
    onNavMenu  = onNavMenu,
    onSaveMenu = onSaveMenu,
    navButtons = {
        menu   = true,
        save   = true,
        reload = false,
        tool   = false,
        help   = false,
    },
    API = {},
}
