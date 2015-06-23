/*/---------------
 Rainbow Breaker
 Made by Simon Hajjar
 From 06.03.12

 This is a simple program that remakes the famed brick-breaker, which
 slight variations on the color scheme. The paddle is controlled by
 the mouse, and when clicked, the ball is released, and the game
 begins. Furthermore, there are also two added power-ups - the x3
 Power Up which multiplies the amount of balls by three, and the
 Extended Paddle Power Up, which extends the paddle for a period,
 of time.

 Original source code: http://www.openprocessing.org/sketch/50736
 Modified for use in Digi's XBee/Arduino Compatible Coding Platform. This game
 uses Digi's XBee Game Controller library to handle user input by replacing the
 control handling through setting the variables and calling the methods 
 originally done through mouse and keyboard input. See the buttonEvent method 
 below, and the beginning of the draw method, for more details.
 ---------------/*/

// Processing XBee Java Library must be installed
import com.digi.xbee.api.*;
// Digi XBee Game Controller library
import xbeegamecontroller.*;

// Change as necessary. Specifies how to address the XBee.
final String XBEE_PORT = "COM5";
final int XBEE_BAUD = 9600;

Controller controller;

final int PADDLE_SPEED_FACTOR = 25; // Paddle will move this many pixels per frame when joystick is all the way left or right.

final int SCREEN_SIZE = 700; //Sets the variables for the width and height

// Because the joystick included in the kit does not always spring back to
// perfectly centered (~512), we effectively reduce the joystick sensitivity by
// ignoring any values less than this far off of center. This means that, to
// see the joystick as being pushed 'left', for example, the X value needs to be
// less than or equal to 487 (512 - 25).
final int JOYSTICK_THRESHOLD = 25;
final float JOYSTICK_THRESHOLD_PERCENT = JOYSTICK_THRESHOLD / 512.0;

//Variales pertaining to the paddle
Paddle playerPaddle; //Creates the player's paddle
PVector paddleSize = new PVector(SCREEN_SIZE/7, SCREEN_SIZE/30); //The size of the paddle
final float CONTRACTED_PADDLE_WIDTH = SCREEN_SIZE/7; //Contracted width of the paddle
final float EXTENDED_PADDLE_WIDTH = SCREEN_SIZE/4; //Extended width of the paddle
int extendedPaddleTimer = 0, PADDLE_EXTEND_TIME = 1000; //The timer for the extended paddle, as well as the maximum time that it will remain extended

//Variables pertaining to balls
ArrayList <Ball> numBalls; //Sets arraylist for the balls
final int BALL_SIZE = SCREEN_SIZE/55; //The size of the balls
final int DEFAULT_BALL_SPEED = SCREEN_SIZE/100; //The default ball speed
final int HORIZANTAL_SPEED_SENSITIVITY = 8; //The sensitivity of the change of rate of speed for balls when hitting the paddle
final int MINIMUM_TIME_BEFORE_NEXT_HIT = 1; //The minimum time before the next ball can be hit - this is to stop a glitch that allows the ball to hit two bricks at once
boolean stickBallToPaddle = true; //If this is true, then the ball will stick to the paddle

//Variables pertaining to the bricks
ArrayList <Brick> numBricks; //Sets the arraylist for the bricks
PVector BRICK_SIZE = new PVector(SCREEN_SIZE*9/100, SCREEN_SIZE*3/100); //Size of the bricks
PVector brickColorScheme; //The color scheme of the bricks of the level - changes with each new spawn
final int COLOR_SCHEME_RANGE = 20; //The range of colors in the same color scheme - the larger it is, the more colorful
final int MINIMUM_COLOR_SCHEME_BRIGHTNESS = 30; //The minimum brightness of the color schemes

//Variables pertaining to the HUD and basic functioning of the game
PFont HUDfont; //The font for the HUD
int ballsLeft = 3; //The number of balls left - is equal to how many lives the player starts with
int currentLevel = 1; //The current level - is equal to what level the user starts with
int AVAILIBLE_LEVELS = 4; //The number of levels in the game - used to give the 'You Win!' message
boolean displayedIntroduction = false; //If the introductory message has been shown to the user yet or not
boolean displayWinningMessage = false; //If the winning message should be displayed
boolean pauseState = false; //If the game is paused or not
boolean gameOverState = false; //If the game has been lost or not
final int COLOR_CHANGE_FREQUENCY = 30; //The frequency of the color change for the color changing animations
int colorChangeTimer = COLOR_CHANGE_FREQUENCY; //The timer that determines when the color changing animation should change colors
color colorChangeAnimationColor; //The current color of the color change animation

