
-- VCarve Gadget Object
-- Copyright 2020 Danilo Almeida. All rights reserved 
-- Version 1.0
-- Credits:
--    Programmer: 
--      Danilo Almeida, <paioniu@gmail.com>, Aug, 2020
--
-- This code is released under a Creative Commons CC-BY "Attribution" License:
-- http://creativecommons.org/licenses/by/3.0/deed.en_US
--
-- It can be used for any purpose so long as:
--    1) the copyright notice above is maintained
--    2) the web-page links above are maintained
--    3) the 'AUTHOR_NOTE' string below is maintained
--
local AUTHOR_NOTE = "-[ gadget.lua package by Danilo Almeida ]-"

--[[ Object representing the gadget ]]
local Gadget ={  
  --[[ Common data ]]
  --    [[ Gadget Name ]]
  name = 'MyGadget',
  --    [[ Main dialog dimensions ]]
  width=640,
  height=480,
  --    [[ Project Data ]]
  copyright = {
    name = 'Danilo Almeida',
    email = 'paioniu@gmail.com',
    years = {
      2020
    }
  },
  credits = {
    {
      brief = 'Programmer',
      name = 'Danilo Almeida',
      email = 'paioniu@gmail.com'
    }
  },
  version = {
    major = 1,
    minor = 0,
    release = 1
  },
  --    [[ Enable debugging messages. Turn OFF for less verbose logs ]]
  debug = true,
  
  --[[ ! Below data members should not be touched ]]
  
  --    [[ Modules to be used by gadget ]]
  MODULES = {
    loaded    = false,
    Logger    = nil,
    Json      = nil,
    Util      = nil
  },
  --    [[ Gadget settings ]]
  settings = {
    --TODO put needed setting vars
  },
  --    [[ Gadget main logger. Initialized when loading modules ]]
  log = nil,
  --    [[ Path for the file were to store settings. Auto-generated ]]
  settingsFilePath = nil,
  --    [[ The HTML for gadget UI ]]
  html = nil,
  --    [[ Where the dialog will just get data ('input') or act as a panel/toolbar ('panel') ]]
  type = 'input'
}

local INSTANCE = nil

--[[ Gadget Specific ]]

--[[ Common methods ]]
  --[[ Create/Return the unique onject instance ]]
function Gadget:getInstance(OBJ)
  if not INSTANCE then
  
    if nil == OBJ then
      error('Gadget:getInstance: Missing initialization table')
    end
    
    if nil == OBJ.scriptPath then
      error('Gadget:getInstance: Missing scriptPath param')
    end
    
    if nil == OBJ.uiGenerator or type(OBJ.uiGenerator) ~= 'function' then
      error('Gadget:getInstance: Missing uiGenerator param or uiGenerator is not a function')
    end
    
    if nil == OBJ.uiFieldSetter or type(OBJ.uiFieldSetter) ~= 'function' then
      error('Gadget:getInstance: Missing uiFieldSetter param or uiFieldSetter is not a function')
    end
    
    if nil == OBJ.job then
      error('Gadget:getInstance: Missing Job')
    end
    
    if nil == OBJ.name then
      error('Gadget:getInstance: Missing name')
    end
    
    if nil == OBJ.title then
      OBJ.title = OBJ.name
    end
    
    if nil == OBJ.windowTitle then
      OBJ.windowTitle = OBJ.name
    end
    
    setmetatable(OBJ, self)
    self.__index = self
        
    OBJ.settingsFilePath = OBJ.scriptPath..'\\settings.json'
        
    INSTANCE = OBJ
  end
  
  return INSTANCE
end

function Gadget:getVersionAsString()
  if not self.versionAsString then
    self.versionAsString = tostring(self.version.major)..'.'..tostring(self.version.minor)..'.'..tostring(self.version.release)
  end
  
  return self.versionAsString
end

function Gadget:getCreditsAsString()
  if not self.creditsAsString then
    self.creditsAsString = ''
    for _, entry in ipairs(self.credits) do
      self.creditsAsString = self.creditsAsString .. entry.brief .. '\n\t' .. entry.name .. ' <' .. entry.email .. '>\n'
    end    
  end
  
  return self.creditsAsString
