-- fiiiiive: sequence
--                  five
--       d('u')b       by five
-- 1.0.0 @marcocinque 
-- llllllll.co/
-- enc1 > ..
-- key3 & key4 > ..
-- enc3 & enc4 > ..
--

engine.name = "PolyPerc"

local MusicUtil = require "musicutil"
local midi_in_device
local xa5 = {}
local ya5 = {}
local xa12 = {} -- cartesian circles
local ya12 = {}
for i = 1, 5 do
  xa5[i] = math.cos(math.rad((72*(i-1))-90))
  ya5[i] = math.sin(math.rad((72*(i-1))-90))
end
for i = 1, 12 do
  xa12[i] = math.cos(math.rad((30*(i-1))-90))
  ya12[i] = math.sin(math.rad((30*(i-1))-90))
end
local xy = {} -- positions
for i = 1, 25 do
  xy[i] = {}
end
local xyp = {}
for i = 1, 10 do
  xyp[i] = {}
end
local serie = {0,4,5,7,9}
local seriesel = 0
local val = {}
local valset = {}
for i = 1, 5 do
  val[i] = {1,2,3,4,5}
end
for i = 1, 5 do
  valset[i] = {}
  for ii = 1, 5 do
    valset[i][ii] = {1,2,3,4,5}
  end
end
local ranges = {}
local range = {}
local range2 = {}
for i = 1, 5 do
  range[i] = {}
end
for i = 1, 5 do
  range2[i] = {}
  for ii = 1, 5 do
    range2[i][ii] = {}
  end
end
screenpos = 0
pos = 0
fivecount = {0,0,0,0,0}
fivecount2 = {}
for i = 1, 5 do
  fivecount2[i] = {0,0,0,0,0}
end
local key2shift, key2shiftmv = 0
local key3shift, key2shiftmv = 0

-- MIDI input
local function midi_event(data)
  
  local msg = midi.to_msg(data)
  local channel_param = params:get("midi_channel")

  if channel_param == 1 or (channel_param > 1 and msg.ch == channel_param - 1) then
    
    -- Note off
    if msg.type == "note_off" then
    
    -- Note on
    elseif msg.type == "note_on" then
     
    -- Pitch bend
    elseif msg.type == "pitchbend" then
      local bend_st = (util.round(msg.val / 2)) / 8192 * 2 -1 
      local bend_range = params:get("bend_range")
      
    -- CC
    elseif msg.type == "cc" then
      -- Mod wheel
      if msg.cc == 1 then

      end
    end
  end
end

local function circlesect(xa, ya, raggio, centro, posi)
  local xys = {}
  xys[1] = (xa[posi]*raggio) + centro[1]
  xys[2] = (ya[posi]*raggio) + centro[2]
  return xys
end

local function circleserie(serie, centro, raggio)
  local xy = {}
  for i = 1, 5 do
    xy[i] = circlesect(xa12, ya12, raggio, centro, serie[i]+1)
  end
  return xy
end

local function circleseq(centro, raggio)
  local xy = {}
  for i = 1, 5 do
    xy[i] = circlesect(xa5, ya5, (raggio[i]+1)*4, centro, i)
  end
  return xy
end

local function circlepent(centro, raggio)
  local xy = {}
  for i = 1, 5 do
    xy[i] = circlesect(xa5, ya5, raggio, centro, i)
  end
  return xy
end

local function arcangle(angle)
  angle = math.rad((angle+270)%360)
  return angle
end

local function seriexy(n,i)
  serie[i]=n
  xy[1]=circleserie(serie, {32,32}, 24) 
  xy[2]=circleserie(serie, {32,32}, 16)
end

local function seqxy(n,i,ii)
  val[i][ii]=n
  xy[3+((i-1)*2)]=circleseq({32,96+((i-1)*64)}, val[i])
end

local function seqsetxy(n,i,ii,iii)
  valset[i][ii][iii]=n
  xy[4+((i-1)*2)]=circleseq({96,96+((i-1)*64)}, valset[i][ii])
end

-- Clamps a number to within a certain range, with optional rounding
local function clamp(n, low, high) 
  return math.min(math.max(n, low), high) 
end

-- screen transition
local function scroll(d)
  for i =1,8 do
    screenpos = clamp(screenpos + (8*d), 0, 256)
    clock.sleep(1/30)
    redraw()
  end
  pos = clamp(pos+d,0,5)
  print(pos)
end
  
