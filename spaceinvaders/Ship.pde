/**  Clone de Space Invader **/
/**  Programmation Tristan Brismontier **/

class Ship
{
  float spX;
  float spY;
  int taille;

  Ship(float x_, float y_)
  {
    spX=x_;
    spY=y_;
    taille=2;
  }
  Ship()
  {
    spX=width/2;
    spY=9*height/10;
    taille=2;
  }

  void display()
  {
    noStroke();
    fill(0,255,0);
    rectMode(CENTER);
    rect(spX,spY,15*taille,7*taille); 
    rect(spX,spY-5*taille,3*taille,3*taille);
    rect(spX,spY-7*taille,taille,taille);
    fill(0);
    rect(spX-7*taille,spY-3*taille,taille,taille);
    rect(spX+7*taille,spY-3*taille,taille,taille);
  }

  boolean contact(float x_, float y_)
  {
    if(x_ >spX-7*taille && x_ < spX+7*taille && y_ > spY-15*taille && y_<spY+taille )
    {
      return true;
    }
    else
    {
      return false;
    } 
  }

  void move(float sens)
  {
    float spXt =spX+sens;

    if( spXt > 14*width/15 )
    {  
    }
    else
    {
      if( spXt< width/15 )
      {
      }
      else
      {
        spX = spX +sens;
      }
    }
  }

}