end

function Gadget:getCopyrightNoticeAsString()
  if not self.copyrightNotice then
      local years = ''
      for i=1, #self.copyright.years do
        years = years .. self.copyright.years[i]
        
        if self.copyright.years[i+1] then
          years = years .. ', '
        end        
      end
      
      self.copyrightNotice = 'Copyright '..years..' '..self.copyright.name .. '. All rights reserved'
      
      if self.copyright.email then
        self.copyrightNotice = self.copyrightNotice .. ' <' .. self.copyright.email .. '>'
      end
      
  end
  
  return self.copyrightNotice
end

--[[
  Load all needed modules
]]
function Gadget:loadModules()
  if not self.MODULES.loaded then    
    -- Logger module should be loaded first in order for all other messages to be recorded
    self.MODULES.Logger = dofile(self.scriptPath.."\\modules\\vcmodcol\\logger.lua")
    if not self.MODULES.Logger then
      error("Gadget:loadModules: Failed to load Logger module")
    end
    
    -- Initialize the main logger
    local err
    self.log, err = self.MODULES.Logger:new{
      path=self.scriptPath,
      prefix="log-main-",
      debug=self.debug
    }
    
    if err then
      error("Gadget:loadModules: Failed to load create a Logger object: "..err)
    end
        
    self.log:debugInfo("Gadget:loadModules", "Loading modules")
    
    -- Load json module
    self.MODULES.Json = dofile(self.scriptPath.."\\modules\\vcmodcol\\json.lua")
    if not self.MODULES.Json then
      return self.log:error("Gadget", "Failed to load Json module")
    end
    self.log:debugInfo("Gadget:loadModules", "    -> Loaded Json Module")
    
    -- Load util module
    self.MODULES.Util = dofile(self.scriptPath.."\\modules\\vcmodcol\\util.lua")
    if not self.MODULES.Util then
      return self.log:error("Gadget:loadModules", "Failed to load Util module")
    end
    self.log:debugInfo("Gadget:loadModules", "    -> Loaded Util Module")
    
    self.MODULES.loaded = true
  else
    self.log:debugInfo("Gadget:loadModules", "Attempt to load modules when they are already loaded. Nothing has changed")
  end
  
  return true
end

--[[
  Save gadget settings
]]
function Gadget:saveSettings()
  self:selfCheck()
  self.log:debugInfo("Gadget:saveSettings", "Saving settings as json to file: "..self.settingsFilePath)
  
  local settingsAsJson = self.MODULES.Json:encode_pretty(self.settings)
  local file, err = io.open(self.settingsFilePath, "w+")  
  if err then
    return self.log:error("Gadget:saveSettings", "Failed while trying to open settings file: "..err)
  end
  file:write(settingsAsJson)
  file:close()
  
  return true
end

--[[
  Load gadget settings
]]
function Gadget:loadSettings()
  self:selfCheck()
  self.log:debugInfo("Gadget:loadSettings", "Loading settings from json file: "..self.settingsFilePath)
  
  local settingsAsJson, err = self.MODULES.Util.readAll(self.settingsFilePath)		
  if err then
    return self.log:error("Gadget:loadSettings", "Failed while trying to read settings file: "..err)
  end
  
  self.settings = self.MODULES.Json:decode(settingsAsJson)
  
  return true
end

--[[
  Do self error checking
]]
function Gadget:selfCheck()
  if not self.MODULES.loaded then
    error('Gadget:selfCheck: Modules not loaded')
  end
  if not self.settingsFilePath then
    error('Gadget:selfCheck: Missing path for settings file')
  end
  if not self.uiGenerator then
    error('Gadget:selfCheck: Missing UI generator')
  end
  if not self.uiFieldSetter then
    error('Gadget:selfCheck: Missing UI field setter')
  end
  if not self.type then
    error('Gadget:selfCheck: Missing type')
  end
  if self.type ~= 'input' and self.type ~= 'panel' then
    error('Gadget:selfCheck: Wrong type. Should be "input" or "panel"')
  end
