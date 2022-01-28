pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
--picokaiju 1.1
--by @spoike 🐱

dirx,diry=split("1,-1,0,0,1,1,-1,-1"),split("0,0,1,-1,1,-1,-1,1")
nextdir=split("4,3,1,2")
debug,last_pressed={},0
map_size_x,map_size_y=54,15
cols=split("0,5,6")
smoke_patterns={░,▒,█}
roars=split("roar,rawr,gawr,grrr,grar,graw,rowr,warr")

menuitem(1,"clear highscore",function ()
 highscore=0
 dset(0,0)
end)

function _init()
 palt(15,true)
 cartdata("spoike_picokaiju_2")
 highscore=dget(0) 
 poke(0x5f2e,1)
 pal(3,133,1)
 pal(4,134,1)
 pal(1,0,1)
 logo_particles,entities,anims,floats,ripples,bq,xoff,xoff_diff,shake,tick,fade,intro_fade,intro_fade_diff,button_released={},{},{},{},{},{},0,0,0,0,0,0,0,true
 for i=1,25 do
  add(logo_particles, 
  {
   rndint(10,118),
   rndint(0,64)
  })
  add(logo_particles, 
   {
    rndint(10,118),
    rndint(65,128)
   })
 end

 start_generate_world()
 start_intro()
 -- testing:
 --_drw,_upd=draw_game,update_game
 --_drw,_upd=draw_game,update_debug
 --[[
 buildings_killed=10
 mobs_killed=20
 trees_killed=10
 level_ups=3
 turns=1
 xp=0xf000.f1ff
 --]]
 --start_game_over()
 --start_level_screen()
end

--[[
function update_debug()
 if btn(1) then
  xoff+=8
 elseif btn(0) then
  xoff-=8
 end
end
]]

stat_labels=split("turns taken,houses destroyed,mobs crushed,trees stomped,power ups grabbed,points")
function start_game_over()
 got_highscore=xp > highscore
 if got_highscore then
  dset(0,xp)
  highscore=xp
 end
 go_x,go_t,go_mov=110,0,false
 stats={turns,buildings_killed,mobs_killed,trees_killed,level_ups,xp}
 music(-1,100)
 add_bq(function ()
  for i=0,20 do
   fade=i*10
   yield()
  end
  music(6,1000)
  _drw,_upd=draw_gameover,update_gameover
  fade=0
 end)
 if player then player.hurt=true end
end

