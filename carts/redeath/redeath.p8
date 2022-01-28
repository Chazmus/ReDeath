pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
-- main
-- The loop
game_objects = {}

function _init()

end

function _update()
	for go in all(game_objects) do
		go:update()
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
	printh("Moving towards target")
	-- local c = cocreate(function()
	-- 	while(not self:is_at_target()) do
	-- 		if(self.target.x > self.position.x) do
	-- 			self.position.x += 1
	-- 		else if(self.target.x < self.position.x) do
	-- 			self.position.x -= 1
	-- 		end
	-- 		if(self.target.y > self.position.y) do
	-- 			self.position.y += 1
	-- 		else if(self.target.y < self.position.y) do
	-- 			self.position.y -= 1
	-- 		end
	-- 		yield()
	-- 	end
	-- end
end

function player:draw()
	spr(000, self.position.x, self.position.y)
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
00aaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9a0aa0aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9aaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9a0000aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9a0000aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09a000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