//Variables pertaining to the powerups
ArrayList <PowerUp> numPowerUps = new ArrayList(); //Sets an arraylist for the powerups
final int CHANCE_OF_POWER_UP = 8; //The reciprical of the chance of a powerup dropping when a block is destroyed -e.g., 1 is a 100% chance, where as 2 is a 50% chance
final int TYPES_OF_POWER_UPS = 2; //The different types of powerups
final int POWER_UP_SIZE = SCREEN_SIZE/30; //The radius of all the power ups
final int POWER_UP_SPEED = SCREEN_SIZE/300; //The speed of the power up
int currentAmountOfBalls; //The current amount of balls on the screen - used to check for each ball on the game whilst disregarding the newly spawned ones, as to save memory

void setup() { //Runs once upon execution of the program
  size(SCREEN_SIZE, SCREEN_SIZE, JAVA2D); //Creates a screen
  HUDfont = loadFont("MicrosoftYaHei-48.vlw"); //Loads the font file from the data folde

  playerPaddle = new Paddle(); //Sets the player's paddle
  numBalls = new ArrayList(); //Sets the numBalls arraylist
  numBricks = new ArrayList(); //Sets the numBricks arraylist

  spawnLevel(currentLevel); //Spawns the first level
  numBalls.add(new Ball(playerPaddle.paddleLocation.x + paddleSize.x/2, playerPaddle.paddleLocation.y - BALL_SIZE/2, 0, DEFAULT_BALL_SPEED)); //Spawns the first ball

  // Connect to the XBee, treat it as an interface to the controller.
  try {
    controller = new Controller(this, XBEE_PORT, XBEE_BAUD);
  } catch (Exception e) {
    /* This would be unexpected. This will usually occur if the serial port
     * does not exist, or was already open.
     */
    System.err.println("Failed to initialize XBee");
    e.printStackTrace();
    System.exit(1);
  }
}

void draw() { //Runs in a loop after the setup method
  background(0); //Sets a black background

  // Record the current paddle position.
  float paddleX = playerPaddle.paddleLocation.x;
  // Get the current joystick X position, convert it to a value from -1 to 1.
  float x = (controller.getX() - 512) / 512.0;
  
  // Ignore any value from when the joystick is very close to center.
  if (Math.abs(x) <= JOYSTICK_THRESHOLD_PERCENT) {
    x = 0;
  } else {
    // Adjust the percentage so that, once the joystick is outside of the
    // central "dead zone" (where the value is ignored), the paddle speed
    // starts from 0.
    if (x < 0) {
      // Negative x values will start at -JOYSTICK_THRESHOLD_PERCENT, so add
      // that amount to x to make the values start at 0.
      x = x + JOYSTICK_THRESHOLD_PERCENT;
    } else {
      // Positive x values will start at JOYSTICK_THRESHOLD_PERCENT, so
      // subtract that amount to x to make the values start at 0.
      x = x - JOYSTICK_THRESHOLD_PERCENT;
    }
  }

  // The 'speed factor' (maximum speed of the paddle when the joystick is all
  // the way left or right) needs to be scaled up, because we added or
  // subtracted the 'threshold percent' above. Without this scaling, the true
  // max speed will only be (100 - JOYSTICK_THRESHOLD)% of PADDLE_SPEED_FACTOR.
  float scaledSpeedFactor = PADDLE_SPEED_FACTOR / (1 - JOYSTICK_THRESHOLD_PERCENT);

  // Move the paddle by x * scaledSpeedFactor pixels.
  paddleX += x * scaledSpeedFactor;
  
  // If the paddle will end up off the left or right edges of the screen, move it back
  // to within screen bounds.
  if (paddleX < 0)
    paddleX = 0;
  if (paddleX > SCREEN_SIZE - paddleSize.x)
    paddleX = SCREEN_SIZE - paddleSize.x;
  
  // Set the new paddle position.
  playerPaddle.paddleLocation.x = paddleX;

  //Rendering of objects
  for (int i = 0; i < numBalls.size(); i++) numBalls.get(i).renderBall(i); //Renders all balls
  for (int i = 0; i < numBricks.size(); i++) numBricks.get(i).renderBrick(); //Renders all bricks
  for (int i = 0; i < numPowerUps.size(); i++) numPowerUps.get(i).renderPowerUp(i); //Renders all power ups
  playerPaddle.renderPaddle(); //Renders the player's paddle
  renderHUD(); //Renders the player's HUD

    //Checks and acts on the amount of balls
  if (numBalls.size() == 0) { //If there are no balls left
    if (!displayWinningMessage) ballsLeft--; //Decrease the amount of balls left by one if the user has not already won
    stickBallToPaddle = true; //Stick the next spawned ball to the paddle
    numPowerUps.clear(); //Removes all power-ups in motion
    extendedPaddleTimer = 0; //Contracts the paddle
    numBalls.add(new Ball(playerPaddle.paddleLocation.x + paddleSize.x/2, playerPaddle.paddleLocation.y - BALL_SIZE/2, 0, DEFAULT_BALL_SPEED)); //Adds a ball
  }
  if (ballsLeft <= 0) gameOverState = true; //If there are no lives left, show the game over screen

  //Checks and acts on the amount of bricks
  if (numBricks.size() == 0 && currentLevel <= AVAILIBLE_LEVELS) { //If there are no bricks left and the user has not completed all levels
    numPowerUps.clear(); //Removes all power-ups in motion
    numBalls.clear(); //Removes all balls
    extendedPaddleTimer = 0; //Contracts the paddle
    numBalls.add(new Ball(playerPaddle.paddleLocation.x + paddleSize.x/2, playerPaddle.paddleLocation.y - BALL_SIZE/2, 0, DEFAULT_BALL_SPEED)); //Adds a ball
    stickBallToPaddle = true; //Sticks the ball back to the paddle
    currentLevel++; //Increment current level by one
    spawnLevel(currentLevel); //Spawns the next level
  }
}

