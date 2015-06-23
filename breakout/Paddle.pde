class Paddle { //Class for the paddle

    //Initialization of the paddle's variables
  public PVector paddleLocation; //Location of the paddle

  Paddle() { //Creates a new paddle
    this.paddleLocation = new PVector(SCREEN_SIZE/2, SCREEN_SIZE - paddleSize.y * 2); //Moves the paddle to the middle of the x-axis, and to just above the bottom of the screen
  }

  void renderPaddle() { //Method for rendering the paddle
    //Movement of the paddle
    //if (!pauseState) //If the game is not paused
      //this.paddleLocation.x = mouseX - paddleSize.x / 2; //Moves the paddle to the mouse

    //Extended properties of the paddle
    if (extendedPaddleTimer > 0) //If the timer states that the paddle should be extended
      paddleSize.x = EXTENDED_PADDLE_WIDTH; //Extend the paddle
    else
      paddleSize.x = CONTRACTED_PADDLE_WIDTH; //Contract the paddle
    if (!pauseState) extendedPaddleTimer--; //Decreases the time for extending the paddle if the game is not paused

    //Drawing of the paddle
    fill(255); //Colors white
    rect(this.paddleLocation.x, this.paddleLocation.y, paddleSize.x, paddleSize.y); //Draws the paddle
  }
}

