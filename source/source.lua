-- title:  iichan demo
-- author: lb_ii
-- desc:   simple sprite demo
-- script: lua
-- input:  gamepad

------------
-- config --
------------

INTRO_SKIP = false
SHOW_DEBUG = false
FIRST_ROOM = "UN_HOME"

-----------
-- utils --
-----------

function drawdebug()
  print("FPS:"..FPS:get(),0,112)
  print("Player x:"..game.player.x,0,120)
end

-- based on FPS counter by Al Rado --

FPS={val=0,cnt=0,prev=-1}
function FPS:get()
  local t = time()
  if t - self.prev <= 1000 then
    self.cnt = self.cnt + 1
  else
    self.val  = self.cnt
    self.cnt  = 0
    self.prev = t
  end
  return self.val
end

-- DeepCopy by Bruno Oliveira --

function DeepCopy(t)
 if type(t)~="table" then return t end
 local r={}
 for k,v in pairs(t) do
  if type(v)=="table" then
   r[k]=DeepCopy(v)
  else
   r[k]=v
  end
 end
 return r
end

-- based on palette demo by Nesbox --

function updpal(pal,offset)
  local p = pal or DB16
  local o = offset or 0
  for i=1,#p,2 do
    local adr=0x3FC0+o*3+i//6*3+i//2%3
    poke(adr,tonumber(p:sub(i,i+1),16))
  end  
end

-- used for deep copied jump patterns --

function pattern(id)
  local p = DeepCopy(PATTERN[id])
  p.pop = function(self)
    return table.remove(self,1)
  end
  return p
end

-------------------------
-- constants and enums --
-------------------------

BUTTON = {
  UP    = 0,
  DOWN  = 1,
  LEFT  = 2,
  RIGHT = 3,
  A     = 4,
  B     = 5,
  x     = 6,
  Y     = 7,
}

SPRITE = {
  UN_SLEEPY = 112,
  UN        = 114,
  UV        = 116,
  SHOSHINSHA= 134,
}

TARGET = 118

STATE = {
  WALK   = 0,
  FALL   = 1,
  BOUNCE = 2,
  JUMP   = 3,
}

MODE = {
  INTRO  = 0,
  GAME   = 1,
  WIN    = 2,
  WIN2   = 3,
}

DB16 = "140c1c".."442434".."30346d"..
       "4e4a4e".."854c30".."346524"..
       "d04648".."757161".."597dce"..
       "d27d2c".."8595a1".."6daa2c"..
       "d2aa99".."6dc2ca".."dad45e"..
       "deeed6"

PATTERN = {
 NONE = {},
 LEFT = {-1},
 RIGHT = {1},
 BOUNCE = {-1,-1,-1,0,0,0,1,1,1,0,0,0},
 JUMP ={-3,-3,-3,-3,-3,-2,-2,-2,-1,-1},
}

HELLO = "Press key Z to start"

-- list of game rooms -----------------
--   bg      : index  of game map    --
--   width   : num of maps to scroll --
--   bgcolor : to replace 7th color  --
--   init    : called on room enter  --
---------------------------------------  

