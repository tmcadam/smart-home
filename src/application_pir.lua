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

tmrSendPirState = tmr.create()

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

local function sendPirState()
  local state = gpio.read(C.app.sensorPin)
  if state == 1 then
    state = true
  else
    state = false
  end
  tbClient.sendTelemetry({motion_detected=state})
end

local function pirInterruptHandler() 
  debug ("App - Motion detected")
  tmrSendPirState:stop()
  tmrSendPirState:start()
  tmr.create():alarm(1, tmr.ALARM_SINGLE, sendPirState)
end

-----------------------------------------------------------------------

local function onTBConnect()
  debug("APP - Connected, changing status led to: ON")
  statusLed:on()
  sendPirState()
  tmrSendPirState:alarm(30000, tmr.ALARM_AUTO, sendPirState)
  gpio.trig(C.app.sensorPin, "up", pirInterruptHandler)
end

local function onTBConnecting()
  debug("APP - Connecting, changing status led to: BLINK")
  statusLed:blink()
end

local function onTBDisconnect()
  debug("APP - Disconnected, changing status led to: OFF")
  gpio.trig(C.app.sensorPin, "none")
  tmrSendPirState:unregister()
  statusLed:off()
end

-----------------------------------------------------------------------

debug("APP - Starting: " .. C.core.deviceID)
tbClient.setConfig({CORE=C.core, WIFI=C.wifi, MQTT=C.mqtt, OTA=C.ota})
tbClient.setCallbacks(onRPC, onTBConnect, onTBConnecting, onTBDisconnect)
tbClient.begin()