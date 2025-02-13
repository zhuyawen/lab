--[[ Copyright (C) 2018 Google Inc.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
]]

local game = require 'dmlab.system.game'
local tensor = require 'dmlab.system.tensor'
local game_entities = require 'dmlab.system.game_entities'
local inventory = require 'common.inventory'

local SCREEN_SHAPE = game:screenShape().buffer

local debug_observations = {}
local names = {}
local inventories = {}
local teams = {}
local camera = {pos = {0, 0, 500}, look = {90, 90, 0}}

local ASPECT = SCREEN_SHAPE.height / SCREEN_SHAPE.width
local function cameraUp(x, y, maxHeight)
  return math.max(x - maxHeight, (y - maxHeight) / ASPECT) + maxHeight
end

local function playerPosition()
  return tensor.DoubleTensor(game:playerInfo().pos)
end

local function playerOrientation()
  return tensor.DoubleTensor(game:playerInfo().angles)
end

local function playerId()
  return tensor.DoubleTensor{game:playerInfo().playerId}
end

local function playersId()
  local playerIds = {}
  for playerId, name in pairs(names) do
    playerIds[#playerIds + 1] = playerId
  end
  return tensor.DoubleTensor(playerIds)
end


local function playersName()
  return table.concat(names, '\n')
end

local function playersHealth()
  local playerHealth = {}
  for playerId, inv in pairs(inventories) do
    playerHealth[#playerHealth + 1] = inv:health()
  end
  return tensor.DoubleTensor(playerHealth)
end

local function playersArmor()
  local playerArmor = {}
  for playerId, inv in pairs(inventories) do
    playerArmor[#playerArmor + 1] = inv:armor()
  end
  return tensor.DoubleTensor(playerArmor)
end

local function playersGadget()
  local playerGadget = {}
  for playerId, inv in pairs(inventories) do
    playerGadget[#playerGadget + 1] = inv:gadget()
  end
  return tensor.DoubleTensor(playerGadget)
end

local function playersGadgetAmount()
  local playerGadgetAmount = {}
  for playerId, inv in pairs(inventories) do
    playerGadgetAmount[#playerGadgetAmount + 1] =
        inv:gadgetAmount(inv:gadget())
  end
  return tensor.DoubleTensor(playerGadgetAmount)
end

local function playersEyePos()
  local eyePos = {}
  for playerId, inv in pairs(inventories) do
    eyePos[#eyePos + 1] = inv:eyePos()
  end
  return tensor.DoubleTensor(eyePos)
end

local function playersEyeRot()
  local eyeRot = {}
  for playerId, inv in pairs(inventories) do
    eyeRot[#eyeRot + 1] = inv:eyeAngles()
  end
  return tensor.DoubleTensor(eyeRot)
end

local TEAM_LOOKUP = {r = 1, b = 2}
local function playersTeam()
  local playerTeam = {}
  for playerId, team in pairs(teams) do
    playerTeam[#playerTeam + 1] = TEAM_LOOKUP[team] or 0
  end
  return tensor.DoubleTensor(playerTeam)
end

local function playersHoldingFlag()
  local playerHoldingFlag = {}
  for playerId, inv in pairs(inventories) do
    local holding = 0
    if inv:hasPowerUp(inventory.POWERUPS.RED_FLAG) then
      holding = holding + 1
    end
    if inv:hasPowerUp(inventory.POWERUPS.BLUE_FLAG) then
      holding = holding + 2
    end
    playerHoldingFlag[#playerHoldingFlag + 1] = holding
  end
  return tensor.DoubleTensor(playerHoldingFlag)
end

local FLAG_STATE = {
  NONE = 0,
  HOME = 1,
  CARRIED = 2,
  DROPPED = 3,
}

local function redFlag()
  for i, ent in ipairs(game_entities:entities{'team_CTF_redflag'}) do
    if ent.visible then
      local x, y, z = unpack(ent.position)
      local player_id = 0
      local flagState = i == 1 and FLAG_STATE.HOME or FLAG_STATE.DROPPED
      return tensor.DoubleTensor{x, y, z, player_id, flagState}
    end
  end
  for playerId, inv in pairs(inventories) do
    if inv:hasPowerUp(inventory.POWERUPS.RED_FLAG) then
      local x, y, z = unpack(inv:eyePos())
      return tensor.DoubleTensor{x, y, z, inv:playerId(), FLAG_STATE.CARRIED}
    end
  end
  return tensor.DoubleTensor{0, 0, 0, 0, FLAG_STATE.NONE}
end

local function blueFlag()
  for i, ent in ipairs(game_entities:entities{'team_CTF_blueflag'}) do
    if ent.visible then
      local x, y, z = unpack(ent.position)
      local player_id = 0
      local flagState = i == 1 and FLAG_STATE.HOME or FLAG_STATE.DROPPED
      return tensor.DoubleTensor{x, y, z, player_id, flagState}
    end
  end

  for _, inv in pairs(inventories) do
    if inv:hasPowerUp(inventory.POWERUPS.BLUE_FLAG) then
      local x, y, z = unpack(inv:eyePos())
      return tensor.DoubleTensor{x, y, z, inv:playerId(), FLAG_STATE.CARRIED}
    end
  end
  return tensor.DoubleTensor{0, 0, 0, 0, FLAG_STATE.NONE}
end

local HOME_FLAG_STATE = {
  NONE = 0,
  HOME = 1,
  AWAY = 2,
}

local function redFlagHome()
  for i, ent in ipairs(game_entities:entities{'team_CTF_redflag'}) do
    local x, y, z = unpack(ent.position)
    local state = ent.visible and HOME_FLAG_STATE.HOME or HOME_FLAG_STATE.AWAY
    return tensor.DoubleTensor{x, y, z, state}
  end
  return tensor.DoubleTensor{0, 0, 0, FLAG_STATE.NONE}
end

local function blueFlagHome()
  for i, ent in ipairs(game_entities:entities{'team_CTF_blueflag'}) do
    local x, y, z = unpack(ent.position)
    local state = ent.visible and HOME_FLAG_STATE.HOME or HOME_FLAG_STATE.AWAY
    return tensor.DoubleTensor{x, y, z, state}
  end
  return tensor.DoubleTensor{0, 0, 0, HOME_FLAG_STATE.NONE}
end

function debug_observations.setMazeShape(width, height)
  debug_observations.setCameraPos{
      width * 50,
      height * 50,
      cameraUp(width * 50, height * 50, 100)
  }
end

function debug_observations.setCameraPos(pos, look)
  camera.pos = pos or camera.pos
  camera.look = look or camera.look
end

function debug_observations.getCameraPos()
  return camera
end

local function topDownCamera()
  local buffer = game:renderCustomView{
      width = SCREEN_SHAPE.width,
      height = SCREEN_SHAPE.height,
      pos = camera.pos,
      look = camera.look,
  }
  return buffer:transpose(3, 2):transpose(2, 1):reverse(2):clone()
end

local function playerView(reticleSize)
  local function view()
    local info = game:playerInfo()
    local pos = {info.pos[1], info.pos[2], info.pos[3] + info.height}
    local buffer = game:renderCustomView{
        width = SCREEN_SHAPE.width,
        height = SCREEN_SHAPE.height,
        pos = pos,
        look = info.angles,
        renderPlayer = false,
    }
    if reticleSize > 0 then
      local hheight = math.floor(SCREEN_SHAPE.height / 2)
      local hwidth = math.floor(SCREEN_SHAPE.width / 2)
      local hsize = math.floor(reticleSize / 2)
      buffer:narrow(1, hheight - hsize, reticleSize)
            :narrow(2, hwidth - hsize, reticleSize)
            :fill{200, 200, 200}
    end
    return buffer:transpose(3, 2):transpose(2, 1):reverse(2):clone()
  end
  return view
end

--[[ Extend custom_observations to contain debug observations. ]]
function debug_observations.extend(custom_observations)
  local co = custom_observations
  names = co.playerNames
  inventories = co.playerInventory
  teams = co.playerTeams
  co.addSpec('DEBUG.CAMERA.TOP_DOWN', 'Bytes',
             {3, SCREEN_SHAPE.height, SCREEN_SHAPE.width}, topDownCamera)
  co.addSpec('DEBUG.CAMERA.PLAYER_VIEW', 'Bytes',
             {3, SCREEN_SHAPE.height, SCREEN_SHAPE.width}, playerView(3))
  co.addSpec('DEBUG.CAMERA.PLAYER_VIEW_NO_RETICLE', 'Bytes',
             {3, SCREEN_SHAPE.height, SCREEN_SHAPE.width}, playerView(0))
  co.addSpec('DEBUG.POS.TRANS', 'Doubles', {3}, playerPosition)
  co.addSpec('DEBUG.POS.ROT', 'Doubles', {3}, playerOrientation)
  co.addSpec('DEBUG.PLAYER_ID', 'Doubles', {1}, playerId)
  co.addSpec('DEBUG.PLAYERS.ARMOR', 'Doubles', {0}, playersArmor)
  co.addSpec('DEBUG.PLAYERS.GADGET', 'Doubles', {0}, playersGadget)
  co.addSpec('DEBUG.PLAYERS.GADGET_AMOUNT', 'Doubles', {0}, playersGadgetAmount)
  co.addSpec('DEBUG.PLAYERS.HEALTH', 'Doubles', {0}, playersHealth)
  co.addSpec('DEBUG.PLAYERS.HOLDING_FLAG', 'Doubles', {0}, playersHoldingFlag)
  co.addSpec('DEBUG.PLAYERS.ID', 'Doubles', {0}, playersId)
  co.addSpec('DEBUG.PLAYERS.EYE.POS', 'Doubles', {0, 3}, playersEyePos)
  co.addSpec('DEBUG.PLAYERS.EYE.ROT', 'Doubles', {0, 3}, playersEyeRot)
  -- New line separated string.
  co.addSpec('DEBUG.PLAYERS.NAME', 'String', {1}, playersName)
  co.addSpec('DEBUG.PLAYERS.TEAM', 'Doubles', {0}, playersTeam)

  -- Flag information (x, y, z, playerId,
  -- {NONE = 0, HOME = 1, CARRIED = 2, DROPPED = 3})
  co.addSpec('DEBUG.FLAGS.RED', 'Doubles', {5}, redFlag)
  co.addSpec('DEBUG.FLAGS.BLUE', 'Doubles', {5}, blueFlag)

  -- Flag information (x, y, z, {NONE = 0, HOME = 1, AWAY = 2})
  co.addSpec('DEBUG.FLAGS.RED_HOME', 'Doubles', {4}, redFlagHome)
  co.addSpec('DEBUG.FLAGS.BLUE_HOME', 'Doubles', {4}, blueFlagHome)
end

function debug_observations.enableCameraMovement(api)
  local time = 0
  local buttonsDown = 0
  local modifyControl = api.modifyControl
  print('----\nWarning debug camera controlls activated!')
  print('Move camera with WASD and Ctrl/Space to move up and down.')
  print('Click to print current camera position.\n----')
  io.flush()
  function api:modifyControl(actions)
    local dt = game:episodeTimeSeconds() - time
    time = game:episodeTimeSeconds()
    local pos = debug_observations.getCameraPos().pos
    pos[1] = pos[1] + actions.strafeLeftRight * 2 * dt
    pos[2] = pos[2] + actions.moveBackForward * 2 * dt
    pos[3] = pos[3] + actions.crouchJump * 2 * dt
    if buttonsDown == 0 and actions.buttonsDown > 0 then
      print('----')
      print('Cam Pos: {' .. pos[1] .. ', ' .. pos[2] .. ', ' .. pos[3] .. '}')
      print('----')
      io.flush()
    end
    buttonsDown = actions.buttonsDown
    actions.buttonsDown = 0
    actions.moveBackForward = 0
    actions.strafeLeftRight = 0
    actions.crouchJump = 0
    return modifyControl and modifyControl(self, actions) or actions
  end
end

return debug_observations
