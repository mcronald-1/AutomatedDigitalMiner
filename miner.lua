-- miner.lua (v2.0 for CC:Tweaked 1.20.1)
-- Usage: paste both files to your turtle, then run `miner.lua`.

-- Settings:
local Settings = {
    MAX_CHUNKS   = 16,    -- how many chunks to run
    SEND_TO_CHAT = true,  -- toggle broadcast messages
  }
  
  -- Change these registry names if your pack uses different IDs:
  local Blocks = {
    BLOCK_MINER       = "mekanism:digital_miner",
    BLOCK_ENERGY      = "mekanism:quantum_entangloporter",
    BLOCK_STORAGE     = "mekanism:quantum_entangloporter",
    BLOCK_CHUNKLOADER = "chickenchunks:chunk_loader",
    BLOCK_CHATBOX     = "advancedperipherals:chat_box",
  }
  
  -- Per-run globals table
  local GV = {
    isChunky       = false,
    hasChunkLoader = false,
    hasChatBox     = false,
    miner          = nil,
    chatBox        = nil,
  }
  
  -- Load our helper module (utils.lua must be in the same dir)
  local utils = require("utils")
  
  -- Run one chunk-cycle (place → mine with status → destroy → move)
  local function runChunk(i)
    -- reset flags
    GV.isChunky       = utils.isChunkyTurtle()
    GV.hasChunkLoader = false
    GV.hasChatBox     = false
    GV.miner          = nil
    GV.chatBox        = nil
  
    -- place everything and wrap peripherals
    utils.placeSetup(Blocks, GV)
    sleep(0.15)
  
    if not GV.miner then
      print("Error: no Digital Miner found!")
      return
    end
  
    -- start mining
    GV.miner.start()
    local total = GV.miner.getToMine()
  
    while GV.miner.isRunning() do
      local rem   = GV.miner.getToMine()
      local pct   = math.floor((rem / total) * 100)
      local eta   = utils.getTimeString(rem * 0.5)
  
      -- chat notifications at 80%, 50%, 30%
      if GV.chatBox and Settings.SEND_TO_CHAT then
        for _, t in ipairs({80,50,30}) do
          if utils.percentageInRange(pct, t, 1) then
            GV.chatBox.sendMessage(
              string.format("%d%% blocks remaining (%d/%d)", t, rem, total),
              "Miner"
            )
            sleep(2)
          end
        end
      end
  
      -- console ETA every 5 blocks
      if rem % 5 == 0 then
        print(string.format("Remaining: %d, ETA: %s", rem, eta))
      end
  
      -- finished this chunk?
      if rem == 0 then
        if GV.chatBox and Settings.SEND_TO_CHAT then
          GV.chatBox.sendMessage(
            string.format("Done chunk %d/%d", i, Settings.MAX_CHUNKS),
            "Miner"
          )
          sleep(1)
          if i == Settings.MAX_CHUNKS then
            GV.chatBox.sendMessage("All chunks done! Pick me up!", "Miner")
            sleep(1)
          end
        end
        -- teardown and move on
        utils.destroyBlocks(GV)
        sleep(2)
        utils.goOneChunk()
      end
  
      sleep(0.5)
    end
  end
  
  -- Ensure utils.lua is present (download if needed)
  if not fs.exists("utils.lua") then
    shell.run("wget", "https://raw.githubusercontent.com/martinjanas/DigitalMinerAutomatization/main/utils.lua")
    sleep(1)
  end
  
  -- Main loop
  for i = 1, Settings.MAX_CHUNKS do
    runChunk(i)
  end
  