ROOM = {
  START = { 
    init = function()
      game.player:setpos(160,72)
      game.player:setface("UN_SLEEPY")
      game:setroom(FIRST_ROOM)
    end
    },

  TEST = {
    bg=11,
    width = 2,
    bgcolor="0c0c0c",
    init = function()
      game.player:setface("UV")
      game.player:setpos(56,72)
      game:addtarget(408, exit)
      game:addcoin(32,16)
      game:addcoin(128,16)
      game:addcoin(160,32)
      game:addcoin(192,8)
      game:addcoin(216,72)
      game:addcoin(240,40)
      game:addcoin(280,40)
      game:addcoin(320,0)
      game:addcoin(320,72)
      game:addcoin(432,72)
    end,
  },

  UN_HOME = {
    bg = 0,
    width = 1,
    bgcolor = "e8d599",
    init = function()
      game.player:setpos(64,72)
      game:addtarget(168,
        game:setsroom("UN_HALL"),
        game.player:setspos(56,72)
      )
    end,
  },

  UN_HALL = {
    bg=1,
    width = 1,
    bgcolor="c0c0c0",
    init = function()
      game:addtarget(112,
        game.player:setsface("UN"),
        game:setsroom("UN_HALL2"),
        game.player:setspos(112,72)
      )
    end,
  },

  UN_HALL2 = {
    bg=1,
    width = 1,
    bgcolor="c0c0c0",
    init = function()
      game:addtarget(168,
        game:setsroom("STREET"),
        game.player:setspos(56,72)
      )
    end,
  },

  STREET = {
    bg=3,
    width = 2,
    bgcolor="c0c0c0",
    init = function()
      game:addtarget(408,
        game:setsroom("UV_HALL"),
        game.player:setspos(168,72)
      )
    end,
  },

  UV_HALL = {
    bg=1,
    width = 1,
    bgcolor="c0c0c0",
    init = function()
      game:addtarget(56,
        game:setsroom("UV_HOME"),
        game.player:setspos(168,72)
      )
    end,
  },

  UV_HOME = {
    bg=2,
    width = 1,
    bgcolor="e8d599",
    init = function()
      game:addnpc("UV",144,64,
      function(self)
        -- wait for player to come
        if self.npcstate == nil then
          if game.player.x < 152 then
            self.npcstate = 1
          end
        -- walk left to bathroom door
        elseif self.npcstate == 1 then
          self:moveleft()
          if self.x <= 56 then
            self.npct  = time()
            self.npcstate = 2
          end
        -- invisible for 1000ms
        elseif self.npcstate == 2 then
          self:setpos(-100,72)
          if time()-self.npct>1000 then
            self:setpos(56,72)
            self.npcstate = 3
          end
        -- walk right to the exit
        elseif self.npcstate == 3 then
          self:moveright()
          if self.x>=168 then
            self.npcstate = 4
            game:addtarget(168,
              game:setsroom("UV_HALL2"),
              game.player:setspos(72,72)
            )
          end
        end
      end)
    end,
  },

  UV_HALL2 = {
    bg=1,
    width = 1,
    bgcolor="c0c0c0",
    init = function()
      game:addnpc("UV",56,72,
        function(self)
          if game.player.x<self.x-14 then
            self:moveleft()
          end
          if game.player.x>self.x+14 then
            self:moveright()
          end
        end
      )
      game:addtarget(168,function()
          game.mode = MODE.WIN
        end
      )
    end,
  },
}

---------------------------
-- game "singleton", lol --
---------------------------

game = {
  -- game mode: intro/game/win
  mode   = MODE.INTRO,
  -- id in ROOM dict -- 
  roomid = "",
  -- dx in current room --
  roomdx = 0,
  -- list of room targets --
  target = {},
  -- list of room NPCs --
  npcs = {},
  -- player info --
  player = nil,
  -- number of coins collected --
  coins = 0,
}
function game:room()
  return ROOM[game.roomid]
end

-- inits the game --

function game:start()
  game.mode = MODE.GAME
  game.player = DeepCopy(character)
  return game:setroom("START")
end

-- game actions per tic --

function game:update()
  game.player:fixpos()
  game:setfocus(game.player)
  for _,npc in pairs(game.npc) do
    npc:interact()
    npc:fixpos()
  end
end

-- checks if a place on map is solid --

function game:issolid(x,y)
  local mx = game:room().bg%8 *30 + x//8
  local my = game:room().bg//8*17 + y//8
  return mget(mx,my)==0
end

-- focus game view dx on character --

function game:setfocus(ch)
  local dx = ch.x - 120
  local m = (game:room().width-1)*240
  dx = (dx<=m) and dx or m
  game.roomdx = (dx>=0) and dx or 0
end

-- adds a target to a list --

function game:addtarget(xx,...)
  table.insert(game.target,
    {x=xx,f={...}}
  )
end

-- triggers a target for given x --

function game:runtargets(x)
  for _,t in pairs(game.target) do
    if x <= t.x+8 and x >= t.x-8 then
      for _,f in pairs(t.f) do
        f()     
      end
    end
  end
end

-- switches room, reset some stuff --

function game:setsroom(m)
  return function()
    return game:setroom(m)
  end
end
function game:setroom(m)
  game.roomid = m
  game.target = {}
  game.npc    = {}
  local f = game:room().init
  if f then f() end
end

-- adds an NPC to the list --

function game:addnpc(who,x,y,f)
  local npc = DeepCopy(character)
  npc:setface(who)
  npc:setpos(x,y)
  npc.interact = f
  table.insert(game.npc,npc)
