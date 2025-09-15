-- telemetry.lua (refactored to use sid.lua)

local i18n = inavsuite.i18n.get
local enableWakeup = false

local mspData = nil
local config = {}
local triggerSave = false
local configLoaded = false
local configApplied = false
local setDefaultSensors = false
local PREV_STATE = {}

----------------------------------------------------------------------
-- Load the shared sensor definitions (sid.lua)
-- Expects sid.lua to 'return sensorList' (table keyed by numeric ID)
----------------------------------------------------------------------
local sensorList = inavsuite.tasks.sensors.getSid()

----------------------------------------------------------------------
-- Build TELEMETRY_SENSORS from sid.lua
-- (id, name, group) are taken directly from sensorList
-- If you prefer i18n names, add an 'i18nKey' in sid.lua entries and
-- replace 'displayName' below to use i18n(i18nKey).
----------------------------------------------------------------------
local TELEMETRY_SENSORS = {}
do
  for id, s in pairs(sensorList) do
    -- prefer i18n if you later add s.i18nKey to sid.lua
    local displayName = s.name or ("Sensor " .. tostring(id))
    TELEMETRY_SENSORS[id] = {
      name  = displayName,
      id    = id,
      group = s.group or "system",
    }
  end
end

----------------------------------------------------------------------
-- Build SENSOR_GROUPS from sid.lua groups
-- Title tries i18n("telemetry.group_"..group) else uses the group name.
-- IDs are sorted numerically for a stable UI order.
----------------------------------------------------------------------
local function buildGroups(list)
  local groups = {}
  for id, s in pairs(list) do
    local grp = s.group or "system"
    if not groups[grp] then
      -- Try internationalized title first; fallback to raw group name
      local key = "telemetry.group_" .. grp
      local title = i18n(key) or grp
      groups[grp] = { title = title, ids = {} }
    end
    table.insert(groups[grp].ids, id)
  end
  -- sort each group's IDs
  for _, g in pairs(groups) do
    table.sort(g.ids, function(a, b) return a < b end)
  end
  return groups
end

local SENSOR_GROUPS = buildGroups(sensorList)

----------------------------------------------------------------------
-- Existing rules: mutually exclusive sensors remain unchanged
----------------------------------------------------------------------
local NOT_AT_SAME_TIME = {
  [10] = {11, 12, 13, 14},  -- control
  [64] = {65, 66, 67},      -- attitude
  [68] = {69, 70, 71},      -- accel
}

----------------------------------------------------------------------
-- Optional: keep the explicit visual order. Any missing groups
-- will be appended automatically in alphabetical order below.
----------------------------------------------------------------------
local GROUP_ORDER = {
  "battery",
  "voltage",
  "current",
  "temps",
  "esc1",
  "esc2",
  "rpm",
  "barometer",
  "gyro",
  "gps",
  "status",
  "profiles",
  "control",
  "system",
  "debug",
}

-- Append any groups not explicitly listed above (once)
do
  local listed = {}
  for _, g in ipairs(GROUP_ORDER) do listed[g] = true end
  local extras = {}
  for g, _ in pairs(SENSOR_GROUPS) do
    if not listed[g] then table.insert(extras, g) end
  end
  table.sort(extras)
  for _, g in ipairs(extras) do table.insert(GROUP_ORDER, g) end
end

----------------------------------------------------------------------
-- Everything below this line is your original UI / MSP logic
----------------------------------------------------------------------

local function countEnabledSensors()
  local count = 0
  for _, v in pairs(config) do
    if v == true then
      count = count + 1
    end
  end
  return count
end

local function alertIfTooManySensors()
  local buttons = {{
    label = i18n("app.modules.profile_select.ok"),
    action = function()
      return true
    end,
  }}

  form.openDialog({
    width = nil,
    title = i18n("app.modules.telemetry.name"),
    message = i18n("app.modules.telemetry.no_more_than_40"),
    buttons = buttons,
    wakeup = function() end,
    paint = function() end,
    options = TEXT_LEFT,
  })
end

