-- variables with _ prefix should not be accessed directly
-- singular names [dog] should be scalars, plural names [hats] should be tables

--[[ DEBUG ]]
-- object should check this before starting debug actions
debug = {
	status = true,

	print = function(_text)
		if (debug.status == true) then
			print(_text)
		end
	end

}

-- required to import 3rd party libraries
package.path = package.path .. ';maps/?.lua;3rdparty/anim8/?.lua'

--[[ REQUIRE ]]
require('testMap')
require('lab')
require('anim8')

--[[ GAME ]]
-- global game object
-- defines game settings such as pause state, games state, any type of timing or score info
game = {
	name = 'Exit Strategy'
}

inputMap = { -- change to differentiate between presses and holds
	w = 'up',
	a = 'left',
	s = 'down',
	d = 'right',
	space = 'use'
}


--[[ MAP ]]
-- global map object
-- loads map definition file, textures and layout
-- draws map to screen
map = {
	_data = nil,
	_tilesets = {},
	_tilesetBatch = {},
	_tileQuads = {},

	load = function(_data)
		debug.print('load map data')
		map._data = testMap -- test


		-- load tileset images
		for key,source in pairs(map._data.sources) do
			debug.print(' load tileset: ' .. source.file)
			local tileset = love.graphics.newImage('maps/' .. map._data.dir .. '/' .. source.file)
			local tilesetBatch = love.graphics.newSpriteBatch(tileset, map._data.width * map._data.height, 'static')

			-- TODO: check for errors
			map._tilesets[key] = tileset
			map._tilesetBatch[key] = tilesetBatch
		end

		-- load used quads
		for layerKey,layer in pairs(map._data.layers) do -- each layer

			-- default this to empty if does not exist
			if (map._tileQuads[layerKey] == nil) then map._tileQuads[layerKey] = {} end

			for tileKey,tileId in pairs(layer) do
				-- only the load the quad if this tile id does not exist on this layer
				if (map._tileQuads[layerKey][tileId] == nil and tileId ~= 0) then
					tileId = tileId - map._data.sources[layerKey].tiledAdjust  -- adjust for Tiled index offset 'firstgid - 1'
					--debug.print('id:' .. tileId)
					--debug.print('ad:' .. map._data.sources[layerKey].tiledAdjust)
					--debug.print('re:' .. tileId - map._data.sources[layerKey].tiledAdjust)

					-- shortcut: need source for xy width height
					local source = map._data.sources[layerKey] 

					-- local x,y are grid coordinates, source values are pixel values for the grid
					local x = math.fmod(tileId-1,source.width) * source.x
					local y = math.floor((tileId-1) / source.width) * source.y

					--debug.print(tileId .. ': ' .. x .. ' ' .. y .. ' ' .. source.x .. ' ' .. source.y)

					-- add tile to the quad list that will be sent to _tilesBatch
					map._tileQuads[layerKey][tileId] = love.graphics.newQuad(	x, -- x location of the sprite in the tileset
																																		y, -- y location of the sprite in the tileset
																																		source.x, -- width of the sprite in the tileset
																																		source.y, -- height of the sprite in the tileset
																																		map._tilesets[layerKey]:getDimensions() -- size of tileset
																																	)

					--debug.print('  load quad: layer ' .. layerKey .. ', tile ' .. tileId)
				end

			end -- for tile
		end -- for layer
		debug.print('done')
	end, -- load()

	
	loadTiledLua = function(_file)
	end,


	draw = function(self, _parameters)
		local deferred = _parameters.deferred or false -- default to false

		-- when accesing sources / layers layerKey always refers to the current layer
		for layerKey,layer in pairs(map._data.layers) do
			
			-- only draw layers that match incoming deferred parameter
			if (deferred == map._data.sources[layerKey].deferred) then
				map._tilesetBatch[layerKey]:clear()

				for tileKey,tileIndex in pairs(layer) do
					if (tileIndex ~= 0) then -- 0 are empty tiles
						--debug.print('id:' .. tileIndex)
						--debug.print('ad:' .. map._data.sources[layerKey].tiledAdjust)
						--debug.print(tileIndex)
						tileIndex = tileIndex - map._data.sources[layerKey].tiledAdjust -- adjust for Tiled index offset 'firstgid - 1'

						-- shortcut: need source for xy width height
						local source = map._data.sources[layerKey]

						-- local x,y are grid coordinates, source values are pixel values for the grid
						local x = math.fmod(tileKey-1,map._data.width) * source.x
						local y = math.floor((tileKey-1) / map._data.width) * source.y

						--debug.print(tileKey .. ':' .. x .. ':' .. y)
						map._tilesetBatch[layerKey]:add(map._tileQuads[layerKey][tileIndex], x, y)
					end -- if
				end
				
				map._tilesetBatch[layerKey]:flush()
				love.graphics.draw(map._tilesetBatch[layerKey])

			end -- if deferred
		end -- for layer
	end, -- draw

	isMoveable = function(_x, _y)
		local grid = map.getGridFromXY(_x, _y)
		local key = (grid.y * map._data.tilesPerRow) + grid.x
		local moveable = map._data.movement[key]

		--debug.print(grid.x .. '/' .. grid.y)
		--debug.print(key)
		--debug.print(moveable)
		if (moveable == 1) then
			return false
		else
			return true
		end
	end,

	getGridFromXY = function(_x, _y)
		local x = math.ceil(_x / (map._data.pixelsPerTile / 2)) -- always half of the number of pixels per tile ? TODO: stupid
		local y = math.ceil(_y / (map._data.pixelsPerTile / 2)) -- always half of the number of pixels per tile ? TODO: stupid
		return {x = x, y = y}
	end,

	getXYFromGrid = function(_x, _y)
		local x = math.floor(_x * map._data.pixelsPerTile)
		local y = math.floor(_y * map._data.pixelsPerTile)
		return {x = x, y = y}
	end
}

