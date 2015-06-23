class Brick { //Class for the bricks

  //Initialization of the bricks's variables
  PVector brickLocation; //Location of the brick
  color brickColor; //The color of the brick

  Brick(float brickSpawnLocationX, float brickSpawnLocationY, PVector currentBrickColorScheme) { //Takes neccessary inputs and creates a brick with those properties
    this.brickLocation = new PVector(brickSpawnLocationX, brickSpawnLocationY); //Sets the brick to the location of the inputed variables
    this.brickColor = color(random(currentBrickColorScheme.x - COLOR_SCHEME_RANGE, currentBrickColorScheme.x + COLOR_SCHEME_RANGE),
    random(currentBrickColorScheme.y - COLOR_SCHEME_RANGE, currentBrickColorScheme.y + COLOR_SCHEME_RANGE),
    random(currentBrickColorScheme.z - COLOR_SCHEME_RANGE, currentBrickColorScheme.z + COLOR_SCHEME_RANGE)); //Gives the brick a random color based on the current color scheme
}

  void renderBrick() { //Renders the brick
    
    //Drawing of the brick
    fill(this.brickColor); //Colors the brick color
    rect(this.brickLocation.x, this.brickLocation.y, BRICK_SIZE.x, BRICK_SIZE.y); //Draws the brick
  }
}

