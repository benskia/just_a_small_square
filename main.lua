-- Scale the 512x512 game resolution to a more visible 1028x1028
local push = require "libraries/push"
local game_width, game_height = 512, 512
local window_width, window_height = 1028, 1028
local push_attributes = {fullscreen=false, resizable=false, pixelperfect=true}
push:setupScreen(game_width, game_height, window_width, window_height, push_attributes)

local timer_start = love.timer.getTime()
local current_time = 0
local result = nil

local menu_buttons = {}
local menu_is_open = false


function love.load()
    wf = require "libraries/windfield"
    sti = require "libraries/sti"
    maps = require("maps/maps")
    controls, alt_controls, player, gravity, terminal_velocity = unpack(require("settings"))

    -- Map index, STI map, and high score initialization
    current_map_index = 1
    game_map = sti(maps[current_map_index])
    local high_scores = {}
    for i = 1, #maps, 1 do
        table.insert(high_scores, i, nil)
    end

    -- Menu button constructor
    local function newButton(text, fn)
        return {
            text = text,
            fn = fn,
    
            now = false,
            last = false
        }
    end

    table.insert(menu_buttons, newButton(
        "Reset Level",
        function()
            reset()
        end
    ))
    table.insert(menu_buttons, newButton(
        "Next Level",
        function()
            if maps[current_map_index + 1] then
                high_scores[current_map_index] = result
                current_map_index = current_map_index + 1
                result = nil
                reset()
            end
        end
    ))
    table.insert(menu_buttons, newButton(
        "Previous Level",
        function()
            if maps[current_map_index - 1] then
                high_scores[current_map_index] = result
                current_map_index = current_map_index - 1
                result = nil
                reset()
            end
        end
    ))
    table.insert(menu_buttons, newButton(
        "Exit Game",
        function()
            love.event.quit(0)
        end
    ))

    local colliders = {}
    local tiled_static_layers = {"platforms", "death_blocks", "exit"}

    function reset()
        game_map = sti(maps[current_map_index])

        -- Clear any existing physics objects before building the current map
        if world then world:destroy() end
        world = wf.newWorld(0, 0, false)

        -- Static windfield colliders are implemented with Tiled object layers
        -- For each layer that exists in the current level, create all colliders
        -- for that layer
        local function construct_static_colliders(layer_name)
            if game_map.layers[layer_name] then
                world:addCollisionClass(layer_name)
                for i, obj in pairs(game_map.layers[layer_name].objects) do
                    local collider = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
                    collider:setCollisionClass(layer_name)
                    collider:setType("static")
                    table.insert(colliders, collider)
                end
            end
        end

        for i, layer in ipairs(tiled_static_layers) do
            construct_static_colliders(layer)
        end

        -- Create the player's collider object, and save position and dimensions
        -- to draw the player during gameplay
        if game_map.layers["player"] then
            world:addCollisionClass("player")
            for i, obj in pairs(game_map.layers["player"].objects) do
                player.x, player.y, player.w, player.h = obj.x, obj.y, obj.width, obj.height
                player.collider = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
                player.collider:setCollisionClass("player")
                player.collider:setFixedRotation(true)
                player.collider:setFriction(0)
            end
        end

        timer_start = love.timer.getTime()

        -- If a lower high score exists for the current map, use it
        if high_scores[current_map_index] and result then
            if high_scores[current_map_index] < result then
                result = high_scores[current_map_index]
            end
        elseif high_scores[current_map_index] and not result then
            result = high_scores[current_map_index]
        end

        -- Directional flags will be used to determine whether the player is able
        -- to jump or move along the x-axis. To set these flags, we check the normal
        -- vector for collisions that take place between the player and platforms.
        local function collision_side(collider_1, collider_2, Contact)
            if collider_1.collision_class == "player"
            and collider_2.collision_class == "platforms" then
                local nx, ny = Contact:getNormal()
                if ny > 0 then player.is_colliding_top = true end
                if ny < 0 then player.is_colliding_bot = true end
                if nx > 0 then player.is_colliding_left = true end
                if nx < 0 then player.is_colliding_right = true end
            end
        end

        -- Before a collision is resolved, determine its normal vector
        player.collider:setPreSolve(collision_side)
    end

    reset()
end


