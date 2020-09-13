ota = require ( "http_ota" )
config = require ( "config" )
local M = {}
local C = {}
local topicConnect = "v1/gateway/connect"
local topicDisconnect = "v1/gateway/disconnect"
local topicRPC = "v1/gateway/rpc"
local topicAttributes = "v1/gateway/attributes"
local topicTelemetry = "v1/gateway/telemetry"
local tmrSendConnectMsg = tmr.create()
local onRPC
local onTBConnect
local onTBConnecting
local onTBDisconnect
local wifiState = 0
local mqttState = 0
local ntpState = 0

----------------- Utilities ---------------------

local function debug(_msg)
  time = rtctime.get()
  print("DEBUG[" .. time .. "][".. node.heap().. "]: " .. _msg)
end

local function getTimestampMS()
  secs = rtctime.get()
  return secs .. "000"
end

----------------- ThingsBoard Messages --------------

local function sendConnectMsg()
  if wifiState < 2 or mqttState < 2 then
    --debug("TB ERROR - Couldn't send TB Gateway connect message")
    return
  end
  local device = {device=C.MQTT.clientID}
  local deviceJSON = sjson.encoder(device)
  local payload = deviceJSON:read()
  m:publish(topicConnect, payload, 0, 0)
  debug("TB - Sent TB Gateway connect message")
end

local function confirmRPC(_id, _success)
  if wifiState < 2 or mqttState < 2 then
    --debug("TB ERROR - Couldn't send RPC confirm message")
    return
  end
  local payloadTable = {device=C.MQTT.clientID,id=_id,data={success=_success}}
  local payloadJSON = sjson.encoder(payloadTable)
  local payload =  payloadJSON:read()
  debug("TB - Sent RPC confirmation - " .. payload)
  m:publish(topicRPC, payload, 0, 0)
end

function M.sendTelemetry(payload)
  if wifiState < 2 or mqttState < 2 or ntpState < 1 then
    debug("TB ERROR - Couldn't send telemetry[wifi:" .. wifiState .. ",mqtt:" .. mqttState .. ",ntp:" .. ntpState .. "]")
    return
  end
  local payloadTable = { [C.MQTT.clientID]= {{values=payload,ts=getTimestampMS()}} }
  local payloadJSON = sjson.encoder(payloadTable)
  local payload =  payloadJSON:read()
  debug("TB - Sending telemetry - " .. payload)
  m:publish(topicTelemetry, payload, 0, 0)
end

function M.sendRPC(payload)
  if wifiState < 2 then
    --debug("TB ERROR - Couldn't send RPC confirm message")
    return
  end
  http.post(C.HTTP.url .. "/api/v1/" .. C.HTTP.token .. "/rpc",
    'Content-Type: application/json\r\n',
    payload,
    function(code, data)
      if (code < 0) then
        print("HTTP request failed")
      else
        print(code, data)
      end
    end)
end

function M.requestAttributes(_keys, _handler)
  if wifiState < 2 then
    --debug("TB ERROR - Couldn't send RPC confirm message")
    return
  end
  http.get("http://192.168.1.1:143/api/v1/DvuH0jszZBL7ty7KwyLC/attributes?" .. _keys, nil, _handler)
  debug("TB - Sent request for attributes")
end

----------------- NTP Sync----------------------------

local function handleNTPSuccess()
  ntpState = 1
  debug("TB - NTP sync complete")
end

local function handleNTPFailed()
  ntpState = 0
  debug("TB - NTP sync failed")
  -- What to do here?
  -- Presume a connection issue and reconnect everything ??
  -- Let's try once more and hopr other connection handlers will help out
  tmr.create():alarm(30000, tmr.ALARM_SINGLE, function()
    sntp.sync("pool.ntp.org", handleNTPSuccess, handleNTPFailed, true)
  end)
end

---------------- MQTT Connection ----------------------

function M.setCallbacks(_onRPC, _onTBConnect, _onTBConnecting, _onTBDisconnect)
  onRPC = _onRPC
  onTBConnect = _onTBConnect
  onTBConnecting = _onTBConnecting
  onTBDisconnect = _onTBDisconnect
end

