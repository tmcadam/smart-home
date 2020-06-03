local M = {}

local tOboj = tmr.create()

local function wifi_wait_ip()
  if wifi.sta.getip() then 
    tObj.unregister()
    print("wifi ready: " .. wifi.sta.getip())
    app.start()
  end 
end

local function wifi_start(aps)
  for key,value in pairs(aps) do
    if config.SSID and config.SSID[key] then
      print("wifi AP: " .. key .. ": " .. value)
      wifi.sta.config(key, config.SSID[key])
      wifi.sta.connect()
      config.SSID = nil  -- more secure and save memory
      tObj.alarm(2500, 1, wifi_wait_ip)
    end
  end
end

function module.start()
  wifi.setmode(wifi.STATION);
  wifi.sta.getap(wifi_start)
end

return module