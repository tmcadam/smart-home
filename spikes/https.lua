-- tls.cert.verify(true)
tls.cert.verify([[
-----BEGIN CERTIFICATE-----
MIIDSjCCAjKgAwIBAgIQRK+wgNajJ7qJMDmGLvhAazANBgkqhkiG9w0BAQUFADA/
MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
DkRTVCBSb290IENBIFgzMB4XDTAwMDkzMDIxMTIxOVoXDTIxMDkzMDE0MDExNVow
PzEkMCIGA1UEChMbRGlnaXRhbCBTaWduYXR1cmUgVHJ1c3QgQ28uMRcwFQYDVQQD
Ew5EU1QgUm9vdCBDQSBYMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AN+v6ZdQCINXtMxiZfaQguzH0yxrMMpb7NnDfcdAwRgUi+DoM3ZJKuM/IUmTrE4O
rz5Iy2Xu/NMhD2XSKtkyj4zl93ewEnu1lcCJo6m67XMuegwGMoOifooUMM0RoOEq
OLl5CjH9UL2AZd+3UWODyOKIYepLYYHsUmu5ouJLGiifSKOeDNoJjj4XLh7dIN9b
xiqKqy69cK3FCxolkHRyxXtqqzTWMIn/5WgTe1QLyNau7Fqckh49ZLOMxt+/yUFw
7BZy1SbsOFU5Q9D8/RhcQPGX69Wam40dutolucbY38EVAjqr2m7xPi71XAicPNaD
aeQQmxkqtilX4+U9m5/wAl0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNV
HQ8BAf8EBAMCAQYwHQYDVR0OBBYEFMSnsaR7LHH62+FLkHX/xBVghYkQMA0GCSqG
SIb3DQEBBQUAA4IBAQCjGiybFwBcqR7uKGY3Or+Dxz9LwwmglSBd49lZRNI+DT69
ikugdB/OEIKcdBodfpga3csTS7MgROSR6cz8faXbauX+5v3gTt23ADq1cEmv8uXr
AvHRAosZy5Q6XkjEGB5YGV8eAlrwDPGxrancWYaLbumR9YbK+rlmM6pZW87ipxZz
R8srzJmwN0jP41ZL9c8PDHIyh8bwRLtTcm1D9SZImlJnt1ir/md2cXjbDaJWFBM5
JDGFoqgCWjBH4d1QB7wCCZAA62RjYJsWvIjJEubSfZGL+T0yjWW06XyxV3bqxbYo
Ob8VZRzI9neWagqNdwvYkQsEjgfbKbYK7p2CNTUQ
-----END CERTIFICATE-----
]])


local function debug(_msg)
    time = rtctime.get()
    print("DEBUG[" .. time .. "][".. node.heap().. "]: " .. _msg)
  end

  local host = "firmware.smartworldbox.com"
  local dir = '/s26/'
  local image = 'lfs.img'

  local doRequest, firstRec, subsRec, finalise
  local n, total, size = 0, 0

  local function doRequest(sk, hostIP)
    if hostIP then
      local con = tls.createConnection()
      debug("OTA - Connecting to: " .. hostIP)

      -- Note that the current dev version can only accept uncompressed LFS images
      con:on("connection",function(sck)
          debug("OTA - Connected")
          local request = table.concat( {
          "GET "..dir..image.." HTTP/1.1",
          "User-Agent: ESP8266 app (linux-gnu)",
          "Accept: application/octet-stream",
          "Accept-Encoding: identity",
          "Host: "..host,
          "Connection: close",
          "", "", }, "\r\n")
          --print(request)
          debug("OTA - Requesting firmware: " .. dir..image)
          sck:send(request)
          sck:on("receive",firstRec)
        end)
        con:connect(443, "firmware.smartworldbox.com")
    end
  end

  firstRec = function (sck,rec)
    print("Hmmmmmmmmmmmmmm")
    -- Process the headers; only interested in content length
    local i      = rec:find('\r\n\r\n',1,true) or 1
    local header = rec:sub(1,i+1):lower()
    size         = tonumber(header:match('\ncontent%-length: *(%d+)\r') or 0)
    --print(rec:sub(1, i+1))
    debug("OTA - Download size: " .. size)
    if size > 0 then
      sck:on("receive",subsRec)
      file.open(image, 'w')
      subsRec(sck, rec:sub(i+4))
    else
      sck:on("receive", nil)
      sck:close()
      debug("OTA - GET failed")
    end
  end

  subsRec = function(sck,rec)
    total, n = total + #rec, n + 1
    if n % 4 == 1 then
      sck:hold()
      node.task.post(0, function() sck:unhold() end)
    end
    --uart.write(0,('%u of %u, \n'):format(total, size))
    debug("OTA - Downloaded " .. total .. " of " .. size )
    file.write(rec)
    if total == size then
      debug("OTA - Download complete")
      finalise(sck)
    end
  end

  finalise = function(sck)
    file.close()
    sck:on("receive", nil)
    sck:close()
    local s = file.stat(image)
    if (s and size == s.size) then
      --wifi.setmode(wifi.NULLMODE, false)
      collectgarbage();collectgarbage()
      node.task.post( function()
                        debug("OTA - Reloading flash")
                        debug("OTA - Restarting node")
                        node.flashreload(image)
                    end)
    else
        debug("OTA - Invalid save of image file, restarting node")
    end
    --tmr.create():alarm(3000, tmr.ALARM_SINGLE, node.restart)
  end

wifi.sta.config({ssid="#######", pwd="########"})
wifi.sta.connect(function()
    debug("OTA - WIFI Connected")
    debug("OTA - Resolving host: " .. host)
    tls.cert.verify(false)
    --http.get("https://firmware.smartworldbox.com/s26/hello.txt", nil, function (code, resp) print(code, resp) end)
    --net.dns.resolve(host, doRequest)
    srv = tls.createConnection()
    srv:on("receive", function(sck, c) print(c) end)
    srv:on("connection", function(sck, c)
    -- Wait for connection before sending.
    sck:send("GET / HTTP/1.1\r\nHost: google.com\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n")
    end)
    sck:on("receive",function() print("Hmmmm")end)
    srv:connect(443,"google.com")

end)
