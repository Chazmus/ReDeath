pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
-- main
-- The loop
game_objects = {}
actions = {}

function _init()
	for go in all(game_objects) do
		go:init()
	end
end

function _update()
	for go in all(game_objects) do
		go:update()
	end
	for c in all(actions) do
		if costatus(c) then
		  coresume(c)
		else
		  del(actions,c)
		end
	end

	-- Input utils update MUST be done last
	input_utils:update()
end

function _draw()
	cls(0)
	for go in all(game_objects) do
		go:draw()
	end
	map()
end
-->8
-- The player
player = {
	position = {x=8,y=8},
	room_position = {x = 0, y = 0},
	target = {x=8,y=8},
	is_moving = false,
	command_queue = {},
	current_command = 0,
	sprite_sequence = {051, 052, 051, 053},
	anim_speed = 8,
	last_move_time = 0
}

add(game_objects, player)

function player:init()
end

function player:update()
	if self.is_moving == false then
		command = nil
		if input_utils:get_button_down(fire1) then
			if self.current_command < 1 then 
				return 
			end
			self.command_queue[self.current_command - 1].unexecute()
			self.current_command -= 1
		end

		if input_utils:get_button_down(fire2) then
			input_utils:handle_hold_button(fire2, 1, 
				function() 
					self:undo_all_commands()
				end)
		end

		if(self.last_move_time + 0.133 > time()) then
			return
		end

		if input_utils:get_button_down(up) then
			command = {}
			function command.execute() 	
				if not check_for_collision(pixel_to_grid({x = self.target.x, y = self.target.y - 8})) then
					self.target.y -= 8
					command.success = true
				end
			end

			function command.unexecute()
				if not (self.command_queue[self.current_command-1].success == nil) 
				and self.command_queue[self.current_command-1].success then
					self.target.y += 8
				end
			end
		end

		if input_utils:get_button_down(down) then
			command = {}
			function command.execute() 	
				if not check_for_collision(pixel_to_grid({x = self.target.x, y = self.target.y + 8})) then
					self.target.y += 8
					command.success = true
				end
			end

			function command.unexecute()
				if not (self.command_queue[self.current_command-1].success == nil) 
				and self.command_queue[self.current_command-1].success then
					self.target.y -= 8
				end
			end
		end

		if input_utils:get_button_down(left) then
			command = {}
			function command.execute() 	
				if not check_for_collision(pixel_to_grid({x = self.target.x - 8, y = self.target.y})) then
					self.target.x -= 8
					command.success = true
				end
			end

			function command.unexecute()
				if not (self.command_queue[self.current_command-1].success == nil) 
				and self.command_queue[self.current_command-1].success then
					self.target.x += 8
				end
			end
		end

		if input_utils:get_button_down(right) then
			command = {}
			function command.execute() 	
				if not check_for_collision(pixel_to_grid({x = self.target.x + 8, y = self.target.y})) then
					self.target.x += 8
					command.success = true
				end
			end

			function command.unexecute()
				if not (self.command_queue[self.current_command-1].success == nil) 
				and self.command_queue[self.current_command-1].success then
					self.target.x -= 8
				end
			end
		end
		
		if (command != nil) then
			self.last_move_time = time()
			self.command_queue[self.current_command] = command
			self.command_queue[self.current_command].execute()
			self.current_command += 1
		end

		if(not self:is_at_target()) then
			self.is_moving = true
		end
	end

	if self.is_moving then
		self:move_towards_target()
	end
end

function player:is_at_target()
	return self.position.x == self.target.x and self.position.y == self.target.y
end

function player:undo_all_commands()
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
	end)

	add(actions, c)
end

function player:move_towards_target()
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

function player:draw()
	spr(get_sprite_animated(self.sprite_sequence, self.anim_speed), self.position.x, self.position.y)
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

collisionlayers = {7}

function check_for_collision(grid_position)
	local tile = mget(grid_position.x, grid_position.y);
	for i in all(collisionlayers) do
		if (fget(tile, i)) then
			return true;
		end
	end
	return false;
end

-->8
-- animated map objects

animator = {}
add(game_objects, animator)

animated_objects = {}

function init_animations()
	animations = {}

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

