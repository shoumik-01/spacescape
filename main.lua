-- Chill Space-scape Scene with Love2D
-- A relaxing space environment with stars, asteroids, comets and occasional wormholes
-- Author: Shoumik Hasan

-- Global variables
local spaceship = {} -- Table to store spaceship properties
local stars = {} -- Table to store star properties
local coloredStars = {} -- Table to store special colored stars
local asteroids = {} -- Table to store asteroid properties
local comets = {} -- Table to store comet properties
local wormholes = {} -- Table to store wormhole properties

-- Colors for various space objects
local COLORS = {
    RED = {1, 0.3, 0.3},
    BLUE = {0.3, 0.5, 1},
    PURPLE = {0.8, 0.3, 1},
    GREEN = {0.3, 1, 0.5},
    YELLOW = {1, 1, 0.3},
    CYAN = {0.3, 1, 1},
    ORANGE = {1, 0.6, 0.2},
    PINK = {1, 0.4, 0.8}
}

-- Initialize the game
function love.load()
    -- Set random seed based on current time for different generation each run
    math.randomseed(os.time())
    
    -- Enable vsync and MSAA (Multi-Sample Anti-Aliasing) with 4 samples
    love.window.setMode(0, 0, {
        vsync = true,
        msaa = 4,
        resizable = false,
        fullscreen = true
    })
    
    -- Set window title
    love.window.setTitle("Chill Space-scape")
    spaceship.thrustersActive = false
    spaceship.thrusterParticles = {}
    -- Load spaceship image
    spaceship.image = love.graphics.newImage("spaceship.png")
    
    -- Calculate spaceship dimensions
    -- Original size is 2048x2048, we'll scale it down to 5% of original size
    spaceship.scale = 0.05
    spaceship.width = spaceship.image:getWidth() * spaceship.scale
    spaceship.height = spaceship.image:getHeight() * spaceship.scale
    
    -- Set initial spaceship position
    spaceship.x = -spaceship.width -- Start just off-screen to the left
    spaceship.y = love.graphics.getHeight() / 2 - spaceship.height / 2
    
    -- Track original position for screen wrap
    spaceship.originX = spaceship.x
    spaceship.originY = spaceship.y
    
    -- Set spaceship auto-movement speed (pixels per second)
    spaceship.autoSpeed = 30
    
    -- Set spaceship manual movement speed (pixels per second)
    spaceship.manualSpeed = 200

    -- Audio support
    music = love.audio.newSource("space_music.mp3", "stream")
    music:setLooping(true) -- Make it loop continuously
    music:setVolume(0.7) -- Set volume to 70%
    music:play() -- Start playing immediately
    
    -- Create regular white stars (multiple layers for parallax effect)
    createStars()
    
    -- Create special colored stars (rare)
    createColoredStars()
    
    -- Create asteroids
    createAsteroids()
    
    -- Create comets with long trails
    createComets()
    
    -- Initialize wormhole timer
    wormhole = {
        active = false,
        timer = love.math.random(15, 30), -- Random time until first wormhole appears
        duration = 0, -- Duration for active wormhole
        minInterval = 15, -- Minimum seconds between wormhole appearances
        maxInterval = 40 -- Maximum seconds between wormhole appearances
    }
end

-- Create multiple layers of stars for parallax effect
function createStars()
    -- Create 3 layers of stars with different speeds and sizes
    for layer = 1, 3 do
        local layerStars = {}
        local count = 0
        
        -- More stars in background layers, fewer in foreground
        if layer == 1 then
            count = 400 -- Distant background stars (small and slow)
        elseif layer == 2 then
            count = 200 -- Middle layer stars
        else
            count = 50 -- Foreground stars (larger and faster)
        end
        
        for i = 1, count do
            local star = {
                x = love.math.random(0, love.graphics.getWidth()),
                y = love.math.random(0, love.graphics.getHeight()),
                size = love.math.random(1, 2) * layer, -- Larger stars in foreground
                speed = love.math.random(10, 30) * layer, -- Faster movement in foreground
                brightness = love.math.random(70, 100) / 100, -- Random brightness
                twinkleSpeed = love.math.random(1, 4), -- How fast the star twinkles
                twinkleOffset = love.math.random(0, 100) / 100 -- Offset for twinkling
            }
            table.insert(layerStars, star)
        end
        
        table.insert(stars, layerStars)
    end
