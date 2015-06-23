/**  Clone de Space Invader **/
/**  Programmation Tristan Brismontier **/

class Invader
{
  int type;
  float spX;
  float spY;
  int taillex;
  int tailley;
  float speedx;
  int speedy;
  boolean existe;
  boolean fspY=false;

  Invader()
  {
    spX=width/2;
    spY=height/2;

    existe=true;

    speedy = 1;
    speedx = 5;

    taillex = 2;
    tailley = 2;
  }

  Invader(int X_, int Y_, int _type)
  {
    type=_type;
    spX=X_;
    spY=Y_;

    existe=true;

    speedy = 1;
    speedx =5;

    taillex = 2;
    tailley = 2;

  }

  void display(boolean flag)
  {
    if(existe==true)
    {
      if(type==1)
      {
        
        noStroke();  
        fill(255);
        rectMode(CORNER);
        rect(-2*taillex+spX,-4*tailley+spY,4*taillex,tailley);   
        rect(-5*taillex+spX,-3*tailley+spY,10*taillex,tailley);    
        rect(-6*taillex+spX,-2*tailley+spY,12*taillex,tailley); 
        rect(-6*taillex+spX,-1*tailley+spY,3*taillex,tailley);  
        rect(-1*taillex+spX,-1*tailley+spY,2*taillex,tailley);
        rect(3*taillex+spX,-1*tailley+spY,3*taillex,tailley);
        rect(-6*taillex+spX,spY,12*taillex,tailley);
        rect(1*taillex+spX,1*tailley+spY,2*taillex,tailley);
        rect(-3*taillex+spX,1*tailley+spY,2*taillex,tailley);
        rect(-1*taillex+spX,2*tailley+spY,2*taillex,tailley);

        if( flag==false)
        {
          rect(-4*taillex+spX,2*tailley+spY,2*taillex,tailley);
          rect(2*taillex+spX,2*tailley+spY,2*taillex,tailley);
          rect(-6*taillex+spX,3*tailley+spY,2*taillex,tailley);
          rect(4*taillex+spX,3*tailley+spY,2*taillex,tailley);
        }
        else
        {
          rect(-5*taillex+spX,2*tailley+spY,2*taillex,tailley);
          rect(3*taillex+spX,2*tailley+spY,2*taillex,tailley);
          rect(-4*taillex+spX,3*tailley+spY,2*taillex,tailley);
          rect(2*taillex+spX,3*tailley+spY,2*taillex,tailley);
        }

      }
      if(type==2)
      {
        noStroke();  
        fill(255);
        rectMode(CORNER);
        rect(-3.5*taillex+spX,-5.0*tailley+spY,1*taillex,1*tailley);
        rect(2.5*taillex+spX,-5.0*tailley+spY,1*taillex,1*tailley);
        rect(-2.5*taillex+spX,-4.0*tailley+spY,1*taillex,1*tailley);
        rect(1.5*taillex+spX,-4.0*tailley+spY,1*taillex,1*tailley);
        rect(-3.5*taillex+spX,-3.0*tailley+spY,7*taillex,1*tailley);
        rect(-3.5*taillex+spX,-3.0*tailley+spY,1*taillex,5*tailley);
        rect(2.5*taillex+spX,-3.0*tailley+spY,1*taillex,5*tailley);
        rect(-3.5*taillex+spX,-1.0*tailley+spY,7*taillex,2*tailley);
        rect(-1.5*taillex+spX,-2.0*tailley+spY,3*taillex,1*tailley);
        rect(-4.5*taillex+spX,-2.0*tailley+spY,1*taillex,2*tailley);
        rect(3.5*taillex+spX,-2.0*tailley+spY,1*taillex,2*tailley);
        if( flag==false)
        {
          rect(-5.5*taillex+spX,-1.0*tailley+spY,1*taillex,3*tailley);
          rect(4.5*taillex+spX,-1.0*tailley+spY,1*taillex,3*tailley);
          rect(.5*taillex+spX,2.0*tailley+spY,2*taillex,1*tailley);
          rect(-2.5*taillex+spX,2.0*tailley+spY,2*taillex,1*tailley);
        }
        else
        {
          rect(-5.5*taillex+spX,-4.0*tailley+spY,1*taillex,3*tailley);
          rect(4.5*taillex+spX,-4.0*tailley+spY,1*taillex,3*tailley);
          rect(3.5*taillex+spX,2.0*tailley+spY,1*taillex,1*tailley);
          rect(-4.5*taillex+spX,2.0*tailley+spY,1*taillex,1*tailley);
        }
      }
      if(type==3)
      {
        noStroke();  
        fill(255);
        rectMode(CORNER);
        rect(-1*taillex+spX,-3*tailley+spY,2*taillex,tailley);
        rect(-2*taillex+spX,-2*tailley+spY,4*taillex,tailley);
        rect(-3*taillex+spX,-1*tailley+spY,6*taillex,tailley);
        rect(-4*taillex+spX,spY,2*taillex,tailley);
        rect(-1*taillex+spX,spY,2*taillex,tailley);
        rect(2*taillex+spX,spY,2*taillex,tailley);
        rect(-4*taillex+spX,1*tailley+spY,8*taillex,tailley);
        rect(-2*taillex+spX,2*tailley+spY,taillex,tailley);
        rect(taillex+spX,2*tailley+spY,taillex,tailley);
        rect(-3*taillex+spX,3*tailley+spY,taillex,tailley);
        rect(2*taillex+spX,3*tailley+spY,taillex,tailley);
        rect(-2*taillex+spX,4*tailley+spY,taillex,tailley);
        rect(taillex+spX,4*tailley+spY,taillex,tailley);
        rect(-2*taillex+spX,4*tailley+spY,taillex,tailley);
        rect(taillex+spX,4*tailley+spY,taillex,tailley);

        if( flag==false)
        {
          rect(-4*taillex+spX,4*tailley+spY,taillex,tailley);
          rect(3*taillex+spX,4*tailley+spY,taillex,tailley);
          rect(-1*taillex+spX,3*tailley+spY,2*taillex,tailley);
        }

      }
    }
  }

  boolean move(float signe, boolean fpY)
  {

    if(fpY!=fspY)
    {
      spY = spY + 10;
      fspY=fpY;
      return false;    
    }
    else
    {
      //float speedxt = speedx * signe;
      spX = spX + signe;
      if(existe==true)
      {
        if( spX > 14*width/15 )
        {      
          return true;
        }
        else
        {
          if( spX < width/15 )
          {
            return true;
          } 
          else
          {
            return false;
          } 
        }
      }
      else
      {
        return false;
      }
    } 
  }

  boolean contact(float x_, float y_)
  {
    if(existe==true)
    {
      if(x_ < 4.5*taillex+spX+taillex && x_ > -4.5*taillex+spX-taillex && y_>-5.0*tailley+spY && y_ < 2.0*tailley+spY)
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

















