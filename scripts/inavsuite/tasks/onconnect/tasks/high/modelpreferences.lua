--[[
 * Copyright (C) Rotorflight Project
 *
 *
 * License GPLv3: https://www.gnu.org/licenses/gpl-3.0.en.html
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 
 * Note.  Some icons have been sourced from https://www.flaticon.com/
 * 
]] --

local modelpreferences = {}

local modelpref_defaults ={
    dashboard = {
        theme_preflight = "nil",
        theme_inflight = "nil",
        theme_postflight = "nil",
    },
    general ={
        flightcount = 0,
        totalflighttime = 0,
        lastflighttime = 0,
        batterylocalcalculation = 1,
    },
    battery = {
        sag_multiplier = 0.5,
        calc_local = 0,
        alert_type = 0,
        becalertvalue = 6.5,
        rxalertvalue = 7.5,
        flighttime = 300,
    }
}

function modelpreferences.wakeup()

    -- quick exit if no apiVersion
    if inavsuite.session.apiVersion == nil then
        inavsuite.session.modelPreferences = nil 
        return 
    end    

    --- check if we have a mcu_id
    if not inavsuite.session.mcu_id then
        inavsuite.session.modelPreferences = nil
        return
    end
  

    if (inavsuite.session.modelPreferences == nil)  then
             -- populate the model preferences variable

        if inavsuite.config.preferences and inavsuite.session.mcu_id then

            local modelpref_file = "SCRIPTS:/" .. inavsuite.config.preferences .. "/models/" .. inavsuite.session.mcu_id ..".ini"
            inavsuite.utils.log("Preferences file: " .. modelpref_file, "info")

            os.mkdir("SCRIPTS:/" .. inavsuite.config.preferences)
            os.mkdir("SCRIPTS:/" .. inavsuite.config.preferences .. "/models")


            local slave_ini = modelpref_defaults
            local master_ini  = inavsuite.ini.load_ini_file(modelpref_file) or {}


            local updated_ini = inavsuite.ini.merge_ini_tables(master_ini, slave_ini)
            inavsuite.session.modelPreferences = updated_ini
            inavsuite.session.modelPreferencesFile = modelpref_file

            if not inavsuite.ini.ini_tables_equal(master_ini, slave_ini) then
                inavsuite.ini.save_ini_file(modelpref_file, updated_ini)
            end      
                   
        end
    end

end

function modelpreferences.reset()
    inavsuite.session.modelPreferences = nil
    inavsuite.session.modelPreferencesFile = nil
end

function modelpreferences.isComplete()
    if inavsuite.session.modelPreferences ~= nil  then
        return true
    end
end

return modelpreferences