function M.configureMQTT()

    C.MQTT.clientID = C.CORE.deviceID
    m = mqtt.Client( C.MQTT.clientID, 120, C.MQTT.user, C.MQTT.password )
    -- m:lwt( MQTT_TOPIC_BASE .. "lwt", "offline", 0, 0 )

    m:on("offline", function(client)
      if mqttState == 2 then
        onTBConnecting()
      end
      mqttState = 0
      debug ("TB - Disconnected from MQTT broker...")
      tmr.create():alarm(10000, tmr.ALARM_SINGLE, M.reconnectMQTT)
    end)

    m:on("connect",
      function(client)
        debug("TB - Connected to broker")
        mqttState = 2
        sendConnectMsg()
        tmrSendConnectMsg:alarm(15000, tmr.ALARM_AUTO, sendConnectMsg)
        client:subscribe({[topicRPC]=0,[topicAttributes]=0},
            function(m)
              debug("TB - Subscribed to RPC topic")
              debug("TB - Subscribed to Attributes topic")
              onTBConnect()
            end
        )
      end)

    m:on("message", function(client, topic, data)

      local dataDecoder = sjson.decoder()
      dataDecoder:write(data)
      payload = dataDecoder:result()
      if payload.device ~= C.MQTT.clientID then
        return
      end

      debug("TB - Incoming message - " .. topic .. "/" .. data )

      if topic == topicRPC then
        if payload.data.method == nil then
          return
        else
          debug("TB - RPC received " .. payload.data.id .. "/" .. payload.data.method .. "/" .. tostring(payload.data.params))
          if payload.data.method == "deviceRestart" then
            debug("TB - RPC reset in 5 seconds")
            tmr.create():alarm(5000, tmr.ALARM_SINGLE, node.restart)
          elseif  payload.data.method == "otaUpdate" then
            debug("TB - RPC OTA update in 5 seconds")
            tmr.create():alarm(5000, tmr.ALARM_SINGLE, M.startOTA)
          elseif payload.data.method == "configUpdatePartial" then
            debug("TB - RPC config update - partial")
            config.updatePartial("config.json", payload.data.params)
            debug("TB - Config updated - restarting")
            tmr.create():alarm(5000, tmr.ALARM_SINGLE, node.restart)
          else
           success = onRPC(payload.data)
          end
        end
        confirmRPC(payload.data.id, success)

      elseif topic == topicAttributes then
        debug("Attributes changed")
      end
    end)
end

function M.reconnectMQTT()
  if mqttState == 0 and wifiState == 2 then
    M.connectMQTT()
  end
end

function M.connectMQTT()
  mqttState = 1
  debug("TB - Connecting to broker")
  m:connect(C.MQTT.host, C.MQTT.port, false, nil,
    function(client, reason)
      mqttState = 0
      debug("TB - Connection to MQTT broker failed: " .. reason)
      tmr.create():alarm(10000, tmr.ALARM_SINGLE, M.reconnectMQTT)
  end)
end

--------------  WiFi Connection -------------------

function M.onWiFiConnect(T)
  debug("TB - Connection to AP("..T.SSID..") established!")
  debug("TB - Waiting for IP address...")
end

function M.onWiFiGotIP(T)
  wifiState = 2
  debug("TB - Connection is ready. IP address: "..T.IP)
  sntp.sync("pool.ntp.org", handleNTPSuccess, handleNTPFailed, true)
  M.connectMQTT()
end

function M.onWiFiDisconnect(T)
  mqttState = 0
  ntpState = 0
  if T.reason == wifi.eventmon.reason.ASSOC_LEAVE then
    debug("WiFi - Connection to AP("..T.SSID..") closed normally!")
    wifiState = 1
    onTBDisconnect()
    return
  else
    for key,val in pairs(wifi.eventmon.reason) do
      if val == T.reason then
          debug("WiFi - Connection to AP("..T.SSID..") failed: "..val.." - ["..key.."]")
          --only change the blink state on the first disconnect event.
          if wifiState == 2 then
            wifiState = 1
            onTBConnecting()
          end
          break
      end
    end
  end
end

function M.setConfig(_config)
  C = _config
end

function M.configureWiFi()
  wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, M.onWiFiDisconnect)
  wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, M.onWiFiConnect)
  wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, M.onWiFiGotIP)
  wifi.setmode(wifi.STATION)
  wifi.sta.config({ssid=C.WIFI.ssid,pwd=C.WIFI.password, auto=false, save=false})
end

function M.connectWiFi()
  wifiState = 1
  onTBConnecting()
  debug("TB - Connecting to WiFi access point...")
  wifi.sta.connect()
end

------------------- OTA ---------------------------

function M.startOTA()
  C.OTA.deviceType = C.CORE.deviceType
  C.OTA.version = "latest" --this could be different if called from RPC
  ota.start(C.OTA)
end

----------------- Start the Client -----------------

function M.begin()
  debug("TB - Starting client")
  M.configureWiFi()
  M.configureMQTT()
  M.connectWiFi()
end

return M
