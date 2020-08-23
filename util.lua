
Util = {
	-- Read All File
	readAll = function (file)
		local f, msg = io.open(file, "r+")
		if f == nil or f == false then
			return false, "Util.readAll: Failed to loading file content\n\t"..msg
		end
		
		local content = f:read("*all")
		f:close()
		return content
	end, 

  GetFileName = function (url)
    local fname = url:match "[^\\]+$"
    return string.gsub(fname, ".crv$", "")
  end,
  
  mysplit = function  (inputstr, sep)
          if sep == nil then
                  sep = "%s"
          end
          local t={}
          for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                  table.insert(t, str)
          end
          return t
  end,

  sleep = function (s)
    local ntime = os.time() + s
    repeat until os.time() > ntime
  end,
  
  file_exists = function (name)
     local f=io.open(name,"r")
     if f~=nil then io.close(f) return true else return false end
  end
}

function Util.exec(prog, params)
  f = assert (io.popen (prog.." "..params, "r"))
  local msg=''
  for line in f:lines() do
    msg=line
    break
  end

  f:close()

  return msg
end

function Util.tempFixFileNames(path)
  local prog='"'..g_scriptpath..'\\listaarquivos.exe" "'..path..'" crv'

  local batFileName=g_scriptpath..'\\tempFixFileNames.bat'

  local batFile=io.open(batFileName, "w+")

  batFile:write(prog.."\ntimeout /T 5 /NOBREAK\n")
  batFile:close()

  os.execute('cmd /c "'..g_scriptpath..'\\tempFixFileNames.bat\"')
end

function Util.recoverFileNames(path)
  local prog='"'..g_scriptpath..'\\listaarquivos.exe" "'..path..'" crv recover keepdata'

  local batFileName=g_scriptpath..'\\tempFixFileNames.bat'

  local batFile=io.open(batFileName, "w+")

  batFile:write(prog.."\ntimeout /T 5 /NOBREAK\n")
  batFile:close()

  os.execute('cmd /c "'..g_scriptpath..'\\tempFixFileNames.bat\"')
  
  prog='"'..g_scriptpath..'\\listaarquivos.exe" "'..path..'" crv recover pdf'

  batFileName=g_scriptpath..'\\tempFixFileNames.bat'

  batFile=io.open(batFileName, "w+")

  batFile:write(prog.."\ntimeout /T 5 /NOBREAK\n")
  batFile:close()

  os.execute('cmd /c "'..g_scriptpath..'\\tempFixFileNames.bat\"')
end

function Util.copyTable(t)
  local newt= {}
  
  for k,v in pairs(t) do
    newt[k]=v
  end
  
  return newt
end

function Util.drawRect(blcoords, width, height)
  local contour = Contour(0.0)
  
  contour:AppendPoint(Point2D(blcoords.x, blcoords.y))
  blcoords.y = blcoords.y + height
  contour:LineTo(Point2D(blcoords.x, blcoords.y))
  blcoords.x = blcoords.x + width
  contour:LineTo(Point2D(blcoords.x, blcoords.y))
  blcoords.y = blcoords.y - height
  contour:LineTo(Point2D(blcoords.x, blcoords.y))
  blcoords.x = blcoords.x - width
  contour:LineTo(Point2D(blcoords.x, blcoords.y))  
  
  return contour
end

function Util.deleteAllInAlayer(layer)
  local toDel = {}
  local pos = layer:GetHeadPosition()
  local cadObj
  
  while pos ~= nil do
    cadObj, pos = layer:GetNext(pos)
    table.insert(toDel, cadObj)
  end
  
  for _, cadObj in ipairs(toDel) do
    layer:RemoveObject(cadObj)
  end
end

function Util.selectAllInAlayer(layer)
  local toDel = {}
  local pos = layer:GetHeadPosition()
  local cadObj  
  local job = VectricJob()
  local selection = job.Selection
  
  
  while pos ~= nil do
    cadObj, pos = layer:GetNext(pos)
    selection:Add(cadObj, true, false)
  end
end

return Util