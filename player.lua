
--[[ PLAYER ]]
-- controls player movement, drawing
player = {
	_x = 100,
	_y = 100,
	_height = 48,
	_width = 48,
	_speed = 4, -- multiplied by map._data.pixelsPerTile
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

		--debug.print(_command)

		local delta = {x=0, y=0} -- amount to move player position on each axis
		local pixels = player._speed * map._data.tileWidth -- pixels per second
		if (_command == 'down') then
			 delta.x = 0
			 delta.y = pixels * _dt
		elseif (_command == 'right') then
			 delta.x = pixels * _dt
			 delta.y = 0
		elseif (_command == 'up') then
			 delta.x = 0
			 delta.y = (pixels * _dt) * -1
		elseif (_command == 'left') then
			 delta.x = (pixels * _dt) * -1
			 delta.y = 0
		end

		--debug.print('player move: ' .. delta.x .. ':' .. delta.y)


		-- check to see if the new grid piece is moveable
		--debug.print(grid.x .. ':' .. grid.y)
		local newX = player._x + delta.x
		local newY = player._y + delta.y

		if (map.isMoveable(newX, newY, player._width, player._height)) then -- adjustment for player sprite width and height
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