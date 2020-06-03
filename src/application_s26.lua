require( "led" )
require( "button" )
tbClient = require ( "tb_client" )
config = require ( "config" )

local function debug(_msg)
  time = rtctime.get()
  print("DEBUG[" .. time .. "][".. node.heap().. "]: " .. _msg)
end

configFile = "config.json"
local C = config.load(configFile)
debug("APP - Config loaded")

gpio.mode(C.app.relayPin, gpio.OUTPUT)
gpio.write(C.app.relayPin, gpio.LOW)

tmrSendRelayState = tmr.create()

local statusLed = LED(C.app.ledPin, 500, C.app.ledOn)

local function setRelay(newState)
  gpio.write(C.app.relayPin, newState)
  debug("APP - Set relay - " .. newState)
  tbClient.sendTelemetry({relayState=newState})
end

local function handleButton(presses)
  if presses <= 2 then
    newState = 1 - gpio.read(C.app.relayPin)
    setRelay(newState)
  elseif presses == 4 then
    debug("APP - Starting OTA")
    statusLed:blink()
    tbClient.startOTA()
  end
end

local button = Button(C.app.buttonPin, handleButton)

local function onRPC(data)
  setRelay(data.params and 1 or 0)
  return true
end

local function sendRelayState()
  tbClient.sendTelemetry({relayState=gpio.read(C.app.relayPin)})
end

-----------------------------------------------------------------------

local function onTBConnect()
  debug("APP - Connected, changing status led to: ON")
  statusLed:on()
  sendRelayState()
  tmrSendRelayState:alarm(30000, tmr.ALARM_AUTO, sendRelayState)
end

local function onTBConnecting()
  debug("APP - Connecting, changing status led to: BLINK")
  statusLed:blink()
end

local function onTBDisconnect()
  debug("APP - Disconnected, changing status led to: OFF")
  tmrSendRelayState:unregister()
  statusLed:off()
end

-----------------------------------------------------------------------

debug("APP - Starting: " .. C.core.deviceID)
tbClient.setConfig({CORE=C.core, WIFI=C.wifi, MQTT=C.mqtt, OTA=C.ota})
tbClient.setCallbacks(onRPC, onTBConnect, onTBConnecting, onTBDisconnect)
tbClient.begin()