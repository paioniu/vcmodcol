
-- Logger
-- By Honolua Homes Inc
-- Version 1 RC 1
-- Coded By Danilo Almeida <paioniu@gmail.com>
-- May, 2020


function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

-- Logger Object
Logger = {
	path = "c:\\",
	prefix = "log-",
	outFile=nil,
  sep="|",
  debug=false,
	
	new = function (self, L)
		L = L or {}
		setmetatable(L, self)
		self.__index = self
		
		local fileName = L.path ..  "\\"  .. L.prefix .. os.date("%m-%d-%Y") .. ".csv"
    
    local fexists = file_exists(fileName)
    local errmsg
		L.outFile, errmsg = io.open(fileName, "a+")
    if L.outFile == nil then
      return nil, "Failed to create a logger\n\t"..errmsg
    end
    
		if not fexists then
      L.outFile:write( "DATE"..self.sep.."TIME "..self.sep.." TYPE"..self.sep.."ID"..self.sep.."MESSAGE\n")
    end
    
		L:debugInfo("Logger", "Logging Initilized")
		
		return L
	end,
	
	print = function (self, type, id, msg)
		--MessageBox("["..id.."] "..msg)
		self.outFile:write( os.date("%m/%d/%Y "..self.sep.." %H:%M:%S")..self.sep..type..self.sep..id..self.sep..msg.."\n")
	end,
	
	error = function (self, id, msg)
		self:print("ERROR", id, msg)
		return nil, id..": "..msg
	end,
	
	info = function (self, id, msg)
		self:print("INFO", id, msg)
		return true
	end,
  
  close = function(self)
    self.outFile:close()
  end
}

function Logger:debugInfo(id, msg)
  if self.debug then
		self:print("DEBUG", id, msg)
  end
end

return Logger
