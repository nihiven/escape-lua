--[[ MAP ]]
-- global map object
-- loads map definition file, textures and layout
-- draws map to screen
return {
	-- map properties from tiled file
	_width = nil,
	_height = nil,
	_renderorder = nil,

	-- internal components
	_layers = {},
	_tilesets = {}, -- image object for tilesets
	_tilesetBatch = {},
	_tileQuads = {},

	load = function(self, _game)
		debug.print('load map data')

		-- load main map information

		
		-- load tileset images and create tileset batch
		for key,source in pairs(self._data.tilesets) do
			debug.print(' load tileset: ' .. source.file)
			local tileset = love.graphics.newImage('maps/' .. source.file)
			local tilesetBatch = love.graphics.newSpriteBatch(tileset, self._data.width * self._data.height, 'static')

			-- TODO: check for errors
			self._tilesets[key] = tileset
			self._tilesetBatch[key] = tilesetBatch
		end
		debug.print(' tilesets loaded')


		-- load used quads
		-- quads are the tiles from a given layer that are used in the map
		-- so if map layer data has quad 195 in 0,0 we need to create a new Love quad from
		-- the layer image and the correct coordinates for tile 195



		debug.print('map.load() complete')
	end, -- load()

	draw = function(self, _parameters)
		local deferred = _parameters.deferred or false -- default to false

		-- when accesing sources / layers layerKey always refers to the current layer
		for layerKey,layer in pairs(self._data.layers) do
			
			-- only draw layers that match incoming deferred parameter
			if (deferred == self._data.sources[layerKey].deferred) then
				self._tilesetBatch[layerKey]:clear()

				for tileKey,tileIndex in pairs(layer) do
					if (tileIndex ~= 0) then -- 0 are empty tiles
						--debug.print('id:' .. tileIndex)
						--debug.print('ad:' .. self._data.sources[layerKey].tiledAdjust)
						--debug.print(tileIndex)
						tileIndex = tileIndex - self._data.sources[layerKey].tiledAdjust -- adjust for Tiled index offset 'firstgid - 1'

						-- shortcut: need source for xy width height
						local source = self._data.sources[layerKey]

						-- local x,y are grid coordinates, source values are pixel values for the grid
						local x = math.fmod(tileKey-1,self._data.width) * self._data.tileWidth
						local y = math.floor((tileKey-1) / self._data.width) * self._data.tileHeight

						--debug.print(tileKey .. ':' .. x .. ':' .. y)
						self._tilesetBatch[layerKey]:add(self._tileQuads[layerKey][tileIndex], x, y)
					end -- if
				end
				
				self._tilesetBatch[layerKey]:flush()
				love.graphics.draw(self._tilesetBatch[layerKey])

			end -- if deferred
		end -- for layer
	end, -- draw

	--------
	-- highlightGrid()
	--------
	highlightGrid = function(_x, _y)
		local xy = self.getXYFromGrid(_x, _y)
		love.graphics.setColor(0, 255, 0)
		love.graphics.rectangle('line', xy.x, xy.y, self._data.tileWidth-1, self._data.tileHeight-1)
		love.graphics.setColor(255, 255, 255)
	end,

	--------
	-- isMoveable()
	--------
	isMoveable = function(_x, _y, _width, _height)
		local grid = self.getGridFromXY(_x, _y)
		local key = (grid.y * self._data.width) + grid.x
		local moveable = self._data.movement[key1]

		love.graphics.setColor(0, 255, 0)
		self.highlightGrid(grid.x, grid.y)
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

	--------
	-- getGridFromXy()
	--------
	getGridFromXY = function(_x, _y)
		local x = math.ceil(_x / self._data.tileWidth) -- always half of the number of pixels per tile ? TODO: stupid
		local y = math.ceil(_y / self._data.tileHeight) -- always half of the number of pixels per tile ? TODO: stupid
		return {x = x, y = y}
	end,

	--------
	-- getXYFromGrid()
	--------
	getXYFromGrid = function(_x, _y)
		-- subtract one to offset the 1,1 grid translation
		local x = math.floor((_x-1) * self._data.tileWidth)
		local y = math.floor((_y-1) * self._data.tileHeight)
		return {x = x, y = y}
	end,

	--------
	-- conversion()
	-- converts from Tiled LUA format
	--------
	conversion = function(_mapFile)
		debug.print('map.conversion()' .. ': _mapFile: ' .. _mapFile)
		local plicard = require(_mapFile)
		local m = {}
		m.width = plicard.width
		m.height = plicard.height
		m.tileWidth = plicard.tilewidth
		m.tileHeight = plicard.tileheight

		m.tilesets = {}
		for key,value in pairs(plicard.tilesets) do
			m.tilesets[key] = value
			m.tilesets[key].file = m.tilesets[key].image -- because we want image to be an image object and file to be the file name
			m.tilesets[key].image = nil -- haven't loaded the image yet
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

