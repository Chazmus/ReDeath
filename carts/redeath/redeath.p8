pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
-- main
-- The loop
game_objects = {}
animator = {}
animations = {}
animated_objects = {}
add(game_objects, animator)
actions = {}

player_list = {
	player1 = nil,
	player2 = nil
}

function _init()
	-- music
	music(0)

	palt(0, false) -- disable the colour 0 (black) being transparent

	init_animations()
	player_list.player1 = spawn_player({x=8, y=8})

	foreach(game_objects, 
	function(go) 
		if go.init != nil then
			go:init()
		end
	end)

	load_level1()
end

function _update()
	foreach(game_objects, 
	function(go) 
		if go.update != nil then
			go:update()
		end
	end)

	foreach(actions, 
	function(c) 
		if costatus(c) then
		  coresume(c)
		else
		  del(actions,c)
		end
	end)

	-- Input utils update MUST be done last
	input_utils:update()
end

function _draw()
	cls(0)

	map()
	for go in all(game_objects) do
		if go.draw != nil then
			go:draw()
		end
	end
end

-->8
-- game state

-- Trying out a way to keep track of which room we're in, loading vars according to room, limited number of moves, and resetting the room on fail

-- game_state = {
-- 	room_number = 1,
-- 	room_vars = {}
-- }

-- function start_room(room_vars)
-- 	game_state.room_vars = room_vars
-- 	player_list.player1 = spawn_player({ x = room_vars.starting_position.x, y = room_vars.starting_position.y })
-- end

-- function restart_room()
-- 	cleanup_room_and_objects()
-- 	start_room(room_vars_list[game_state.room_number])
-- end

-- function next_room()
-- 	cleanup_room_and_objects()
-- 	start_room(room_vars_list[game_state.room_number + 1])
-- 	game_state.room_number += 1
-- end

-- function cleanup_room_and_objects()
-- 	del(game_objects, player_list.player1)
-- 	del(game_objects, player_list.player2)
-- 	-- destroy old player objects
-- 	-- anything else to do before starting next room
-- end


-->8
-- room vars

-- room_vars_list = {
-- 	{ starting_position = {x = 8, y = 8}, total_steps = 20 }, -- room 1
-- 	{ starting_position = {x = 24, y = 24}, total_steps = 35} -- room 2, etc

-- }

-->8
-- the player
player_base = {}
function spawn_player(starting_position)
	local starting_target = {x=starting_position.x, y=starting_position.y}
	local player = player_base:new{
		position = starting_position,
		target = starting_target,
		is_moving = false,
		command_queue = {},
		current_command = 0,
		sprite_sequence = {051, 052, 051, 053},
		anim_speed = 8,
		last_move_time = 0,
		is_alive = true,
		-- remaining_steps = game_state.room_vars.total_steps
	}
	add(game_objects, player)
	return player
end

function player_base:new (o)
	-- Instantiate a new player
    o = o or {}
    setmetatable(o, self) -- This is basically how you do classes in lua, brilliant :)
    self.__index = self
    return o
end

function player_base:get_sprite_sequence()
	if self.is_alive then
		return {48,49,50}
	end
	return {51,52,53}
end

