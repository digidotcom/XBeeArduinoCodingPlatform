class PowerUp { //Class for the power ups

  //Initialization of the power up's variables
  PVector powerUpLocation; //The location of the power ups

  /* PowerUp Type Values
   0 = x3 Balls Power-Up 
   1 = Extended Paddle Power Up*/
  int powerUpType; //The type of the power up

  PowerUp(float powerUpSpawnLocationX, float powerUpSpawnLocationY) { //Creates a power-up with the inputed proportions
    this.powerUpLocation = new PVector(powerUpSpawnLocationX, powerUpSpawnLocationY); //Sets the location to the inputed co-ordinates
    this.powerUpType = int(random(TYPES_OF_POWER_UPS)); //Sets the power up type to the inputed power up type
  }

  void renderPowerUp(int powerUpNumber) { //Renders the power up
    //Movement of the power up
    this.powerUpLocation.y += POWER_UP_SPEED; //Lowers the power up

    //Collision with the bottom wall
    if (this.powerUpLocation.y - POWER_UP_SIZE > SCREEN_SIZE) numPowerUps.remove(powerUpNumber); //If the powerup passes the bottom of the screen, remove it

    //Collision with the paddle
    if (this.powerUpLocation.x + POWER_UP_SIZE/2 > playerPaddle.paddleLocation.x //If the powerup is right of the left side of the paddle
    && this.powerUpLocation.x - POWER_UP_SIZE/2 < playerPaddle.paddleLocation.x + paddleSize.x //If the powerup is on the left of the right side of the paddle
    && this.powerUpLocation.y + POWER_UP_SIZE/2 > playerPaddle.paddleLocation.y //If the powerup is past the top of the paddle
    && this.powerUpLocation.y + POWER_UP_SIZE/2 < playerPaddle.paddleLocation.y + paddleSize.y) { //If the powerup is above the bottom of the paddle
    
      switch(this.powerUpType) { //Checks the power up type
      case 0: //If it is a x3 power up
        currentAmountOfBalls = numBalls.size(); //Sets the current amount of balls to the size of the arraylist as to not run out of memory in a constant loop due to newly spawned balls
        for (int i = 0; i < currentAmountOfBalls; i++) { //For every ball that is on the game...
          numBalls.add(new Ball(numBalls.get(i).ballLocation.x, numBalls.get(i).ballLocation.y, numBalls.get(i).ballSpeed.x, -numBalls.get(i).ballSpeed.y)); //Creates a ball going diagonally top-right relative to the ball's direction
          numBalls.add(new Ball(numBalls.get(i).ballLocation.x, numBalls.get(i).ballLocation.y, -numBalls.get(i).ballSpeed.x, numBalls.get(i).ballSpeed.y)); //Creates a ball going diagonally bottom-left relative to the ball's direction
          numBalls.add(new Ball(numBalls.get(i).ballLocation.x, numBalls.get(i).ballLocation.y, -numBalls.get(i).ballSpeed.x, -numBalls.get(i).ballSpeed.y)); //Creates a ball going diagonally top-left relative to the ball's direction
        }
        break;
      case 1: //If it is an extended paddle power up
        extendedPaddleTimer = PADDLE_EXTEND_TIME; //Sets sticky time to maximum sticky time
        break;
      }
      numPowerUps.remove(powerUpNumber); //Remove the power up
    }

    //Drawing of the power up
    fill(colorChangeAnimationColor); //Colors the color animation color
    ellipse(this.powerUpLocation.x, this.powerUpLocation.y, POWER_UP_SIZE, POWER_UP_SIZE); //Draws the power up

    fill(0);
    textFont(HUDfont, SCREEN_SIZE/50); //Sets the text font
    switch(this.powerUpType) { //Checks the type of the power up
    case 0: //If it is a x3 Power Up
      text("3", this.powerUpLocation.x - SCREEN_SIZE/800, this.powerUpLocation.y + SCREEN_SIZE*3/400); //Writes the number 3 on the power up for recognition from the user
      break;
    case 1: //If it is an extended paddle power up
      text("E", this.powerUpLocation.x - SCREEN_SIZE/800, this.powerUpLocation.y + SCREEN_SIZE*3/400); //Writes the letter E on the power up for recognition from the user
      break;
    }
  }
}