end
function game:addcoin(x,y)
  game:addnpc("SHOSHINSHA",x,y,
    function(self)
      local dx = self.x-game.player.x
      local dy = self.y-game.player.y
      if dx>-8 and dx<8 and
         dy>-16 and dy<24
      then 
        game.coins = game.coins + 1
        self:setpos(-200,72)
      end
    end
  )
end

---------------------------------
-- characters: player and NPCs --
---------------------------------

character = {
  -- sprite id in SPRITE dict --
  sprite = "",
  -- used for legs animation --
  anim   = 0,
  -- direction: 0=right 1=left --
  flip   = 0,
  -- moving state: walk,jump,etc... --
  state  = STATE.WALK,
  -- x,y of upper left corner --
  x      = 0,
  y      = 0,
  -- queue of x,y modificators --
  xqueue = pattern("NONE"),
  yqueue = pattern("NONE"),
  -- number of jumps left allowed --
  jumps  = 2,
  -- function to call every tic
  interact = function() end
}

-- changes position --

function character:setspos(x,y)
  return function()
    return self:setpos(x,y)
  end
end
function character:setpos(x,y)
  self.x = x
  self.y = y
end

-- switches sprite --

function character:setsface(s)
  return function()
    return self:setface(s)
  end
end
function character:setface(s)
  self.sprite = SPRITE[s]
end

-- motion: bounce --

function character:bounce()
  local a = self.anim
  if self.state == STATE.WALK then
    self.state  = STATE.BOUNCE
    self.yqueue = pattern("BOUNCE")
    self.anim   = a + 6 - a%6
  end
  self.anim = self.anim + 1
end

-- motion: move left/right --

function character:moveleft()
  self:bounce()
  self.xqueue = pattern("LEFT")
  self.flip = 1
end
function character:moveright()
  self:bounce()
  self.xqueue = pattern("RIGHT")
  self.flip = 0
end

-- motion: jump --

function character:canjump()
  return self.jumps > 0
end
function character:tryjump()
  if self.jumps>0 then
    self.jumps  = self.jumps - 1
    self.state  = STATE.JUMP
    self.yqueue = pattern("JUMP")
  end
end

-- collisions: walls and stairs --

function character:getforcex()
  return self.xqueue:pop() or 0
end
function character:fixposx()
  local dx = self:getforcex()
  local mx = self.x + dx
  local my = self.y
  if dx and dx<0 and (
     game:issolid(mx+5,my+3) or
     game:issolid(mx+5,my+11) or
     game:issolid(mx+5,my+16) )
  then
    dx = 1
  elseif dx and dx>0 and (
     game:issolid(mx+9,my+3) or
     game:issolid(mx+9,my+11) or
     game:issolid(mx+9,my+16) )
  then
    dx = -1
  end
  self.x = self.x + dx
end

-- collisions: floor and ceiling --

function character:getforcey()
  local dy = self.yqueue:pop()
  if dy == nil then
    self.state = STATE.FALL
    dy = 2
  end
  return dy
end
function character:fixposy()
  local dy = self:getforcey()
  local mx = self.x
  local my = self.y+dy
  if dy and dy<0 then
    if game:issolid(mx+5,my) or
       game:issolid(mx+9,my)
    then
      dy = self.y % 8
      self.state = STATE.FALL
      self.yqueue= pattern("NONE")
    end
  elseif dy and dy>0 then
    if game:issolid(mx+5,my+22) or
       game:issolid(mx+9,my+22)
    then
      dy = self.y % 8
      dy = dy>0 and -dy or 0
      self.state  = STATE.WALK
      self.yqueue = pattern("NONE")
      self.jumps  = 2
    end
  end
  self.y = self.y + dy
end

-- collisions: all together --

function character:fixpos()
  self:fixposx()
  self:fixposy()
  
  -- irrational fear of falling down --
  if self.y > 72 then
    self.y = 72
  end
end

--------------------------------------
-- low-level crap drawing functions --
--------------------------------------

-- draw a character --

