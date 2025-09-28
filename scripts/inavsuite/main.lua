--[[
 * Copyright (C) Inav Project
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
 *
 * Note. Some icons have been sourced from https://www.flaticon.com/
]]

-- Global namespace for the suite
inavsuite = {}
inavsuite.session = {}

-- Ensure legacy font (ethos 1.6 vs 1.7)
if not FONT_M then FONT_M = FONT_STD end

--======================
-- Configuration
--======================
local config = {
  toolName = "Inav",
  icon = lcd.loadMask("app/gfx/icon.png"),
  icon_logtool = lcd.loadMask("app/gfx/icon_logtool.png"),
  icon_unsupported = lcd.loadMask("app/gfx/unsupported.png"),
  version = { major = 2, minor = 3, revision = 0, suffix = "20250731" },
  ethosVersion = { 1, 6, 2 }, -- min supported Ethos version
  supportedMspApiVersion = { "2.05" },
  baseDir = "inavsuite",
  preferences = "inavsuite.user", -- user preferences folder location
  defaultRateProfile = 4, -- ACTUAL
  watchdogParam = 10, -- progress box timeout
}


-- Pre-format minimum version string once
config.ethosVersionString = string.format("ETHOS < V%d.%d.%d", table.unpack(config.ethosVersion))

inavsuite.config = config

-- CPU Load and Memory tracking
local performance = {
            cpuload             = 0,
            freeram             = 0,
            mainStackKB         = 0,
            ramKB               = 0,  
            luaRamKB            = 0,
            luaBitmapsRamKB     = 0,
        }

inavsuite.performance = performance


--======================
-- Preferences / INI
--======================
inavsuite.ini = assert(loadfile("lib/ini.lua"))(config) -- self-contained; never compiled

local userpref_defaults = {
  general = {
    iconsize = 2,
    syncname = false,
    gimbalsupression = 0.85,
    txbatt_type = 0,
  },
  localizations = {
    temperature_unit = 0, -- 0 = Celsius, 1 = Fahrenheit
    altitude_unit = 0, -- 0 = meters, 1 = feet
  },
  dashboard = {
    theme_preflight = "system/default",
    theme_inflight = "system/default",
    theme_postflight = "system/default",
  },
  events = {
    armflags = true,
    voltage = true,
    governor = true,
    pid_profile = true,
    rate_profile = true,
    esc_temp = false,
    escalertvalue = 90,
    smartfuel = true,
    smartfuelcallout = 0,
    smartfuelrepeats = 1,
    smartfuelhaptic = false,
    adj_v = false,
    adj_f = false,
  },
  switches = {},
  developer = {
    compile = true, -- compile the script
    devtools = false, -- show dev tools menu
    logtofile = false, -- log to file
    loglevel = "off", -- off, info, debug
    logmsp = false, -- print msp byte stream
    logobjprof = false, -- periodic print object references
    logmspQueue = false, -- periodic print the msp queue size
    memstats = false, -- periodic print memory usage
    taskprofiler = false, -- periodic print task profile
    mspexpbytes = 8,
    apiversion = 2, -- msp api version to use for simulator
    overlaystats = false, -- show cpu load in overlay
    overlaygrid = false, -- show overlay grid
    overlaystatsadmin = false
  },
  timer = {
    timeraudioenable = false,
    elapsedalertmode = 0,
    prealerton = false,
    postalerton = false,
    prealertinterval = 10,
    prealertperiod = 30,
    postalertinterval = 10,
    postalertperiod = 30,
  },
  menulastselected = {},
}

-- Build paths once
local prefs_dir = "SCRIPTS:/" .. inavsuite.config.preferences
os.mkdir(prefs_dir)
local userpref_file = prefs_dir .. "/preferences.ini"

-- Load and merge
local master_ini = inavsuite.ini.load_ini_file(userpref_file) or {}
local updated_ini = inavsuite.ini.merge_ini_tables(master_ini, userpref_defaults)
inavsuite.preferences = updated_ini

-- Save only if the merged result differs from the on-disk data
if not inavsuite.ini.ini_tables_equal(master_ini, updated_ini) then
  inavsuite.ini.save_ini_file(userpref_file, updated_ini)
end

--======================
-- Core modules
--======================
inavsuite.config.bgTaskName = inavsuite.config.toolName .. " [Background]"
inavsuite.config.bgTaskKey = "invbg"

inavsuite.compiler = assert(loadfile("lib/compile.lua"))(inavsuite.config)

inavsuite.utils = assert(inavsuite.compiler.loadfile("lib/utils.lua"))(inavsuite.config)

inavsuite.app = assert(inavsuite.compiler.loadfile("app/app.lua"))(inavsuite.config)

inavsuite.tasks = assert(inavsuite.compiler.loadfile("tasks/tasks.lua"))(inavsuite.config)

-- Flight mode & session
inavsuite.flightmode = { current = "preflight" }
inavsuite.utils.session() -- reset session state

-- Simulator hooks
inavsuite.simevent = { telemetry_state = true }