function player_base:update()
	if self.is_moving == false then
		-- handle input
		local command = nil
		if self.is_alive then
			if input_utils:get_button_down(fire1) then
				-- Idle button
			end

			if input_utils:get_button_down(fire2) then
				input_utils:handle_hold_button(fire2, 0.5, 
					function() 
						self.is_alive = false
						self:undo_all_commands(
							function()
								local player2 = spawn_player({x=16, y=8})
								add(game_objects, player2)
								player_list.player2 = player2
							end)
					end)
			end

			-- don't let them move too quickly
			if(self.last_move_time + 0.133 > time()) then
				return
			end
			if input_utils:get_button_down(up) then
				command = self:create_move_command(up)
			end
			if input_utils:get_button_down(down) then
				command = self:create_move_command(down)
			end
			if input_utils:get_button_down(left) then
				command = self:create_move_command(left)
			end
			if input_utils:get_button_down(right) then
				command = self:create_move_command(right)
			end
		end
		
		if (command != nil) then
			-- part of the game_state tab things

			-- printh(self.remaining_steps)
			-- if (self.remaining_steps <= 0) then
			-- 	if (self == player_list.player1) then
			-- 		self.is_alive = false
			-- 		self:undo_all_commands(
			-- 				function()
			-- 					local player2 = spawn_player({x=16, y=8})
			-- 					add(game_objects, player2)
			-- 					player_list.player2 = player2
			-- 				end)
			-- 	elseif (self == player_list.player2) then
			-- 		restart_room()
			-- 	else
			-- 		return
			-- 	end
			-- end

			self.last_move_time = time()
			self.command_queue[self.current_command] = command
			self.command_queue[self.current_command].execute()
			self.current_command += 1
			-- self.remaining_steps -= 1
			tick_command()
		end

		if(not self:is_at_target()) then
			self.is_moving = true
		end
	end

	if self.is_moving then
		self:move_towards_target()
	end
end

function player_base:is_at_target()
	return self.position.x == self.target.x and self.position.y == self.target.y
end

function player_base:create_move_command(direction)
	local direction_map = {}
	direction_map[up] = {x=0, y=-8}
	direction_map[down] = {x=0, y=8}
	direction_map[left] = {x=-8, y=0}
	direction_map[right] = {x=8, y=0}

	local movement = direction_map[direction]
	local command = {}
	function command.execute() 	
		newX = self.target.x + movement.x
		newY = self.target.y + movement.y
		if not check_for_collision(pixel_to_grid({x = newX, y = newY})) then
			self.target.x = newX
			self.target.y = newY
			command.success = true
		end
	end

	function command.unexecute()
		if not (self.command_queue[self.current_command-1].success == nil) 
		and self.command_queue[self.current_command-1].success then
			self.target.x -= movement.x
			self.target.y -= movement.y
		end
	end

	return command
end

function player_base:undo_all_commands(callback)
	local c = cocreate(function()
		self.last_move_time = time()
		while self.current_command > 0 do
			if(self.last_move_time < time() - 0.27) then
				self.command_queue[self.current_command - 1].unexecute()
				self.current_command -= 1
				self.last_move_time = time()
			else
				yield()
			end
		end
		if callback != nil then
			callback()
		end
	end)

	add(actions, c)
end

function player_base:move_towards_target()
	local c = cocreate(function()
	 	while not self:is_at_target() do
			if self.target.x > self.position.x then
				self.position.x += 1
			elseif self.target.x < self.position.x then
				self.position.x -= 1
			end

			if self.target.y > self.position.y then
				self.position.y += 1
			elseif self.target.y < self.position.y then
				self.position.y -= 1
			end
			yield()
		 end
		 self.is_moving = false
	end)

	add(actions, c)
end

function player_base:draw()
	spr(get_sprite_animated(self:get_sprite_sequence(), self.anim_speed), self.position.x, self.position.y)
end
-->8
-- utils
left,right,up,down,fire1,fire2=0,1,2,3,4,5
black,dark_blue,dark_purple,dark_green,brown,dark_gray,light_gray,white,red,orange,yellow,green,blue,indigo,pink,peach=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15

input_utils = {
	left = false,
	right = false,
	up = false,
	down = false,
	fire1 = false,
	fire2 = false
}

function input_utils:update()
	self[left] = btn(left)
	self[right] = btn(right)
	self[up] = btn(up)
	self[down] = btn(down)
	self[fire1] = btn(fire1)
	self[fire2] = btn(fire2)
end

function input_utils:get_button_down(button)
	-- Returns true only in the frame that the button was pushed down
	return self[button] == false and btn(button)
end

function input_utils:get_button_up(button)
	-- Returns true only in the frame that the button was released
	return self[button] == true and not btn(button)
end

