-- Desc: Dig straight down a given distance, when interesting blocks are found, dig to the sides limited by the given size

local tArgs = { ... }

-- Size of the square to dig
local reachSize = 0

-- Used to calculate max fuel needed to dig a square of a given size
-- 64 blocks to reach 0 and 64 to reach -64 (bedrock)
local maxDepth = 64 * 2

-- Current position
local x,y,z = 0,0,0
-- Current direction
local xDir, zDir = 0,1

-- Target position
local tx, tz = tonumber(tArgs[1]), tonumber(tArgs[2])

-- Standby location with fuel, unload chest and blocklist chest
local unloadX, unloadZ, unloadXDir, unloadZDir = 0, 0, 0, -1
local fuelX, fuelZ, fuelXDir, fuelZDir = 0, 0, 1, 0
local blacklistX, blacklistZ, blacklistXDir, blacklistZDir = 0, 0, -1, 0

-- List of items to ignore when searching for items to collect
local searchItemsBlacklist = {}


-- Check if the turtle has any free slots left
local function canCollect()	
    local bFull = true
    for n=1,16 do
        local nCount = turtle.getItemCount(n)
        if nCount == 0 then
            bFull = false
        end
    end

    if bFull then
        print( "No empty slots left." )
        return false
    end
    return true
end

-- Try moving forward, if there is a block in the way, dig it
local function tryForwards()
    while not turtle.forward() do
        if turtle.detect() then
            if not turtle.dig() then
                return false
            end
        elseif not turtle.attack() then
            sleep(0.1)
        end
    end

    x = x + xDir
    z = z + zDir
    return true
end

-- Try moving down, if there is a block in the way, dig it
local function tryDown()
    while not turtle.down() do
        if turtle.detectDown() then
            if not turtle.digDown() then
                return false
            end
        elseif not turtle.attackDown() then
            sleep(0.1)
        end
    end

    y = y + 1
    return true
end

-- Turn left and update the direction
local function turnLeft()
    turtle.turnLeft()
    xDir, zDir = -zDir, xDir
end

-- Turn right and update the direction
local function turnRight()
    turtle.turnRight()
    xDir, zDir = zDir, -xDir
end

-- Move to the given position and direction
function goTo(tx, ty, tz, txd, tzd)
    while y > ty do
        if turtle.up() then
            y = y - 1
        elseif not (turtle.digUp() or turtle.attackUp()) then
            sleep(0.1)
        end
    end

    if x > tx then
        while xDir ~= -1 do
            turnLeft()
        end
        while x > tx do
            if turtle.forward() then
                x = x - 1
            elseif not (turtle.dig() or turtle.attack()) then
                sleep(0.1)
            end
        end
    end

    if z > tz then
        while zDir ~= -1 do
            turnLeft()
        end
        while z > tz do
            if turtle.forward() then
                z = z - 1
            elseif not (turtle.dig() or turtle.attack()) then
                sleep(0.1)
            end
        end
    elseif z < tz then
        while zDir ~= 1 do
            turnLeft()
        end
        while z < tz do
            if turtle.forward() then
                z = z + 1
            elseif not (turtle.dig() or turtle.attack()) then
                sleep(0.1)
            end
        end
    end

    if x < tx then
        while xDir ~= 1 do
            turnLeft()
        end
        while x < tx do
            if turtle.forward() then
                x = x + 1
            elseif not (turtle.dig() or turtle.attack()) then
                sleep(0.1)
            end
        end
    end

    while y < ty do
        if turtle.down() then
            y = y + 1
        elseif not (turtle.digDown() or turtle.attackDown()) then
            sleep(0.1)
        end
    end

    while zDir ~= tzd or xDir ~= txd do
        turnLeft()
    end
end

-- Fill the list of items to ignore when searching for items to collect
-- with the items from the crate in front of the turtle
local function fillSearchItemsBlacklist()
    for n=1,16 do
        turtle.select(n)
        turtle.suck()
    end

    for n=1,16 do
        turtle.select(n)
        local item = turtle.getItemDetail()
        if item then
            print("Ignoring " .. item.name)
            searchItemsBlacklist[item.name] = true
        end
        turtle.drop()
    end
