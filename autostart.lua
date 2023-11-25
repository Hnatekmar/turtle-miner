print("Loading miner in 5 seconds...")
os.sleep(5)

local request = http.get("https://raw.githubusercontent.com/Hnatekmar/turtle-miner/main/digSquare.lua")

local code = request.readAll()

local scriptFile = fs.open("miner", "w")
scriptFile.write(code)
scriptFile.flush()
scriptFile.close()

local payload = http.get("http://172.16.100.29:8000/task")

if payload == nil then
    print("Couldn't get task, rebooting...")
    os.sleep(5)
    os.reboot()
end

local position = payload.readAll()

local commaLocation = string.find(position, ",")

local x = string.sub(position, 0, commaLocation - 1)
local y = string.sub(position, commaLocation + 1, 99999)
local size = 1

-- print("X: " .. x)
-- print("Y: " .. y)

shell.run("miner", x, y, size)

print("Program finished, rebooting...")
os.sleep(5)
os.reboot()
