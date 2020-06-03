local M = {}
local C = {}

local function debug(_msg)
  time = rtctime.get()
  print("DEBUG[" .. time .. "][".. node.heap().. "]: " .. _msg)
end

local doRequest, firstRec, subsRec, finalise, image, dir
local n, total, size = 0, 0

local function doRequest(sk, hostIP)
  if hostIP then
    local con = net.createConnection(net.TCP,0)
    debug("OTA - Connecting to: " .. hostIP)
    con:connect(80, hostIP)
    -- Note that the current dev version can only accept uncompressed LFS images
    con:on("connection",function(sck)
        debug("OTA - Connected")
        local request = table.concat( {
        "GET "..dir..image.." HTTP/1.1",
        "User-Agent: ESP8266 app (linux-gnu)",
        "Accept: application/octet-stream",
        "Accept-Encoding: identity",
        "Host: "..C.serverName,
        "Connection: close",
        "", "", }, "\r\n")
        --print(request)
        debug("OTA - Requesting firmware: " .. dir..image)
        sck:send(request)
        sck:on("receive",firstRec)
      end)
  end
end

firstRec = function (sck,rec)
  -- Process the headers; only interested in content length
  local i      = rec:find('\r\n\r\n',1,true) or 1
  local header = rec:sub(1,i+1):lower()
  size         = tonumber(header:match('\ncontent%-length: *(%d+)\r') or 0)
  --print(rec:sub(1, i+1))
  debug("OTA - Download size: " .. size)
  if size > 0 then
    sck:on("receive",subsRec)
    file.open(image, 'w')
    subsRec(sck, rec:sub(i+4))
  else
    sck:on("receive", nil)
    sck:close()
    debug("OTA - GET failed")
  end
end

subsRec = function(sck,rec)
  total, n = total + #rec, n + 1
  if n % 4 == 1 then
    sck:hold()
    node.task.post(0, function() sck:unhold() end)
  end
  --uart.write(0,('%u of %u, \n'):format(total, size))
  debug("OTA - Downloaded " .. total .. " of " .. size )
  file.write(rec)
  if total == size then
    debug("OTA - Download complete") 
    finalise(sck) 
  end
end

finalise = function(sck)
  file.close()
  sck:on("receive", nil)
  sck:close()
  local s = file.stat(image)
  if (s and size == s.size) then
    --wifi.setmode(wifi.NULLMODE, false)
    collectgarbage();collectgarbage()
    node.task.post( function() 
                      debug("OTA - Reloading flash")
                      debug("OTA - Restarting node")
                      file.remove("lfs.img")
                      file.rename(image, "lfs.img")
                      file.remove(image)
                      node.flashreload("lfs.img")
                  end)
  else
      debug("OTA - Invalid save of image file, restarting node")
  end
  tmr.create():alarm(5000, tmr.ALARM_SINGLE, node.restart)
end

function M.start(_config)
  C = _config
  dir = '/lfs/'
  image = C.deviceType .. "_" .. C.version .. ".img"
  debug("OTA - Resolving host: " .. C.serverName)
  net.dns.resolve(C.serverName, doRequest)
end

return M