
class MotherShip
{

  float spX;
  float spY;
  int taillex;
  int tailley;
  float speedx;
  boolean existe;
  boolean sens;


  MotherShip()
  {
    spX=width/2;
    spY=65;

    existe=false;

    speedx = 1;

    taillex = 2;
    tailley = 2;
  }



  void display()
  {
    if(existe==true)
    {
      
      noStroke();  
      fill(255,10,10);
      rectMode(CORNER);
      rect(-3*taillex+spX,-3*tailley+spY,6*taillex,tailley);
      rect(-5*taillex+spX,-2*tailley+spY,10*taillex,tailley);
      rect(-6*taillex+spX,-1*tailley+spY,12*taillex,tailley);
      rect(-7*taillex+spX,0*tailley+spY,2*taillex,tailley);
      rect(-4*taillex+spX,0*tailley+spY,2*taillex,tailley);
      rect(-1*taillex+spX,0*tailley+spY,2*taillex,tailley);
      rect(2*taillex+spX,0*tailley+spY,2*taillex,tailley);
      rect(5*taillex+spX,0*tailley+spY,2*taillex,tailley);
      rect(-8*taillex+spX,1*tailley+spY,16*taillex,tailley);
      rect(-6*taillex+spX,2*tailley+spY,3*taillex,tailley);
      rect(-1*taillex+spX,2*tailley+spY,2*taillex,tailley);
      rect(3*taillex+spX,2*tailley+spY,3*taillex,tailley);
      rect(-5*taillex+spX,3*tailley+spY,1*taillex,tailley);
      rect(4*taillex+spX,3*tailley+spY,1*taillex,tailley);

    }
  }

  void lancement(float k)
  {
    if( k < 1 )
    {
      
      spX=-7*taillex;
      sens = true;
    }
    else
    {
      spX=width+7*taillex;
      sens=false;
    }
    speedx=random(0.8,2);
    existe=true;
  }
  
  
  void move()
  {
    if(spX +8*taillex > 0 && spX - 8*taillex < width)
    {
      if( sens == true ) 
      {
         spX = spX + speedx;
      }
      else
      {
        
        spX = spX -speedx;
      }
    }
    else
    {
      existe=false;
    }
  }

  boolean contact(float x_, float y_)
  {
    if(existe==true)
    {
      if(x_ < spX +8*taillex && x_ > spX - 8*taillex && y_> -3*tailley+spY && y_ < 3*tailley+spY)
      {
        existe=false;

      } 
      return existe;
    }
    else
    {
      return true;
    }
  }
}