-- clockwork
function fiveloop(num, den, counter, counter2, range, range2, serie, val, valset)
  while true do
    clock.sync(num/den)
    counter[1] = ((counter[1] + 1) % (math.abs(range[1][2] - range[1][1])+1)) + range[1][1]
    if val[1][counter[1]+1]-1 > 0 then
      for i = 2, 5 do
        counter[i] = ((counter[i] + 1) % (math.abs(range[i][2] - range[i][1])+1)) + range[i][1]
      end
      for i = 1, 5 do
        if counter[i] == range[i][1] then
          -- counter2[i][counter[i]+1] = ((counter2[i][counter[i]+1] + 1) % math.abs(range2[i][counter[i]+1][2]-range2[i][counter[i]+1][1])) + range2[i][counter[i]+1][1]
          -- val[i][counter[i]+1] = valset[i][counter[i]+1][counter2[i][counter[i]]+1]
        end
        print("id: " .. i .. " count: " .. counter[i] .. " value: " .. val[i][counter[i]+1])
      end
    end
  end
  redraw()
end

function init()
  
  midi_in_device = midi.connect(1)
  midi_in_device.event = midi_event
  
  params:add{type = "number", id = "midi_device", name = "MIDI Device", min = 1, max = 4, default = 1, action = function(value)
    midi_in_device.event = nil
    midi_in_device = midi.connect(value)
    midi_in_device.event = midi_event
  end}
  
  local channels = {"All"}
  for i = 1, 16 do 
    table.insert(channels, i) 
  end
  
  table.insert(channels, "MPE")
  params:add{type = "option", id = "midi_channel", name = "MIDI Channel", options = channels}
  params:add{type = "number", id = "bend_range", name = "Pitch Bend Range", min = 1, max = 48, default = 2}
  
  params:add_separator("ranges")
  
  for i = 1, 2 do
    params:add_control("serie_rng_" .. i, "serie_range_" .. i, controlspec.new(0, 11, "lin", 1, 0, ""))
    params:set_action("serie_rng_" .. i, function(x) ranges[i]=x end)
  end
  params:set("serie_rng_2", 11)
  
  for i = 1, 5 do
    for ii = 1, 2 do
      params:add_control("seq_rng_" .. i .. "_" .. ii, "seq_range_" .. i .. "_" .. ii, controlspec.new(0, 4, "lin", 1, 0, ""))
      params:set_action("seq_rng_" .. i .. "_" .. ii, function(x) range[i][ii]=x end)
    end
  end
  for i = 1, 5 do
    for ii = 2, 2 do
      params:set("seq_rng_" .. i .. "_" .. ii, 4)
    end
  end
  
  for i = 1, 5 do
    for ii = 1, 5 do
      for iii = 1, 2 do
        params:add_control("seq2_rng_" .. i .. "_" .. ii .. "_" .. iii, "seq2_range_" .. i .. "_" .. ii .. "_" .. iii, controlspec.new(0, 4, "lin", 1, 0, ""))
        params:set_action("seq2_rng_" .. i .. "_" .. ii .. "_" .. iii, function(x) range2[i][ii][iii]=x end)
      end
    end
  end
  for i = 1, 5 do
    for ii = 1, 5 do
      for iii = 2, 2 do
        params:set("seq2_rng_" .. i .. "_" .. ii .. "_" .. iii, 4)
      end
    end
  end
  
  params:add_separator("values")

  for i = 1, 5 do
    params:add_control("serie_" .. i, "serie_" .. i, controlspec.new(0, 11, "lin", 1, i-1, ""))
    params:set_action("serie_" .. i, function(x) seriexy(x,i) end)
  end
  
  for i = 1, 5 do
    for ii = 1, 5 do
      params:add_control("seq_val_" .. i .. "_" .. ii, "seq_set_value_" .. i .. "_" .. ii, controlspec.new(1, 5, "lin", 1, ii, ""))
      params:set_action("seq_val_" .. i .. "_" .. ii, function(x) seqxy(x,i,ii) end)
    end
  end
  
  for i = 1, 5 do
    for ii = 1, 5 do
      for iii = 1, 5 do
        params:add_control("seq_valset_" .. i .. "_" .. ii .. "_" .. iii, "seq_valset_" .. i .. "_" .. ii .. "_" .. iii, controlspec.new(1, 5, "lin", 1, iii, ""))
        params:set_action("seq_valset_" .. i .. "_" .. ii .. "_" .. iii, function(x) seqsetxy(x,i,ii,iii) end)
      end
    end
  end
  
  -- load default pset
  params:read()
  params:bang()
  
  test = clock.run(fiveloop, 4, 1, fivecount, fivecount2, range, range2, serie, val, valset)
  
