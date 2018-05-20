dofile("credentials.lua")
-- init mqtt client without logins, keepalive timer 120s
m = mqtt.Client("relay001", 120, MQTT_USER, MQTT_PASS)
m:lwt("/lwt", "offline", 0, 0)

led_pin = 4
relay_pin = 1
gpio.mode(led_pin,gpio.OUTPUT)
gpio.mode(relay_pin,gpio.OUTPUT)

local function send_switch_state()
    m:publish("switch1-state", tostring(gpio.read(relay_pin)), 0, 0)
end

-- on publish message receive event
m:on("message", function(client, topic, data)
    print(topic .. ":" .. data )
    if data == "1" then
        gpio.write(led_pin,gpio.LOW)
        gpio.write(relay_pin,gpio.HIGH)
    elseif data == "0" then
        gpio.write(led_pin,gpio.HIGH)
        gpio.write(relay_pin,gpio.LOW)
    end
    send_switch_state()
end)

local reconnect_timer = tmr.create()

local function connect_mqtt()
    print ("MQTT - Connecting.....")
    m:connect(MQTT_HOST, MQTT_PORT, 1, function(client)
        print("MQTT - Connected")
        reconnect_timer:stop()
        tmr.alarm(0, 1000, 1, send_switch_state)
        client:subscribe("switch1", 0, function(client) print("MQTT - Subscribed to topic") end)
    end,
    function(client, reason)
        print("MQTT Connection Failed: " .. reason)
    end)
end
reconnect_timer:register(30000,1,connect_mqtt)

m:on("offline", function(client)
    print ("MQTT - Disconnected")
    tmr.unregister(0)
    reconnect_timer:start()
end)

connect_mqtt()
reconnect_timer:start()
