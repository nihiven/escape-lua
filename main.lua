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
package.path = package.path .. ';maps/?.lua;3rdparty/anim8/?.lua;3rdparty/serpent/src/?.lua'

--[[ REQUIRE ]]
-- 3rd party
require('anim8')

-- home grown
require('map')
require('player')

--[[ GAME ]]
-- global game object
-- defines game settings such as pause state, games state, any type of timing or score info
game = {
	name = 'Exit Strategy',
	map = 'plicard'
}

inputMap = { -- change to differentiate between presses and holds
	w = 'up',
	a = 'left',
	s = 'down',
	d = 'right',
	space = 'use',
	shift = 'run' -- TODO: figure this out later
}



---------------------------------------------

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

	map.highlightGrid(1,2)
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