function drawchar(ch)
  local who  = ch.sprite
  local anim = ch.anim
  local x    = ch.x - game.roomdx
  local y    = ch.y
  local flip = ch.flip
  local f = flip or 0
  local g = 1 - f
  local a = ((anim//6)%4)
  a = (a==3) and 16 or a*16
  spr(who+f     ,x+0,y+0, 7,1,flip)
  spr(who+g     ,x+8,y+0, 7,1,flip)
  spr(who+f+16  ,x+0,y+8, 7,1,flip)
  spr(who+g+16  ,x+8,y+8, 7,1,flip)
  spr(who+f+32+a,x+0,y+16,7,1,flip)
  spr(who+g+32+a,x+8,y+16,7,1,flip)
end

-- draw targets --

function drawtarget()
  for _,t in pairs(game.target) do
    spr(TARGET  ,t.x-game.roomdx  ,56)
    spr(TARGET+1,t.x-game.roomdx+8,56)
  end
end

-- draw coins counter --

function drawcounter()
  if game.coins > 0 then
    spr(SPRITE.SHOSHINSHA+16,200,120,7)
    spr(SPRITE.SHOSHINSHA+17,208,120,7)
    spr(SPRITE.SHOSHINSHA+32,200,128,7)
    spr(SPRITE.SHOSHINSHA+33,208,128,7)
    print("x"..game.coins,216,124)
  end
end

-- draw everything --

function drawgame()
  updpal(game:room().bgcolor,7)
  cls(7)
  map(
    game:room().bg%8*30+game.roomdx//8,
    game:room().bg//8*17,
    31,17,
    -(game.roomdx%8),0
  )
  drawtarget()
  drawcounter()
  drawchar(game.player)
  for _,npc in pairs(game.npc) do
    drawchar(npc)
  end
  if SHOW_DEBUG then
    drawdebug()
  end
end

-- nongame modes --

function drawintro()
  local c = (time()//500)%2 == 0
  print(HELLO,64,124,c and 7 or 15)
end

function scanline(l)
  if game.mode == MODE.WIN then
    updpal("000000",0)
    updpal("692C7D",1)
    updpal("0E3665",2)
    updpal("35301A",3)
    updpal("7D482C",4)
    updpal("06BA36",5)
    updpal("35301A",7)   
    updpal("FBDDBA",12)
    updpal("2471CB",13)
    updpal("FFFFFF",15)
    if l < 64 then
      updpal("FE4040",6)
      updpal("92FF01",14)
    else
      updpal("F41101",6)
      updpal("F3FE01",14)
    end

    local a=0x3FC0
    poke(a+24,210-l*2)
    poke(a+25,232-l//2)
    poke(a+26,252-l*3//2)
    poke(a+33,106-(l-55)//3)
    poke(a+34,206-(l-55)//10)
    poke(a+35,174-(l-55))
  elseif game.mode == MODE.WIN2 then
    updpal("000000",0)
    updpal("ffffff",15)
  else
    updpal()
  end
end

function drawwin()
  updpal()
  cls(7)
  map(210,119)
  local lst = {
    {12,15,304,0,32},
    {2,8,256,160,0},
    {1,5,281,184,24},
  }
  for _,l in pairs(lst) do
    for i = 0, l[1]*8, 8 do
      for j = 0, l[2], 1 do
        spr(l[3]+2*i+j,l[4]+8*j,l[5]+i)
      end
    end
  end
  spr(287,128,80)
  spr(303,128,88)
end

function drawwin2()
  map(180,119)
end

------------------------------
-- process buttons keypress --
------------------------------

function processinput()
  if game.mode == MODE.INTRO then
    if INTRO_SKIP then
      game:start()
    elseif btn(BUTTON.A) then
      if btn(BUTTON.UP) then
        FIRST_ROOM = "TEST"
      end
      game:start()
    end
  elseif game.mode == MODE.GAME then
    if btnp(BUTTON.A) then
      game.player:tryjump()
    end
    if btn(BUTTON.RIGHT) then
      game.player:moveright()
    end
    if btn(BUTTON.LEFT) then
      game.player:moveleft()
    end
    if btn(BUTTON.DOWN) then
      game:runtargets(game.player.x)
    end
  elseif game.mode == MODE.WIN then
    if btnp(BUTTON.A) then
      game.mode = MODE.WIN2
    end
  elseif game.mode == MODE.WIN2 then
    if btnp(BUTTON.A) then
      exit()
    end
  end
end

-----------------------------------
-- main function, runs every tic --
-----------------------------------

function TIC()
  processinput()
  if game.mode == MODE.INTRO then
    drawintro()
  elseif game.mode == MODE.GAME then
    game.update()
    drawgame()
  elseif game.mode == MODE.WIN then
    drawwin()
  elseif game.mode == MODE.WIN2 then
    drawwin2()
  end
end