function draw_gameover()
  --rect(0,0,127,10,8)
  print_cs("all things must come to pass",10,7,4)
  draw_player_sprite(flr(go_x),24,false,go_mov,false,true)
  for i, entry in pairs(stats) do
    if go_t > i*20 then
      local t = min((go_t-(i*20))/20,1)
      local l = flr(lerp(0,entry,t)) 
      if i == #stats then
        l=get_score(xp)
      end
      print_c(
        pad_between(stat_labels[i],l),
        40+(8*(i-1)),7)
    end
  end
  --if got_highscore then
  if got_highscore and go_t > (#stats)*20 then
   print("high score!", 83, 88, 8)
  end

  if go_t > (#stats+2)*20 and blink then
    print_cs("press any button to restart", 110, 7, 4)
  end
end

function pad_between(str_a,str_b,width)
 width = width or 30
 width -= #str_a + #(str_b.."") + 2 
 local o = str_a.." "
 for i=0,width do
  o=o.."."
 end
 return o.." "..str_b
end

function update_gameover()
  local d = abs(sin(t()*0.2)*0.25)
  go_x-=d
  go_t+=1
  go_mov = d > 0.1
  if go_x<-8 then go_x=127 end

  if go_t > (#stats+2)*20 and btnp() > 0 then
   button_released=false
   start_intro()
   sfx(5)
  elseif btnp() > 0 then
   go_t=flr((go_t/20)+1)*20
  end
end

function spawn_player(x,y)
 player = {
  x=x,
  y=y,
  tx=flr(x/8),
  ty=flr(y/8),
  sel_dir=2,
  mov=false,
  flip=true,
  draw=draw_player
 }
 add(entities,player)
 add_roar()
 add_splash(player.x,player.y+4)
 add_ripple(flr(player.x/8),flr(player.y/8))
end

function start_generate_world()
 move_map={}
 music(-1,1000)
 -- test new abilities here
 abilities=split("grab,throw")
 abilities_to_level=split("hp_up,regen_up,energy_up,throw_up,zap")
 turns,xp,poison,hp,max_hp,energy,max_energy,regen,level_ups,combo,music_started,next_level_up=-1,0,0,5,5,5,5,1,0,0,false,0x0000.01f4
 xoff,player,entities,anims,bq,mobs,tiledata,mobs_killed,trees_killed,buildings_killed=0,nil,{},{},{},{},{},0,0,0
 mob_civ,mob_cop,mob_tank,mob_heli,mob_mad={},{},{},{},{}
 in_hand,throw_length,throw_strength,zap_range=nil,12,2,5
 procgen=cocreate(generate_world)
end

function generate_world()
 -- Shoreline
 local shore=rndint(3,5)
 for y=0,map_size_y do
  shore=mid(3,7,shore+rndint(-1,1))
  for x=0,map_size_x do
   local t = 0
   if shore>x then
    t=63
   elseif maybe() then
    --trees
    t=rndint(1,3)
   end
   mset(x,y,t)
  end
  yield()
 end
 prettify_tiles(0)

 copy_map(4,rndint(2,9),
  rndint(0,6)*5+1,17,
  3,3
 )
 prettify_tiles(0)
 for sx=7,map_size_x-7,5 do
  if maybe() then
    for i=0,8 do mset(sx,i,76) end
  end
  local y=2
  while y < 13 do
    local h=rndint(3,4)
    copy_map(sx,y,
      rndint(0,6)*5,h == 3 and 16 or 19,
      6,
      min(h+1,14-y)
    )
    yield()
    y+=h
  end
  if maybe(0.6) then
    for i=9,15 do
      mset(sx,i,76)
    end
  end
  prettify_tiles(1)
  yield()
 end
end

function prettify_houses(sx,sy,w,h)
 for x=sx,sx+w do
  for y=sy,sy+h do
   local tile = mget(x,y)
   if tile==1 then
    mset(x,y,rndint(1,3))
   elseif tile==5 then
    mset(x,y,rndint(5,11))
   elseif tile==12 then
    if x > 20 and maybe(0.25) then
      add_building(x,y,
        rndint(5, 8)
      )
    else
    mset(x,y,rndint(10,15))
    end
   elseif tile==112 then
    if x > 20 or maybe(0.25) then
      add_building(x,y,
        rndint(5,
          rndint(6,6+flr(x/5))
        )
      )
    else
      mset(x,y,rndint(5,14))
    end
   end
  end
 end
end

function copy_map(sx,sy,dx,dy,w,h)
  for i=0,h-1 do
   memcpy(0x2000+sx+((sy+i)*128),0x2000+dx+((dy+i)*128),w)
  end
  prettify_tiles(1)
  prettify_houses(sx,sy,w,h)
end

function update_procgen()
 if procgen and costatus(procgen) != "dead" then
  coresume(procgen)
 else
  procgen = nil
 end
end

function prettify_tiles(flag)
 for y=0,map_size_y do
  for x=0,map_size_x do
   local t=flr(mget(x,y)/16)*16
   if fget(t,flag) then
    local sig = tilesig(x,y,flag)
    mset(x,y,t+sig)
   end
  end
 end
end


function _update()
 if procgen then
  update_procgen()
 end
 tick+=1
 shake*=0.6
 last_pressed = btn()==0 and last_pressed+1 or 0
 show_cmds=player and _upd==update_game and last_pressed > 120
 blink=sin(t()*0.5)>=0
 for anim in all(anims) do
  if anim and costatus(anim) != "dead" then
   coresume(anim)
  else
   del(anims,anim)
  end
 end
 update_floats()
 if tick % 3 == 0 then
  update_ripples()
 end
 _upd()
end

function _draw()
 cls()
 _drw()
 camera()
 for idx,line in pairs(debug) do
  print(line,0,(idx-1)*7+1,0)
  print(line,0,(idx-1)*7,15)
 end
 --center_camera()
 --[[debug move_map
 for i,tile in pairs(move_map) do
  spr(137+tile[3], tile[1]*8, tile[2]*8)
  print(tile[4], tile[1]*8, tile[2]*8, 7)
 end
 --]]
end

function update_floats()
 for f in all(floats) do
  f.t+=1
  if f.t >= 30 then
   del(floats, f)
  end
 end
end

function add_float(text,x,y,fgcol,bgcol,bubble)
  text=text..''
  add(floats,{text,x,y,fgcol,bgcol,t=0,bubble=bubble})
end

function add_roar()
 shake=5
 if regen > 0 then
  hp=mid(1,hp+regen,max_hp)
 end
 add(floats, {rnd(roars),
  player.x+4,
  player.y,7,0,
  t=0,bubble=true})
end

function draw_floats()
 for f in all(floats) do
  local maxt,text = 14,f[1]..''
  local offx=#text*2
  if f.bubble then
   maxt = 13
   pal(8,1)
   spr(134,f[2]-3-offx,f[3]-mid(0,f.t,maxt)-3,3,2)
   pal(0)
   spr(134,f[2]-3-offx,f[3]-mid(0,f.t,maxt)-4,3,2)
  end
  print_s(f[1],f[2]-offx,f[3]-mid(0,f.t,maxt),f[4],f[5])
 end
end


-->8
-- main routines

function draw_game(disable_ui)
 center_camera()
 if not disable_ui then
  clip(0,8,128,120)
 end
 map(0,0,0,0,map_size_x,map_size_y)
 draw_water()
 if _upd==update_select_direction then
  local x,y = (player.tx-dirx[player.sel_dir])*8,
   (player.ty-diry[player.sel_dir])*8
  if sin(t()*4) > 0 then
   rectfill(x-1,y-1,x+8,y+8,8)
  end
 end
 for entity in all(entities) do
  entity.draw(entity)
 end
 -- draw ui
 clip()
 camera()
 if disable_ui then
  return
 end
 fillp()
 rectfill(0,0,128,8,0)
 rectfill(0,120,128,128)
 -- draw hp bar
 if max_hp > 0 and turns > 4 then
  spr(162,0,0)
  for i=1,max_hp do
   local x=i*2+6
   rectfill(x,2,x,7,5)
   if i<=hp then
   rectfill(x,2,x,6,7)
   end
  end
  if poison >= 1 then
    print("-"..poison,max_hp*2+10,3,8)
  end
 end
 local command=""
 if hp <= 2 then
  command=blink and "🅾️ roar to\n   heal "..regen.."hp" or ""
 elseif show_cmds then
  command="🅾️ roar"
 end
 print_s(command,1,9,7,2)

 -- draw energy bar
 if max_energy > 0 and turns > 4 then
  spr(163,120,0)
  for i=1,max_energy do
   local x=122-(i*2)
   rectfill(x,2,x,7,5)
   if i<=energy then
    rectfill(x,2,x,6,7)
   end
  end
 end
 command=""
 local cl=0
 if energy<=1 then
  command=in_hand==nil and "grab & chomp ❎" or "chomp    ❎"
  cl=#command
  command=command.."\nto recharge"
  command=blink and command or ""
 elseif show_cmds then
  command="abilities ❎"
  cl=#command
 end
 print_s(command,124-(cl*4),9,7,2)

 --line(64,0,64,128,8) debug center
 if combo >= 2 then
  local c = combo..""
  local s = mid(0,6,(combo/2)-2)
  local yoff=combo > 10 and (sin(t()*6)+sin(t()*8))*0.5 or 0
  if combo > 10 then
   pal(7,8)
  end
  local x 
  for i=1,#c do
    x = flr(58+(i*(8+s))-(#c*(4.5+s)))
    sspr((ord(c,i)-48)*8+32,
      80,
      6,8,
      x,yoff,
      6+s,8+s
    )
  end
  sspr(112,80,6,8,x+(8+s),yoff,6+s,8+s)
  pal(0)
 end
 if turns > 0 then
   print_s('TURN '..turns,1,121,6,5)
 end
 if xp > 0x0000.0000 then
  local xp_label='XP '..get_score(xp)..'/'..get_score(next_level_up)
  print_s(xp_label,128-(#xp_label*4),121,6,5)
 end
 if message then
  local y = player.y>64 and 8 or 110
  rectfill(2,y,125,y+11,1)
  rect(3,y+1,124,y+10,6)
  print_cs(message, y+3, 7, 4)
 end
 if not player and not procgen then
  print_cs("press 🅾️ to roar",121,7,4)
 end

 center_camera()
 draw_floats()

 camera()
 rectfill(0,128-fade,128,128,0)
end

function draw_water()
 -- waves
 for y=0,map_size_y do
  for x=0,map_size_x do
   if has_tile_flag(x,y,0) then
    local p = sin((t()-(x*0.2)-(y*0.15))*0.2)
    fillp(ˇ)
    if p>0.95 then
     fillp(▒)
    elseif p>0.70 then
     fillp(░)
    end
    if p>0.2 then
     rectfill(x*8+1,y*8+1,(x+1)*8-2,(y+1)*8-2,4)
    end
    fillp()
   end
  end
 end
 -- ripples
 for ripple in all(ripples) do
  fillp(░)
  for cell in all(ripple.previous_cells) do
   if has_tile_flag(cell.x,cell.y,0) then
    rectfill(
     cell.x*8+1,cell.y*8+1,
     (cell.x+1)*8-2,(cell.y+1)*8-2,6)
   end
  end
  fillp(▒)
  for cell in all(ripple.cells) do
   if has_tile_flag(cell.x,cell.y,0) then
    rectfill(
     cell.x*8+1,cell.y*8+1,
     (cell.x+1)*8-2,(cell.y+1)*8-2,6)
   end
  end
 end
end
function add_ripple(x,y,dir)
 add(ripples, {x=x,y=y,r=0,dir=dir,cells={}})
end
function update_ripples()
 for ripple in all(ripples) do
  ripple.previous_cells=ripple.cells
  ripple.r+=1
  local cells = {}
  local r=ceil(ripple.r)*8
  for i=0,r do
   local xi,yi=
    flr(sin(i/r)*ripple.r+ripple.x+0.5),
    flr(cos(i/r)*ripple.r+ripple.y+0.5)
   if has_tile_flag(xi,yi,0) and xi >= 0 and xi < map_size_x and yi >= 0 and yi < map_size_y then
    add(cells, {
     x=xi,
     y=yi})
   end
  end
  ripple.cells = cells
  if ripple.r > 10 then
   del(ripples, ripple)
  end
 end
end

function print_s(text,x,y,cfg,cbg)
 print(text,x,y+1,cbg)
 print(text,x,y,cfg)
end
function print_cs(text,y,cfg,cbg)
  print_s(text,64-(#text*2),y,cfg,cbg)
end
function print_c(text,y,cfg)
  print(text,64-(#text*2),y,cfg)
end

function draw_intro()
 center_camera()
 draw_game(true)
 camera()

 -- draw logo smoke particles
 local fade_scale = mid(0,1 - (intro_fade/256),1)
 for p in all(logo_particles) do
  local s = mid(0,p[2]/3,60)*fade_scale
  fillp(░)
  circfill(p[1],p[2],s,5)
 end
 for p in all(logo_particles) do
  local s = mid(0,p[2]/3,60)*fade_scale
  fillp(░)
  circfill(p[1],p[2],s-3,6)
  fillp()
  circfill(p[1],p[2],s-10,6)
 end

 -- for label
 -- big logo
 clip(max(0,(intro_fade*0.5)-20),0,128,128)
 pal(8,2)
 sspr(0,80,16,8,24,12,32,16)
 sspr(0,64,48,16,2,32,76,60)
 pal(0)
 sspr(0,80,16,8,24,10,32,16)
 sspr(0,64,48,16,2,29,76,60)

 -- bar with text
 clip(intro_fade*1.5,0,128,128)
 fillp(▤)
 rectfill(0,30,128,49,0)
 fillp()
 rectfill(0,34,128,43,0)
 print("picokaiju",9,38,8)
 print_s("picokaiju",9,36,7,8)

 -- kaiju dino
 palt(15, true)
 sspr(0,96,32,32,2,10+max(0,sin(t())*5),128,128)

 clip()
 rectfill(0,0,127,8,1)
 rectfill(0,120,127,127,1)

 if highscore > 0 then
  print_cs("highscore "..get_score(highscore),121,7,3)
 end
 if blink then
  print_cs("press any button to start",2,8,3)
 end

end

function update_intro()
 -- scrolling marquee
 xoff=xoff+xoff_diff
 if 
   (xoff_diff > 0 and xoff >= (map_size_x*8)-128) or
   (xoff_diff < 0 and xoff <= 0)
 then
  xoff_diff*=-1
 end
 -- update logo particles
 if button_released and btnp() > 1 then
  intro_fade_diff=6.28
  sfx(5)
 end
 if button_released == false and btn() == 0 then
  button_released=true
 end
 for p in all(logo_particles) do
  p[2]=mid(0,p[2]-1,150)
  if p[2] == 0 then
   p[2] = 200
  end
 end
 intro_fade=mid(0,intro_fade+intro_fade_diff,257)
 if intro_fade > 256 then
  _drw,_upd=draw_game,update_game
  intro_fade,intro_fade_diff=0,0
  start_generate_world()
 end
end

function start_intro()
  music(0)
  _drw,_upd=draw_intro,update_intro
  xoff=0
  xoff_diff=0.20
  intro_fade=255
  intro_fade_diff=-10
end

function rndint(a,b)
 local range = max(a,b)-min(a,b)
 return flr(rnd(range+1))+min(a,b)
end

player_body={16,38}
player_feet={{32,33},{40,41}}
function draw_player(player)
 local on_water = has_tile_flag(player.tx,player.ty,7)
 draw_player_sprite(player.x,player.y,player.flip,player.mov,on_water,player.hurt,player.blinking)
end

function draw_player_sprite(x,y,flip,mov,on_water,hurt,blinking)
 local s=hurt and 2 or 1
 y = y-4
 x = flip and x-9 or x-8--flip and x-5 or x
 if blinking and tick % 4 > 1 then
  pal(hurt and 4 or 7,8)
 end
 if not on_water then
  spr(player_body[s],x+4,y,2,1,flip) -- body
  local f = get_frame(player_feet[s],not mov)
  spr(f,flip and x+9 or x+7,y+8,1,1,flip) -- legs
 else
  spr(player_body[s],x+4,y+2,2,1,flip) -- body
 end
 if blinking then
  pal(0)
 end
end

function has_tile_flag(tx,ty,flag)
 return fget(mget(tx,ty),flag)
end

function add_anim(anim, arg, arg2)
 return add_coroutine(anims, anim, arg, arg2)
end

function add_bq(routine, arg, arg2)
 return add_coroutine(bq, routine, arg, arg2)
end

function add_coroutine(arr, routine, arg, arg2)
 return add(arr, cocreate(function () routine(arg, arg2) end))
end

function co_seq(sequence, start_after)
 local seq={}
 for a in all(sequence) do add(seq,cocreate(a)) end
 return function()
  for i=0,(start_after or 0) do
   yield()
  end
  while #seq>0 do
   local a=seq[1]
   if costatus(a)~="dead" then
    coresume(a)
    yield()
   else
    del(seq,a)
   end
  end
 end
end

function fix_mob_positions()
  for mob in all(mobs) do
    put_entity_at(mob.tx,mob.ty,mob)
  end
end

function move_player(dir)
 sfx(4)
 previous_combo=combo
 local bounce=false
 local ptx,pty=player.tx,player.ty
 local ntx,nty= player.tx-dirx[dir],player.ty-diry[dir]

 local mob = entity_at(ntx,nty)
 mob = mob != nil and mob.d == 0 and mob or nil
 local crushable_tile=is_tile_crushable(ntx,nty)
 player.sel_dir=dir
 if dir<3 then
  player.flip=dir==2
 end 
 if energy < 1 and (
   mob or crushable_tile
 ) then
  -- out of energy
  player.hurt=true
  sfx(24)
  return add_bq(
    co_seq({
      show_message('out of energy', 20),
      function() player.hurt=false end
    })
  )
 end
 local animation = {}
 if mob and mob.hp > 0 then
  -- bounce against building
  mob.hp-=1
  add(animation, do_bounce(player, ptx*8,pty*8,ntx*8,nty*8))
 else
  -- go!
  add(animation, do_move(player, ptx*8, pty*8, ntx*8, nty*8, 8, true))
 end

 check_and_kill(ntx,nty,false)

 queue_ai_turn()
 add_bq(co_seq(animation))
 add_anim(co_seq({
  function ()
   if   
    (has_tile_flag(ptx,pty,7) and not has_tile_flag(ntx,nty,7)) or
    (not has_tile_flag(ptx,pty,7) and has_tile_flag(ntx,nty,7))
   then
    sfx(32)
    add_splash(ptx*8,pty*8+4)
   end
  end
 },4))
end

function is_tile_crushable(tx,ty)
 return fget(mget(tx,ty),6)
end

function kill_tile(ntx,nty,free_energy)
 if not is_tile_crushable(ntx,nty) then return end
 sfx(8)
 combo+=1
 add_anim(function()
  add_splash(ntx*8,nty*8)
  local p=25
  if mget(ntx,nty) >= 5 then -- goal tile is a house or tree
    -- crush a house
    buildings_killed+=1
    mset(ntx,nty,rndint(80,95))
    p=50
    add_smoke(ntx*8,nty*8+4)
    shake+=1
  else
    trees_killed+=1
    mset(ntx,nty,4)
  end
  if not free_energy then energy=max(0,energy-1) end
  add_xp_points(p,{x=ntx*8,y=nty*8})
 end)
end

function kill_mob(mob, free_energy)
  if mob.d != 0 then return end
  sfx(8)
  del(mobs,mob) -- remove before ai turn
  get_points_from(mob)
  add_anim(function()
    mob.destroy(mob)
  end) 
  if not free_energy then energy=max(0,energy-1) end
end

function queue_ai_turn(is_blocking)
 local a = is_blocking and add_bq or add_anim
 a(co_seq({spawn_mob, move_mobs},5))
 turns+=1
 if previous_combo == combo then
  combo=0
 end
 if poison > 0 then
  add_bq(poison_player)
 end
end

function poison_player()
 message="kaiju is poisoned"
 player.blinking,player.hurt = true,true
 local damage = poison*-1
 add_float(damage,player.x+4,player.y,8)
 hp+=damage
 for i=1,20 do
  yield()
 end
 player.blinking,player.hurt=false,false
 message=nil
end

function do_move(entity, from_x, from_y, to_x, to_y, frames, do_calc_tile)
 if do_calc_tile then
  entity.tx,entity.ty=flr(to_x/8),flr(to_y/8)
 end
 return function()
  entity.mov=true
  for i=0,frames do
   local t = i/frames
   entity.x,entity.y=lerp(from_x,to_x,t),lerp(from_y,to_y,t)
   center_on_player()
   yield()
  end
  entity.x,entity.y=to_x,to_y
  entity.mov=false
 end
end

function do_bounce(entity, from_x, from_y, to_x, to_y)
 return function()
  entity.mov=true
 local t
  for i=0,4 do
   t = i/8
   entity.x,entity.y=lerp(from_x,to_x,t),lerp(from_y,to_y,t)
   yield()
  end
  entity.hurt=true
  for i=0,8 do
   t = (8+i)/16
   entity.x,entity.y=lerp(to_x,from_x,t),lerp(to_y,from_y,t)
   yield()
  end
  entity.mov=false
  entity.hurt=false
 end
end

function show_message(text, frames)
  return function ()
    message=text
    for i=0,frames do
      yield()
    end
    message=nil
  end
end

function move_mobs()
 for mob in all(mobs) do
  mob.has_moved=false
 end
 -- do a quick shortest path from the player
 -- run ai on mobs who are found during this process 
 local next,visited={{player.tx,player.ty,0,0}},{}
 local iter=0
 while #next > 0 and iter < 200 do
  iter+=1
  qsort(next, function(a,b) return b[4] > a[4] end)
  local n = deli(next,1)
  local x,y=n[1],n[2]
  visited[as_key(x,y)]=n
  for i=1,4 do 
    local nx,ny=x+dirx[i],y+diry[i]
    if visited[as_key(nx,ny)] == nil and has_tile_flag(x,y,1) then
     local mob = entity_at(nx,ny)
     if mob and mob.tick and not mob.has_moved then
      mob.tick(mob)
     end
     if has_tile_flag(nx,ny,1) and
        nx >= 0 and nx <= map_size_x and ny >= 0 and ny <= map_size_y 
     then
      move_map[as_key(x,y)]=n
      add(next,{nx,ny,i,n[4]+1})
     end
    end
  end
 end
 for mob in all(mobs) do
  if mob.tick and not mob.has_moved then mob.tick(mob) end
 end
end

function as_key(tx,ty)
 return tx..":"..ty
end
function entity_at(tx,ty)
 return tiledata[as_key(tx,ty)]
end
function put_entity_at(tx,ty,entity)
  tiledata[as_key(tx,ty)]=entity
end
function remove_entity(e)
 del(entities,e)
 put_entity_at(e.tx,e.ty,nil)
end
function remove_mob(mob)
 if mob.group then
  del(mob.group,mob)
 end
 del(mobs, mob)
 remove_entity(mob)
end

function spawn_mob()
 --debug[2]=#mob_civ.." "..#mob_cop.." "..#mob_tank
 -- spawn every second turn
 if turns % 2 > 0 then return end

 local roads,map_edges={},{}
 for x=max(0,player.tx-10),min(map_size_x,player.tx+10) do
  for y=1,map_size_y-1 do
   if y==player.y and x==player.x then break end
   if has_tile_flag(x,y,1) and entity_at(x,y) == nil then
    local road={x=x,y=y}
    if y==1 or y==map_size_y-1 then
     add(map_edges,road)
    else
     add(roads,road)
    end
   end
  end
 end
 shuffle(roads)
 shuffle(map_edges)

 local multiplier=ceil((buildings_killed+mobs_killed+trees_killed)/60)

 -- spawn civvies
 if #mob_civ<5*multiplier then
  mob=create_mob("people",mob_civ,roads[1],draw_civilian)
  mob.passive = true
 else
  -- secretly despawn civvies far away
  for civ in all(mob_civ) do
    if (dist(civ,player) > 10) remove_mob(civ)
  end
 end
 
 if (not music_started) return
 local edge,mob=map_edges[1]
 if maybe() and #mob_cop < multiplier*2 then
  create_mob("cop car",mob_cop,edge,draw_cop)
 elseif buildings_killed>20 and maybe() and #mob_heli < multiplier then
  mob = create_mob("copter",mob_heli,edge,draw_heli)
  mob.flying=true
 elseif buildings_killed>40 and maybe() and #mob_tank < (multiplier*2) then
  mob=create_mob("tank",mob_tank,edge,draw_tank)
  mob.str = 2
  mob.range = 5
  mob.points = 300
 elseif buildings_killed > 80 and #mob_mad < 1 then
  mob=create_mob("mad scientist",mob_mad,edge,draw_mad)
  mob.flying = true
  mob.str = 2
  mob.poison = 1
  range = 2
  mob.points = 800
 end
end

function create_mob(label,group,point,draw)
 local x,y=point.x,point.y
 local mob = {
  label=label,
  group=group,
  tx=x,
  ty=y,
  x=x*8,
  y=y*8,
  hp=0,
  dir=1,
  str=1,
  d=0,
  tick=tick_ai,
  destroy=destroy_simple_mob,
  points=150,
  range=1.5,
  draw=draw
 }
 put_entity_at(x,y,mob)
 add(entities,add(mob.group,add(mobs,mob)))
 return mob
end

function destroy_simple_mob(mob)
 mobs_killed+=1
 shake+=3
 add_splash(mob.x,mob.y+4)
 remove_mob(mob)
end
function get_points_from(entity)
 if entity.d and entity.d>0 then return end
 if entity.points then
  combo+=1
  add_xp_points(entity.points,entity)
 end
end
function add_xp_points(p,coords)
  p*=combo
  coords=coords or player
  add_float(p,coords.x+4,coords.y,7)
  xp += p >> 16
end

function add_building(x,y,h)
 local building = {
  x=x*8,
  y=y*8,
  tx=x,ty=y,
  h=h or 8,
  draw=draw_building,
  roof=rndint(96,106),
  wall=rndint(112,122),
  update=update_building,
  destroy=destroy_building,
  points=200+((h-5)*100),
  d=0,
  hp=1,
 }

 put_entity_at(x,y,building)
 mset(x,y,rndint(80,95))
 add(entities, building)
end
function destroy_building(b)
 if b.d != 0 then return end
 shake=7
 b.d=1
 buildings_killed+=1
 b.particles = {}
 for i=1,5 do
  add(b.particles, {
   x=i+b.x,
   py=rndint(1,5),
   radius=2,
   pattern=rnd(smoke_patterns),
   col=rnd(cols)
  })
 end
end
function update_building(b)
 if b.d>0 then
  b.h*=0.9
 end
 for p in all(b.particles) do
  p.py=(p.py+0.5)%5
  p.y=b.y-p.py+6
 end
 if b.h <= 0.1 then
  add_smoke(b.x,b.y)
  remove_entity(b)
 end
end
function draw_building(b)
 if (b.hp == 0) then
  pal(5,3)
 end
 for i=1,ceil(b.h/8) do
  spr(b.wall,b.x,b.y-((i-1)*8))
 end
 spr(b.roof,b.x,b.y-b.h+b.d)
 pal(0)
 if b.particles then draw_particles(b) end
end

function draw_civilian(civilian)
 spr(get_frame{34,34,35,35}, civilian.x, civilian.y)
end
function draw_cop(cop)
 spr(get_frame(cop.dir > 2 and {22,23} or {20,21}), cop.x, cop.y,1,1,true,cop.flip)
end
function bob() return abs(sin(t()*0.2)*2) end
function draw_heli(heli)
 spr(
   get_frame{42,43},
   heli.x,heli.y-2-bob(),1,1,heli.dir%2==0,
   heli.flip
 )
end
function draw_mad(mad)
  spr(
    get_frame{28,29},
    mad.x,mad.y-2-bob(),1,1,mad.dir%2==0,
    mad.flip
  )
end
function draw_tank(tank)
 spr(23+tank.dir,tank.x,tank.y,1,1,false,tank.flip)
end

function can_ai_shoot(entity)
 local distance = dist(entity,player)
 if distance > entity.range then
  return false
 end
 for i=1,(entity.range < 2 and 8 or 4) do
  if check_dir(entity.tx,entity.ty,entity.range,i) then
    return true
  end
 end
 return false
end

function check_dir(sx,sy,range,dir)
 for r=1,range do
  local x,y=sx+(dirx[dir]*r),sy+(diry[dir]*r)
  if entity_at(x,y) != nil or
    is_tile_crushable(x,y) then 
   return false
  end
  if player.tx==x and player.ty==y then
   return true
  end
 end
 return false
end

function tick_ai(entity)
  if entity.passive or entity.has_moved then return end
  -- entity ai
  entity.has_moved=true
  if can_ai_shoot(entity) then
    add_bq(shoot_from_mob, entity, entity.label.." takes a shot")
    return
  end
  local move_tile=move_map[as_key(entity.tx,entity.ty)]
  --debug[1]=move_tile[3]
  local mob = entity_at(entity.tx,entity.ty)
  if move_tile and not entity.flying and (not mob or not mob.has_moved) then
    move_mob(entity,move_tile[3])
    return
  end
  local path=nil
  for i=1,(entity.flying and 8 or 4) do
    local x,y=entity.tx-dirx[i],entity.ty-diry[i]
    local mob = entity_at(x,y)
    if
        not (mob != nil and (mob.draw == draw_building or mob.has_moved))
        and not (x == player.tx and y == player.ty)
        and (has_tile_flag(x,y,1) or entity.flying)
        and (not entity.previous or not (
          entity.previous.x==x and entity.previous.y==y
        ))
    then
      local d=dist(player,{x=x*8,y=y*8})
      if path == nil or (path.d > d and mdist(path, entity.previous) > 0) then
      path = {x=x,y=y,dir=i,d=d}
      end
    end
  end
  entity.previous=path
  if path != nil then
    move_mob(entity,path.dir)
  end
end

function shoot_from_mob(mob, m)
  sfx(23)
  message=m
  local bullet = {x=mob.x,y=mob.y,radius=1,col=8}
  local bullet_emitter = {
    x=mob.x,
    y=128,
    draw=draw_particles,
    particles={bullet}
  }
  add(entities, bullet_emitter)
  local l = 5+(dist(mob,player)*2)
  for i=0,l do
   bullet.x,bullet.y=lerp(mob.x+4,player.x+2,i/l),lerp(mob.y,player.y,i/l)
   yield()
  end
  del(entities, bullet_emitter)
  player.blinking,player.hurt = true,true
  add_float(mob.str*-1,player.x+6,player.y,8)
  hp=max(0,hp-mob.str)
  poison+=mob.poison or 0
  for i=0,30 do yield() end
  message,player.blinking,player.hurt = nil,false,false
end

function move_mob(mob,dir)
  local sx,sy=mob.tx,mob.ty
  local nx,ny=mob.tx-dirx[dir],mob.ty-diry[dir]
  local to_swap = entity_at(nx, ny) or nil
  put_entity_at(sx,sy,to_swap)
  if to_swap then
   to_swap.tx,to_swap.ty=sx,sy
  end
  put_entity_at(nx,ny,mob)
  mob.tx,mob.ty,mob.dir=nx,ny,dir

  return add_anim(function()
    for i=0,7 do
      if to_swap then
       to_swap.has_moved=true
       to_swap.x+=dirx[dir]
       to_swap.y+=diry[dir]
      end
      mob.x-=dirx[dir]
      mob.y-=diry[dir]
      yield()
    end
    if to_swap then
      to_swap.x,to_swap.y=sx*8,sy*8
    end
    mob.x,mob.y=nx*8,ny*8
  end)
end

function perform_throw()
  local x,y,dir=player.x,player.y,player.sel_dir
  local entity=add(entities, {
    x=x,y=y,flip=true,
    dir=dir,draw=in_hand.draw})
  add_bq(function()
    sfx(45)
    local tl=throw_length*4
    local strength_left=throw_strength
    for i=0,tl do
     if strength_left==0 then
      break
     end
     local t=i/tl
     x,y=x-dirx[dir]*2,y-diry[dir]*2
     local b = abs(cos(t))*4
     entity.x=x-2
     entity.y=y-b
     if in_hand.label == "people" and i == 4 then break end
     local tx,ty=flr(x/8),flr(y/8)
     if i%4 == 2 then
      if check_and_kill(tx,ty,true) then
        strength_left-=1
        dir=nextdir[dir]
      elseif tx==player.tx and ty==player.ty and i > 4 then
        add_float("catch",player.x+4,player.y,7)
        del(entities, entity)
        sfx(25)
        return
      end
     end
     if i%4 == 0 and b < 1 then sfx(46) end
     yield()
    end
    sfx(8)
    remove_mob(in_hand)
    in_hand=nil
    abilities[1]="grab"
    destroy_simple_mob(entity)
  end)
  queue_ai_turn(true)
end

function check_and_kill(tx,ty,free_energy)
 local mob,killed = entity_at(tx,ty),false
 
 if mob then
  kill_mob(mob,free_energy)
  killed = true
 end
 if is_tile_crushable(tx,ty) then
  kill_tile(tx,ty,free_energy)
  killed = true
 end
 -- crush road
 local tile = mget(tx,ty)
 if fget(tile) == 2 then
  sfx(47)
  mset(tx,ty,tile+112)
 end
 add_smoke(tx*8,ty*8)
 return killed
end

function add_zap(x,y,dir,length,perform_after)
 local zapper=add(entities,
  {x=x,y=y,tx=x,ty=y,draw=draw_zap}
 )
 shake+=5
 add_bq(function()
  local tl=length*4
  for i=1,tl do
   local t=i/tl
   zapper.tx,zapper.ty=x+4-(dirx[dir]*length*t*8),y+4-(diry[dir]*length*t*8)
   if i%4==0 then
    check_and_kill(flr(zapper.tx/8),flr(zapper.ty/8),true)
   end
   yield()
  end
  del(entities,zapper)
  if perform_after then perform_after() end
 end)
end
function draw_zap(zapper)
  line(
    zapper.x+4,
    zapper.y,
    zapper.tx,
    zapper.ty,
    rnd(split("1,6,7,8,8,8"))
  )
end

function add_smoke(x,y)
 local emitter = add(entities, {x=x,y=y,type="smoke",draw=draw_particles,particles={}})
 local end_turn = turns+5
 add_anim(function()
  for i=0,10 do
   add(emitter.particles, {x=x+rndint(0,4),y=y+rndint(0,5),col=rnd(cols),radius=0,pattern=rnd(smoke_patterns)})
  end
  while end_turn > turns do
   for p in all(emitter.particles) do
     p.y-=0.5
     p.radius *= 0.98
     if p.y < y-10 then
      p.y=y
      p.radius=2
     end
   end
   yield()
  end
  del(entities, emitter)
 end)
end

function add_splash(x,y)
 local emitter = {x=x,y=y,type="splash",draw=draw_particles,particles={}}
 add(entities, emitter)
 add_anim(function ()
  for i=0,20 do
   add(emitter.particles, {x=x,y=y,dx=rnd(2)-1,dy=-1-rnd(3),col=rnd(cols),radius=rnd(1.1)})
  end
  while #emitter.particles > 0 do
   for p in all(emitter.particles) do
    p.dy+=0.4
    p.x+=p.dx
    p.y+=p.dy
    if p.y>y then
     del(emitter.particles, p)
    end
   end
   yield()
  end
  del(entities, emitter)
 end)
end

function draw_particles(emitter)
 for p in all(emitter.particles) do
  fillp(p.pattern)
  circfill(p.x,p.y,p.radius,p.col)
  fillp()
 end
end

function center_on_player()
  if player==nil then return end
  xoff=mid(0,
     flr(player.x-60),
     (map_size_x*8)-120
    )
end
function center_camera()
  camera(
   xoff,
   flr(sin(t()*7)*shake)
  )
end

function get_frame(frames,paused)
 if paused then
  return frames[1]
 end
 return frames[
  1 + flr((tick*0.25) % (#frames))
 ]
end

function update_game()
 zsort_entities()
 for entity in all(entities) do
  if entity.update then entity.update(entity) end
 end
 if #bq>0 then
  local e=bq[1]
  if costatus(e) != "dead" then
    if not coresume(e) then
      del(bq, e)
    end
  else
    del(bq, e)
  end
  if #bq > 0 then
    return
  end
 end
 if not procgen and not player and btn(4) then
  -- spawning player
  spawn_player(8,56)
  --music(10,1000)
 end
 if not music_started and (player and player.tx>10 or buildings_killed >= 2) then
  music(12,100)
  music_started=true
 end
 if not player or player.hurt then
  return
 end
 if hp <= 0 then
  start_game_over()
  sfx(44)
  return
 end
 if xp >= next_level_up then
  start_level_screen()
  return
 end
 if btn()>0 then fix_mob_positions() end
 if btn(4) then
  sfx(3)
  previous_combo=combo
  add_roar()
  queue_ai_turn(true)
  return 
 end
 if btn(5) then
  return start_ability_menu()
 end
 for i=1,4 do
  if btn(i-1) then
   local nx,ny = player.tx-dirx[i], player.ty-diry[i]
   if nx >= 0 and
      nx <= map_size_x-1 and
      ny >= 1 and
      ny <= map_size_y-1
   then
    move_player(i)
    break
   end
  end
 end
end

function start_level_screen()
  _drw=draw_level_screen
  next_level_up,level_screen_fade,selected_powerup,powerups=
   next_level_up+(next_level_up*(next_level_up <= 0x0000.2710 and 2 or 1)),0,1,{}
  local abils = shuffle(abilities_to_level)
  for i=1,min(3,#abils) do
    add(powerups,abils[i])
  end
  -- add to test
  --add(powerups,"zap_up")
  if #powerups < 3 then
   add(powerups,"skip")
  end

  add_bq(function ()
   for i=0,8 do 
    level_screen_fade=(i+1)/8
    yield()
   end
   level_screen_fade=1
   _upd=update_level_screen
  end)
end

function exit_level_screen()
  level_ups+=1
  add_anim(function ()
   for i=0,8 do 
    level_screen_fade=1-((i+1)/8)
    yield()
   end
   level_screen_fade=0
   local p_key = powerups[selected_powerup]
   powerup_perform[p_key]()
   _upd,_drw=update_game,draw_game
  end)
end

function update_level_screen()
  if level_screen_fade < 1 then return end
  if btnp(3) then
    sfx(5)
    selected_powerup=mid(1,#powerups,selected_powerup+1)
  elseif btnp(2) then
    sfx(5)
    selected_powerup=mid(1,#powerups,selected_powerup-1)
  elseif btn(5) then
    sfx(6)
    exit_level_screen()
  end
end

powerup_data={
 hp_up=split("hp up,increases max hp by 5"),
 regen_up=split("hp regen up,increases hp regeneration\nper roar by 1"),
 energy_up=split("energy up,increases max energy by 5"),
 zap=split("zap,shoot laser from your eyes\nagainst enemies along a\ncolumn or row\n\nrange: 5"),
 zap_up=split("zap range up,increases zap range by\n1 tile"),
 --throw=split("throw,throws heavy objects in\nyour hand with each hit\nturning thrown object ccw\n\nrange: 10"),
 throw_up=split("throw str up,throw will hit another mob\nor building and turn\ndirection counterclockwise\n\n...like a boomerang"),
 skip=split("skip,skips this powerup")
}
powerup_perform={
  hp_up=function()
   max_hp+=5
   hp=hp+5
   if max_hp == 20 then del(abilities_to_level,"hp_up") end
  end,
  regen_up=function()
    regen+=1
    if regen == 5 then del(abilities_to_level,"regen") end
  end,
  energy_up=function()
    max_energy+=5
    energy=energy+5
    if max_energy == 20 then del(abilities_to_level,"energy_up") end
  end,
  zap=function() enable_ability("zap","zap_up") end,
  zap_up=function() zap_range+=1 end,
  --[[
  throw=function() enable_ability("throw","throw_up") end,
  ]]
  throw_up=function() throw_strength+=1 end,
  skip=function() end
}
function enable_ability(id,to_add)
  add(abilities,id)
  del(abilities_to_level,id)
  if to_add then add(abilities_to_level,to_add) end
end
function draw_level_screen()
  draw_game()
  local y=min(119,lerp(5,119,level_screen_fade))
  local ky=lerp(-16,4,level_screen_fade)
  clip(0,0,128,y+1)
  rectfill(5,8,122,y,0)
  rect(5,8,122,y,7)
  pal(8,2)
  spr(128,38,ky+1,6,2)
  pal(0)
  spr(128,38,ky,6,2)
  if level_screen_fade >= 1 then
   print_cs('level up',10,7,5)
  end
  print_cs('select a power up',25,7,2)
  print_cs('confirm with ❎',31,6,2)
  for i,p in pairs(powerups) do
   local is_selected=i==selected_powerup
   local powerup = powerup_data[powerups[i]]
   print((is_selected and "●" or "  ")..powerup[1],20,40+(i*8),is_selected and 8 or 7)
  end
  print(powerup_data[powerups[selected_powerup]][2],10,80,6)
end

function start_ability_menu()
  sfx(6)
  _drw=draw_ability_menu
  ability_fade,selected=0,1
  add_bq(function ()
    ability_fade=0
    for i=0,4 do
      local t=(i+1)/5
      ability_fade=lerp(0,103,t)
      xoff=mid(0,map_size_x*8-32,flr(lerp(player.x-58,player.x-32,t)))
      yield()
    end
    _upd=update_ability_menu
  end)
end

function update_ability_menu()
  if ability_fade < 103 then return end
  if btnp(3) then
    sfx(5)
    selected=mid(1,selected+1,#abilities)
  elseif btnp(2) then
    sfx(5)
    selected=mid(1,selected-1,#abilities)
  elseif btnp(4) then
   -- exit
   sfx(7)
   exit_ability_menu()
  elseif btnp(5) then
   -- selected ability
   sfx(6)
   local a = ability_map[abilities[selected]]
   if not can_use_ability(a) then
    return
   end
   if a.skip_selection then
    handle_selected_ability()
   else
    _upd=update_select_direction
   end
  end
end

function update_select_direction()
 for i=1,4 do
  if btnp(i-1) then
    sfx(5)
   player.sel_dir=i
   if i==1 then
    player.flip=false
   elseif i==2 then 
    player.flip=true
   end
  end
 end
 if btnp(4) then
  -- go back
  sfx(7)
  _upd=update_ability_menu
 elseif btnp(5) then
  sfx(6)
  handle_selected_ability()
 end
end

function handle_selected_ability()
  previous_combo = combo
  local a = ability_map[abilities[selected]]
  if a.cost then
    energy=max(0,energy-a.cost)
  end
  add_anim(a.perform,
    player.tx-dirx[player.sel_dir],
    player.ty-diry[player.sel_dir]
  )
  exit_ability_menu()
end

function exit_ability_menu()
  _upd=update_game
  add_bq(function ()
    for i=0,8 do
      local t=(i+1)/8
      ability_fade=lerp(103,0,t)
      xoff=mid(0,map_size_x*8-120,flr(lerp(player.x-32,player.x-58,t)))
      yield()
    end
    center_on_player()
    _drw=draw_game
  end)
end

ability_map={
  chomp={
    perform=function()
      message="chomps "..in_hand.label.." +5 ENERGY"
      local ct=rnd(split("chomp,crunch"))
      shake+=7
      add_float(
       ct,
       player.x+4,
       player.y-8,
       7
      )
      add_splash(player.x,player.y+4)
      sfx(26)
      abilities[1],in_hand.x,in_hand.y="grab",player.x,player.y
      get_points_from(in_hand)
      destroy_simple_mob(in_hand)
      in_hand=nil
      energy=min(max_energy,energy+5)
      for i=0,10 do yield() end
      queue_ai_turn()
      for i=0,30 do yield() end
      message=nil
    end,
    skip_selection=true
  },
  grab={
    perform=function (tx,ty)
     local mob = entity_at(tx,ty)
     if mob and mob.label then
      abilities[1]="chomp"
      remove_entity(del(mobs,mob))
      in_hand=mob
      add_float(rnd(split("grab,yoink")),player.x+4,player.y,7)
      sfx(25)
      queue_ai_turn()
     else
      message="nothing to grab there"
      sfx(24)
      for i=0,50 do yield() end
      message=nil
     end
    end
  },
  throw={
    cost=1,
    needs_in_hand=true,
    perform=perform_throw
  },
  zap={
    cost=2,
    perform=function()
      add_zap(player.x,player.y,player.sel_dir,zap_range,queue_ai_turn)  
      sfx(27)
    end
  }
}
in_hand=nil
function can_use_ability(ability)
  return not (
    (ability.cost != nil and ability.cost > energy) or
    (ability.needs_in_hand) and in_hand == nil
  )
end
function draw_ability_menu()
  draw_game()
  local h=mid(10,10+ability_fade,113)
  clip(0,9,128,h)
  rectfill(64,10,126,h,1) 
  rect(64,10,126,h,7) 

  if _upd== update_ability_menu then
    print_s("select ability",66,12,7,5)
    for i,a in pairs(abilities) do
      local c = i==selected and 8 or 7
      local cs = i==selected and 2 or 4
      local ab = ability_map[a]
      local cost = ab.cost
      local y=8+(14*i)
      if not can_use_ability(ab) then
        c,cs=5,5
      end
      pal(7,c)
      print((i==selected and "●" or "  ")..a,66,y,c)
      local sub=""
      if i==1 then
        sub = in_hand and in_hand.label or "empty handed"
      elseif a=="throw" then
        sub = "hits "..throw_strength.."X"
      elseif a=="zap" then
        sub = zap_range.." tiles"
      end
      print(sub,74,y+6,cs)
      if cost then
        print("\^:04020f0402000000"..cost,113,y,c)
      end
      pal(0)
    end
    --print("HP/ROAR:+"..regen,66,89,6)
    print_s("🅾️EXIT ❎SELECT",66,106,7,1)
  elseif _upd==update_select_direction then
    print_s("select a tile\nto "..abilities[selected],66,12,7,5)
    print_s("🅾️BACK ❎SELECT",66,106,7,1)
  end
  clip()
end

-->8
-- utils
function qsort(a,c,l,r)
    c,l,r=c or ascending,l or 1,r or #a
    if l<r then
        if c(a[r],a[l]) then
            a[l],a[r]=a[r],a[l]
        end
        local lp,rp,k,p,q=l+1,r-1,l+1,a[l],a[r]
        while k<=rp do
            if c(a[k],p) then
                a[k],a[lp]=a[lp],a[k]
                lp+=1
            elseif not c(a[k],q) then
                while c(q,a[rp]) and k<rp do
                    rp-=1
                end
                a[k],a[rp]=a[rp],a[k]
                rp-=1
                if c(a[k],p) then
                    a[k],a[lp]=a[lp],a[k]
                    lp+=1
                end
            end
            k+=1
        end
        lp-=1
        rp+=1
        a[l],a[lp]=a[lp],a[l]
        a[r],a[rp]=a[rp],a[r]
        qsort(a,c,l,lp-1       )
        qsort(a,c,  lp+1,rp-1  )
        qsort(a,c,       rp+1,r)
    end
end

function zcomp(a,b) 
 --print(a.type,0,0,6)
 --assert(a.y != nil)
 --assert(b.y != nil)
 if a.y == b.y then return b == player end
 return a.y < b.y 
end

function zsort_entities() qsort(entities, zcomp) end

function distcomp(a,b)
 return a.d < b.d
end

function tilesig(x,y,flag)
 local sig,digit=0
 for i=1,4 do
  local dx,dy=x-dirx[i],y-diry[i]
  --★
  if dx < 0 or dx > map_size_x or dy < 0 or dy > map_size_y then
   digit=1
  else
   digit = fget(mget(dx,dy),flag) and 1 or 0
  end
  sig|=digit<<i-1
 end
 return sig
end

function shuffle(t)
  -- fisher-yates
  for i=#t,1,-1 do
    local j=flr(rnd(i)) + 1
    t[i],t[j] = t[j],t[i]
  end
  return t
end

function dist(e1,e2)
  local dx,dy=(e1.x-e2.x)/8,(e1.y-e2.y)/8
  return sqrt((dx*dx)+(dy*dy))
end

function mdist(e1,e2)
  if e1 == nil or e2 == nil then
    return 9999
  end
  local dx,dy=(e1.x-e2.x),(e1.y-e2.y)
  return abs(dx)+abs(dy)
end

function lerp(
  a, -- target
  b, -- source
  t  -- percent 0.0-1.0
)
 return (1-t)*a + t*b
end

function get_score(points)
  return tostr(points,0x2)
end

function maybe(chance)
 return rnd(1) <= (chance or 0.5)
end

__gfx__
00000000000000000000000000000000000000000000060000000000000006000000000000000000001666000016660000000000000000000000000000000000
00000000000060000000560000046600000000000000046000000060066664600000060000600030011444600114446004444440044444400444400004444440
00700700000060000005446000544460000000000000044600000546055514400300546005460000011444460114444604111140041111400411400004111140
00077000000546000056000000555440000000000000044400600504055114400000504005040000015111440151114404444140045551400451444004514440
00077000000554000544656000555540000300000000504405460050011115400030050000500030051555140515551401114140045551400451114004514110
00700700005555400550544600050500000300300005000405040555055151500300555005550300005151500055555005514440044444400444444004444550
00000000005505500050554500005000030000300000050000500000000015100030000000000000005555500051115000001110011111100111111001111000
00000000000050000000055000005000050030000000555005550000000055500000000000000000005151500051115000005550055555500555555005555000
07777700000000000000000000000000000700000001000000000000000000000000000000000000000100000001000000077000000770000000000000000000
77777170000000000000000000000000006666000066660000166700007661000044400000444000004460000044600000667700006677000000000000000000
77777770000000000000000000000000636166606367666000666600006666004444444044444440044444000444440004666740046667400000000000000000
77777770000000000000000000000000633131606331316000133100001331001144444044444110044444000441440044566544445665440000000000000000
11117777000700000000000000000000111111101111111000666600006666004433344044333440045554000451540014455447744554410000000000000000
00007777707700000000000000000000111111101111111000111100001111001116111011161110045554000455540057171715517171750000000000000000
00077777777700000000000000000000040004000400040000400400004004003111113031111130053335000533350005555550055555500000000000000000
00017777777100000000000000000000000000000000000000000000000000000333330003333300030003000300030000055000000550000000000000000000
07777771077777710070000000700000007000000070000000000100000000000444444104444441733370000070000000000000000000000000000000000000
01777710017777100060000006660000006000000060000004441710000000000144441001444410003000000030007000000000000000000000000000000000
00711700000770000050000000500000005000000060000044417171000000000041140000044000066607370666003000000000000000000000000000000000
00100100000110000060000000600000006000000606000044441710000000000010010000011000666666106666667000000000000000000000000000000000
00000000000000000000070000000700000007000000070044444144000400000000000000000000666651006666510000000000000000000000000000000000
00000000000000000000666000000600000006000000060000004744404400000000000000000000555500005555000000000000000000000000000000000000
00000000000000000000050000000500000005000000050000044744444400000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000060000000600000060600000060000014444444100000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000055555505555555005555555555555550000000000000000000000000000000005555550555555500555555555555555
00555500555555000055555555555555055555505555555005555555555555550055550055555500005555555555555505555550555555500555555555555555
05555550555555500555555555555555055555505555555005555555555555550555555055555550055555555555555505555550555555500555555555555555
05555550555555500555555555555555055555505555555005555555555555550555555055555550055555555555555505555550555555500555555555555555
05555550555555500555555555555555055555505555555005555555555555550555555055555550055555555555555505555550555555500555555555555555
05555550555555500555555555555555055555505555555005555555555555550555555055555550055555555555555505555550555555500555555555555555
00555500555555000055555555555555005555005555550000555555555555550555555055555550055555555555555505555550555555500555555555555555
00000000000000000000000000000000000000000000000000000000000000000555555055555550055555555555555505555550555555500555555555555555
00000000000000000000000000000000555455505554555055545550555455500000000000000000000000000000000055545550555555505554555055555550
03333300333333000033333333333333555455505554555055545553555455530333330033333300033333333333333355545550555555505554555355555553
35555530555555300355555555555555555555505555555055555555555555553555553055555530355555555555555555555550555555505555555555555555
55555550555555500555555555555555555555505555555055555555555555555555555055555550555555555555555555555550555555505555555555555555
55555550445555500555445544554455555455504455555055555555445555555554555044555550555544555555555555545550555555505555555555555555
55555550555555500555555555555555555455505555555055555555555555555554555055555550555555555555555555545550555555505555555555555555
55555550555555500555555555555555555555505555555055555555555555555555555055555550555555555555555555555550555555505555555555555555
05555500555555000055555555555555055555005555550005555555555555555555555055555550555555555555555555555550555555505555555555555555
00000000000000000000000000000000030000500000003000300000000000030000000000000000030000000030000005000050000000500500000003000000
05300330303003500530353030305003030030300000000003000003300000000550555005303550355053500505305003000030300000300300300300000300
03000030000000000300030000003000000000000000003005000000000300300330335033303350053033333303303350000350050000003000000000030003
00030000000000300000300000000000050300500000305003030000030000000500003000000030030000000000000030300030030000500030050003000000
00003030000300300000000003000000030000300300003000000030000030000300030000000000000300000000030000000000000300300500030000000000
03000000030000500305000500000030000000000003000005000000000000305003005003000050050000000000000005030050000000000300000030000030
05005050055305500503050350035300053050503500055005303353350050053300003000000030030030305030000003000030300000000000000300300000
03003030033003300300030030003003030030303330033003300330030333330000300030003030003000033000000300000300030000300300003000000300
11111111000110001111111111111111000110001111111111111111001111001111111111111111111111110001110000000000000000000000066666600000
16666661001461001466664116666661001661001666666115546661011461101346666116667661166766610014411100000000000000000466641111666660
14111161013366101341164114111161013446101411116113355661114466111334466114114161141411611114466100000000000000000411145551611160
14555161113556111345144114556161133446611456516113544561144466611335566114554161145451611334466100000000000000000415545551655160
14555161135555411344444114554161133446611454516113411441144556611355556114554161145451611335566100000000000000000415544444455160
14555161131111411311114114555161131554611455516113431431145555611515515114555161145551611335555100000000000000000415515555155160
14444461134444411444444114444461115555411444446113555531155555511555555114444461144444611555555100000000000000000415517557155160
11111111155555511111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000415516776155160
15111141151551411111111115355341151551411531134113111151153553411111111115155141131111411515414100000000000000000415516666155160
15555541155555411555554115355341151111411535534113333351155555411333334115355341135555411555444100000000000000000411115665111160
15111141151551411111111115155141151551411531134113111151153553411111111115155141131111411515414100000000000000000444405555144440
15555541155555411555554115155141151111411535534113333351155555411333334115355341135555411555444100000000000000000111115115111111
15111141151551411111111115355341151551411531134113111151153553411111111115155141131111411515414100000000000000000555515115155550
15555541155555411555554115355341151111411535534113333351155555411333334115355341135555411555444100000000000000000511511111151150
15111141151551411111111115155141151551411531134113111151153553411111111115155141131111411515414100000000000000000555510000155550
15555541155555411555554115155141151111411535534113333351155555411333334115355341135555411555444100000000000000000111100000011110
00000008888008888888888808808808880000888800880000000800800800080000000088888888000000000000000000080000000800000000000000000000
00000008888008888888888008808808800000888800880008000880888880880080000082222228000800000000800000888000000800000000000000000000
00000008888000088800880000000000000000888800088008808888888888880880000080000808008800000000880008888800000800000000000000000000
00000008888000008888800008888888800000888800000008888888888888888880000080808208088888800888888002282200088888000000000000000000
00088808888088800888000008008800808888888888888000888888888888888888800080282008028822200222882000080000028882000000000000000000
00088808888088808888880008888888808888888888888008888888888888888888000080020008002800000000820000080000002820000000000000000000
00888808888088808800888008008800808888888888888088888888888888888880000088888888000200000000200000020000000200000000000000000000
08888808888088800000088008888888800000888880000000888888888888888888000022222222000000000000000000000000000000000000000000000000
08888008888008880888000000000000000000888880000088888888888888888888800000000000000000000000000000000000000000000000000000000000
00880008888000000888000008888888880000888880000008888888888888888880000000000000000000000000000000000000000000000000000000000000
00000008888008888888888008888888880008880888000000888888888888888888000000000000000000000000000000000000000000000000000000000000
00000008888008888888888000000000000008880888000000808808880888088000000000000000000000000000000000000000000000000000000000000000
00000008888000000888000008888888880008800088000000008000800880008000000000000000000000000000000000000000000000000000000000000000
00000008888000000888000008800000880088800088800000000000000800000000000000000000000000000000000000000000000000000000000000000000
00000000888088888888888808888888880088800088800000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000880088888888888808800000880888000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000080000000000000000000000000077777000077000007777000077770000007770077777700077770007777770007777000077770000000000000000000
88000808088888800000000000000000772277000777000077227700772277000077770077222200772220007722770077227700772277000000000000000000
88000080088888880770770000000700770077007777000022007700220077000772770077000000770000002200770077007700770077000000000000000000
88888000000000880777770000007500770077002277000000777200007772007720770077777000777770000007720027777200277777007707700000000000
88000000000000880777770000077770770077000077000007722000002277007777770022227700772277000077200077227700022277002772200000000000
88000000000000880577750000055750770077000077000077200000770077002222770077007700770077000772000077007700770077000277000000000000
88888880088888880057500000007500777772007777770077777700277772000000770077777200277772000770000027777200277772007727700000000000
08888880000000880005000000005000222220002222220022222200022220000000220022222000022220000220000002222000022220002202200000000000
00000000000000000000000000000000553455300554555035545530555455500000000000000000000000000000000055545350555555505034555055555550
03330300333033000003303333335333555455503554550035545303355453530303330030303300033030333303303353545550055553505534555005555553
35553530553355300355535535533535555555505355553053555035535555553555553035535530353330555335533555555553355555505555555335555555
55555550555355500535555555553555553535305555555055553355553535555553555055355550555553555535535535555330355555503555353553555355
33555550445535300553445544554455355455504455355055553555445555555554355044355350555544555555555555545550555555003555535555535555
55355530555555300555555555555555535455505555553035535555555555535354535055555550355553555555355555545550553555305555555555555555
55553530355355500555555553555555553535503535553003355535553555353555555055355330535535555535555553535550555555503553555553535535
05535500553555000053555355355535030355000303530003555335350355355555355035555550555555355555535555555350355555535555553555505505
fffffffffffffff111111fffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff177777711fffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffffffff177777777711fffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffff177777777777711fffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffff1777777777777771ffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffff1666667677775571ffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffff17777777777777171fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffff16666667677777171fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffff17777777777777771fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffff17555555577754671fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffff175666665751466671ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffff154666665546666671ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffffffff166444666666666671f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffffffff144444444441154661f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffff1111111111554671ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffffffffffff1655555546671ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffffffffffff1655554466671ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffffffffffff1744444666671ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffff1111fffff17664446666671ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff117661ffff176666666666471ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fff1176661ffff1766666666666671ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff1766651fff117667766666465571ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f1766451ff117766667766666664771f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17666771117766665667664645566771000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17666667776666664554666666456671000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1466666666666666644664645554551f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f16666666666666666666666644571ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f14666666666646464455445555571ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff1666666666666666644664444571ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff146666646444655655545555571fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fff16666666666666646464644571fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fff1466646556555455545555571ffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000m6600000m6650000m6600555m5550000000000000560000006000000m6600555m555000006000000m66000000
000000000000000000000000500000000000885mmm60005m5m60505mmm6055000000000000000000000000006000005mmm605555555000006000005mmm600000
00000000000000000000005000500000000088555mm000555m5000555mm05500000000000000000000000005m60000555mm0555555500005m60000555mm00000
0000000000000000000050008888500000882288558888888888885555m055000000000000000000000000055m00005555m0555m555000055m00005555m00000
000000000000000000000050888800000088228805888888888888050500550000000000000000000000005555m000050500555m5550005555m0000505000000
00000000000000005000500088885000002288225088888888888888500000777777777777777777777777000000000050005555555000550550000050000000
00000000000000500050005088880050002288225088888888888888500000777777777777777777777777000000000050005555555000005000000050000000
00000000000000005000500088888888880022000022222222228888500000777777777777777777777777000000000000005555555000000000000000000000
000000005600005000600l5l88888888885l225lll22222222228888ll000077777777777777777777777700000000llllll5555555lllllllllllllllllllll
00000005mm6050006000555588882222225555555555655565558800007777777777777777777777777777777777770000000055555555555555555555555555
00000056000000600060555588882222225555555555556555558800007777777777777777777777777777777777770000000055555555555555555555555555
000005mm656050006000655588886m556m556m555m556m556m5588000077777777777777777777777777777777777700000000555555mm55mm55mm55mm55mm55
000005505mm600600060555588885565556555655555556555658800007777777777777777777777777777777777770000000055555555555555555555555555
0000005055m550006000555588888888888888556588888888000077777777777777777777777777777777777777777777777700000000555555555555555555
00000000055000500060555588888888888888655588888888000077777777777777777777777777777777777777777777777700000000555555555555555555
00000000000000005000555m22888888888888006022222222000077777777777777777777777777777777777777777777777700000000000600000000000000
00000000000000506050555m22888888888888600022222222000077777777777777777777777777777777777777777777777700000000666m60000000600060
000000000000000050005555552222222222220065m66m00600000777777777777777777777777777777777777777777777777777777770000m0000005m605m6
0000000000000005m60055555522222222222260056m0m60mm0000777777777777777777777777777777777777777777777777777777770000m00060050m050m
00000000000000055m00555m55505505650m65m660506m50600000777777777777777777777777777777777777777777777777777777770000m005m600500050
000000000000088888805558888888888888888805888m8888000077777777777777777777777777777777777777777777777777777777000050050m05550555
00000000000000000000000000000000000000000000000000000066666666666666666666777766667777777777777777555555557777000000000000000000
00000000005008888880555888888888888888880088858888000066666666666666666666777766667777777777777777555555557777000050055500000000
00000000000000000000000000000000000000000000000000000066666666666666666666777766667777777777777777555555557777000000000000000000
00000000005008888880555888888888888888226088808888000066666666666666666666777766667777777777777777555555557777000050000006000000
00000000000000000000000000000000000000000000000000000077777777777777777777777777777777777777777777777777770000777700000000000000
00000000000000000000000000000000000000000000000000000077777777777777777777777777777777777777777777777777770000777700000000000000
00000000077707770077007707070777077707770707000000000077777777777777777777777777777777777777777777777777770000777700000000000000
00000000078708780788078707070787087808780707000000000077777777777777777777777777777777777777777777777777770000777700000000000000
00000000077708780788078707780777087808780707000000000066666666666666666666666677776666777777777777777777770000777700000000000000
00000000078800700700070707870787007000700707000000000066666666666666666666666677776666777777777777777777770000777700000000000000
00000000078807770877077807870787077707700877000000000066666666666666666666666677776666777777777777777777770000777700000000000000
00000000080008880888088808080808088808800888000000000066666666666666666666666677776666777777777777777777770000777700000000000000
00000000080008880088088008080808088808800088000000000077777777777777777777777777777777777777777777777777777777777700000000000000
00000000000000000000000000000000000000000000000000000077777777777777777777777777777777777777777777777777777777777700000000000000
00000000000000000000000000000000000000000000000000000077777777777777777777777777777777777777777777777777777777777700000000000000
5m56056888886888888668888862288888200m6mmm82228888000077777777777777777777777777777777777777777777777777777777777700005555555555
000000000000000000000000000000000000000000000000000000777755555555555555555555555555557777777777775555mmmm6666777700000000000000
055000688888088888865888886668888860056555866688880000777755555555555555555555555555557777777777775555mmmm6666777700005555555555
000000000000000000000000000000000000000000000000000000777755555555555555555555555555557777777777775555mmmm6666777700000000000000
0000006888880888888058888868888888888l6l66888888880000777755555555555555555555555555557777777777775555mmmm666677770000500m600mmm
00005008888868888880688888688888888885566688888888000077775555666666666666666666665555777755550000mmmm66666666666677770000m60m00
00000058888808888880588888688888888885666688888888000077775555666666666666666666665555777755550000mmmm66666666666677770000mm0m50
00000888888868888880688888688882228888666682228888000077775555666666666666666666665555777755550000mmmm66666666666677770000mm0m50
00000888888808888880588888688882228888666682228888000077775555666666666666666666665555777755550000mmmm666666666666777700000m0mmm
0000088888886888888068888868888222888866668222888800005555mmmm6666666666666666666655555555mmmm6666666666666666666677770000000000
0000888888880888888058888862222555288866668888888800005555mmmm6666666666666666666655555555mmmm6666666666666666666677770000500555
0000888888886888888068888852222066288866668888888800005555mmmm6666666666666666666655555555mmmm6666666666666666666677770000005000
000088888888088888805888886222200m288866668888888800005555mmmm6666666666666666666655555555mmmm6666666666666666666677770000500000
000088888888688888806888886060006mm8886666888888888888000066666666mmmmmmmmmmmm66666666666666666666666666666666666666667777000005
005088888822088888866228888668888862226666222222222222000066666666mmmmmmmmmmmm66666666666666666666666666666666666666667777000056
5000888888226888888662288886688888m222m666222222222222000066666666mmmmmmmmmmmm666666666666666666666666666666666666666677770000mm
005088888822088888866228888668888862226m66222222222222000066666666mmmmmmmmmmmm66666666666666666666666666666666666666667777000050
5000888888006888888666688886688888006050666666666666600000mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm000000005555mmmm66666666000050
0060288822606888888666622226688888600565008888888888880000mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm000000005555mmmm66666666000060
6000288822006888888666622226688888606006668888888888880000mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm000000005555mmmm66666666000000
0060288822666888888666622226688888660066668888888888880000mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm000000005555mmmm6666666600006m
600068886m666888888666666666688888666066668888888888888866000000000000000000000000000000000000000055555555mmmm666677770000m66m00
0060022266666888888666688888888888888866668888888888888866000000000000000000000000000000000000000055555555mmmm6666777700006m0m6m
6000622266666888888666688888888888888866668888888888888866000000000000000000000000000000000000000055555555mmmm6666777700006m6000
0060022266666888888666688888888888888866668888888888888866000000000000000000000000000000000000000055555555mmmm666677770000600560
600066666666688888866668888888888888886666222222222222226666688886688800006666555555555555555555555555mmmm6666666677770000666000
006666666666688888866668888888888888886666222222222222226666688886688800006666555555555555555555555555mmmm6666666677770000660060
606666666666688888866668888888888888886666222222222222226666688886688800006666555555555555555555555555mmmm6666666677770000666000
006666666666688888866668888888888888886666666666666666666666688886688800006666555555555555555555555555mmmm666666667777000066666l
6666666666666888888666622222288888222266668888888888888866666888266228000066665555555555555555mmmmmmmm66666666666677770000666666
0666666666666888888666622222288888222266668888888888888866666888266228000066665555555555555555mmmmmmmm66666666666677770000666666
6666666666666888888666622222288888222266668888888888888866666888266228000066665555555555555555mmmmmmmm66666666666677770000666666
6666666666666888888666666666688888666666668888888888888866666888666668000066665555555555555555mmmmmmmm66666666666677770000666666
666666666666688888866666666668888866666666888222222228886668888866666800007777mmmmmmmmmmmmmmmmmmmm666666666666666677770000666666
666666666666688888866666666668888866666666888222222228886668888866666800007777mmmmmmmmmmmmmmmmmmmm666666666666666677770000666666
666666666666688888866666666668888866666666888222222228886668888866666800007777mmmmmmmmmmmmmmmmmmmm666666666666666677770000666666
666666666666688888866666666668888866666666888666666668886668888866666800007777mmmmmmmmmmmmmmmmmmmm666666666666666677770000666666
6666666666666228888668888888880000000000000000888888888866688888660000777766666666mmmmmmmmmmmm6666666666666666666677770000666666
6666666666666228888668888888880000000000000000888888888866688888660000777766666666mmmmmmmmmmmm6666666666666666666677770000666666
6666666666666228888668888888880000000000000000888888888866688888660000777766666666mmmmmmmmmmmm6666666666666666666677770000666666
6666666666666668882668888888880000000000000000222222288868888822660000777766666666mmmmmmmmmmmm6666666666666666666677770000666666
66666666666666688826680000000077776666666600002222222888688888000077776666666666666666666666666666666666666666mmmm77770000666666
66666666666666688826680000000077776666666600002222222888688888000077776666666666666666666666666666666666666666mmmm77770000666666
66666666666666688866680000000077776666666600006666666888688888000077776666666666666666666666666666666666666666mmmm77770000666666
66666666666666622266620000000077776666666600006666666222622222000077776666666666666666666666666666666666666666mmmm77770000666666
66666666666666000000007777666666666666000022266666666222620000777766666666666666666666666666666666666666666666666677770000666666
66666666666666000000007777666666666666000022266666666222620000777766666666666666666666666666666666666666666666666677770000666666
66666666666666000000007777666666666666000066666666666666660000777766666666666666666666666666666666666666666666666677770000666666
66666666666666000000007777666666666666000066666666666666660000777766666666666666666666666666666666666666666666666677770000666666
66666666660000777766666666666655550000666666666666000000007777666666667777777766666666666666666666mmmm66665555555577770000666666
66666666660000777766666666666655550000666666666666000000007777666666667777777766666666666666666666mmmm66665555555577770000666666
66666666660000777766666666666655550000666666666666000000007777666666667777777766666666666666666666mmmm66665555555577770000666666
56666666660000777766666666666655550000666666666666000000007777666666667777777766666666666666666666mmmm66665555555577770000666666
6666660000777766666666mmmm555500006666666600000000777777776666666666666666777777776666666666666666666666666666mmmm77777777000066
0666660000777766666666mmmm555500006666666600000000777777776666666666666666777777776666666666666666666666666666mmmm77777777000066
6566660000777766666666mmmm555500006666666600000000777777776666666666666666777777776666666666666666666666666666mmmm77777777000066
5m66660000777766666666mmmm555500006666666600000000777777776666666666666666777777776666666666666666666666666666mmmm77777777000066
650000777766666666666677777777000000000000777777776666666666666666555566666666777766666666mmmm6666mmmm55555555666666667777777700
050000777766666666666677777777000000000000777777776666666666666666555566666666777766666666mmmm6666mmmm55555555666666667777777700
600000777766666666666677777777000000000000777777776666666666666666555566666666777766666666mmmm6666mmmm55555555666666667777777700
600000777766666666666677777777000000000000777777776666666666666666555566666666777766666666mmmm6666mmmm55555555666666667777777700
600000777766666666666666666666777777777777666666666666666666666666mmmm55555555mmmm666666666666666666666666mmmm555566666666777700
m60000777766666666666666666666777777777777666666666666666666666666mmmm55555555mmmm666666666666666666666666mmmm555566666666777700
6m0000777766666666666666666666777777777777666666666666666666666666mmmm55555555mmmm666666666666666666666666mmmm555566666666777700
550000777766666666666666666666777777777777666666666666666666666666mmmm55555555mmmm666666666666666666666666mmmm555566666666777700
650000mmmm666666666666666666666666666666666666666666666666666666666666mmmmmmmm66666666mmmm6666mmmm555555555555mmmm55555555000066
500000mmmm666666666666666666666666666666666666666666666666666666666666mmmmmmmm66666666mmmm6666mmmm555555555555mmmm55555555000066
500000mmmm666666666666666666666666666666666666666666666666666666666666mmmmmmmm66666666mmmm6666mmmm555555555555mmmm55555555000066
000000mmmm666666666666666666666666666666666666666666666666666666666666mmmmmmmm66666666mmmm6666mmmm555555555555mmmm55555555000066
500060000066666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666mmmmmmmm555577770000666666
005000000066666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666mmmmmmmm555577770000666666
000050000066666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666mmmmmmmm555577770000666666
005000000066666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666mmmmmmmm555577770000666666
0000500000mmmm6666666666666666666666666666666666666666mmmm6666mmmm6666mmmmmmmm55555555mmmmmmmm5555555555555555555577770000666666
0050000000mmmm6666666666666666666666666666666666666666mmmm6666mmmm6666mmmmmmmm55555555mmmmmmmm5555555555555555555577770000666666
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0040404000404040404040404040404000000000000000000000000000000000000000000000000000000000000000008181818181818181818181818181818102020202020202020202020202020202040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606060606060606060606060606060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000002f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b434343434b434343434b434343434b434343434b434343434b434343434b434343434b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4c050505054c050505054c700505054c050505054c050505054c707005054c050570704c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4c050505054c057070054c050505704c707005054c050570704c050505054c050505054c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f434343434f434343434f434343434f434343434f434343434f434343434f434343434f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4c0c05050c4c0c70700c4c0c703a394c0101700c4c0c0c70704c0c0c0c0c4c70700c0c4c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4c053231054c0c01010c4c0c0136354c3a39010c4c0c01010c4c700101704c0c01010c4c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4c0c05050c4c0c70700c4c0c7001014c3635700c4c70700c0c4c0c0c0c0c4c0c0c70704c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f434343434f434343434f434343434f434343434f434343434f434343434f434343434f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
790700041811418115171141711500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7907000c1811418115171141711518114181151911419115181141811517114171151d0001d0001c0001c00000000000000000000000000000000000000000000000000000000000000000000000000000000000
01080008181241812518124181251a1241a1251a1241a125000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52090000163311b3412135129361303611d3561b34617336103210b321073110731103311043072d3072d3072c3072b3072b3072b307313070d3070c307083070130702307003070030700307003070030700307
0002000007030040200070007700077000603007020097000a7000070003000010000070000700007000100003000007000070000700007000070000700007000070000700007000070000700007000070000700
000300001c55018550005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000500002a5502c550005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
01050000175500a551000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000253011620035301a62019620033300202000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
011000002191021910219102191021910219102191021910219102191021910219102191021910219102191021910219102191021910219102191021910219102191021910219102191021910219102191021910
95100000094240943009432094320f4210f4300f4320f432094210943009432094321042110430104321043209421094150040000400004000040000400004000040000400004000040000400004000040000400
011000002181021810218102181021810218102181021810218102181021810218102181021810218102181021910219102191021910219102191021910219102191021910219102191021910219102191021910
c51000000942409430094320943211421114301143211432094210943009432094321242112430124321243209421094150000000000000000000000000000000000000000000000000000000000000000000000
951000000910009100081000810009100091000810008100091000910008100081000a1000a10009100091000911009015081100801509110090150811008015091100901508110080150a1100a0150911009015
951000000911009015081100801509110090150811008015091100901508110080150a1100a01509110090150911009015081100801509110090150811008015091100901508110080150a1100a0150911009015
951000000911009015081100801509110090150811008015091100901508110080150a1100a01509110090150911009110091120911209112091120911209115091000900008100080000a1000a0000910009000
0110000021810218102181021810218102181021810218102181021810218102181021810218102181021a1020a1020a1021a1021a1020a1020a1021a1021a1020a1020a1021a1021a1020a1020a1021a1021a10
0110000020a1021a1021a1020a1020a1021a1021a1020a1020a1021a1021a1020a1020a1021a1021a1020a1020a1021a1021a1020a1024a1023a1023a1024a1024a1023a1023a1024a1024a1023a1023a1024a10
951000000543405430054300543005432054320543205432044310443004430044300443004430044300443004432044320443204435024340243202432024350443404432044320443505434054320543205435
951000000243402430024300243002430024320243202432024300243002430024350900002435024350243502430024350000010000000000000000000000000443004435000000000000000000000000000000
0110000023a1022a1022a1023a1023a1022a1022a1023a1023a1022a1022a1023a1024a1023a1023a1024a1020a1021a1021a1020a1020a1021a1021a1020a1020a1021a1021a1020a1020a1021a1021a1020a10
951000000843408430084300843008430084300843208432084320843208432084320943009430094320943200430004300043000430004300043000432004320043200432004320043200435004350043500435
0110000020a1021a1021a1020a1020a1021a1021a1020a1020a1021a1021a1020a1020a1021a1021a1020a1020a0021a0021a0020a0020a0021a0021a0020a0020a0021a0021a0020a0020a0021a0021a0020a00
0d0500002125321253121400813004220032100010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
001200000b44505435000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90080000083200d331193412230027300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
4a0700001964019635000000000010640106350000000000006300062500600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000000
000a000000000000001c45017451124410f4410b43109435004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
011000001113011120111201112011120111221112211115121301212012120121201212012122121221211511130111201112011120111201112211122111151213012120121201212012120121221212212115
011000001654016530165301653016530165301652016525165401653016530165321652216525165401653516540165301653016530165301653016530165301652016520165201652016522165221652216525
011000001654016530165301653016530165301652016525165401653016530165321653216535165301653516530165301653016530165301653016520165251953019530195301952019522195251853018525
011000001854018530185301853018532185251654016525165401653016530165321653216525165401652516540165301653016530165301653016530165201652016520165201652216522165221652216525
00040000052300862008610006000f2400f6300f6200f6100f6100f6100f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
011000001003010020100201001010010100101001010010100121001210012100121001210012100121001514010140101401014010140101401214012140150e0300e0220e0220e0150f0100f0120f0120f015
01100000090300902209022090150a0300a0120a0120a015000300003200022000150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000413504135041350000000000041350413504135000000000004135041350413500000000000413500000000000205002030020350205002030020350413504135041350000000000041350413504135
001000000000000000041350413504135000000000004135000000000002050020300203502050020300203504135041250412500000000000413504125041250000000000041350412504125000000000004145
001000000000000000020500203002035020500203002035041350413504135000000000004135041350413500000000000413504135041350000000000041350000000000020500203002035020500203002035
001000001073510735107350070000700107351073510735007000070010735107351073500700007001073500700007001175011730117351175011730117351773517735177350070000700177351773517735
00100000007000070017735177351773500700007001773500700007001a7301a7301a7351a7301a7301a73517735177351773500700007001773517735177350070000700177351773517735007000070017735
001000000070000700137501373013735117301173011735107351073510735007000070010735107351073500700007001073510735107350070000700107350070000700117501173011735117501173011735
011000000564500625056000060500605056450560000605006050060505645006050060500605006050564500605006051d64500605006050564500605006050564500625006050060500605056450060500605
00100000000000000005645006050060500605006050564500605006051d645006050060505645006050060505645006250060500605006050564500605006050000000000056450000000000000000000005645
0010000000000000001d64500605006050564500605006050564500625006050060500605056450060500605000000000005645000000000000000000000564500000000001d6450060500605056450060500605
010800002d2532d2532d2532b1512b1512815125151221511e1511a15112151081510010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000000
01050000186501c3511f3512d3512f551325513255500300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
01050000074500d451124510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000026100a31002610053100a300093000930000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
001000001075410740107301073210732107321073210732107321073210732107221072210715007000070000700007001175411740117301173211732117221775117740177301773017732177321773217732
00100000177321773217722177221772510700107001070010700107001a7501a7401a7301a7321a7321a72217741177401773017730177301773017730177301773217732177321773217732177321773217732
001000001773217735137301375213742117311172211722107511074010730107301073010730107301073010732107321073210732107321073210732107351070000700117501174511700117501174500700
__music__
01 494a0d09
00 4b0a0e0b
00 4b0c0f10
00 41421211
00 41421514
02 41421316
01 41421c1d
00 41421c1e
02 41421c1f
00 41424344
01 41422144
04 41422244
01 41422344
00 41422444
00 41422544
01 41292366
00 412a2467
00 412b2568
01 41292326
00 412a2427
00 412b2528
00 30292366
00 312a2467
02 322b2568

