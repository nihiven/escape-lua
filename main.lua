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

package.path = package.path .. ';maps/?.lua'

--[[ REQUIRE ]]
require('testMap')
require('lab')

--[[ GAME ]]
-- global game object
-- defines game settings such as pause state, games state, any type of timing or score info
game = {
	name = 'Exit Strategy'
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
			if (map._tileQuads[layerKey] == nil) then
				map._tileQuads[layerKey] = {}
			end

			for tileKey,tileId in pairs(layer) do
				-- only the load the quad if this tile id does not exist on this layer
				if (map._tileQuads[layerKey][tileId] == nil and tileId ~= 0) then
					tileId = tileId - map._data.sources[layerKey].tiledAdjust
					debug.print('id:' .. tileId)
					debug.print('ad:' .. map._data.sources[layerKey].tiledAdjust)
					debug.print('re:' .. tileId - map._data.sources[layerKey].tiledAdjust)

					local source = map._data.sources[layerKey] -- need source for xy width height

					local x = math.fmod(tileId-1,source.width) * source.x
					local y = math.floor((tileId-1) / source.width) * source.y

				--	debug.print(tileId .. ': ' .. x .. ' ' .. y .. ' ' .. source.x .. ' ' .. source.y)

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
	end, -- load()

	
	loadTiledLua = function(_file)
	end,


	draw = function ()
		for layerKey,layer in pairs(map._data.layers) do
			map._tilesetBatch[layerKey]:clear()

			for tileKey,tileIndex in pairs(layer) do
				if (tileIndex ~= 0) then
					debug.print('id:' .. tileIndex)
					debug.print('ad:' .. map._data.sources[layerKey].tiledAdjust)
					debug.print(tileIndex)
					tileIndex = tileIndex - map._data.sources[layerKey].tiledAdjust

					local source = map._data.sources[layerKey]
					local x = math.fmod(tileKey-1,map._data.width) * source.x
					local y = math.floor((tileKey-1) / map._data.width) * source.y

--				debug.print(tileKey .. ':' .. x .. ':' .. y)
					map._tilesetBatch[layerKey]:add(map._tileQuads[layerKey][tileIndex], x, y)
				end -- if
			end
			
			map._tilesetBatch[layerKey]:flush()
			love.graphics.draw(map._tilesetBatch[layerKey])
		end -- for layer

	end
}

--[[ PLAYER ]]
-- controls player movement, drawing
player = {
	_x = 0,
	_y = 0,
	_texture = nil,

	draw = function()
		debug:print(player._x)
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
	love.window.setMode(1920, 1080, { msaa=8, fullscreen=false, resizable=false, vsync=true })

	entities.add(map)
	-- load stuff
	entities.call('load', game)
end

function love.draw()
	entities.call('draw')

	if (debug == true) then 
		entities.call('debug')
	end
end

function love.update(_dt)
	--- send updates to entities
	entities.call('update', {dt = _dt, g = game})
end