--======================
-- Public: version API
--======================
function inavsuite.version()
  local v = inavsuite.config.version
  return {
    version = string.format("%d.%d.%d-%s", v.major, v.minor, v.revision, v.suffix),
    major = v.major,
    minor = v.minor,
    revision = v.revision,
    suffix = v.suffix,
  }
end

--======================
-- Init / Registration
--======================
local function unsupported_tool()
  return {
    name = inavsuite.config.toolName,
    icon = inavsuite.config.icon_unsupported,
    create = function() end,
    wakeup = function()
      lcd.invalidate()
    end,
    paint = function()
      local w, h = lcd.getWindowSize()
      lcd.color(lcd.RGB(255, 255, 255, 1))
      lcd.font(FONT_M)
      local msg = inavsuite.config.ethosVersionString
      local tw, th = lcd.getTextSize(msg)
      lcd.drawText((w - tw) / 2, (h - th) / 2, msg)
    end,
    close = function() end,
  }
end

local function unsupported_i18n()
  return {
    name = inavsuite.config.toolName,
    icon = inavsuite.config.icon_unsupported,
    create = function() end,
    wakeup = function()
      lcd.invalidate()
    end,
    paint = function()
      local w, h = lcd.getWindowSize()
      lcd.color(lcd.RGB(255, 255, 255, 1))
      lcd.font(FONT_M)
      local msg = "i18n not compiled - download a release version"
      local tw, th = lcd.getTextSize(msg)
      lcd.drawText((w - tw) / 2, (h - th) / 2, msg)
    end,
    close = function() end,
  }
end

local function register_main_tool()
  system.registerSystemTool({
    event = inavsuite.app.event,
    name = inavsuite.config.toolName,
    icon = inavsuite.config.icon,
    create = inavsuite.app.create,
    wakeup = inavsuite.app.wakeup,
    paint = inavsuite.app.paint,
    close = inavsuite.app.close,
  })
end

local function register_bg_task()
  system.registerTask({
    name = inavsuite.config.bgTaskName,
    key = inavsuite.config.bgTaskKey,
    wakeup = inavsuite.tasks.wakeup,
    event = inavsuite.tasks.event,
    init = inavsuite.tasks.init,
    read = inavsuite.tasks.read,
    write = inavsuite.tasks.write,
  })
end

local function load_widget_cache(cachePath)
  local loadf, loadErr = inavsuite.compiler.loadfile(cachePath)
  if not loadf then
    inavsuite.utils.log("[cache] loadfile failed: " .. tostring(loadErr), "info")
    return nil
  end
  local ok, cached = pcall(loadf)
  if not ok then
    inavsuite.utils.log("[cache] execution failed: " .. tostring(cached), "info")
    return nil
  end
  if type(cached) ~= "table" then
    inavsuite.utils.log("[cache] unexpected content; rebuilding", "info")
    return nil
  end
  inavsuite.utils.log("[cache] Loaded widget list from cache", "info")
  return cached
end

local function build_widget_cache(widgetList, cacheFile)
  inavsuite.utils.createCacheFile(widgetList, cacheFile, true)
  inavsuite.utils.log("[cache] Created new widgets cache file", "info")
end

local function register_widgets(widgetList)
  inavsuite.widgets = {}
  local dupCount = {}

  for _, v in ipairs(widgetList) do
    if v.script then
      local path = "widgets/" .. v.folder .. "/" .. v.script
      local scriptModule = assert(inavsuite.compiler.loadfile(path))(config)

      local base = v.varname or v.script:gsub("%.lua$", "")
      if inavsuite.widgets[base] then
        dupCount[base] = (dupCount[base] or 0) + 1
        base = string.format("%s_dup%02d", base, dupCount[base])
      end
      inavsuite.widgets[base] = scriptModule

      system.registerWidget({
        name = v.name,
        key = v.key,
        event = scriptModule.event,
        create = scriptModule.create,
        paint = scriptModule.paint,
        wakeup = scriptModule.wakeup,
        build = scriptModule.build,
        close = scriptModule.close,
        configure = scriptModule.configure,
        read = scriptModule.read,
        write = scriptModule.write,
        persistent = scriptModule.persistent or false,
        menu = scriptModule.menu,
        title = scriptModule.title,
      })
    end
  end
end

local function init()
  local cfg = inavsuite.config

  -- Bail early if Ethos is too old
  if not inavsuite.utils.ethosVersionAtLeast() then
    system.registerSystemTool(unsupported_tool())
    return
  end

  local isCompiledCheck = "@i18n(iscompiledcheck)@"
  if isCompiledCheck ~= "true" then
    system.registerSystemTool(unsupported_i18n())
  else
    register_main_tool()
  end

    register_bg_task()

  -- Widgets: try cache, else rebuild
  local cacheFile = "widgets.lua"
  local cachePath = "cache/" .. cacheFile
  local widgetList = load_widget_cache(cachePath)

  if not widgetList then
    widgetList = inavsuite.utils.findWidgets()
    build_widget_cache(widgetList, cacheFile)
  end

  register_widgets(widgetList)
end

return { init = init }