end

-- Calculate the max fuel needed to dig a square of a given size
local function calculateMaxFuelNeeded()
    local floorMoves = 1
    if reachSize >= 1 then
        floorMoves = 5
        l = 1
        for i=1,reachSize-1 do
            l = l * 3
            floorMoves = floorMoves + l * 4
        end
    end
    local tripDown = (maxDepth * floorMoves)
    local tripUp = (maxDepth * floorMoves) + 1 -- +1 to get one block above the surface when returning
    local tripToTarget = tx + tz
    local tripBack = tx + tz + 1 -- +1 to get back from one block above the surface when returning
    return tripDown + tripUp + tripToTarget + tripBack
end

-- Drop all items in the chest in front of the turtle
local function unload()
    print("Unloading items...")
    for n=1,16 do
        turtle.select(n)
        turtle.drop()
    end
    turtle.select(1)
end

-- Refuel the turtle from the chest in front of it
local function refuel()
    print("Refueling...")
    local neededFuel = calculateMaxFuelNeeded()
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel == "unlimited" or fuelLevel >= neededFuel then
        return true
    end

    turtle.select(1)
    while turtle.getFuelLevel() < neededFuel do
        if not turtle.suck() then
            print("No fuel available")
            while turtle.getFuelLevel() < neededFuel and not turtle.suck() do
                sleep(0.1)
            end
        end
        if not turtle.refuel() then
            print("Refueling failed, waiting for fuel to become available in slot 1")
            while turtle.getFuelLevel() < neededFuel and not turtle.refuel() do
                sleep(0.1)
            end
        end
        turtle.drop()
    end
end

-- Finish quest by returning home (to the starting position)
local function returnToHome()
    print("Returning to unload items...")
    if y < 0 then
        -- Return to the middle of the square
        goTo(tx, y, tz, xDir, zDir)
    end

    -- Return to the surface
    goTo(tx, -1, tz, xDir, zDir)

    -- Return to the starting position one block above the surface
    goTo(unloadX, -1, unloadZ, unloadXDir, unloadZDir)
    -- Descend to the starting position
    goTo(unloadX, 0, unloadZ, unloadXDir, unloadZDir)
end

-- Dig to the sides
local function digSides(distanceFromTarget)
    if not canCollect() then
        -- Skip digging to the sides if the inventory is full
        return
    end

    for i=1,4 do
        local success, item = turtle.inspect()
        if success then
            print("Found " .. item.name)
            if not searchItemsBlacklist[item.name] then
                print("Collecting " .. item.name)
                if distanceFromTarget < reachSize then
                    -- Recursively dig to the side
                    if tryForwards() then
                        digSides(distanceFromTarget + 1)

                        -- Return back to the original position and direction
                        turnLeft()
                        turnLeft()
                        if not tryForwards() then
                            print("Something is blocking the way back")
                            while not tryForwards() do
                                sleep(0.1)
                            end
                        end
                        turnLeft()
                        turnLeft()
                    end
                else
                    turtle.dig()
                end
            else
                print("Ignoring " .. item.name)
            end
        end

        turnLeft()
    end
end

-- Main loop for digging the square
local function digSquare()
    -- Dig down
    while y < maxDepth do
        if not canCollect() then
            return
        end
        if not tryDown() then
            print("Can't dig down")
            return
        end

        -- Dig to the sides
        digSides(0)
    end
end


-- Main program
print("Digging square " .. tx .. ", " .. tz .. "...")

-- Load blacklist
goTo(blacklistX, 0, blacklistZ, blacklistXDir, blacklistZDir)
fillSearchItemsBlacklist()

-- Unload items and refuel
goTo(unloadX, 0, unloadZ, unloadXDir, unloadZDir)
unload()
goTo(fuelX, 0, fuelZ, fuelXDir, fuelZDir)
refuel()

-- Move to target position
goTo(tx, 0, tz, xDir, zDir)

-- Dig down
digSquare()

-- Return to the starting position
returnToHome()

-- Unload items
goTo(unloadX, 0, unloadZ, unloadXDir, unloadZDir)
unload()

-- Return to the starting position
goTo(0, 0, 0, 1, 0)

-- End of program
