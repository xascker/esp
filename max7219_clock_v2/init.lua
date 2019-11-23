wifi.setmode(wifi.STATION)
local cfg={
   ip = "192.168.5.191",
   netmask = "255.255.255.0",
   gateway = "192.168.5.254"
}
cfg.ssid="WRT123"
cfg.pwd="passwd"
wifi.sta.config(cfg)
wifi.sta.setip(cfg)
cfg = nil
collectgarbage()

dofile("main.lua")
dofile("WebServer.lua")
