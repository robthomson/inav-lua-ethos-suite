local activateWakeup = false
local i18n = inavsuite.i18n.get
local apidata = {
    api = {
        [1] = "PID_PROFILE",
    },
    formdata = {
        labels = {
            {t = i18n("app.modules.profile_pidbandwidth.name"), inline_size = 8.15, label = 1, type = 1},
            {t = i18n("app.modules.profile_pidbandwidth.dterm_cutoff"), inline_size = 8.15, label = 2, type = 1},
            {t = i18n("app.modules.profile_pidbandwidth.bterm_cutoff"), inline_size = 8.15, label = 3, type = 1}
        },
        fields = {
            {t = i18n("app.modules.profile_pidbandwidth.roll"), inline = 3, label = 1, mspapi = 1, apikey = "gyro_cutoff_0"},
            {t = i18n("app.modules.profile_pidbandwidth.pitch"), inline = 2, label = 1, mspapi = 1, apikey = "gyro_cutoff_1"},
            {t = i18n("app.modules.profile_pidbandwidth.yaw"), inline = 1, label = 1, mspapi = 1, apikey = "gyro_cutoff_2"},
            {t = i18n("app.modules.profile_pidbandwidth.roll"), inline = 3, label = 2, mspapi = 1, apikey = "dterm_cutoff_0"},
            {t = i18n("app.modules.profile_pidbandwidth.pitch"), inline = 2, label = 2, mspapi = 1, apikey = "dterm_cutoff_1"},
            {t = i18n("app.modules.profile_pidbandwidth.yaw"), inline = 1, label = 2, mspapi = 1, apikey = "dterm_cutoff_2"},
            {t = i18n("app.modules.profile_pidbandwidth.roll"), inline = 3, label = 3, mspapi = 1, apikey = "bterm_cutoff_0"},
            {t = i18n("app.modules.profile_pidbandwidth.pitch"), inline = 2, label = 3, mspapi = 1, apikey = "bterm_cutoff_1"},
            {t = i18n("app.modules.profile_pidbandwidth.yaw"), inline = 1, label = 3, mspapi = 1, apikey = "bterm_cutoff_2"}
        }
    }                 
}

local function postLoad(self)
    inavsuite.app.triggers.closeProgressLoader = true
    activateWakeup = true
end

local function wakeup()

    if activateWakeup and inavsuite.tasks.msp.mspQueue:isProcessed() then       
        if inavsuite.session.activeProfile then
            inavsuite.app.formFields['title']:value(inavsuite.app.Page.title .. " #" .. inavsuite.session.activeProfile)
            currentProfileChecked = true
        end
    end

end

return {
    apidata = apidata,
    title = i18n("app.modules.profile_pidbandwidth.name"),
    refreshOnProfileChange = true,
    reboot = false,
    eepromWrite = true,
    postLoad = postLoad,
    wakeup = wakeup,
    API = {},
}