end

-- Create rare multicolored flickering stars
function createColoredStars()
    -- Create a small number of special colored stars
    local coloredStarCount = love.math.random(15, 25) -- Rare compared to white stars
    
    local colorKeys = {}
    for k in pairs(COLORS) do
        table.insert(colorKeys, k)
    end
    
    for i = 1, coloredStarCount do
        -- Pick a random color from the COLORS table
        local colorKey = colorKeys[love.math.random(1, #colorKeys)]
        local color = COLORS[colorKey]
        
        local star = {
            x = love.math.random(0, love.graphics.getWidth()),
            y = love.math.random(0, love.graphics.getHeight()),
            size = love.math.random(2, 4), -- Slightly larger than regular stars
            speed = love.math.random(15, 40), -- Similar speed to regular stars
            color = color,
            flickerSpeed = love.math.random(3, 8), -- Faster flickering than regular stars
            flickerOffset = love.math.random(0, 100) / 100,
            pulseSize = love.math.random(5, 20) / 100 -- How much the star size pulses
        }
        table.insert(coloredStars, star)
    end
end

-- Create asteroid field
function createAsteroids()
    local asteroidCount = love.math.random(20, 40)
    
    for i = 1, asteroidCount do
        local asteroid = {
            x = love.math.random(0, love.graphics.getWidth() * 2),
            y = love.math.random(0, love.graphics.getHeight()),
            size = love.math.random(5, 25),
            speed = love.math.random(20, 50),
            rotation = love.math.random(0, 360) * math.pi / 180,
            rotationSpeed = love.math.random(-50, 50) / 100,
            vertices = {}
        }
        
        -- Create irregular asteroid shape with vertices
        local vertexCount = love.math.random(5, 10)
        for j = 1, vertexCount do
            local angle = (j - 1) * (2 * math.pi / vertexCount)
            local distance = asteroid.size * love.math.random(7, 13) / 10
            local vertex = {
                x = math.cos(angle) * distance,
                y = math.sin(angle) * distance
            }
            table.insert(asteroid.vertices, vertex)
        end
        
        table.insert(asteroids, asteroid)
    end
end

-- Create comets with extra long tails
function createComets()
    -- Much fewer comets (1-3 instead of 4-8)
    local cometCount = love.math.random(1, 3)
    
    for i = 1, cometCount do
        -- Pick a random color from the COLORS table for each comet
        local colorKeys = {}
        for k in pairs(COLORS) do
            table.insert(colorKeys, k)
        end
        local colorKey = colorKeys[love.math.random(1, #colorKeys)]
        local color = COLORS[colorKey]
        
        -- Much more irregularly sized comets (5-30 instead of 8-15)
        local size = love.math.random(5, 30)
        
        local comet = {
            x = love.graphics.getWidth() + love.math.random(0, love.graphics.getWidth() * 2), -- Start further away
            y = love.math.random(0, love.graphics.getHeight()),
            size = size,
            -- Much slower comets (30-70 instead of 100-200)
            speed = love.math.random(30, 70),
            angle = 0, -- No angle, only horizontal movement
            tailLength = love.math.random(200, 400), -- Even longer tails
            color = color,
            particles = {},
            glowSize = size * love.math.random(2, 3), -- Glow size proportional to comet size
            trail = {}, -- Add trail table for pong-like effect
            trailLength = love.math.random(10, 20), -- Length of trail in segments
            trailThickness = size * 0.7 -- Thickness of trail
        }
        
        -- Initialize empty trail
        for j = 1, comet.trailLength do
            table.insert(comet.trail, {x = comet.x, y = comet.y, size = comet.size * (1 - (j / comet.trailLength) * 0.7)})
        end
        
        -- Create comet tail particles (more particles for longer tail)
        local particleCount = love.math.random(70, 100) -- More particles
        for j = 1, particleCount do
            local particle = {
                distance = love.math.random(0, comet.tailLength) / 100,
                offset = love.math.random(-comet.size, comet.size) / 3,
                size = love.math.random(2, comet.size / 2),
                alpha = love.math.random(2, 10) / 10,
                flicker = love.math.random(80, 120) / 100 -- Random flicker value
            }
            table.insert(comet.particles, particle)
        end
        
        table.insert(comets, comet)
    end
end

-- Create a new wormhole
function createWormhole()
    wormhole.active = true
    wormhole.duration = love.math.random(5, 15) -- Wormhole stays visible for 5-15 seconds
    
    local newWormhole = {
        x = love.math.random(love.graphics.getWidth() * 0.2, love.graphics.getWidth() * 0.8),
        y = love.math.random(love.graphics.getHeight() * 0.2, love.graphics.getHeight() * 0.8),
        outerRadius = love.math.random(30, 60), -- Size of the wormhole
        innerRadius = love.math.random(15, 30),
        rotation = 0,
        rotationSpeed = love.math.random(5, 15) / 10,
        particles = {},
        colors = {},
        pulseSpeed = love.math.random(1, 3),
        pulseOffset = 0
    }
    
    -- Add 3-4 random colors for the wormhole
    local colorKeys = {}
    for k in pairs(COLORS) do
        table.insert(colorKeys, k)
    end
    
    -- Shuffle color keys
    for i = #colorKeys, 2, -1 do
        local j = love.math.random(i)
        colorKeys[i], colorKeys[j] = colorKeys[j], colorKeys[i]
    end
    
    -- Take first 3-4 colors
    local colorCount = love.math.random(3, 4)
    for i = 1, colorCount do
        table.insert(newWormhole.colors, COLORS[colorKeys[i]])
    end
    
    -- Create particles around the wormhole
    local particleCount = love.math.random(20, 40)
    for i = 1, particleCount do
        local angle = love.math.random(0, 360) * math.pi / 180
        local particle = {
            distance = love.math.random(80, 140) / 100, -- Distance from center (0.8 to 1.4 times radius)
            angle = angle,
            angleSpeed = love.math.random(5, 20) / 100 * (love.math.random() < 0.5 and 1 or -1), -- Rotation speed
            size = love.math.random(2, 6),
            colorIndex = love.math.random(1, #newWormhole.colors),
            alpha = love.math.random(5, 10) / 10
        }
        table.insert(newWormhole.particles, particle)
    end
    
    wormholes = {newWormhole} -- Replace any existing wormhole
end

-- Update game state
function love.update(dt)
    -- Auto-move spaceship from left to right
    spaceship.x = spaceship.x + spaceship.autoSpeed * dt
    
    -- If spaceship goes off right edge, wrap back to origin (screensaver effect)
    if spaceship.x > love.graphics.getWidth() then
        spaceship.x = spaceship.originX
        spaceship.y = spaceship.originY
    end
    
    -- Handle keyboard input for manual spaceship movement
    handleSpaceshipMovement(dt)
    
    -- Update stars (parallax effect)
    updateStars(dt)
    
    -- Update special colored stars
    updateColoredStars(dt)
    
    -- Update asteroids
    updateAsteroids(dt)
    
    -- Update comets
    updateComets(dt)
    
    -- Update wormhole
    updateWormhole(dt)
end

-- Handle spaceship movement based on keyboard input
function handleSpaceshipMovement(dt)
    spaceship.thrustersActive = false
    -- Move left
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        spaceship.x = spaceship.x - spaceship.manualSpeed * dt
    end
    
    -- Move right
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        spaceship.x = spaceship.x + spaceship.manualSpeed * dt
        spaceship.thrustersActive = true
    end
    
    -- Move up
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        spaceship.y = spaceship.y - spaceship.manualSpeed * dt
    end
    
    -- Move down
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        spaceship.y = spaceship.y + spaceship.manualSpeed * dt
    end
    
    -- Keep spaceship within screen boundaries (vertical only)
    spaceship.y = math.max(0, math.min(spaceship.y, love.graphics.getHeight() - spaceship.height))
    updateThrusters(dt)
end

function updateThrusters(dt)
    -- Remove old particles
    for i = #spaceship.thrusterParticles, 1, -1 do
        local particle = spaceship.thrusterParticles[i]
        particle.lifetime = particle.lifetime - dt
        
        if particle.lifetime <= 0 then
            table.remove(spaceship.thrusterParticles, i)
        end
    end
    
    -- If thrusters are active, create new particles
    if spaceship.thrustersActive then
        -- Create 2-4 new particles per frame when thrusters are active
        local particlesToCreate = love.math.random(2, 4)
        
        for i = 1, particlesToCreate do
            local particle = {
                x = spaceship.x,
                y = spaceship.y + spaceship.height / 2 + love.math.random(-5, 5),
                size = love.math.random(3, 6),
                speed = love.math.random(70, 120),
                lifetime = love.math.random(3, 6) / 10, -- 0.3 to 0.6 seconds
                alpha = love.math.random(7, 10) / 10
            }
            table.insert(spaceship.thrusterParticles, particle)
        end
    end
    
    -- Update particle positions
    for i, particle in ipairs(spaceship.thrusterParticles) do
        particle.x = particle.x - particle.speed * dt
    end
end

function drawThrusterParticles()
    for _, particle in ipairs(spaceship.thrusterParticles) do
        -- Calculate alpha based on remaining lifetime
        local alpha = particle.alpha * (particle.lifetime * 3)
        
        -- Outer glow (light blue)
        love.graphics.setColor(0.3, 0.7, 1, alpha * 0.4)
        love.graphics.circle("fill", particle.x, particle.y, particle.size * 1.5)
        
        -- Inner bright core (bright blue)
        love.graphics.setColor(0.5, 0.8, 1, alpha * 0.7)
        love.graphics.circle("fill", particle.x, particle.y, particle.size)
        
        -- Center (white-blue)
        love.graphics.setColor(0.7, 0.9, 1, alpha)
        love.graphics.circle("fill", particle.x, particle.y, particle.size * 0.5)
    end
end

-- Update stars with parallax effect
function updateStars(dt)
    for layer, layerStars in ipairs(stars) do
        for i, star in ipairs(layerStars) do
            -- Move stars from right to left (opposite of spaceship)
            star.x = star.x - star.speed * dt
            
            -- Wrap stars around when they go off screen
            if star.x < -5 then
                star.x = love.graphics.getWidth() + 5
                star.y = love.math.random(0, love.graphics.getHeight())
            end
            
            -- Update star twinkling
            star.twinkleOffset = star.twinkleOffset + dt * star.twinkleSpeed
            if star.twinkleOffset > 1 then
                star.twinkleOffset = star.twinkleOffset - 1
            end
        end
    end
end

-- Update special colored stars
function updateColoredStars(dt)
    for i, star in ipairs(coloredStars) do
        -- Move colored stars from right to left (opposite of spaceship)
        star.x = star.x - star.speed * dt
        
        -- Wrap stars around when they go off screen
        if star.x < -5 then
            star.x = love.graphics.getWidth() + 5
            star.y = love.math.random(0, love.graphics.getHeight())
        end
        
        -- Update star flickering
        star.flickerOffset = star.flickerOffset + dt * star.flickerSpeed
        if star.flickerOffset > 1 then
            star.flickerOffset = star.flickerOffset - 1
        end
    end
end

-- Update asteroids
function updateAsteroids(dt)
    for i, asteroid in ipairs(asteroids) do
        -- Move asteroids from right to left (opposite of spaceship)
        asteroid.x = asteroid.x - asteroid.speed * dt
        
        -- Update asteroid rotation
        asteroid.rotation = asteroid.rotation + asteroid.rotationSpeed * dt
        
        -- Wrap asteroids around when they go off screen
        if asteroid.x < -asteroid.size * 2 then
            asteroid.x = love.graphics.getWidth() + asteroid.size * 2
            asteroid.y = love.math.random(0, love.graphics.getHeight())
        end
    end
end

-- Update comets
function updateComets(dt)
    for i, comet in ipairs(comets) do
        -- Store previous position for trail
        local prevX, prevY = comet.x, comet.y
        
        -- Move comets from right to left only horizontally
        comet.x = comet.x - comet.speed * dt
        
        -- Update trail (pong-like effect)
        table.insert(comet.trail, 1, {x = prevX, y = prevY, size = comet.size})
        if #comet.trail > comet.trailLength then
            table.remove(comet.trail)
        end
        
        -- Wrap comets around when they go off screen (much less frequent spawning)
        if comet.x < -comet.tailLength then
            -- Move comet far away and randomize properties
            comet.x = love.graphics.getWidth() + love.math.random(love.graphics.getWidth(), love.graphics.getWidth() * 3)
            comet.y = love.math.random(0, love.graphics.getHeight())
            comet.size = love.math.random(5, 30) -- Irregular size
            comet.speed = love.math.random(30, 70) -- Random speed
            comet.glowSize = comet.size * love.math.random(2, 3)
            comet.trailThickness = comet.size * 0.7
            
            -- Reset trail
            comet.trail = {}
            for j = 1, comet.trailLength do
                table.insert(comet.trail, {x = comet.x, y = comet.y, size = comet.size * (1 - (j / comet.trailLength) * 0.7)})
            end
        end
        
        -- Update particle flicker
        for j, particle in ipairs(comet.particles) do
            particle.flicker = particle.flicker * 0.95 + love.math.random(85, 115) / 100 * 0.05
        end
    end
end

-- Update wormhole
function updateWormhole(dt)
    if wormhole.active then
        -- Update active wormhole
        wormhole.duration = wormhole.duration - dt
        
        if wormhole.duration <= 0 then
            -- Wormhole disappears
            wormhole.active = false
            wormhole.timer = love.math.random(wormhole.minInterval, wormhole.maxInterval)
            wormholes = {}
        else
            -- Update existing wormhole
            for _, wh in ipairs(wormholes) do
                -- Update rotation
                wh.rotation = wh.rotation + wh.rotationSpeed * dt
                
                -- Update pulse effect
                wh.pulseOffset = wh.pulseOffset + dt * wh.pulseSpeed
                if wh.pulseOffset > 1 then
                    wh.pulseOffset = wh.pulseOffset - 1
                end
                
                -- Update particles
                for i, particle in ipairs(wh.particles) do
                    -- Rotate particles around wormhole
                    particle.angle = particle.angle + particle.angleSpeed * dt
                    
                    -- Occasionally change particle color
                    if love.math.random() < 0.01 then
                        particle.colorIndex = love.math.random(1, #wh.colors)
                    end
                end
            end
        end
    else
        -- Count down to next wormhole
        wormhole.timer = wormhole.timer - dt
        
        if wormhole.timer <= 0 then
            -- Create a new wormhole
            createWormhole()
        end
    end
end

-- Draw everything to the screen
function love.draw()
    -- Draw background (dark space)
    love.graphics.setColor(0.02, 0.02, 0.05)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw regular stars with twinkling effect
    for layer, layerStars in ipairs(stars) do
        for i, star in ipairs(layerStars) do
            -- Calculate twinkling brightness using sine wave
            local twinkle = math.sin(star.twinkleOffset * math.pi * 2) * 0.2 + 0.8
            local brightness = star.brightness * twinkle
            
            love.graphics.setColor(brightness, brightness, brightness)
            love.graphics.rectangle("fill", star.x, star.y, star.size, star.size)
        end
    end
    
    -- Draw special colored stars with flickering
    for i, star in ipairs(coloredStars) do
        -- Calculate flickering effect
        local flicker = math.sin(star.flickerOffset * math.pi * 2) * 0.4 + 0.6
        
        -- Calculate size pulsing
        local sizeMultiplier = 1 + math.sin(star.flickerOffset * math.pi * 4) * star.pulseSize
        
        -- Draw colored star with glow effect
        love.graphics.setColor(star.color[1], star.color[2], star.color[3], 0.3 * flicker)
        love.graphics.circle("fill", star.x, star.y, star.size * 2 * sizeMultiplier)
        
        love.graphics.setColor(star.color[1], star.color[2], star.color[3], 0.7 * flicker)
        love.graphics.circle("fill", star.x, star.y, star.size * sizeMultiplier)
        
        -- Bright center
        love.graphics.setColor(1, 1, 1, flicker)
        love.graphics.circle("fill", star.x, star.y, star.size * 0.5 * sizeMultiplier)
    end
    
    -- Draw wormhole if active
    if wormhole.active and #wormholes > 0 then
        for _, wh in ipairs(wormholes) do
            -- Draw outer glow
            for i = 1, #wh.colors do
                local color = wh.colors[i]
                local angle = wh.rotation + (i - 1) * (2 * math.pi / #wh.colors)
                
                -- Pulse effect
                local pulse = math.sin(wh.pulseOffset * math.pi * 2) * 0.2 + 0.8
                
                love.graphics.setColor(color[1], color[2], color[3], 0.3 * pulse)
                love.graphics.circle("fill", wh.x, wh.y, wh.outerRadius * 1.5)
            end
            
            -- Draw rotating color segments
            for i = 1, 12 do
                local angle = wh.rotation + (i - 1) * (math.pi / 6)
                local nextAngle = angle + math.pi / 6
                
                -- Use a color from the wormhole's color palette
                local color = wh.colors[(i % #wh.colors) + 1]
                
                love.graphics.setColor(color[1], color[2], color[3], 0.7)
                
                -- Draw segment of the ring
                love.graphics.arc("fill", wh.x, wh.y, wh.outerRadius, angle, nextAngle)
            end
            
            -- Draw inner black hole
            love.graphics.setColor(0, 0, 0)
            love.graphics.circle("fill", wh.x, wh.y, wh.innerRadius)
            
            -- Draw particles orbiting the wormhole
            for i, particle in ipairs(wh.particles) do
                local color = wh.colors[particle.colorIndex]
                love.graphics.setColor(color[1], color[2], color[3], particle.alpha)
                
                local px = wh.x + math.cos(particle.angle) * (wh.outerRadius * particle.distance)
                local py = wh.y + math.sin(particle.angle) * (wh.outerRadius * particle.distance)
                
                love.graphics.circle("fill", px, py, particle.size)
            end
        end
    end
    
    -- Draw comets
    for i, comet in ipairs(comets) do
        -- Draw pong-like trail first (behind everything else)
        for j, pos in ipairs(comet.trail) do
            -- Calculate alpha based on position in trail
            local alpha = 0.8 * (1 - (j / #comet.trail))
            
            -- Use comet color with diminishing alpha
            love.graphics.setColor(comet.color[1], comet.color[2], comet.color[3], alpha)
            
            -- Draw trail segment with diminishing size
            love.graphics.circle("fill", pos.x, pos.y, pos.size)
        end
        
        -- Draw comet tail (long particle trail)
        for j, particle in ipairs(comet.particles) do
            -- Apply flicker effect to trail
            local particleAlpha = particle.alpha * (1 - particle.distance) * particle.flicker
            
            -- Use comet color
            love.graphics.setColor(comet.color[1], comet.color[2], comet.color[3], particleAlpha)
            
            -- Calculate position along tail (horizontal only)
            local tailX = comet.x + comet.tailLength * particle.distance
            local tailY = comet.y + particle.offset -- Offset is the same throughout
            
            -- Draw particle with size diminishing along the tail
            love.graphics.circle("fill", tailX, tailY, particle.size * (1 - particle.distance * 0.7))
        end
        
        -- Draw comet head glow
        love.graphics.setColor(comet.color[1], comet.color[2], comet.color[3], 0.3)
        love.graphics.circle("fill", comet.x, comet.y, comet.glowSize)
        
        -- Draw brighter inner glow
        love.graphics.setColor(comet.color[1], comet.color[2], comet.color[3], 0.7)
        love.graphics.circle("fill", comet.x, comet.y, comet.size * 1.5)
        
        -- Draw comet head (bright white center)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.circle("fill", comet.x, comet.y, comet.size)
    end
    
    -- Draw asteroids
    for i, asteroid in ipairs(asteroids) do
        love.graphics.push()
        love.graphics.translate(asteroid.x, asteroid.y)
        love.graphics.rotate(asteroid.rotation)
        
        -- Draw asteroid body
        love.graphics.setColor(0.6, 0.6, 0.6, 1.0)
        
        -- Draw irregular polygon shape
        if #asteroid.vertices > 0 then
            local vertices = {}
            for j, vertex in ipairs(asteroid.vertices) do
                table.insert(vertices, vertex.x)
                table.insert(vertices, vertex.y)
            end
            love.graphics.polygon("fill", vertices)
            
            -- Draw highlight
            love.graphics.setColor(0.8, 0.8, 0.8, 1.0)
            love.graphics.circle("fill", -asteroid.size * 0.2, -asteroid.size * 0.2, asteroid.size * 0.2)
        end
        
        love.graphics.pop()
    end
    
    -- Draw spaceship
    drawThrusterParticles()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(spaceship.image, spaceship.x, spaceship.y, 0, spaceship.scale, spaceship.scale)
    
    -- Draw UI
    drawUI()
end

-- Draw UI information
function drawUI()
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.print("Controls: Arrow Keys or WASD to move", 20, 20)
    love.graphics.print("Spaceship will automatically drift across the screen", 20, 40)
    love.graphics.print("ESC: Quit", 20, 60)
end

-- Handle key presses
function love.keypressed(key)
    -- Quit game if Escape is pressed
    if key == "escape" then
        love.event.quit()
    end
end