function love.update(dt)
    if not menu_is_open then
        player.x = player.collider:getX() - player.w / 2
        player.y = player.collider:getY() - player.h / 2
        player.is_colliding_top = false
        player.is_colliding_bot = false
        player.is_colliding_left = false
        player.is_colliding_right = false

        player.collider:setLinearVelocity(player.vx, player.vy)
        world:update(dt)

        local function calc_velocity_y(vy, float_coeff, drag_coeff, gravity, t_velocity, is_bonking)
            -- Scrub upward momentum when the player collides upward into a platform
            if is_bonking then vy = 0 end

            -- Holding jump decreases the downward acceleration and maximum,
            -- downward speed of the player
            if love.keyboard.isDown(controls.jump) or love.keyboard.isDown(alt_controls.jump) then
                gravity = gravity * float_coeff
                t_velocity = t_velocity * drag_coeff
            end
    
            vy = vy + gravity

            if vy > t_velocity then vy = t_velocity end

            return vy
        end

        if not player.is_colliding_bot then
            player.vy = calc_velocity_y(
                player.vy, player.float_coefficient, player.drag_coefficient,
                gravity, terminal_velocity, player.is_colliding_top
            )
        end

        if (love.keyboard.isDown(controls.left) or love.keyboard.isDown(alt_controls.left))
        and not player.is_colliding_left then
            player.vx = player.speed * -1
            
        elseif (love.keyboard.isDown(controls.right) or love.keyboard.isDown(alt_controls.right))
        and not player.is_colliding_right then
            player.vx = player.speed
        else
            player.vx = 0
        end
    end

    if player.collider:enter("death_blocks") then
        reset()
    end

    if player.collider:enter("exit") then
        if not result or current_time < result then
            result = current_time
        end
        reset()
    end
end


function love.keypressed(key)
    if (key == controls.jump or key == alt_controls.jump)
    and player.is_colliding_bot then
        player.vy = player.jump_strength * -1
    end

    if key == controls.menu then
        menu_is_open = not menu_is_open
    end
end


function love.draw()
    push:start()
        game_map:drawLayer(game_map.layers["background"])
        game_map:drawLayer(game_map.layers["foreground"])

        love.graphics.setColor(player.rgb)
        love.graphics.rectangle('fill', player.x, player.y, player.w, player.h)
    push:finish()

    if not menu_is_open then
        current_time = love.timer.getTime() - timer_start
        love.graphics.printf(string.format("%.3f", current_time), window_width / 2 - 32, 32, 256, center, 0, 2)

        if result then
            love.graphics.printf(string.format("%.3f",result), window_width / 2 - 32, 4, 256, center, 0, 2)
        end
    end

    if menu_is_open then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Level "..current_map_index, window_width / 2 - 32, 32, 256, center, 0, 2)

        local button_width = 300
        local button_height = 64
        local margin = 8
        local scale = 2

        local menu_height = (button_height + margin) * #menu_buttons
        local cursor_y = 0

        for i, button in ipairs(menu_buttons) do
            button.last = button.now

            local button_x = window_width / 2 - button_width / 2
            local button_y = window_height / 2 - menu_height / 2 + cursor_y

            local color = {0.6, 0.6, 0.6, 1.0}
            local mx, my = love.mouse.getPosition()
            local mouseover = mx > button_x and mx < button_x + button_width and my > button_y and my < button_y + button_height

            if mouseover then
                color = {0.8, 0.8, 0.8, 1.0}
            end

            button.now = love.mouse.isDown(1)

            if button.now and not button.last and mouseover then
                button.fn()
            end

            love.graphics.setColor(unpack(color))
            love.graphics.rectangle(
                'fill',
                button_x,
                button_y,
                button_width,
                button_height
            )

            love.graphics.setColor(0, 0, 0)
            love.graphics.printf(
                button.text,
                button_x,
                button_y + button_height / 3,
                button_width / scale,
                "center",
                0,
                scale
            )

            cursor_y = cursor_y + button_height + margin
        end
    end
end


-- Override love.run() to pass a fixed deltaTime to love.update(), based on accumulated lag

-- 1 / Ticks Per Second
local TICK_RATE = 1 / 144

-- How many Frames are allowed to be skipped at once due to lag (no "spiral of death")
local MAX_FRAME_SKIP = 25

function love.run()
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
 
    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end

    local lag = 0.0

    -- Main loop time.
    return function()
        -- Process events.
        if love.event then
            love.event.pump()
            for name, a,b,c,d,e,f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                love.handlers[name](a,b,c,d,e,f)
            end
        end

        -- Cap number of Frames that can be skipped so lag doesn't accumulate
        if love.timer then lag = math.min(lag + love.timer.step(), TICK_RATE * MAX_FRAME_SKIP) end

        while lag >= TICK_RATE do
            if love.update then love.update(TICK_RATE) end
            lag = lag - TICK_RATE
        end

        if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())
 
            if love.draw then love.draw() end
            love.graphics.present()
        end

        -- Even though we limit tick rate and not frame rate, we might want to cap framerate at 1000 frame rate as mentioned https://love2d.org/forums/viewtopic.php?f=4&t=76998&p=198629&hilit=love.timer.sleep#p160881
        if love.timer then love.timer.sleep(0.001) end
    end
end