function input_utils:handle_hold_button(button, hold_time, success_function, update_function)
	-- Return true if the given button has been held down for the given amount of time
	local c = cocreate(
		function()
			start_time = time()
			while btn(button) and time() < (start_time + hold_time) do
				if update_function != nil then
					update_function()
				end
				yield()
			end
			if not btn(button) then
				return
			end
			success_function()
		end
	)
	add(actions, c)
end

-- grid functions
function grid_to_pixel(grid_position)
	return {x=grid_position.x * 8, y=grid_position.y * 8}
end

function pixel_to_grid(grid_position)
	return {x=(grid_position.x / 8), y=(grid_position.y / 8)}
end

collisionlayer = { 7 }

function check_for_collision(grid_position)
	local tile = mget(grid_position.x, grid_position.y);
	return fget(tile, collisionlayer[1])
	-- for i in all(collisionlayers) do
	-- 	if (fget(tile, i)) then
	-- 		return true;
	-- 	end
	-- end
	-- return false;
end

-->8
-- Interactables

-- door
door = {}
function create_door(pos)
	local new_door = door:new{
		position = pos,
		is_open = false,
		sprite = {133,134}
	}
	return new_door
end

function door:new (o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function door:init()
	if self != nil then
		mset(self.position.x, self.position.y, self.sprite[1])
	end
end

function door:update()
	mset(self.position.x, self.position.y, self.is_open and self.sprite[2] or self.sprite[1]) -- works as a ternary operator, self.is_open ? self.sprite[1] : self.sprite[2], (order flipped)
end

-- pressure plate
pressure_plate = {}
function create_pressure_plate(pos, doors)
	local new_pressure_plate = pressure_plate:new{
		is_on = false,
		changed = true,
		position = pos,
		sprite = {184,185}, -- could have a sequence of active_sprites and inactive_sprites for anim 
		connected_doors = doors
	}
	return new_pressure_plate
end

function pressure_plate:new (o)
	o = o or {}
	setmetatable(o, self) 
	self.__index = self
	return o
end

function pressure_plate:init()
	--if self == nil then return
	mset(self.position.x, self.position.y, self.sprite[1])
end

function pressure_plate:update()
	--if self == nil then return

	local state = false
	-- check for player1 at this position
	if (not (player_list.player1 == nil)) then
		local p1 = pixel_to_grid(player_list.player1.position)
		state = p1.x == self.position.x and p1.y == self.position.y
	end
	-- check for player2
	if (not state and not (player_list.player2 == nil)) then
		local p2 = pixel_to_grid(player_list.player2.position)
		state = state or (p2.x == self.position.x and p2.y == self.position.y)
	end

	self.changed = (self.is_on and not state) or (state and not self.is_on)

	-- only update if the state has changed
	if (self.changed) then
		self.is_on = state

		for connected_door in all(self.connected_doors) do
			connected_door.is_open = state
		end

		mset(self.position.x, self.position.y, self.is_on and self.sprite[2] or self.sprite[1])
	end
end

-- pickup_key

pickup_key = {}
function create_pickup_key(pos, doors)
	local new_pickup_key = pickup_key:new{
		is_picked_up = false,
		position = pos,
		sprite = {177,178,177,179},
		connected_doors = doors,
	}
	return new_pickup_key
end

function pickup_key:new (o)
	o = o or {}
	setmetatable(o, self) 
	self.__index = self
	return o
end

function pickup_key:init()
	mset(self.position.x, self.position.y, self.sprite[1])
end

function pickup_key:update()
	if self.is_picked_up then end

	local state = false
	-- check for player1 at this position
	if (not (player_list.player1 == nil)) then
		local p1 = pixel_to_grid(player_list.player1.position)
		state = p1.x == self.position.x and p1.y == self.position.y
	end

	-- check for player2
	if (not state and not (player_list.player2 == nil)) then
		local p2 = pixel_to_grid(player_list.player2.position)
		state = state or (p2.x == self.position.x and p2.y == self.position.y)
	end

	if state then -- key is picked up
		self.is_picked_up = true

		for connected_door in all(self.connected_doors) do
			connected_door.is_open = true
		end

		mset(self.position.x, self.position.y, 000)
	end
end

-->8
-- Level management

level_loader = {}

function load_level1()
	-- initialise animated map objects

	local tree1 = {
		init = function() 
			add(animated_objects, {	position = {x = 4, y = 10}, -- celx, cely
									anim = animations["tree"]})
		end
	}

	-- create interactable objects

	-- needs to be updated for new map
	local door1 = create_door({x = 1, y = 5})
	local door2 = create_door({x = 2, y = 5})
	local door3 = create_door({x = 3, y = 5})
	local door4 = create_door({x = 5, y = 4})

	local pressure_plate1 = create_pressure_plate({x = 4, y = 1}, { door1, door2, door3, door4 })
	
	--local door2 = create_door({x = 7, y = 3})
	--local key1 = create_pickup_key({x = 6, y = 1}, { door2 })

	-- add objects to level
	local level1 = {
		--tree1,
		door1,
		door2,
		door3,
		door4,
		pressure_plate1,
		--key1,
	}

	level_loader:load_level_objects(level1)

end

function level_loader:load_level_objects(level_objects)
	self:unload_level_objects()
	self.current_level = level_objects
	for go in all(level_objects) do
		go:init()
		add(game_objects, go)
	end
end

function level_loader:unload_level_objects()
	if self.current_level == nil then return end
	for go in all(self.current_level) do
		go:init()
		remove(game_objects, go)
	end
end

function init_animations()

	-- define animated sprites
	animations["tree"] = {
		sprite_sequence = {64, 66},
		sprite_size = {x = 2, y = 2},
		speed = 1.5
	}

	animations["keycard"] = {
		sprite_sequence = {181, 182, 183, 182},
		sprite_size = {x = 1, y = 1},
		speed = 4
	}

	return animations
end

function animator:update()
	for obj in all(animated_objects) do
		local sprite_this_frame = get_sprite_animated(obj.anim.sprite_sequence, obj.anim.speed)
		for i = 0,obj.anim.sprite_size.x-1 do
			for j = 0,obj.anim.sprite_size.y-1 do
				mset(obj.position.x + i, obj.position.y + j, sprite_this_frame  + (i + j*16))
			end
		end
	end
end

function get_sprite_animated(frames, speed)
 	return frames[flr(time()*speed % #frames) + 1]
end

-->8
-- command ticker
function tick_command() 
	-- tick command will make player 1 move if they exist and are dead
	local player1 = player_list.player1
	if player1 != nil and not player1.is_alive then
		-- if current command + 1 is still a thing
		local command_to_run = player1.command_queue[player1.current_command]
		if command_to_run == nil then return end
		command_to_run.execute()
		player1.current_command += 1
	end
end

__gfx__
000888800000000044444444444444444444444444444444444444446211112600dddd0000555500444444448008800805050505eeeeeeee9999999900000000
0008000000000000444555555555555555555444455555544555555426111162000dd00000000000440000440000000050505050ee0ee0ee9000000900000000
0008000000000000445555555555555555555544454444544544445411111111d000000d50055005400000040080080000500505e000000e9099990900000000
0008888000000000455555555555555555555554454544544544545411166111dd0550dd50055005400440048008800855055050ee0ee0ee9090090900000000
0008000000000000455555555555555555555554454454544545445411166111dd0550dd50055005400440048008800805055005ee0ee0ee9090090900000000
0008000000000000455555555555555555555554454444544544445411111111d000000d50000005400000040080080050500500e000000e9099990900000000
0008000000000000455555555555555555555554455555544555555426111162000dd00000000000440000440000000000505055ee0ee0ee9000000900000000
000888800000000045555555555555555555555444444444444444446211112600dddd0000555500444444448008800850505050eeeeeeee9999999900000000
00000000000000004555555555555555555555544444444444444444411441144444444400000000777777777777777777777777000000000000000000000000
00000000000000004555555555555555555555544555555445555554115115114444444400000000700000000000000000000007000000000000000000000000
00000000000000004555555555555555555555544544445445444454154554514444444400000000700666666666666666666007000000000000000000000000
00000000000000004555555555555555555555544544545445454454415445144444444400000000706666666666666666666607000000000000000000000000
00000000000000004555555555555555555555544545445445445454415445144444444400000000706655555555555555556607000000000000000000000000
00000000000000004555555555555555555555544544445445444454154554514444444400000000706655555555555555556607000000000000000000000000
00000000000000004555555555555555555555544555555445555554115115114444444400000000706655555555555555556607000000000000000000000000
00000000000000004555555555555555555555544444444444444444411441144444444400000000706655555555555555556607000000000000000000000000
00000000000000004555555555555555555555544444444444444444000000000000000000000000706655557777777755556607666666660000000000000000
00000000000000004555555555555555555555544445555555555444000000000000000000000000706655557755557755556607666666660000000000000000
00000000000000004555555555555555555555544455555555555544000000000000000000000000706655557566665755556607666666660000000000000000
00000000000000004555555555555555555555544555555555555554000000000000000000000000706655557560065755556607666666660000000000000000
00000000000000004555555555555555555555544555555555555554000000000000000000000000706655557560065755556607666666660000000000000000
00000000000000004455555555555555555555444455555555555544000000000000000000000000706655557566665755556607666666660000000000000000
00000000000000004445555555555555555554444445555555555444000000000000000000000000706655557755557755556607666666660000000000000000
00000000000000004444444444444444444444444444444444444444000000000000000000000000706655557777777755556607666666660000000000000000
66666666666666666666666666666666666666666666666600000000000000000000000000000000706655555555555555556607000000000000000000000000
66777766667777666666666666000066660000666666666600000000000000000000000000000000706655555555555555556607000000000000000000000000
67777776677777766677776660000006600000066600006600000000000000000000000000000000706655555555555555556607000000000000000000000000
67777776677777766777777660000006600000066000000600000000000000000000000000000000706655555555555555556607000000000000000000000000
67777776677777766777777660000006600000066000000600000000000000000000000000000000706666666666666666666607000000000000000000000000
67777776677777766777777660000006600000066000000600000000000000000000000000000000700666666666666666666007000000000000000000000000
67777776677777766777777660000006600000066000000600000000000000000000000000000000700000000000000000000007000000000000000000000000
67666676676666766766667660666606606666066066660600000000000000000000000000000000777777777777777777777777000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000003bbbbb00000000003bbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00003bbbbbb0000000003bbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bb3bbbbbbbb00000bbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333bbbbbb0003333333bb33bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
333bb333bbbbb3003333b333bb33b300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03bbbbb33bb3b3b003bbbbb33bb333b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b333bb3b33333000b333bb3b3333b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333b333bbb303333333b333bbb30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0333353333bbbb300333333333b33b30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000554333333b300033354334333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005444440333000000544444033300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005544440000000000554444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055544444000000005554444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055545444000000005554544400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005445540000000000544554000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88808080004444000000000000333300000000005666666556666665000000000000000000000000000000000000000000000000000000000000000000000000
8000080004445440400000000334b330300000005077000550666605000000000000000000000000000000000000000000000000000000000000000000000000
88808080545454544000000033344b4b3b0000005066660550666605000000000000000000000000000000000000000000000000000000000000000000000000
80000000545454544000000034345444400000005070070650666657000000000000000000000000000000000000000000000000000000000000000000000000
8880808054549a444a00000054b49a544a0000005066660550666650000000000000000000000000000000000000000000000000000000000000000000000000
00000088545499444900000054549954490000005077070750666656000000000000000000000000000000000000000000000000000000000000000000000000
00008080544450544000000054344054300000005066660550666605000000000000000000000000000000000000000000000000000000000000000000000000
00008088555444445000000053b535445b0000005070070550666605000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0009a0000009a00a0a09a0a00909a00000a0a0a000a0a0a000a0a0a000a0a0a05555555555555555000000000000000000000000000000000000000000000000
0099a0009099a0a00099a0000099a009009c9c90009c9c90009c9c90009c9c905667777556600005000000000000000000000000000000000000000000000000
004990000049900000499090004990a0011111100111111001111110011111105666667556666605000000000000000000000000000000000000000000000000
00009000a000900a9000900000009000011111100111111001111110011111105066667557666605000000000000000000000000000000000000000000000000
00999a0000999a0000999a0000999a09057777500577bb50057bb75005bb77505066667557666605000000000000000000000000000000000000000000000000
049999a0049999a0049999a0a49999a0055500500555005005550050055580505066666557666665000000000000000000000000000000000000000000000000
049009a0049009a0049009a0049009a0055555500555555005555550055555505000066557777665000000000000000000000000000000000000000000000000
00499900a04999000049990a00499900000055500000555000005550000055505555555555555555000000000000000000000000000000000000000000000000
__gff__
0000808080000000000000000000000000008080800000000000808080000000000080808000000000008080800000000000000000000000000080808000000000000000000000000000000000000000808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1a1b1b1b1b1b1b1b1b1b1b1b1b1b1b1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2d2d2d2d2b2b2b2d2d2d2b2b2b2d2c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2d2d2d2d2b2b2b2d2d2d2b2b2d2d2c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2d2d2d2d2b2b2b2d2d2d2b2b2d2d2c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2d2d2d2d2d2d2d2d2d2d2b2d2d2d2c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2d2d2d2b2b2d2d2d2b2b2d2d2d2d2c1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2d2d2d2b2b2d2d2b2b2b2d2d2d2d2c1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2d2d2d2d2d2d2d2b2d2d2d2d2d2d2c1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2d2d2d2d2d2d2d2d2d2d2b2b2d2d2c1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2d2d2d2d2d2d2d2d2d2d2b2b2d2d2c1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2d2d2d2d2d2d2d2d2d2d2d2d2d2d2c1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2d2d2d2d2b2b2b2d2d2d2d2d2d2d2c1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2d2d2d2d2b2b2b2d2d2d2d2d2d2d2c1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2d2d2d2d2d2d2d2d2d2d2d2d2d2d2c1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2d2d2d2d2d2d2d2d2d2d2d2d2d2d2c1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a3b3b3b3b3b3b3b3b3b3b3b3b3b3b3c1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000800000e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e7500e750
001400000c7400c7400c7400c7400c7400c7400c7400c7400c7400c7400c7400c7400c7400c7400c7400c74009740097400974009740097400974009740097400974009740097400974009740097400974009740
00140000217402174021740217402174021740217402174021740217402174021740217402174021740217401c7401c7401c7401c7401c7401c7401c7401c7401c7401c7401c7401c7401c7401c7401c7401c740
00140000107401074010740107401074010740107401074010740107401074010740107401074010740107400e7400e7400e7400e7400e7400e7400e7400e7400e7400e7400e7400e7400e7400e7400e7400e740
001400201f7401f7401f7401f7401f7401f7401f7401f7401f7401f7401f7401f7401f7401f7401f7401f7401e7401e7401e7401e7401e7401e7401e7401e7401e7401e7401e7401e7401e7401e7401e7401e740
00140000215501c5502450024550000000000018550175000000015550000000000000000000000000000000215501c55024500245500000000000235501f5501a5501a5001c5501850000000000000000000000
00140000215501c550245002455000000000001a550005000000018550000000000015550155000000000000215501c5502450024550000000000023550215501f55001500185002150021550215502150021500
00140000006300c600076003f600256201c60000000000000060000000006300000025620006000000000000006300c600076003f600256201c60000000126100060000000006300000025620006000000000000
01140000006300c600076003f600256201c60000000000000060000000006300000025620006000000000000006300c600076003f600256201c60000000000000060000000006300000025620006001e62012610
__music__
01 01020705
02 03040806

