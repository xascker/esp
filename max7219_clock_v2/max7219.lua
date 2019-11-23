-- DIN = 7  -- ESP8266 GPIO13 - MAX7219 DIN pin
-- CLK = 5  -- ESP8266 GPIO14 - MAX7219 CLK pin
local CS = 8 -- ESP8266 GPIO15 - MAX7219 CS pin 
local numberOfModules = 4

local function sendByte(module, register, data)
  spiRegister = {}
  spiData = {}
  -- set all to 0 by default
  for i=1, numberOfModules do
    spiRegister[i] = 0
    spiData[i] = 0
  end
  -- set the values for just the affected display
  spiRegister[module] = register
  spiData[module] = data
  -- enble sending data
  gpio.write(CS, gpio.LOW)
  for i=1, numberOfModules do
    spi.send(1, spiRegister[i] * 256 + spiData[i])
  end
 gpio.write(CS, gpio.HIGH)
end

local function set_MAX_Registers()  -- Initialise MAX7219 registers
   spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 16, 8)
   for i=1, numberOfModules do
      sendByte(i, 0x0b, 0x07) -- Set Scan Limit
      sendByte(i, 0x09, 0x00) -- Set Decode Mode
      sendByte(i, 0x0c, 0x01) -- Set Shut Down Mode (On)
      sendByte(i, 0x0f, 0x00) -- Set Display Test (Off)
      sendByte(i, 0x0a, 0x00) -- Set LED Brightness (0 - 15)
   end
   gpio.mode(CS, gpio.OUTPUT)
end 

local function WriteModule(module,data)
    for i=1, 8 do
        sendByte(module, i, data[i])
    end
    collectgarbage()
end

local function ClearDisplay() 
    for j=1,numberOfModules do
        for i=1,8 do
            sendByte(j, i, 0)
        end
    end
end

------- rotate fuction start -------
local function numberToTable(number, base, minLen)
  local t = {}
  repeat
    local remainder = number % base
    table.insert(t, 1, remainder)
    number = (number - remainder) / base
  until number == 0
  if #t < minLen then
    for i = 1, minLen - #t do table.insert(t, 1, 0) end
  end
  return t
end

local function rotate(char, rotateleft)
  local matrix = {}
  local newMatrix = {}

  for _, v in ipairs(char) do table.insert(matrix, numberToTable(v, 2, 8)) end

  if rotateleft then
    for i = 8, 1, -1 do
      local s = ""
      for j = 1, 8 do
        s = s .. matrix[j][i]
      end
      table.insert(newMatrix, tonumber(s, 2))
    end
  else
    for i = 1, 8 do
      local s = ""
      for j = 8, 1, -1 do
        s = s .. matrix[j][i]
      end
      table.insert(newMatrix, tonumber(s, 2))
    end
  end
  return newMatrix
end
------- rotate fuction end -------

------- scroll fuction start -------
local arr = {
{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, -- 1 matrix
{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, -- 2 matrix
{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, -- 3 matrix
{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}  -- 4 matrix
}
 
local function Shift(data)
   for  i=1,8 do  
      --Shift first module
      arr[1][i] = bit.lshift(arr[1][i] , 1)
      --Get data for first row
      if  bit.isset(data,i-1) == true then
        arr[1][i] = bit.set(arr[1][i],0)
      else
        arr[1][i] = bit.clear(arr[1][i],0)
      end
      --Shift data on each modules
      for m=numberOfModules , 1, -1 do
         --First module
         if m == 1 then
            if bit.isset(arr[m][i],8) == true then
               arr[m+1][i] = bit.set(arr[m+1][i],0)
               arr[m][i] = bit.clear(arr[m][i],8)
            end
         --Last module
         elseif m == numberOfModules then
            if bit.isset(arr[m][i],7) == true then
               arr[m][i] = bit.clear(arr[m][i],7) 
            end
            arr[m][i] = bit.lshift(arr[m][i] , 1) 
          --Other moduls
         else
            if bit.isset(arr[m][i],7) == true then
               arr[m+1][i] = bit.set(arr[m+1][i],0)
               arr[m][i] = bit.clear(arr[m][i],7)
            end
            arr[m][i] = bit.lshift(arr[m][i] , 1) 
         end
      end --Shift data on each modules
    --collectgarbage()
   end --For each row
   for m=numberOfModules , 1, -1 do
      WriteModule(m, arr[numberOfModules-m+1])
   end
end

function Scroll(char, modules, cycle)
   for j=1, cycle do
      for i=1, 8*modules do
         Shift(char[i])
         tmr.delay(50)
      end
   end
end

------- scroll fuction end -------

function PrintDisplay(data, rotation)
   for i=1,#data do
      if rotation then
         WriteModule(i,rotate(data[i],true))
      else
         WriteModule(i,data[i])
      end
   end
end

-----------------------------------------------------------

set_MAX_Registers()
ClearDisplay()
