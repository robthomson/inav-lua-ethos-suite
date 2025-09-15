
local enableWakeup = false

-- Local config table for in-memory edits
local config = {}

local function openPage(pageIdx, title, script)
    enableWakeup = true
    if not inavsuite.app.navButtons then inavsuite.app.navButtons = {} end
    inavsuite.app.triggers.closeProgressLoader = true
    form.clear()

    inavsuite.app.lastIdx    = pageIdx
    inavsuite.app.lastTitle  = title
    inavsuite.app.lastScript = script

    inavsuite.app.ui.fieldHeader(
        "@i18n(app.modules.settings.name)@" .. " / " .. "@i18n(app.modules.settings.dashboard)@" .. " / " .. "@i18n(app.modules.settings.localizations)@"
    )
    inavsuite.app.formLineCnt = 0
    local formFieldCount = 0

    -- Prepare working config as a shallow copy of localizations preferences
    local saved = inavsuite.preferences.localizations or {}
    for k, v in pairs(saved) do
        config[k] = v
    end

    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = form.addLine("@i18n(app.modules.settings.temperature_unit)@")
    inavsuite.app.formFields[formFieldCount] = form.addChoiceField(
        inavsuite.app.formLines[inavsuite.app.formLineCnt],
        nil,
        {
            {"@i18n(app.modules.settings.celcius)@", 0},
            {"@i18n(app.modules.settings.fahrenheit)@", 1}
        },
        function()
            return config.temperature_unit or 0
        end,
        function(newValue)
            config.temperature_unit = newValue
        end
    )

    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = form.addLine("@i18n(app.modules.settings.altitude_unit)@")
    inavsuite.app.formFields[formFieldCount] = form.addChoiceField(
        inavsuite.app.formLines[inavsuite.app.formLineCnt],
        nil,
        {
            {"@i18n(app.modules.settings.meters)@", 0},
            {"@i18n(app.modules.settings.feet)@", 1}
        },
        function()
            return config.altitude_unit or 0
        end,
        function(newValue)
            config.altitude_unit = newValue
        end
    )

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
        "@i18n(app.modules.settings.name)@",
        "settings/settings.lua"
    )
    return true
end

local function onSaveMenu()
    local buttons = {
        {
            label  = "@i18n(app.btn_ok_long)@",
            action = function()
                local msg = "@i18n(app.modules.profile_select.save_prompt_local)@"
                inavsuite.app.ui.progressDisplaySave(msg:gsub("%?$", "."))
                for key, value in pairs(config) do
                    inavsuite.preferences.localizations[key] = value
                end
                inavsuite.ini.save_ini_file(
                    "SCRIPTS:/" .. inavsuite.config.preferences .. "/preferences.ini",
                    inavsuite.preferences
                )
                -- update dashboard theme
                inavsuite.widgets.dashboard.reload_themes()
                -- close save progress
                inavsuite.app.triggers.closeSave = true
                return true
            end,
        },
        {
            label  = "@i18n(app.modules.profile_select.cancel)@",
            action = function()
                return true
            end,
        },
    }

    form.openDialog({
        width   = nil,
        title   = "@i18n(app.modules.profile_select.save_settings)@",
        message = "@i18n(app.modules.profile_select.save_prompt_local)@",
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
            "@i18n(app.modules.settings.name)@",
            "settings/settings.lua"
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
