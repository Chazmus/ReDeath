pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
-- main
-- The loop
game_objects = {}
actions = {}

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
end

function _draw()
	cls(0)
	for go in all(game_objects) do
		go:draw()
	end
end
-->8
-- The player
player = {
	position = {x=0,y=0}, -- In pixel space
	target = {x=0,y=0}, -- In pixel space
	is_moving = false,
}


add(game_objects, player)

function player:update()
	if self.is_moving == false then
		if(btn(up)) then
			self.target.y -= 8
		end
		if(btn(down)) then
			self.target.y += 8
		end
		if(btn(left)) then
			self.target.x -= 8
		end
		if(btn(right)) then
			self.target.x += 8
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

function player:move_towards_target()
	local c = cocreate(function()
	 	while not self:is_at_target() do
			printh(time())
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
	spr(000, self.position.x, self.position.y)
	printh("x")
	printh(tostring(self.position.x))
	printh("y")
	printh(tostring(self.position.y))
end


-->8
-- utils
left,right,up,down,fire1,fire2=0,1,2,3,4,5
black,dark_blue,dark_purple,dark_green,brown,dark_gray,light_gray,white,red,orange,yellow,green,blue,indigo,pink,peach=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15

-- grid functions
function grid_to_pixel(grid_position)
	return {x=grid_position.x * 8, y=grid_position.y * 8}
end

function pixel_to_grid(grid_position)
	return {x=(grid_position.x * 8), y=(grid_position.y * 8)}
end
__gfx__
0008888000aaaa0044444444444444444444444444444444444444446211112600dddd0000555500444444448008800805050505eeeeeeee9999999900000000
000800000aaaaaa0444555555555555555555444455555544555555426111162000dd00000000000440000440000000050505050ee0ee0ee9000000900000000
000800009a0aa0aa445555555555555555555544454444544544445411111111d000000d50055005400000040080080000500505e000000e9099990900000000
000888809aaaaaaa455555555555555555555554454544544544545411166111dd0550dd50055005400440048008800855055050ee0ee0ee9090090900000000
000800009a0000aa455555555555555555555554454454544545445411166111dd0550dd50055005400440048008800805055005ee0ee0ee9090090900000000
000800009a0000aa455555555555555555555554454444544544445411111111d000000d50000005400000040080080050500500e000000e9099990900000000
0008000009a000a0455555555555555555555554455555544555555426111162000dd00000000000440000440000000000505055ee0ee0ee9000000900000000
000888800099990045555555555555555555555444444444444444446211112600dddd0000555500444444448008800850505050eeeeeeee9999999900000000
00000000000000004555555555555555555555544444444444444444411441144444444400000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544555555445555554115115114444444400000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544544445445444454154554514444444400000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544544545445454454415445144444444400000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544545445445445454415445144444444400000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544544445445444454154554514444444400000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544555555445555554115115114444444400000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555544444444444444444411441144444444400000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004555555555555555555555540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004455555555555555555555440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004445555555555555555554440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004444444444444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001020202000008000000000000040000000202020000000000000000000000000002020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00040000000001a000146001965019650146001260005650056501160010600156501565015600106001660007650076501660010600106001560010600106001060010600106000f6000c600000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000076000760007600076000760007500064000640007500076000760007600075000630006300065000760007600076000760007400064000640007600076000760007600065000640006500076000760
__music__
06 41024344

