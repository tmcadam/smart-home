dofile("credentials.lua")
-- init mqtt client with logins, keepalive timer 120s
m = mqtt.Client("relay001", 120, MQTT_USER, MQTT_PASS)
m:lwt("/lwt", "offline", 0, 0)

led_pin = 4
relay_pin = 1
btn_pin = 3
debounce_tmr = 1
debounce_delay = 20

gpio.mode(led_pin,gpio.OUTPUT)
gpio.mode(relay_pin,gpio.OUTPUT)
gpio.write(led_pin,gpio.HIGH)
gpio.write(relay_pin,gpio.LOW)
gpio.mode(btn_pin, gpio.INPUT)

local function send_switch_state()
    m:publish("switch1-state", tostring(gpio.read(relay_pin)), 0, 0)
end

local function toggle_relay_state()
    local state = tostring(gpio.read(relay_pin))
    if  state == "0" then
        gpio.write(led_pin,gpio.LOW)
        gpio.write(relay_pin,gpio.HIGH)
    elseif state == "1" then
        gpio.write(led_pin,gpio.HIGH)
        gpio.write(relay_pin,gpio.LOW)
    end
    print("Switch pressed - "  .. state )
end

local function set_state(data)
    if data == "1" then
        gpio.write(led_pin,gpio.LOW)
        gpio.write(relay_pin,gpio.HIGH)
    elseif data == "0" then
        gpio.write(led_pin,gpio.HIGH)
        gpio.write(relay_pin,gpio.LOW)
    end
    print("Remote switch - "  .. data )
    send_switch_state()
end

local last_button_state = 1
local function button_watcher()
    button_state = gpio.read(btn_pin)
    if button_state ~= last_button_state then
        if button_state == 0 then
            print ("Button pressed")
        elseif button_state == 1 then
            toggle_relay_state()
            print ("Button released")
        end
        last_button_state = button_state
    end
end

m:on("message", function(client, topic, data)
    print("MQTT Message - " .. topic .. "/" .. data )
    set_state(data)
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
reconnect_timer:register(3000,1,connect_mqtt)

m:on("offline", function(client)
    print ("MQTT - Disconnected")
    tmr.unregister(0)
    reconnect_timer:start()
end)

connect_mqtt()
reconnect_timer:start()
tmr.alarm(debounce_tmr, debounce_delay, tmr.ALARM_AUTO, button_watcher)
