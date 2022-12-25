--         .       .
--      .       .            .
--              .     .
--    .    . Swarmatron .
--         .         .    .
--             .   .     .
--           .             .
-- E1, E2 oscillator, E3 span
-- K1+E2,E3 filter

-- First, a bash script starts a headless Pd with the Pd patch `swarmatron.pd`.
-- Second, the patch listens to UDP OSC messages in port 10121.
--
-- The following addresses are recognized:
--
--     /freq  f    Oscillator frequency.
--     /span  f    Span of the swarm.
--     /ffreq f    Low-pass filter frequency.
--     /fq    f    Low-pass filter Q.
--
-- Finally when the norns script exits, all running Pd processes are killed (crude!)

DEBUG = false

pd_osc = {"localhost", 10121}
engine_boot = _path.this.lib.."swarmatron.sh"

screen_width = 128
screen_height = 65
shifted = false

-- # Lifecycle.

function init()
  -- Initialize everything.
  start_pd()
  init_params()

  -- Get an UI loop going.
  clock.run(function()
    while true do
      clock.sleep(1/15)
      redraw()
    end
  end)
end

function rerun()
  cleanup()
end

function cleanup()
  stop_pd()
end

-- # Pd process management. Crude lol.

function start_pd()
  if not DEBUG then
    os.execute(engine_boot)
  end
end

function stop_pd()
  if not DEBUG then
    os.execute("killall pd")
  end
end

-- # Parameter setup.

function init_params()
  -- params:add_control('freq', 'freq', controlspec.WIDEFREQ)
  params:add_control('freq', 'freq', controlspec.new(0, 20000, 'lin', 1/200000, 261.61, 'Hz', 1/200000)) -- Waah I don't understand what all these things are in a controlspec!
  params:set_action('freq', function(freq) osc.send(pd_osc, "/freq", {freq}) end)
  
  -- params:add_control('span', 'span', controlspec.new(0, 100, 0.01, 0.01, 25))
  -- params:add_number('span', 'span', 0.0, 100.0, 25)
  params:add_control('span', 'span', controlspec.new(0, 100, 'lin', 1/1000, 2, '', 1/1000))
  params:set_action('span', function(span) osc.send(pd_osc, "/span", {span}) end)
  
  params:add_control('ffreq', 'ffreq', controlspec.WIDEFREQ)
  params:set_action('ffreq', function(ffreq) osc.send(pd_osc, "/ffreq", {ffreq}) end)
  params:set('ffreq', 666) -- 🤘
  
  -- params:add_control('fq', 'q', controlspec.new(0.1, 10.0, 'lin', 0.01, 2))
  -- params:add_control('fq', 'fq', controlspec.RQ)
  params:add_control('fq', 'q', controlspec.new(0.01, 10.0, 'lin', 0.01, 2))
  params:set_action('fq', function(fq) osc.send(pd_osc, "/fq", {fq}) end)
end

-- # Interactions.

-- Respond to encoders.
function enc(encoder, delta)
  if encoder == 1 then          -- adjust oscillator
    params:delta('freq', delta*100)
  elseif encoder == 2 then
    if shifted then             -- adjust filter frequency
      params:delta('ffreq', delta)
    else                        -- fine adjust oscillator frequency
      params:delta('freq', delta)
    end
  elseif encoder == 3 then
    if shifted then             -- adjust filter Q
      params:delta('fq', delta)
    else                        -- adjust the span
      params:delta('span', delta)
    end
  end
end

-- K1 pressed. It's the shift.
function key(button, pressed)
  -- NB. 0 is true in Lua, not false
  if button == 1 then
    if pressed == 1 then
      shifted = true
    elseif pressed == 0 then
      shifted = false
    end
  end
end

-- # Drawing

-- Redraw the screen.
function redraw()
  screen.clear()
  draw_swarm()
  screen.move(screen_width/2,screen_height/2+10)
  screen.level(15)
  screen.font_face(40)
  screen.font_size(20)
  screen.text_center(util.round(params:get('freq'), 0.1))
  -- screen.font_face(1)
  -- screen.font_size(8)
  screen.update()
end

function draw_swarm()
  swarminess = params:get('span') * 25
  brightness = util.round(util.linlin(params:get_range('ffreq')[1], params:get_range('ffreq')[2], 1, 16, params:get('ffreq')))

  screen.level(brightness)
  for i=0,swarminess,1 do
    screen.pixel(math.random(screen_width), math.random(screen_height))
    screen.fill()
  end
end
