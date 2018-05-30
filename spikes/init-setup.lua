-- Starts the portal to choose the wi-fi router to which we have
-- to associate

wifi.setmode(wifi.STATIONAP)
wifi.ap.config({ssid="SmartWorldBox_"..node.chipid(), auth=wifi.OPEN})
print ("Beginning wireless configuration")
enduser_setup.manual(true)
enduser_setup.start(
  function()
    print("Connected to wifi as:" .. wifi.sta.getip())
    enduser_setup.stop()
  end,
  function(err, str)
    print("enduser_setup: Err #" .. err .. ": " .. str)
  end
)
