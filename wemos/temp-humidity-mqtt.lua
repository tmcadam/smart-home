dofile("credentials.lua")

m = mqtt.Client("dht001", 120, MQTT_USER, MQTT_PASS)
m:lwt("/lwt", "offline", 0, 0)

local function send_temp_humidity()
    pin = 4
    status, temp, humi, temp_dec, humi_dec = dht.read(pin)
    if status == dht.OK then
        -- Float firmware using this example
        m:publish("temp1", tostring(temp), 0, 0)
        m:publish("humidity1", tostring(humi), 0, 0 )
        print("Sent temp: " .. temp .. " Sent humidty: " .. humi)
    elseif status == dht.ERROR_CHECKSUM then
        print( "DHT Checksum error." )
    elseif status == dht.ERROR_TIMEOUT then
        print( "DHT timed out." )
    end
end

local reconnect_timer = tmr.create()

local function connect_mqtt()
    print ("MQTT - Connecting.....")
    m:connect(MQTT_HOST, MQTT_PORT, 1,
        function(client)
            print ("MQTT - Connected")
            reconnect_timer:stop()
            tmr.alarm(0, 1000, 1, send_temp_humidity)
        end,
        function(client, reason)
            print("MQTT - Connection Failed: " .. reason)
        end)
end

    reconnect_timer:register(30000,1,connect_mqtt)

m:on("offline",
    function(client)
        print ("MQTT - Disconnected")
        tmr.unregister(0)
        reconnect_timer:start()
    end)

connect_mqtt()
reconnect_timer:start()
