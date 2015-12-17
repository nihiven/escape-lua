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


--[[ TEST MAP ]]
testMap = {
	dir = 'lab',
	name = 'Plikard',

	-- width and height are given in tile count
	width = 22,
	height = 22,

	-- contains all of the tilesets required to build the map
	-- explicitly indexed to match layers data
	sources = {
		{ file = 'SF_Outside_A5.png', x = 48, y = 48, width = 8, height = 16 } -- TODO: x y is confusing, should be  width, height
	},
	

	-- data is {source index, tile index}
	layers = {
		{ -- layer 1
			{{1,50},{1,19},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50}}, -- row 1
			{{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,30},{1,50},{1,1},{1,50},{1,4},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50},{1,50}} -- row 2
		}
	} -- data
} -- testMap


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
			debug.print(' file: ' .. source.file)
			local tileset = love.graphics.newImage('maps/' .. map._data.dir .. '/' .. source.file)
			local tilesetBatch = love.graphics.newSpriteBatch(tileset, map._data.width * map._data.height, 'static')
			-- TODO: check for errors
			map._tilesets[key] = tileset
		end

		-- load used quads
		for layerKey,layer in pairs(map._data.layers) do -- each layer
			for rowKey,row in pairs(layer) do -- each row
				for tileKey,tile in pairs(row) do -- each tile {}
					local index = tile[2]

					if (map._tileQuads[layerKey] == nil) then
						map._tileQuads[layerKey] = {}
					end

					-- only the load the quad if this index does not exist on this layer
					if (map._tileQuads[layerKey][index] == nil) then
						local source = map._data.sources[layerKey]
						local point = getPointFromIndex(index, source.width, source.x, source.y)

						map._tileQuads[layerKey][index] = love.graphics.newQuad(point.x, point.y, source.x, source.y, source.x * source.width, source.y * source.height)
						debug.print('  load quad: layer ' .. layerKey .. ', tile ' .. index)
					end

				end -- for tile
			end -- for row
			debug.print('  quads loaded: ' .. #map._tileQuads[1])

		end -- for layer
	end, -- load()

	draw = function ()
		for key,layer in pairs(map._data.layers) do
			local tileset = map._tilesets[layer[1][1][1]]
			local tile = layer[1][1][2]
		end
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

-- given a index, size(width of tileset in tiles), width, height: return the starting x,y values of a tile
function getPointFromIndex(_index, _size, _width, _height)
	local y = math.ceil(_index / _size)
	local x = (_size + (_index - (y * _size)))
	return { x = x * _width, y = y * _height}
end

