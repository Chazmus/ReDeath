pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
-- main
-- The loop
game_objects = {}

function _update()
	for go in all(game_objects) do
		go:update()
	end
end

function _draw()
	--cls(0)
	for go in all(game_objects) do
		go:draw()
	end
end
-->8
-- The player
player = {
	position = {x=0,y=0},
	target = {x=0,y=0},
	is_moving = false,
}

add(game_objects, player)

function player:update()
	if self.is_moving == false then
		if(btn(up)) then
			self.target.y -= 1
		end
		if(btn(down)) then
			self.target.y += 1
		end
		if(btn(left)) then
			self.target.x -= 1
		end
		if(btn(right)) then
			self.target.x += 1
		end

		if(self.position.x != self.target.x or self.position.y != self.target.y) then 
			self.is_moving = true
		end
	end

	if self.is_moving then
		self:move_towards_target()
	end

end

function player:move_towards_target()
	if(self.position.x == self.target.x & self.position.y == self.target.y) then
		printh("end movement")
		self.is_moving = false
		return;
	end

	if(self.position.x - self.target.x > 0)then
		self.position.x +=1
	else if(self.position.x - self.target.x < 0)
		self.position.x -=1
	end

	if(self.position.y - self.target.y > 0)then
		self.position.y +=1
	else if(self.position.y - self.target.y > 0)
		self.position.y -=1
	end
end

function player:draw()
	grid_pos = grid_to_pixel(self.position)
	spr(000, grid_pos.x, grid_pos.y)
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
