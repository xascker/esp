-- Close old Server
if srv then
 srv:close()
end

srv = net.createServer(net.TCP)
srv:listen(80, function(conn)
  conn:on("receive", function(client, request)
    local buf = ""
    local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP")
    if (method == nil) then
      _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP")
    end
    local _GET = {}
    if (vars ~= nil) then
      for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
        _GET[k] = v
      end
    end
    buf = buf .. "<!DOCTYPE html><html><body><h1>Clock v2.0</h1><form src=\"/\"><label>Offset <input type=\"text\" name=\"offset\"></label><input type=\"submit\" name=\"apply\" value=\"Apply\">"
    if _GET.apply  then
        if file.open("offset.txt", "w+") then
            file.write(_GET.offset)
            file.close()
        end
        UTC_OFFSET = _GET.offset
    end
    buf = buf .. "<br><br>Current offset " ..UTC_OFFSET.. "</option></select></form></body></html>"
    client:send(buf)
  end)
  conn:on("sent", function(c) c:close() end)
end)