end

--[[
  Generate a Custom Html UI for gadget
]]
function Gadget:generateUI(uiGenerator)
  self:selfCheck()
  self.log:debugInfo("Gadget:setUIGenerator", "Generating UI HTML code")
  
  local err
  self.html, err = uiGenerator(self)
  if err then
    local msg  = 'UI Generator reported error: '..err
    return self.log:error('Gadget:setUIGenerator', msg)
  end
  
  return true
end

function Gadget:run()
  self:selfCheck()
  self.log:debugInfo("Gadget:run", "Running gadget")
  
  -- Load settings
  local res
  res, err = self:loadSettings()
  if err then
    local msg  = 'Could not load settings'..err
    return self.log:error('Gadget:run', msg)
  end
  
  -- Generate HTML for main dialog
  local err
  self.html, err = self.uiGenerator(self)
  if err then
    local msg  = 'UI Generator reported error: '..err
    return self.log:error('Gadget:run', msg)
  end
  
  -- Create the main dialog  
  self.mainDialog = HTML_Dialog(false, self.html, self.width, self.height, self.windowTitle)
  
  -- Do first time configuration
  if self.settings.firstTime then
    if self.firstTimeConfiguration and type(self.firstTimeConfiguration) == 'function' then
      res, err = self.firstTimeConfiguration(self)
      if err then
        local msg  = 'Could not make first time configuration: '..err
        --TODO Check if the user want to retry make first time configuration
        self.log:debugInfo('Gadget:run **TODO**', 'Check if the user want to retry make first time configuration')
        return self.log:error('Gadget:run', msg)
      end
      self.log:debugInfo('Gadget:run', 'First time configuration was done')
      self.settings.firstTime = false
    end
  end
  
  -- Set UI fields 
  self.uiFieldSetter(self)
  
  if self.type == 'input' then
    -- Shows the dialog to collect data
    if self.mainDialog:ShowDialog() then
      res, err = self.inputGetter(self)
      if err then
        local msg = 'Failed getting user input: '..err
        MessageBox(msg)
        return self.log:error('Gadget:run', msg)
      end

      res, err = self.dataProcessor(self)
      if err then
        local msg = 'Processing failed: '..err
        MessageBox(msg)
        return self.log:error('Gadget:run', msg)
      end
      
      res, err = self:saveSettings()
      if err then
        local msg  = 'Could not save settings'..err
        --TODO Check if the user want to retry saving settings
        self.log:debugInfo('Gadget:run **TODO**', 'Check if the user want to retry saving settings')
        return self.log:error('Gadget:run', msg)
      end
    else
        self.log:debugInfo('Gadget:run', 'User canceled')
    end
  elseif self.type == 'panel' then
    self.mainDialog:ShowDialog()

    res, err = self.inputGetter(self)
    if err then
      local msg = 'Failed getting user input: '..err
      MessageBox(msg)
      return self.log:error('Gadget:run', msg)
    end
    
    res, err = self:saveSettings()
    if err then
      local msg  = 'Could not save settings'..err
      --TODO Check if the user want to retry saving settings
      self.log:debugInfo('Gadget:run **TODO**', 'Check if the user want to retry saving settings')
      return self.log:error('Gadget:run', msg)
    end
  end
  
  return true
end

--[[ TESTS ]] --[[
print('Version: '..Gadget:getVersionAsString())

print('Credits:\n'..Gadget:getCreditsAsString())

print(Gadget:getCopyrightNoticeAsString())

local mygadget = Gadget:getInstance{
    scriptPath = 'C:\\Users\\Public\\Documents\\Vectric Files\\Gadgets\\VCarve Pro V10.0\\ELKUM_Gadget',
    debug=true
  }

mygadget:loadModules()
Gadget:getInstance():loadModules()

local mygadget = Gadget:getInstance{
    scriptPath = 'C:\\Users\\Public\\Documents\\Vectric Files\\Gadgets\\VCarve Pro V10.0\\ELKUM_Gadget',
    debug=true
  }

mygadget:loadModules()

mygadget:loadSettings()
]]

return Gadget
