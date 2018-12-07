-- push is a library that will allow us to draw our game at a virtual
-- resolution, instead of however large our window is; used to provide
-- a more retro aesthetic
--
-- https://github.com/Ulydev/push
push = require 'push'

-- the "Class" library we're using will allow us to represent anything in
-- our game as code, rather than keeping track of many disparate variables and
-- methods
--
-- https://github.com/vrld/hump/blob/master/class.lua
Class = require 'class'

require 'Paddle'
require 'Ball'

WINDOW_WIDTH = 640
WINDOW_HEIGHT = 480

VIRTUAL_WIDTH = 400
VIRTUAL_HEIGHT = 300

PADDLE_SPEED = 200

--[[
    Runs when the game first starts up, only once; used to initialize the game.
]]
function love.load()

  love.window.setTitle("Pranav's Pong")

  -- use nearest-neighbor filtering on upscaling and downscaling to prevent blurring of text
  -- and graphics; try removing this function to see the difference!
  love.graphics.setDefaultFilter('nearest', 'nearest')

  -- "seed" the RNG so that calls to random are always random
  -- use the current time, since that will vary on startup every time
  math.randomseed(os.time())

  smallFont = love.graphics.newFont('font.ttf', 8)
  largeFont = love.graphics.newFont('font.ttf', 16)
  scoreFont = love.graphics.newFont('font.ttf', 32)

  love.graphics.setFont(smallFont)

  -- initialize our virtual resolution, which will be rendered within our
  -- actual window no matter its dimensions; replaces our love.window.setMode call
  -- from the last example
  push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
    fullscreen = false,
    resizable = true,
    vsync = true
  })

  sounds = {
    ["paddle_hit"] = love.audio.newSource("sounds/paddle_hit.wav", "static"),
    ["score"] = love.audio.newSource("sounds/score.wav", "static"),
    ["wall_hit"] = love.audio.newSource("sounds/wall_hit.wav", "static")
  }

  player1Score = 0
  player2Score = 0

  leftPaddle = Paddle(10, 30, 5, 20)
  rightPaddle = Paddle(VIRTUAL_WIDTH - 15, VIRTUAL_HEIGHT - 30, 5, 20)

  ball = Ball(VIRTUAL_WIDTH/2 - 2, VIRTUAL_HEIGHT/2 - 2, 4, 4)

  servingPlayer = 1

  -- game state variable used to transition between different parts of the game
  -- (used for beginning, menus, main game, high score list, etc.)
  -- we will use this to determine behavior during render and update
  gameState = 'start'
end

--[[
    Keyboard handling, called by LÖVE2D each frame;
    passes in the key we pressed so we can access.
]]
function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  elseif key == 'enter' or key == 'return' then
    if gameState == 'start' then
      gameState = 'serve'
    elseif gameState == 'serve' then
      gameState = 'play'
    elseif gameState == 'finish' then
      gameState = 'serve'

      ball:reset()

      player1Score = 0
      player2Score = 0

      if winningPlayer == 1 then
        servingPlayer = 2
      else
        servingPlayer = 1
      end

    end
  end
end

