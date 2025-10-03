
local Fivesynth = {}
local ControlSpec = require 'controlspec'
local Formatters = require 'formatters'

-- helper function to round and format parameter value text:
function round_form(param,quant,form)
  return(util.round(param,quant)..form)
end

-- first, we'll collect all of our commands into a table of norns-friendly ranges.
-- since all the voices share the same parameter names,
--   we can just iterate on this table and cleanly build 16 parameters across 9 voices.
local specs = {
  {type = "separator", name = "synthesis"},
  {id = 'sub_div', name = 'sub division', type = 'number', min = 1, max = 10, default = 1},
  {id = 'noise_amp', name = 'noise level', type = 'control', min = 0, max = 2, warp = 'lin', default = 0, formatter = function(param) return (round_form(param:get()*100,1,"%")) end},
  {id = 'coef', name = 'pluck coef', type = 'control', min = -0.99, max = 0.99, warp = 'lin', default = 0.5},
  {id = 'attack', name = 'attack', type = 'control', min = 0.001, max = 10, warp = 'exp', default = 0, formatter = function(param) return (round_form(param:get(),0.01," s")) end},
  {id = 'release', name = 'release', type = 'control', min = 0.001, max = 10, warp = 'exp', default = 0.3, formatter = function(param) return (round_form(param:get(),0.01," s")) end},
  {id = 'slew', name = 'frequency slew', type = 'control', min = 0.001, max = 10, warp = 'exp', default = 0, formatter = function(param) return (round_form(param:get(),0.01," s")) end}
}

-- initialize parameters:
function Fivesynth.add_params()
  params:add_separator("Fivesynth")
  local voices = {"all",1,2,3,4,5} -- match the engine's expected arguments for commands
  for i = 1,#voices do -- for each voice...
    params:add_group("voice ["..voices[i].."]",#specs) -- add a PARAMS group, eg. 'voice [all]'
    for j = 1,#specs do -- for each of the lines in the 'specs' table above, do this:
      local p = specs[j] -- (creates an alias for the line's contents)
      if p.type == 'control' then -- if the 'type' in the current 'specs' line is 'control', do this:
        params:add_control( -- add a control using:
          voices[i].."_"..p.id, -- the 'id' in the line
          p.name, -- the name in the line
          ControlSpec.new(p.min, p.max, p.warp, 0, p.default), -- the controlspec values in the line ('min', 'max', 'warp', and 'default')
          p.formatter -- the formatter in the line
        )
      elseif p.type == 'number' then -- otherwise, if the 'type' is 'number', do this:
        params:add_number(
          voices[i].."_"..p.id,
          p.name,
          p.min,
          p.max,
          p.default,
          p.formatter
        )
      elseif p.type == "option" then -- otherwise, if the 'type' is 'option', do this:
        params:add_option(
          voices[i].."_"..p.id,
          p.name,
          p.options,
          p.default
        )
      elseif p.type == 'separator' then -- otherwise, if the 'type' is 'separator', do this:
        params:add_separator(p.name)
      end
      
      -- if the parameter type isn't a separator, then we want to assign it an action to control the engine:
      if p.type ~= 'separator' then
        params:set_action(voices[i].."_"..p.id, function(x)
          -- use the line's 'id' as the engine command, eg. engine.amp or engine.cutoff_env,
          --  and send the voice and the value:
          engine[p.id](voices[i],x) -- 
          if voices[i] == "all" then -- it's nice to echo 'all' changes back to the parameters themselves
            -- since 'all' voice corresponds to the first entry in 'voices' table,
            --   we iterate the other parameter groups as 2 through 9:
            for other_voices = 2,#voices do
              -- send value changes silently, since 'all' changes all values on SuperCollider's side:
              params:set(voices[other_voices].."_"..p.id, x, true)
            end
          end
        end)
      end
      
    end
  end
  
  local cs_amp = controlspec.new(0, 2, "lin", 0.001, 1, nil, 1 / 200)
  local cs_fc1 = controlspec.new(20, 20000, "exp", 0, 600, "Hz")
  local cs_fc2 = controlspec.new(20, 20000, "exp", 0, 1800, "Hz")
  local cs_pan = controlspec.new(-1, 1, "lin", 0.001, 0, nil, 1 / 200)
  local gain = controlspec.new(0, 1000, "exp", 0.1, 1)
  local level = controlspec.new(0, 1, "lin", 0.01, 1)

  local frm_percent = function(param)
    return ((param:get() * 100) .. "%")
  end

  params:add({
    type = "control",
    id = "dry_level",
    name = "dry level",
    controlspec = cs_amp,
    formatter = frm_percent,
    action = function(x)
      engine.set_dry("level", x)
    end,
  })

  params:add({
    type = "control",
    id = "delay_level",
    name = "delay level",
    controlspec = cs_amp,
    formatter = frm_percent,
    action = function(x)
      engine.set_send("level", x)
    end,
  })

  params:add({
    type = "control",
    id = "dry_pan",
    name = "dry pan",
    controlspec = cs_pan,
    formatter = Formatters.bipolar_as_pan_widget,
    action = function(x)
      engine.set_dry("pan", x)
    end,
  })

  params:add({
    type = "control",
    id = "delay_pan",
    name = "delay pan",
    controlspec = cs_pan,
    formatter = Formatters.bipolar_as_pan_widget,
    action = function(x)
      engine.set_send("pan", x)
    end,
  })

  params:add({
    type = "separator",
    id = "main_eq_separator",
    name = "main EQ",
  })

  params:add({
    type = "control",
    id = "eq_lo",
    name = "lo",
    controlspec = cs_amp,
    formatter = frm_percent,
    action = function(x)
      engine.set_main("ampLo", x)
    end,
  })

  params:add({
    type = "control",
    id = "eq_mid",
    name = "mid",
    controlspec = cs_amp,
    formatter = frm_percent,
    action = function(x)
      engine.set_main("ampMid", x)
    end,
  })

  params:add({
    type = "control",
    id = "eq_hi",
    name = "hi",
    controlspec = cs_amp,
    formatter = frm_percent,
    action = function(x)
      engine.set_main("ampHi", x)
    end,
  })

  params:add({
    type = "control",
    id = "fc1",
    name = "lo freq",
    controlspec = cs_fc1,
    action = function(x)
      engine.set_main("fc1", x)
    end,
  })

  params:add({
    type = "control",
    id = "fc2",
    name = "hi freq",
    controlspec = cs_fc2,
    action = function(x)
      engine.set_main("fc2", x)
    end,
  })

  params:add({
    type = "control",
    id = "gain",
    name = "gain",
    controlspec = gain,
    action = function(x)
      engine.set_main("gain", x)
    end,
  })

  params:add({
    type = "control",
    id = "level",
    name = "level",
    controlspec = level,
    action = function(x)
      engine.set_main("level", x)
    end,
  })
  
  -- activate the parameters' current values:
  params:bang()
end

 -- we return these engine-specific Lua functions back to the host script:
return Fivesynth