--[[ PLAYER ]]
-- controls player movement, drawing
player = {
	_x = 100,
	_y = 100,
	_height = 48,
	_width = 48,
	_speed = 2, -- multiplied by map._data.pixelsPerTile
	_texture = nil,
	_quad = nil,
	_animations = {},
	_state = 'empty',
	_spawned = false,
	_dt = nil, -- stored from update

	load = function()
		debug.print('load player data')
		debug.print(' load texture: Evil.png')
		player._texture = love.graphics.newImage('img/player/Evil.png')
		debug.print(' set player quad')
		player._quad = love.graphics.newQuad(0,0,player._height,player._width,player._texture:getDimensions())
		debug.print('done')
		player._state = 'idle'
	end,

	update = function(_self, _parameters)
		if (player._spawned == false) then return end
		
		for key,animation in pairs(player._animations) do
			animation:update(_parameters.dt)
		end

		-- key pressed test
		-- input mapping is done here. keys are translated to commands and commands passed to input
		for key,command in pairs(inputMap) do
			if (love.keyboard.isDown(key) == true) then
				player.input(command, _parameters.dt)
			end
		end
	end,

	draw = function()
		if (player._spawned == false) then return end

		player.print(player._state)
		love.graphics.draw(player._texture, player._quad, player._x, player._y)
	end,

	-- _command: player command up, down, right, open, etc...
	-- _dt: time since last frame
	input = function(_command, _dt)
		if (player._spawned == false) then return end

		debug.print(_command)

		local movement = {x=0, y=0} -- amount to move player position on each axis
		local adjust = {x=0, y=0} -- adjust hit detection for player width and height
		local pixels = player._speed * map._data.pixelsPerTile -- pixels per second
		if (_command == 'down') then
			 movement.x = 0
			 movement.y = pixels * _dt
			 adjust.y = player._height
		elseif (_command == 'right') then
			 movement.x = pixels * _dt
			 movement.y = 0
			 adjust.x = player._width
		elseif (_command == 'up') then
			 movement.x = 0
			 movement.y = (pixels * _dt) * -1
		elseif (_command == 'left') then
			 movement.x = (pixels * _dt) * -1
			 movement.y = 0
		end

		--debug.print('player move: ' .. movement.x .. ':' .. movement.y)


		-- check to see if the new grid piece is moveable
		--debug.print(grid.x .. ':' .. grid.y)
		local newX = player._x + movement.x
		local newY = player._y + movement.y

		if (map.isMoveable(newX + adjust.x, newY + adjust.x)) then -- adjustment for player sprite width and height
			player._x = newX
			player._y = newY
		end

	end,

	debug = function()

	end,

	print = function(_text) -- prints information above the player
		if (player._spawned == false) then return end

		love.graphics.setColor(255, 0, 0)
		love.graphics.print(_text, player._x, player._y-20)
		love.graphics.print(math.floor(player._x) .. ':' .. math.floor(player._y), player._x, player._y-10)
		love.graphics.setColor(255, 255, 255)
	end,

	playerSpawn = function()
		local spawn = map.getXYFromGrid(map._data.spawn.x, map._data.spawn.y)
		player._x = spawn.x
		player._y = spawn.y

		player._spawned = true
		debug.print('spawn player')
		debug.print(' location: ' .. player._x .. ':' .. player._y)
	end

}



--[[ ENTITIES ]]
-- contains all of the game related objects (except game god object)
entities = {
	_list = {},
	add = function(_entity)
		table.insert(entities._list, _entity)
	end,

	remove = function(entity)
		table.remove(entities._list, _entity)
	end,

	call = function(_action, _parameters)
		for key,value in pairs(entities._list) do
			if (value[_action] ~= nil) then
				value[_action](value, _parameters)
			end
		end
	end -- call()
}

---------------------------
--[[ testing ]]
---------------------------


---------------------------
--[[ LOVE ]]
---------------------------
function love.load()
	-- set window/screen modes
	love.window.setMode(1920, 1080, { msaa=0, fullscreen=false, resizable=false, vsync=true })

	-- add entities
	entities.add(map)
	entities.add(player)

	-- load stuff
	entities.call('load', game)

	-- spawn the player
	love.event.push('playerSpawn')
end

function love.draw()
	entities.call('draw', { deferred = false })
	-- entities non-deferred

	-- how do you control the draw order of the player and the map?
	-- you might have to make the player a special case or use z ordering

	entities.call('draw', { deferred = true })
	-- entities deferred

	if (debug == true) then 
		entities.call('debug')
	end
end

function love.update(_dt)
	--- send updates to entities
	entities.call('update', {dt = _dt})
end

function love.keypressed(_key, _scancode, _isrepeat)
	-- Key repeat needs to be enabled with love.keyboard.setKeyRepeat for repeat keypress events to be received.
	entities.call('keypressed', {method = 'key', value = _key, isRepeat = _isrepeat})
end

-- custom events
function love.handlers.playerSpawn()
	entities.call('playerSpawn')
end