void mousePressed() { //If the mouse is pressed
  stickBallToPaddle = false; //Un-stick the ball from the paddle
  displayedIntroduction = true; //Remove the introduction message
}

void keyReleased() { //If a key is released
  if (key == 'Q' || key == 'q') exit(); //If the player presses 'q', quit the game
  if (key == 'P' || key == 'p') pauseState = !pauseState; //If the player presses 'p', toggle the pause
}

void renderHUD() { //Renders the player's HUD

    noCursor(); //Removes the user's cursor
  fill(colorChangeAnimationColor); //Colors white
  textAlign(LEFT); //Aligns the text to the left of co-ordinates
  textFont(HUDfont, SCREEN_SIZE*4/125); //Sets the text font
  text("Balls Left: ", SCREEN_SIZE/100, SCREEN_SIZE/25); //Writes the text "Balls Left"
  text("Current Level: " + currentLevel, SCREEN_SIZE/100, SCREEN_SIZE*7/80); //Writes out the current level
  for (int ballsToDraw = 0; ballsToDraw < ballsLeft; ballsToDraw++) ellipse(SCREEN_SIZE*2/11 + ballsToDraw * BALL_SIZE*3/2, SCREEN_SIZE/32, BALL_SIZE, BALL_SIZE); //Draws a ball for each life left

  textAlign(CENTER); //Aligns the text to the, center of co-ordinates
  textFont(HUDfont, SCREEN_SIZE/50); //Sets the text font
  if (!displayedIntroduction) text("Welcome to Rainbow Breaker!" + "\nTo let go of the ball, click the mouse or the left button." + "\nTo control the paddle, move the joystick." + "\nTo pause the game, press 'P'." + "\nTo quit the game, press 'Q'.", SCREEN_SIZE/2, SCREEN_SIZE*6/10); //Displays the introduction message
  if (displayWinningMessage) text("Congratulations!" + "\nYou won Rainbow Breaker!" + "\nPress 'Q' to quit the game.", SCREEN_SIZE/2, SCREEN_SIZE/2); //If the user has won, display the winning text

  if (pauseState) { //If the game is paused
    cursor(ARROW); //Sets the user's cursor to an arrow
    fill(0, 0, 0, 220); //Fills with a transparent black
    rect(0, 0, SCREEN_SIZE, SCREEN_SIZE); //Darkens the whole screen
    fill(255); //Colors white
    textFont(HUDfont, SCREEN_SIZE*4/125); //Sets the text font
    text("Game Paused", SCREEN_SIZE/2, SCREEN_SIZE/2); //Writes a pause message to the user
    textFont(HUDfont, SCREEN_SIZE/50); //Sets the text font
    text("Press 'P' or the left button to resume the game.", SCREEN_SIZE/2, SCREEN_SIZE*11/21); //Writes instructions regarding the pause to the user
  }
  else { //If the game is not paused

    //The color-changing animation
    if (colorChangeTimer >= COLOR_CHANGE_FREQUENCY) { //If it is time for the color change to occur
      colorChangeTimer = 0; //Resets the color change timer
      colorChangeAnimationColor = color(random(255), random(255), random(255)); //Randomizes the color of the imation
    }
    colorChangeTimer++; //Increments the color change timer
  }

  if (gameOverState) { //If the game has been lost
    background(0); //Colors the screen black, overlaying all the renderings
    fill(colorChangeAnimationColor); //Fills with the color change animation color
    textFont(HUDfont, SCREEN_SIZE*4/125); //Sets the text font
    text("Game Over", SCREEN_SIZE/2, SCREEN_SIZE/2); //Writes a game over message to the user
    textFont(HUDfont, SCREEN_SIZE/50); //Sets the text font
    text("Press 'Q' to exit the game.", SCREEN_SIZE/2, SCREEN_SIZE*11/21); //Writes instructions regarding the quit to the user
  }
}

