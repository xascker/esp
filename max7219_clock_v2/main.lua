require("max7219")
require("x-font8x8")

local timetag = ":"
UTC_OFFSET = 0
local status_of_wifi = wifi.sta.status()

file_offset = "offset.txt"

if file.exists(file_offset) then
  if file.open("offset.txt", "r") then
     UTC_OFFSET = file.read('\n')
     file.close()
   end
end

print ("Time offset is "..UTC_OFFSET)
PrintDisplay(PrintFont8x8("clock", 4),true)

local function clock()
  local count = 1
  tmr.create():alarm(5000, tmr.ALARM_AUTO, function()
      local tm = rtctime.epoch2cal(rtctime.get() + UTC_OFFSET)
      local time = string.format("%02d%s%02d", tm["hour"], timetag, tm["min"])
      PrintDisplay(PrintFont8x8(time, 4, false , true),true) 

      count = count + 1
      if (count > 10) then
         http.get("http://192.168.5.190/", nil, function(code, data)
            if (code < 0) then
               print("HTTP request to 192.168.5.190 failed")
            else
              local t =  sjson.decode(data)
               --local t =  sjson.decode('{"place":"cockpit","bme":{"pres":998.442,"temp":22.5},"dht_out":{"humi":"56.0","temp":"26.4"},"dht_in":{"humi":"35.0","temp":"29.3"}}')
               if (t.bme.temp ~= nil and t.dht_out.temp ~= nil) then
                  --Scroll(PrintFont8x8("in" .. string.format(math.floor(t.bme.temp)) .. "out" .. string.format(math.floor(t.dht_out.temp)), 8, true),8, 1)
                  PrintDisplay(PrintFont8x8(string.format(math.floor(t.bme.temp)) .. " " .. string.format(math.floor(t.dht_out.temp)), 4, false , true),true) 
               else
                  print("Values of weather are emty")
               end   
            end 
         end)
         count = 1
      end
  end)
end

local function NTPsync(sync)
   if (sync == 1)  then
      sntp.sync(nil, function(now) 
      print ("Connect to SNTP server is successful!") 
      --PrintDisplay(PrintFont8x8("ntp )", 4, false , true),true)
      --tmr.create():alarm(5000, tmr.ALARM_SINGLE, function() print ("starting clock..."); clock() end)
      Scroll(PrintFont8x8("loading", 6, true),6, 1)
      clock()
      end, function()
      print('failed connect to SNTP server!')
      PrintDisplay(PrintFont8x8("ntp (", 4, false , true),true)
      end)
   end
end

tmr.create():alarm(5000, tmr.ALARM_SEMI, function() 
   if wifi.sta.getip()==nil then 
      print(" Wait to IP address!")
      PrintDisplay(PrintFont8x8("ip (", 4, false , true),true)
      tmr.start()
   else 
      print("New IP address is "..wifi.sta.getip()) 
      PrintDisplay(PrintFont8x8("ip )", 4, false , true),true)
      NTPsync(1)
   end
end)