end


function redraw()
  screen.clear()
  screen.stroke()
  screen.aa(0)
  screen.line_width(1)
  
  screen.translate(0,-(screenpos))
  
  screen.level(3)
  screen.arc(32,32,24,arcangle(ranges[1]*30),arcangle(ranges[2]*30))
  screen.stroke()
  screen.arc(96,32,24,arcangle(0),arcangle(359))
  screen.stroke()
  
  screen.arc(32,96,20,arcangle(range[1][1]*72),arcangle(range[1][2]*72))
  screen.stroke()
  screen.arc(96,96,20,arcangle(range2[1][1][1]*72),arcangle(range2[1][1][2]*72))
  screen.stroke()
  
  screen.arc(32,160,20,arcangle(range[2][1]*72),arcangle(range[2][2]*72))
  screen.stroke()
  screen.arc(96,160,20,arcangle(range2[2][fivecount[2]+1][1]*72),arcangle(range2[2][fivecount[2]+1][2]*72))
  screen.stroke()
  
  screen.arc(32,224,20,arcangle(range[3][1]*72),arcangle(range[3][2]*72))
  screen.stroke()
  screen.arc(96,224,20,arcangle(range2[3][fivecount[3]+1][1]*72),arcangle(range2[3][fivecount[3]+1][2]*72))
  screen.stroke()
  
  screen.arc(32,288,20,arcangle(range[4][1]*72),arcangle(range[4][2]*72))
  screen.stroke()
  screen.arc(96,288,20,arcangle(range2[4][fivecount[4]+1][1]*72),arcangle(range2[4][fivecount[4]+1][2]*72))
  screen.stroke()
  
-- serie graph  
  for i = 1, 5 do 
    screen.level(6)
    screen.circle(xy[1][i][1],xy[1][i][2],4)
    if seriesel + 1 == i then screen.stroke() else screen.fill() end
  end
  for i = 1, 5 do
    screen.level(3)
    screen.move(xy[2][i][1],xy[2][i][2])
    screen.line(xy[2][(i%5)+1][1],xy[2][(i%5)+1][2])
    screen.stroke()
  end
  
-- amp graph
  for i = range[1][1]+1, range[1][2]+1 do 
    screen.level(6)
    screen.move(xy[3][i][1]+(val[1][i]),xy[3][i][2]+(val[1][i]))
    screen.line(xy[3][i][1]-(val[1][i]),xy[3][i][2]-(val[1][i]))
    screen.line(xy[3][i][1]+(val[1][i]*2),xy[3][i][2]-(val[1][i]))
    screen.close()
    if i == fivecount[1]+1 then screen.stroke() else screen.fill() end
  end
  for i = range2[1][fivecount[1]+1][1]+1, range2[1][fivecount[1]+1][2]+1 do 
    screen.level(6)
    screen.move(xy[4][i][1]+(valset[1][fivecount[1]+1][i]),xy[4][i][2]+(valset[1][fivecount[1]+1][i]))
    screen.line(xy[4][i][1]-(valset[1][fivecount[1]+1][i]),xy[4][i][2]-(valset[1][fivecount[1]+1][i]))
    screen.line(xy[4][i][1]+(valset[1][fivecount[1]+1][i]*2),xy[4][i][2]-(valset[1][fivecount[1]+1][i]))
    screen.close()
    if i == fivecount2[1][fivecount[1]+1]+1 then screen.stroke() else screen.fill() end
  end
  
-- dur graph
  for i = range[2][1]+1, range[2][2]+1 do 
    screen.level(6)
    screen.rect(xy[5][i][1]-val[2][i],xy[5][i][2]-val[2][i],val[2][i]*2,val[2][i]*2)
    screen.close()
    if i == fivecount[2]+1 then screen.stroke() else screen.fill() end
  end
  for i = range2[2][fivecount[1]+1][1]+1, range2[2][fivecount[1]+1][2]+1 do
    screen.level(6)
    screen.rect(xy[6][i][1]-valset[2][fivecount[2]+1][i],xy[6][i][2]-valset[2][fivecount[2]+1][i],valset[2][fivecount[2]+1][i]*2,valset[2][fivecount[2]+1][i]*2)
    screen.close()
    if i == fivecount2[2][fivecount[2]+1]+1 then screen.stroke() else screen.fill() end
  end
  
