-- utils.lua (v2.0 for CC:Tweaked 1.20.1)
-- Place this in the same folder as miner.lua, then in miner.lua call: local utils = require("utils")

local M = {}

--- Wraps the first peripheral whose type matches (or contains) `name` (case-insensitive).
function M.getPeripheralWrap(name)
  for _, side in ipairs(peripheral.getNames()) do
    local pType = peripheral.getType(side)
    if pType == name or (type(pType) == "string" and pType:lower():find(name:lower(), 1, true)) then
      return peripheral.wrap(side)
    end
  end
  return nil
end

--- Detects if this is a Chunky Turtle (AdvancedPeripherals chunky upgrade).
function M.isChunkyTurtle()
  for _, side in ipairs(peripheral.getNames()) do
    local pType = peripheral.getType(side)
    if pType and pType:lower():find("chunky", 1, true) then
      return true
    end
  end
  return false
end

--- Formats seconds as HH:MM:SS
function M.getTimeString(seconds)
  local h = math.floor(seconds / 3600)
  local m = math.floor((seconds % 3600) / 60)
  local s = seconds % 60
  return string.format("%02d:%02d:%02d", h, m, s)
end

--- Move the turtle forward by one chunk (16 blocks), facing the same direction.
function M.goOneChunk()
  turtle.turnLeft(); turtle.turnLeft(); turtle.turnLeft()
  for i = 1, 16 do turtle.forward() end
end

--- Selects the first inventory slot containing `itemName`. Leaves that slot selected.
-- @return true if found (turtle is already selected), false otherwise
function M.selectItem(itemName)
  for slot = 1, 16 do
    local detail = turtle.getItemDetail(slot)
    if detail and detail.name == itemName then
      turtle.select(slot)
      return true
    end
  end
  return false
end

--- Places out all the required blocks & wraps the peripherals.
-- Blocks = table of BLOCK_MINER, BLOCK_ENERGY, etc.
-- GV = global vars table returned to caller
function M.placeSetup(Blocks, GV)
  -- 1) Miner
  if M.selectItem(Blocks.BLOCK_MINER) then
    turtle.placeUp()
    -- move to energy-facing side
    turtle.turnRight(); turtle.forward(); turtle.forward(); turtle.turnLeft()
    -- 2) Energy block
    if M.selectItem(Blocks.BLOCK_ENERGY) then
      turtle.placeUp()
      turtle.forward(); turtle.forward(); turtle.turnLeft(); turtle.forward(); turtle.forward(); turtle.up()
      -- 3) Storage
      if M.selectItem(Blocks.BLOCK_STORAGE) then
        turtle.placeUp()
        turtle.forward()
        -- 4) Chunk loader (if not chunky turtle)
        if not GV.isChunky and M.selectItem(Blocks.BLOCK_CHUNKLOADER) then
          GV.hasChunkLoader = true
          turtle.placeUp()
        end
        -- reposition for chat box
        turtle.forward(); turtle.turnLeft(); turtle.forward(); turtle.forward()
        if GV.isChunky then turtle.turnLeft() end
        -- 5) Chat box
        if M.selectItem(Blocks.BLOCK_CHATBOX) then
          GV.hasChatBox = true
          turtle.placeUp()
        end
        sleep(0.3)
        -- Wrap peripherals
        GV.chatBox = M.getPeripheralWrap("chat_box")
        GV.miner   = M.getPeripheralWrap("digital_miner")
      end
    end
  end
end

--- Digs up all the blocks placed earlier, resetting the turtle to its original spot.
function M.destroyBlocks(GV)
  if GV.hasChatBox then turtle.digUp() end
  if not GV.isChunky then turtle.turnLeft() end
  turtle.dig(); turtle.forward(); turtle.forward(); turtle.forward()
  turtle.dig(); turtle.turnLeft(); turtle.forward(); turtle.forward(); turtle.up()
  turtle.turnLeft(); turtle.dig()
  if not GV.isChunky and GV.hasChunkLoader then
    turtle.forward(); turtle.dig()
  end
  turtle.down(); turtle.down()
end

--- Checks if `value` is within `tol` of `target`.
function M.percentageInRange(value, target, tol)
  tol = tol or 0
  return value >= (target - tol) and value <= (target + tol)
end

return M
