print ("Hi Tom")

-- url="https://raw.githubusercontent.com/tmcadam/smart-home/master/init.lua"
--
-- http.get(url, nil, function(code, data)
--     if (code < 0) then
--       print("HTTP request failed")
--     else
--       print(code, data)
--       if file.open("new-file.lua", "w") then
--           file.write(data)
--           file.close()
--           file.remove("init.lua")
--           file.rename("new-file.lua", "init.lua")
--           node.restart()
--       end
--     end
--   end)

function Sendfile(client, filename)
  if file.open(filename, "r") then
      local function sendChunk()
          local line = file.read(512)
          if line then
              client:send(line, sendChunk)
          else
              file.close()
              client:close()
              collectgarbage()
          end
      end
      client:send("HTTP/1.1 200 OK\r\n" ..
          "Server: NodeMCU on ESP8266\r\n" ..
          "Content-Type: text/html; charset=UTF-8\r\n\r\n", sendChunk)
  else
      client:send("HTTP/1.0 404 Not Found\r\n\r\nPage not found")
      client:close()
  end
end

wifi.sta.disconnect()
wifi.setmode(wifi.SOFTAP)
wifi.ap.config({ssid="SmartWorldBox_"..node.chipid(), auth=wifi.OPEN})
wifi.ap.setip({ ip="192.168.1.1", netmask="255.255.255.0", gateway="192.168.1.1"})

a = 0
function receive(conn, payload)
    print(payload)
    a = a + 1

    local content="<!DOCTYPE html><html><head><link rel='icon' type='image/png' href='http://nodemcu.com/favicon.png' /></head><body><h1>Hello!</h1><p>Since the start of the server " .. a .. " connections were made</p></body></html>"
    local contentLength=string.len(content)

    conn:on("sent", function(sck) sck:close() end)
    conn:send("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length:" .. contentLength .. "\r\n\r\n" .. content)
end

function connection(conn)
    conn:on("receive", receive)
end

print ("Server listening")
srv = net.createServer(net.TCP)
-- a simple http server
srv=net.createServer(net.TCP)
--srv:listen(80, connection)

srv:listen(80, function(conn)
  conn:on ("receive", function(client, request)
      print ("Request received")
      local path = string.match(request, "GET /(.+) HTTP")
      if path == "" then path = "index.htm" end
      Sendfile(client, path)
  end)
end)
