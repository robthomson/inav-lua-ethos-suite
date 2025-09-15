local settings = {}
local i18n = inavsuite.i18n.get
local function openPage(pageIdx, title, script)
    enableWakeup = true
    inavsuite.app.triggers.closeProgressLoader = true
    form.clear()

    inavsuite.app.lastIdx    = pageIdx
    inavsuite.app.lastTitle  = title
    inavsuite.app.lastScript = script

    inavsuite.app.ui.fieldHeader(
        i18n("app.modules.settings.name") .. " / " .. i18n("app.modules.settings.txt_development")
    )
    inavsuite.app.formLineCnt = 0

    local formFieldCount = 0

    settings = inavsuite.preferences.developer

formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = form.addLine(i18n("app.modules.settings.txt_devtools"))
    inavsuite.app.formFields[formFieldCount] = form.addBooleanField(inavsuite.app.formLines[inavsuite.app.formLineCnt], 
                                                        nil, 
                                                        function() 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                return settings['devtools'] 
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                settings.devtools = newValue
                                                            end    
                                                        end)    


    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = form.addLine(i18n("app.modules.settings.txt_compilation"))
    inavsuite.app.formFields[formFieldCount] = form.addBooleanField(inavsuite.app.formLines[inavsuite.app.formLineCnt], 
                                                        nil, 
                                                        function() 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                return settings['compile'] 
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                settings.compile = newValue
                                                            end    
                                                        end)                                                        

    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = form.addLine(i18n("app.modules.settings.txt_apiversion"))
    inavsuite.app.formFields[formFieldCount] = form.addChoiceField(inavsuite.app.formLines[inavsuite.app.formLineCnt], nil, 
                                                        inavsuite.utils.msp_version_array_to_indexed(),
                                                        function() 
                                                                return settings.apiversion
                                                        end, 
                                                        function(newValue) 
                                                                settings.apiversion = newValue
                                                        end) 



    local logpanel = form.addExpansionPanel(i18n("app.modules.settings.txt_logging"))
    logpanel:open(false) 

    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = logpanel:addLine(i18n("app.modules.settings.txt_loglocation"))
    inavsuite.app.formFields[formFieldCount] = form.addChoiceField(inavsuite.app.formLines[inavsuite.app.formLineCnt], nil, 
                                                        {{i18n("app.modules.settings.txt_console"), 0}, {i18n("app.modules.settings.txt_consolefile"), 1}}, 
                                                        function() 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                if inavsuite.preferences.developer.logtofile  == false then
                                                                    return 0
                                                                else
                                                                    return 1
                                                                end   
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                local value
                                                                if newValue == 0 then
                                                                    value = false
                                                                else    
                                                                    value = true
                                                                end    
                                                                settings.logtofile = value
                                                            end    
                                                        end) 

    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = logpanel:addLine(i18n("app.modules.settings.txt_loglevel"))
    inavsuite.app.formFields[formFieldCount] = form.addChoiceField(inavsuite.app.formLines[inavsuite.app.formLineCnt], nil, 
                                                        {{i18n("app.modules.settings.txt_off"), 0}, {i18n("app.modules.settings.txt_info"), 1}, {i18n("app.modules.settings.txt_debug"), 2}}, 
                                                        function() 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                if settings['loglevel']  == "off" then
                                                                    return 0
                                                                elseif settings['loglevel']  == "info" then
                                                                    return 1
                                                                else
                                                                    return 2
                                                                end   
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                local value
                                                                if newValue == 0 then
                                                                    value = "off"
                                                                elseif newValue == 1 then
                                                                    value = "info"
                                                                else
                                                                    value = "debug"
                                                                end    
                                                                settings['loglevel'] = value 
                                                            end    
                                                        end) 
 
    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = logpanel:addLine(i18n("app.modules.settings.txt_mspdata"))
    inavsuite.app.formFields[formFieldCount] = form.addBooleanField(inavsuite.app.formLines[inavsuite.app.formLineCnt], 
                                                        nil, 
                                                        function() 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                return settings['logmsp'] 
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                settings.logmsp = newValue
                                                            end    
                                                        end)     

    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = logpanel:addLine(i18n("app.modules.settings.txt_queuesize"))
    inavsuite.app.formFields[formFieldCount] = form.addBooleanField(inavsuite.app.formLines[inavsuite.app.formLineCnt], 
                                                        nil, 
                                                        function() 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                return settings['logmspQueue'] 
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                settings.logmspQueue = newValue
                                                            end    
                                                        end)                                                             

    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = logpanel:addLine(i18n("app.modules.settings.txt_memusage"))
    inavsuite.app.formFields[formFieldCount] = form.addBooleanField(inavsuite.app.formLines[inavsuite.app.formLineCnt], 
                                                        nil, 
                                                        function() 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                return settings['memstats'] 
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                settings.memstats = newValue
                                                            end    
                                                        end)  

    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = logpanel:addLine(i18n("app.modules.settings.txt_taskprofiler"))
    inavsuite.app.formFields[formFieldCount] = form.addBooleanField(inavsuite.app.formLines[inavsuite.app.formLineCnt], 
                                                        nil, 
                                                        function() 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                return settings['taskprofiler'] 
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                settings.taskprofiler = newValue
                                                            end    
                                                        end)       
                                                        
    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = logpanel:addLine(i18n("app.modules.settings.txt_objectprofiler"))
    inavsuite.app.formFields[formFieldCount] = form.addBooleanField(inavsuite.app.formLines[inavsuite.app.formLineCnt], 
                                                        nil, 
                                                        function() 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                return settings['logobjprof'] 
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                settings.logobjprof = newValue
                                                            end    
                                                        end)                                                            


    local dashboardPanel = form.addExpansionPanel(i18n("app.modules.settings.dashboard"))
    dashboardPanel:open(false)

    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = dashboardPanel:addLine(i18n("app.modules.settings.txt_overlaygrid"))
    inavsuite.app.formFields[formFieldCount] = form.addBooleanField(inavsuite.app.formLines[inavsuite.app.formLineCnt], 
                                                        nil, 
                                                        function() 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                return settings['overlaygrid'] 
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                settings.overlaygrid = newValue
                                                            end    
                                                        end)       

    formFieldCount = formFieldCount + 1
    inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1
    inavsuite.app.formLines[inavsuite.app.formLineCnt] = dashboardPanel:addLine(i18n("app.modules.settings.txt_overlaystats"))
    inavsuite.app.formFields[formFieldCount] = form.addBooleanField(inavsuite.app.formLines[inavsuite.app.formLineCnt], 
                                                        nil, 
                                                        function() 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                return settings['overlaystats'] 
                                                            end
                                                        end, 
                                                        function(newValue) 
                                                            if inavsuite.preferences and inavsuite.preferences.developer then
                                                                settings.overlaystats = newValue
                                                            end    
                                                        end)   

    
end

local function onNavMenu()
    inavsuite.app.ui.progressDisplay(nil,nil,true)
    inavsuite.app.ui.openPage(
        pageIdx,
        i18n("app.modules.settings.name"),
        "settings/settings.lua"
    )
end

local function onSaveMenu()
    local buttons = {
        {
            label  = i18n("app.btn_ok_long"),
            action = function()
                local msg = i18n("app.modules.profile_select.save_prompt_local")
                inavsuite.app.ui.progressDisplaySave(msg:gsub("%?$", "."))
                for key, value in pairs(settings) do
                    inavsuite.preferences.developer[key] = value
                end
                inavsuite.ini.save_ini_file(
                    "SCRIPTS:/" .. inavsuite.config.preferences .. "/preferences.ini",
                    inavsuite.preferences
                )
                
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
            "settings/settings.lua"
        )
        return true
    end
end

return {
    event      = event,
    openPage   = openPage,
    wakeup     = wakeup,
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