void spawnLevel(int levelToSpawn) { //Spawns the level that should be spawned
  do {
    brickColorScheme = new PVector(random(255), random(255), random(255)); //Randomizes the color of the brick scheme
  }
  while (brickColorScheme.x + brickColorScheme.y + brickColorScheme.z < MINIMUM_COLOR_SCHEME_BRIGHTNESS); //If the color is less then the neccessary brightness, re-do the randomization

  switch(levelToSpawn) { //Checks the current level that was already incremented  before this was called
  case 1: //If must spawn level one
    for (float spawnYofBrick = SCREEN_SIZE*10/45; spawnYofBrick < SCREEN_SIZE - BRICK_SIZE.y*20; spawnYofBrick += BRICK_SIZE.y) //Arranges each row one block apart
      for (float spawnXofBrick = BRICK_SIZE.x; spawnXofBrick < SCREEN_SIZE - BRICK_SIZE.x*2; spawnXofBrick += BRICK_SIZE.x) //Aranges each column one block apart
        numBricks.add(new Brick(spawnXofBrick, spawnYofBrick, brickColorScheme)); //Spawns each brick
    break;
  case 2: //If must spawn level two
    for (float spawnYofBrick = SCREEN_SIZE*8/45; spawnYofBrick < SCREEN_SIZE - BRICK_SIZE.y*15; spawnYofBrick += BRICK_SIZE.y) //Arranges each row one block apart
      for (float spawnXofBrick = BRICK_SIZE.x; spawnXofBrick < SCREEN_SIZE - BRICK_SIZE.x*2; spawnXofBrick += BRICK_SIZE.x*2)
        numBricks.add(new Brick(spawnXofBrick, spawnYofBrick, brickColorScheme)); //Spawns each brick
    break;
  case 3: //If must spawn level three
    for (float spawnYofBrick = SCREEN_SIZE*14/45; spawnYofBrick < SCREEN_SIZE - BRICK_SIZE.y*15; spawnYofBrick += BRICK_SIZE.y) //Arranges each row one block apart
      for (float spawnXofBrick = BRICK_SIZE.x; spawnXofBrick < SCREEN_SIZE - BRICK_SIZE.x*2; spawnXofBrick += BRICK_SIZE.x) //Aranges each column one block apart
        if (spawnXofBrick < SCREEN_SIZE*3/8 || spawnXofBrick > SCREEN_SIZE/2) numBricks.add(new Brick(spawnXofBrick, spawnYofBrick, brickColorScheme)); //Spawns each brick, except in the middle column
    break;
  case 4: //If must spawn level four
    for (float spawnYofBrick = SCREEN_SIZE*2/9; spawnYofBrick < SCREEN_SIZE - BRICK_SIZE.y*17; spawnYofBrick += BRICK_SIZE.y) //Arranges each row one block apart
      for (float spawnXofBrick = BRICK_SIZE.x; spawnXofBrick < SCREEN_SIZE - BRICK_SIZE.x*2; spawnXofBrick += BRICK_SIZE.x) //Aranges each column one block apart
        if(spawnXofBrick == BRICK_SIZE.x || spawnXofBrick >= SCREEN_SIZE - BRICK_SIZE.x*3 //If it is in one of the two columns
        || spawnYofBrick == SCREEN_SIZE*2/9 || spawnYofBrick >= SCREEN_SIZE - BRICK_SIZE.y*18) //If it is in on of the two rows
        numBricks.add(new Brick(spawnXofBrick, spawnYofBrick, brickColorScheme)); //Spawns bricks in a box shape
    break;
  case 5: //If must spawn level five (which is non-existent)
    displayWinningMessage = true; //Display the winning message, as there are no more levels
    break;
  }
}

// buttonEvent is automatically called by the XBee Game Controller library when
// button states change.
void buttonEvent(boolean leftButtonPushed, boolean rightButtonPushed) {
  if (leftButtonPushed) {
    // If the left button on the controller is pressed, perform the same
    // actions as when the mouse is clicked.
    mousePressed();

    // Also unpause the game if it is currently paused.
    if (pauseState) {
      pauseState = false;
    }
  }
}