-- note graph
  for i = 1, 5 do 
    xyp[i] = circlepent(xy[7][i],val[3][i]+2)
  end
  for i = range[3][1]+1, range[3][2]+1 do 
    screen.level(6)
    for ii = 1, 5 do
      screen.line(xyp[i][ii][1],xyp[i][ii][2])
    end
    screen.close()
    if i == fivecount[3]+1 then screen.stroke() else screen.fill() end
  end
  for i = 1, 5 do 
    xyp[5+i] = circlepent(xy[8][i],valset[3][fivecount[3]+1][i]+2)
  end
  for i = range2[3][fivecount[1]+1][1]+1, range2[3][fivecount[1]+1][2]+1 do 
    screen.level(6)
    for ii = 1, 5 do
      screen.line(xyp[5+i][ii][1],xyp[5+i][ii][2])
    end
    screen.close()
    if i == fivecount2[3][fivecount[3]+1]+1 then screen.stroke() else screen.fill() end
  end
  
-- octave graph
  for i = range[4][1]+1, range[4][2]+1 do
    screen.level(6)
    screen.circle(xy[9][i][1],xy[9][i][2],val[4][i]+1)
    if i == fivecount[4]+1 then screen.stroke() else screen.fill() end
  end
  for i = range2[4][fivecount[4]+1][1]+1, range2[4][fivecount[4]+1][2]+1 do 
    screen.level(6)
    screen.circle(xy[10][i][1],xy[10][i][2],valset[4][fivecount[4]+1][i]+1)
    if i == fivecount2[4][fivecount[4]+1]+1 then screen.stroke() else screen.fill() end
  end
  
  screen.translate(0,screenpos)
  screen.update()
end


function enc(n, d)
  if n == 1 then
    scrollscreen = clock.run(scroll,d)
  
  elseif n == 2 then
    if pos == 0 then
      if key2shift == 0 and key3shift == 0 then
        seriesel = (seriesel + d) % 5
      elseif key2shift == 1 and key3shift == 0 then
        key2shiftmv = 1
        params:delta("serie_rng_" .. 1, d)
      end
    elseif pos > 0 then
      if key2shift == 0 and key3shift == 0 then
        fivecount2[pos][fivecount[pos]+1] = (fivecount2[pos][fivecount[pos]+1] + d) % 5
      elseif key2shift == 1 and key3shift == 0 then
        key2shiftmv = 1
        params:delta("seq_rng_" .. pos .. "_" .. 1, d)
      elseif key2shift == 0 and key3shift == 1 then
        key3shiftmv = 1
        params:delta("seq2_rng_" .. pos .. "_" .. fivecount[pos]+1 .. "_" .. 1, d)
      end
    end
 
  elseif n == 3 then
    if pos == 0 then
      if key2shift == 0 and key3shift == 0 then
        serie[seriesel+1] = (serie[seriesel+1]+d)%12
        xy[1]=circleserie(serie, {32,32}, 24)
        xy[2]=circleserie(serie, {32,32}, 16)
      elseif key2shift == 1 and key3shift == 0 then
        key2shiftmv = 1
        params:delta("serie_rng_" .. 2, d)
      end
    elseif pos > 0 then
      if key2shift == 1 and key3shift == 0 then
        key2shiftmv = 1
        params:delta("seq_rng_" .. pos .. "_" .. 2, d)
      elseif key2shift == 0 and key3shift == 1 then
        key3shiftmv = 1
        params:delta("seq2_rng_" .. pos .. "_" .. fivecount[pos]+1 .. "_" .. 2, d)
      elseif key2shift == 0 and key3shift == 0 then
        params:delta("seq_valset_" .. pos .. "_" .. fivecount[pos]+1 .. "_" .. fivecount2[pos][fivecount[pos]+1]+1, d)
      end
    end

  end
  redraw()
end


function key(n, z)
  if n == 1 then
    
  elseif n == 2 then
    if z == 1 then
      key2shift = 1
      key2shiftmv = 0
    end
    if pos > 0 and z == 0 and key2shiftmv == 0 and key3shift == 0 then
      fivecount[pos] = (fivecount[pos] - 1) % 5
    end
    if z == 0 then
      key2shift = 0
    end
  
  elseif n == 3 then
    if z == 1 then
      key3shift = 1
      key3shiftmv = 0
    end
    if screenpos > 0 and z == 0  and key2shift == 0 and key3shiftmv == 0 then
      fivecount[pos] = (fivecount[pos] + 1) % 5
    end
    if z == 0 then
      key3shift = 0
    end
    
  end
  redraw()
end

function cleanup()
end