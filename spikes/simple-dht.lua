
function getVals()
  pin = 4
  status, temp, humi, temp_dec, humi_dec = dht.read(pin)
  if status == dht.OK then
      -- Float firmware using this example
      print("DHT Temperature:"..temp..";".."Humidity:"..humi)
  elseif status == dht.ERROR_CHECKSUM then
      print( "DHT Checksum error." )
  elseif status == dht.ERROR_TIMEOUT then
      print( "DHT timed out." )
  end
end
getVals()


-- a simple http server
srv=net.createServer(net.TCP)
srv:listen(80,function(conn) 
    conn:on("receive",function(conn,payload)
      print(payload)
      conn:send("<h1> Hello, NodeMcu.</h1>")
      end)
end)