function animator:init()
	local animations = init_animations()

	-- initialise animated map objects
	add(animated_objects, {	position = {x = 4, y = 10}, -- celx, cely
							anim = animations["tree"]})

	add(animated_objects, {	position = {x = 10, y = 10},
							anim = animations["tree"]})

	add(animated_objects, { position = {x = 5, y = 5},
							anim = animations["keycard"]})

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

function animator:draw()
	-- spr(get_sprite_animated(sprite.sequence, sprite.speed), sprite.position.x, sprite.position.y, sprite.size.x, sprite.size.y)
end

function get_sprite_animated(frames, speed)
 	return frames[flr(time()*speed % #frames) + 1]
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
00000000000000004555555555555555555555544444444444444444411441144444444400000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544555555445555554115115114444444400000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544544445445444454154554514444444400000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544544545445454454415445144444444400000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544545445445445454415445144444444400000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544544445445444454154554514444444400000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544555555445555554115115114444444400000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544444444444444444411441144444444400000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544444444444444444000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544445555555555444000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544455555555555544000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544555555555555554000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544555555555555554000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004455555555555555555555444455555555555544000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004445555555555555555554444445555555555444000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004444444444444444444444444444444444444444000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aa7700000000000000000000cc66000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00aa770009aaaa70a000000000cc66000ccccc60c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09aaaa70090aa0a000aa770a0ccccc600c7cc7c000cc770c00000000000000000000000000000000000000000000000000000000000000000000000000000000
090aa0a009aaaaa009aaaa700c7cc7c00cccccc00ccccc7000000000000000000000000000000000000000000000000000000000000000000000000000000000
09aaaaa009000aa0090aa0a00cccccc00cc00cc00c7cc7c000000000000000000000000000000000000000000000000000000000000000000000000000000000
09000aa009900aa009aaaaaa01c00cc001ccccc00ccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
09900aa00099990099a00aaa01ccccc000111c0011c00ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
00999900055555009999aaaa0011cc0000000000111ccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
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
88808080004444000000000000333300000000005000000550000005000000000000000000000000000000000000000000000000000000000000000000000000
8000080004445440400000000334b3303000000051cc661551000015000000000000000000000000000000000000000000000000000000000000000000000000
88808080545454544000000033344b4b3b0000005100001551000015000000000000000000000000000000000000000000000000000000000000000000000000
800000005454545440000000343454444000000051c66cd8510000db000000000000000000000000000000000000000000000000000000000000000000000000
8880808054549a444a00000054b49a544a000000510000d0510000d0000000000000000000000000000000000000000000000000000000000000000000000000
00000088545499444900000054549954490000005166c6dd510000dd000000000000000000000000000000000000000000000000000000000000000000000000
00008080544450544000000054344054300000005100001551000015000000000000000000000000000000000000000000000000000000000000000000000000
00008088555444445000000053b535445b000000516cc61551000015000000000000000000000000000000000000000000000000000000000000000000000000
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
0009a0000009a00a0a09a0a00909a00000a0a0a000a0a0a000a0a0a000a0a0a00000000000000000000000000000000000000000000000000000000000000000
0099a0009099a0a00099a0000099a009009c9c90009c9c90009c9c90009c9c900000000000000000000000000000000000000000000000000000000000000000
004990000049900000499090004990a0011111100111111001111110011111100000000000000000000000000000000000000000000000000000000000000000
00009000a000900a9000900000009000011111100111111001111110011111100000000000000000000000000000000000000000000000000000000000000000
00999a0000999a0000999a0000999a09057777500577bb50057bb75005bb77500000000000000000000000000000000000000000000000000000000000000000
049999a0049999a0049999a0a49999a0055500500555005005550050055580500000000000000000000000000000000000000000000000000000000000000000
049009a0049009a0049009a0049009a0055555500555555005555550055555500000000000000000000000000000000000000000000000000000000000000000
00499900a04999000049990a00499900000055500000555000005550000055500000000000000000000000000000000000000000000000000000000000000000
__gff__
0000808080000000000000000000000000008080800000000000000000000000000080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0203030303030303030303030303030400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000008500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200020300000304020300000304001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200120000000014120000000014001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200120000000014120000000014001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200222300002324222300002324001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2223232323232323232323232323232400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
