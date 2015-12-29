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
		map._data = map.conversion(game.map)
		
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
					local x = math.fmod(tileId-1,map._data.width) * map._data.tileWidth
					local y = math.floor((tileId-1) / map._data.width) * map._data.tileHeight

					--debug.print(tileId .. ': ' .. x .. ' ' .. y .. ' ' .. source.x .. ' ' .. source.y)

					-- add tile to the quad list that will be sent to _tilesBatch
					map._tileQuads[layerKey][tileId] = love.graphics.newQuad(	x, -- x location of the sprite in the tileset
																																		y, -- y location of the sprite in the tileset
																																		map._data.tileWidth, -- width of the sprite in the tileset
																																		map._data.tileHeight, -- height of the sprite in the tileset
																																		map._tilesets[layerKey]:getDimensions() -- size of tileset
																																	)

					--debug.print('  load quad: layer ' .. layerKey .. ', tile ' .. tileId)
				end

			end -- for tile
		end -- for layer
		debug.print('done')
	end, -- load()

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
						local x = math.fmod(tileKey-1,map._data.width) * map._data.tileWidth
						local y = math.floor((tileKey-1) / map._data.width) * map._data.tileHeight

						--debug.print(tileKey .. ':' .. x .. ':' .. y)
						map._tilesetBatch[layerKey]:add(map._tileQuads[layerKey][tileIndex], x, y)
					end -- if
				end
				
				map._tilesetBatch[layerKey]:flush()
				love.graphics.draw(map._tilesetBatch[layerKey])

			end -- if deferred
		end -- for layer
	end, -- draw

	highlightGrid = function(_x, _y)
		local xy = map.getXYFromGrid(_x, _y)
		love.graphics.setColor(0, 255, 0)
		love.graphics.rectangle('line', xy.x, xy.y, map._data.tileWidth-1, map._data.tileHeight-1)
		love.graphics.setColor(255, 255, 255)
	end,

	isMoveable = function(_x, _y, _width, _height)
		local grid = map.getGridFromXY(_x, _y)
		local key = (grid.y * map._data.width) + grid.x
		local moveable = map._data.movement[key1]

		love.graphics.setColor(0, 255, 0)
		map.highlightGrid(grid.x, grid.y)
		love.graphics.setColor(255, 255, 255)

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
		local x = math.ceil(_x / map._data.tileWidth) -- always half of the number of pixels per tile ? TODO: stupid
		local y = math.ceil(_y / map._data.tileHeight) -- always half of the number of pixels per tile ? TODO: stupid
		return {x = x, y = y}
	end,

	getXYFromGrid = function(_x, _y)
		-- subtract one to offset the 1,1 grid translation
		local x = math.floor((_x-1) * map._data.tileWidth)
		local y = math.floor((_y-1) * map._data.tileHeight)
		return {x = x, y = y}
	end,

	conversion = function(_dir)
		local plicard = require(_dir)
		local m = {}
		m.width = plicard.width
		m.height = plicard.height
		m.tileWidth = plicard.tilewidth
		m.tileHeight = plicard.tileheight

		m.tilesets = {}
		for key,value in pairs(plicard.tilesets) do
			m.tilesets[key] = value
			m.tilesets[key].file = m.tilesets[key].image
			m.tilesets[key].image = nil
		end

		m.layers = {}
		for key,value in pairs(plicard.layers) do
			m.layers[key] = {}
			m.layers[key].name = value.name

			if (value.type == 'tilelayer') then
				for index,tile in pairs(value.data) do
					local x = math.fmod((index-1),m.width) + 1
					local y = math.floor((index-1) / m.width) + 1

					if (m.layers[key][y] == nil) then m.layers[key][y] = {} end
					m.layers[key][y][x] = tile
				end
			end

			-- if 'objectgroup'
		end

		--[[
		local serpent = require('serpent')
		local file = io.output('conv_'.._dir..'.lua')
		io.write(serpent.block(m, {comment = false})) -- multi-line indented, no self-ref section
		io.close(file)
		]]

		return m
	end
}