--[[
    Runs every frame, with "dt" passed in, our delta in seconds
    since the last frame, which LÖVE2D supplies us.
]]
function love.update(dt)

  if gameState == 'serve' then
    ball.dy = math.random(-50, 50)

    if servingPlayer == 1 then
      ball.dx = math.random(100, 200)
    else
      ball.dx = -math.random(100,200)
    end

  elseif gameState == 'play' then

    if ball:isCollision(leftPaddle) == true then
      ball.dx = -ball.dx * 1.03
      ball.x = leftPaddle.x + 5

      if ball.dy < 0 then
        ball.dy = -math.random(10, 150)
      else
        ball.dy = math.random(10, 150)
      end

      sounds["paddle_hit"]:play()
    end

    if ball:isCollision(rightPaddle) == true then
      ball.dx = -ball.dx * 1.03
      ball.x = rightPaddle.x - 4

      if ball.dy < 0 then
        ball.dy = -math.random(10, 150)
      else
        ball.dy = math.random(10, 150)
      end

      sounds["paddle_hit"]:play()
    end

    -- top window border collision
    if ball.y <= 0 then
      ball.y = 0
      ball.dy = -ball.dy
      sounds["wall_hit"]:play()
    end

    if ball.y + ball.height >= VIRTUAL_HEIGHT then
      ball.y = VIRTUAL_HEIGHT - ball.height
      ball.dy = -ball.dy
      sounds["wall_hit"]:play()
    end

    -- ball touches left window border
    if ball.x < 0 then
      servingPlayer = 2
      player2Score = player2Score + 1
      sounds["score"]:play()

      if player2Score == 3 then
        winningPlayer = 2
        gameState = 'finish'
      else
        ball:reset()
        gameState = 'serve'
      end

    end

    -- ball touches right window border
    if ball.x > VIRTUAL_WIDTH then
      servingPlayer = 1
      player1Score = player1Score + 1
      sounds["score"]:play()

      if player1Score == 3 then
        winningPlayer = 1
        gameState = 'finish'
      else
        ball:reset()
        gameState = 'serve'
      end

    end
  end

  -- player 1
  if love.keyboard.isDown('w') then
    leftPaddle.dy = -PADDLE_SPEED
  elseif love.keyboard.isDown('s') then
    leftPaddle.dy = PADDLE_SPEED
  else
    leftPaddle.dy = 0
  end

  -- player 2
  -- if love.keyboard.isDown('up') then
  --   rightPaddle.dy = -PADDLE_SPEED
  -- elseif love.keyboard.isDown('down') then
  --   rightPaddle.dy = PADDLE_SPEED
  -- else
  --   rightPaddle.dy = 0
  -- end



  if gameState == 'play' then

    ball:update(dt)

    -- AI controlled right paddle (player 2)
    rightPaddle.y = ball.y
  end

  leftPaddle:update(dt)

end

--[[
    Called after update by LÖVE2D, used to draw anything to the screen, updated or otherwise.
]]
function love.draw()

  -- begin rendering at virtual resolution
  push:apply('start')

  -- clear the screen with a specific color; in this case, a color similar
  -- to some versions of the original Pong
  love.graphics.clear(40/255, 45/255, 52/255, 255)

  displayScore()

  if gameState == 'start' then
    love.graphics.setFont(smallFont)
    love.graphics.printf('Welcome to PoNg!', 0, 10, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('Press enter to serve !', 0, 20, VIRTUAL_WIDTH, 'center')
  elseif gameState == 'serve' then
    love.graphics.setFont(smallFont)
    love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s turn to serve", 0, 10, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('Press enter to play !', 0, 20, VIRTUAL_WIDTH, 'center')
  elseif gameState == 'finish' then
    love.graphics.setFont(largeFont)
    love.graphics.printf('Player ' .. tostring(winningPlayer) .. " has won !", 0, 10, VIRTUAL_WIDTH, 'center')
    love.graphics.setFont(smallFont)
    love.graphics.printf("Press enter to play again !", 0, 30, VIRTUAL_WIDTH, 'center')
  end

  -- draw left and right paddles
  leftPaddle:render()
  rightPaddle:render()

  -- draw the ball in the middle
  ball:render()

  displayFPS()

  push:apply('end')
end

function love.resize(w, h)
  push:resize(w, h)
end

function displayFPS()
  love.graphics.setFont(smallFont)
  love.graphics.setColor(0, 1, 0, 255)
  love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end

function displayScore()
  love.graphics.setFont(scoreFont)
  love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH/2 - 50, VIRTUAL_HEIGHT/3)
  love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH/2 + 30, VIRTUAL_HEIGHT/3)
end
