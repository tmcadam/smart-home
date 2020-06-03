require( "led" )
require( "button" )
t = require("ds18b20")
tbClient = require ( "tb_client" )
config = require ( "config" )

local function debug(_msg)
  time = rtctime.get()
  print("DEBUG[" .. time .. "][".. node.heap().. "]: " .. _msg)
end

configFile = "config.json"
local C = config.load(configFile)
debug("APP - Config loaded")

tmrSendTemperature = tmr.create()

gpio.mode(C.app.sensorPin, gpio.INT)

local statusLed = LED(C.app.ledPin, 500, C.app.ledOn)

local function handleButton(presses)
  if presses == 4 then
    debug("APP - Starting OTA")
    statusLed:blink()
    tbClient.startOTA()
  end
end

local button = Button(C.app.buttonPin, handleButton)

local function sendTemperature(tempTable)
  for addr, temp in pairs(tempTable) do
    tbClient.sendTelemetry({temperature=temp})
    break
  end
end

-----------------------------------------------------------------------

local function onTBConnect()
  debug("APP - Connected, changing status led to: ON")
  statusLed:on()
  t:read_temp(sendTemperature, C.app.sensorPin, t.C)
  tmrSendTemperature:alarm(60000, tmr.ALARM_AUTO, function() 
    t:read_temp(sendTemperature, C.app.sensorPin, t.C)
  end)
  tmr.create():alarm(10000, tmr.ALARM_SINGLE, function()
    debug("APP - Connected, changing status led to: OFF")
    statusLed:off()
  end)
end

local function onTBConnecting()
  debug("APP - Connecting, changing status led to: BLINK")
  statusLed:blink()
end

local function onTBDisconnect()
  debug("APP - Disconnected, changing status led to: OFF")
  tmrSendTemperatureState:unregister()
  statusLed:off()
end

-----------------------------------------------------------------------

debug("APP - Starting: " .. C.core.deviceID)
tbClient.setConfig({CORE=C.core, WIFI=C.wifi, MQTT=C.mqtt, OTA=C.ota})
tbClient.setCallbacks(onRPC, onTBConnect, onTBConnecting, onTBDisconnect)
tbClient.begin()