local function openPage(pidx, title, script)
  form.clear()

  -- track page
  inavsuite.app.lastIdx    = pidx
  inavsuite.app.lastTitle  = title
  inavsuite.app.lastScript = script

  -- header
  inavsuite.app.ui.fieldHeader(i18n("app.modules.telemetry.name"))

  inavsuite.app.formLineCnt = 0
  inavsuite.app.formFields = {}

  -- quick exit if running unsupported version of msp protocol
  if inavsuite.utils.apiVersionCompare("<", "12.08") then
    inavsuite.app.triggers.closeProgressLoader = true

    inavsuite.app.formLines[#inavsuite.app.formLines + 1] = form.addLine(i18n("app.modules.telemetry.invalid_version"))

    inavsuite.app.formNavigationFields["save"]:enable(false)
    inavsuite.app.formNavigationFields["reload"]:enable(false)

    return
  end

  local formFieldCount = 0

  for _, key in ipairs(GROUP_ORDER) do
    local group = SENSOR_GROUPS[key]
    if group and group.ids and #group.ids > 0 then
      local panel = form.addExpansionPanel(group.title)
      panel:open(false)
      for _, id in ipairs(group.ids) do
        local sensor = TELEMETRY_SENSORS[id]
        if sensor then
          local line = panel:addLine(sensor.name)
          formFieldCount = id -- keep index aligned with sensor ID
          inavsuite.app.formLineCnt = inavsuite.app.formLineCnt + 1

          inavsuite.app.formFields[formFieldCount] = form.addBooleanField(
            line,
            nil,
            function()
              return config[sensor.id] or false
            end,
            function(val)
              local count = countEnabledSensors()
              if count > 40 then
                alertIfTooManySensors()
                return false
              end

              if val == true and NOT_AT_SAME_TIME[sensor.id] then
                -- disable conflicting sensors
                for _, conflictId in ipairs(NOT_AT_SAME_TIME[sensor.id]) do
                  -- remember previous state
                  PREV_STATE[conflictId] = config[conflictId]

                  config[conflictId] = false
                  if inavsuite.app.formFields[conflictId] then
                    inavsuite.app.formFields[conflictId]:enable(false)
                  end
                end
              elseif val == false and NOT_AT_SAME_TIME[sensor.id] then
                -- re-enable conflicting sensors
                for _, conflictId in ipairs(NOT_AT_SAME_TIME[sensor.id]) do
                  if inavsuite.app.formFields[conflictId] then
                    inavsuite.app.formFields[conflictId]:enable(true)
                  end

                  -- restore previous state if we saved one
                  if PREV_STATE[conflictId] ~= nil then
                    config[conflictId] = PREV_STATE[conflictId]
                    PREV_STATE[conflictId] = nil -- clear after restoring
                  end
                end
              end

              config[sensor.id] = val
            end
          )
        end
      end
    end
  end

  enableWakeup = true
end

local function rebootFC()
  local RAPI = inavsuite.tasks.msp.api.load("REBOOT")
  RAPI.setUUID("123e4567-e89b-12d3-a456-426614174000")
  RAPI.setCompleteHandler(function(self)
    inavsuite.utils.log("Rebooting FC", "info")
    inavsuite.utils.onReboot()
  end)
  RAPI.write()
end

local function applySettings()
  local EAPI = inavsuite.tasks.msp.api.load("EEPROM_WRITE")
  EAPI.setUUID("550e8400-e29b-41d4-a716-446655440000")
  EAPI.setCompleteHandler(function(self)
    inavsuite.utils.log("Writing to EEPROM", "info")
    rebootFC()
  end)
  EAPI.write()
end

local function getDefaultSensors(sensorListFromApi)
  local defaultSensors = {}
  local i = 0
  for _, sensor in pairs(sensorListFromApi) do
    if sensor["mandatory"] == true and sensor["set_telemetry_sensors"] ~= nil then
      defaultSensors[i] = sensor["set_telemetry_sensors"]
      i = i + 1
    end
  end
  return defaultSensors
end

local function wakeup()
  if enableWakeup == false then return end

  -- get the current config from fbl
  if not inavsuite.app.Page.configLoaded then
    local API = inavsuite.tasks.msp.api.load("TELEMETRY_CONFIG")
    API.setCompleteHandler(function(self, buf)
      local hasData = API.readValue("telem_sensor_slot_40")
      if hasData then
        inavsuite.app.Page.mspData = API.data()
        inavsuite.app.Page.configLoaded = true
      end
    end)
    API.setUUID("a23e4567-e89b-12d3-a456-426614174001")
    API.read()
  end

  -- if we have data, populate config if empty (stop as soon as config has something in it)
  if inavsuite.app.Page and inavsuite.app.Page.configLoaded == true and inavsuite.app.Page.configApplied == false then
    local parsed = inavsuite.app.Page.mspData.parsed
    for _, value in pairs(parsed) do
      -- by default field is 'false' so only set true values
      if value ~= 0 then
        config[value] = true
      end
    end
    inavsuite.app.Page.configApplied = true
    inavsuite.app.triggers.closeProgressLoader = true
  end

  -- save?
if triggerSave == true then
  inavsuite.app.ui.progressDisplaySave(i18n("app.modules.profile_select.save_settings"))

  local selectedSensors = {}

  -- add selected sensors first
  for k, v in pairs(config) do
    if v == true then
      table.insert(selectedSensors, k)
    end
  end

  local WRITEAPI = inavsuite.tasks.msp.api.load("TELEMETRY_CONFIG")
  WRITEAPI.setUUID("123e4567-e89b-12d3-a456-426614174120")
  WRITEAPI.setCompleteHandler(function(self, buf)
    inavsuite.utils.log("Telemetry config written, now writing to EEPROM","info")
    applySettings()
  end
  )
  WRITEAPI.setErrorHandler(function(self, buf)
    inavsuite.utils.log("Write to fbl failed.","info")

  end
  )


  local buffer = inavsuite.app.Page.mspData["buffer"] -- Existing buffer
  
  local slotsStrBefore = table.concat(buffer, ",")

  local sensorIndex = 13 -- Start at byte 13 (1-based indexing)

  -- NEW: track exactly what we apply (max 40)
  local appliedSensors = {}

  -- Insert new sensors into buffer
  for _, sensor_id in ipairs(selectedSensors) do
    if sensorIndex <= 52 then -- 13 bytes + 40 sensor slots = 53 max (1-based)
      buffer[sensorIndex] = sensor_id
      table.insert(appliedSensors, sensor_id) -- NEW: mirror applied
      sensorIndex = sensorIndex + 1
    else
      break -- Stop if buffer limit is reached
    end
  end

  local slotsStrAfter = table.concat(buffer, ",")

  -- Fill remaining slots with zeros
  for i = sensorIndex, 52 do
    buffer[i] = 0
  end

  -- NEW: update session copy of applied telemetry config
  inavsuite.session = inavsuite.session or {}
  inavsuite.session.telemetryConfig = appliedSensors

  inavsuite.utils.log("Applied telemetry sensors: " .. table.concat(appliedSensors, ", "), "info")

  -- Send updated buffer
  WRITEAPI.write(buffer)

  triggerSave = false
end

if setDefaultSensors == true then
  local sensorListFromApi = getDefaultSensors(inavsuite.tasks.telemetry.listSensors())
  for _, v in pairs(sensorListFromApi) do
    config[v] = true
  end
  setDefaultSensors = false
end


  if setDefaultSensors == true then
    local sensorListFromApi = getDefaultSensors(inavsuite.tasks.telemetry.listSensors())
    for _, v in pairs(sensorListFromApi) do
      config[v] = true
    end
    setDefaultSensors = false
  end
end

local function onSaveMenu()
  local buttons = {{
    label = i18n("app.btn_ok_long"),
    action = function()
      triggerSave = true
      return true
    end,
  }, {
    label = i18n("app.modules.profile_select.cancel"),
    action = function()
      triggerSave = false
      return true
    end,
  }}

  form.openDialog({
    width = nil,
    title = i18n("app.modules.profile_select.save_settings"),
    message = i18n("app.modules.profile_select.save_prompt"),
    buttons = buttons,
    wakeup = function() end,
    paint = function() end,
    options = TEXT_LEFT,
  })

  triggerSave = false
end

local function onToolMenu(self)
  local buttons = {{
    label = inavsuite.i18n.get("app.btn_ok"),
    action = function()
      -- we push this to the background task to do its job
      setDefaultSensors = true
      return true
    end,
  }, {
    label = inavsuite.i18n.get("app.btn_cancel"),
    action = function()
      return true
    end,
  }}

  form.openDialog({
    width = nil,
    title = inavsuite.i18n.get("app.modules.telemetry.name"),
    message = inavsuite.i18n.get("app.modules.telemetry.msg_set_defaults"),
    buttons = buttons,
    wakeup = function() end,
    paint = function() end,
    options = TEXT_LEFT,
  })
end

local function mspSuccess()
  --inavsuite.utils.log("MSP operation successful", "info")
end

local function mspRetry()
  --inavsuite.utils.log("MSP operation retrying", "info")
end

local function mspTimeout()
  inavsuite.utils.log("MSP operation timed out", "info")

  -- page cant be relied on, force close
  inavsuite.app.audio.playTimeout = true
  inavsuite.app.ui.disableAllFields()
  inavsuite.app.ui.disableAllNavigationFields()
  inavsuite.app.ui.enableNavigationField('menu')
end

return {
  mspData = mspData, -- expose for other modules
  openPage = openPage,
  eepromWrite = true,
  mspSuccess = mspSuccess,
  mspRetry = mspRetry,
  mspTimeout = mspTimeout,
  onSaveMenu = onSaveMenu,
  onToolMenu = onToolMenu,
  reboot = false,
  wakeup = wakeup,
  API = {},
  configLoaded = configLoaded,
  configApplied = configApplied,
  navButtons = {
    menu   = true,
    save   = true,
    reload = true,
    tool   = true,
    help   = false,
  },
}
