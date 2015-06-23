/**  Clone de Space Invader **/
/**  Programmation Tristan Brismontier **/

class Laser
{
  float pX;
  float pY;
  float taille;
  boolean tire;
  float speedy;
  int type;
  boolean unedeux=true;

  Laser(float x_, float y_)
  {
    pX=x_;
    pY=y_;
    taille = 3;
    tire=false;
    speedy=-2.5;  
    type = 2;
  }

  Laser()
  {
    pX=width/2;
    pY=9*height/10;
    taille = 2;  
    tire=false;  
    speedy=4.1;
    type = 1;
  }

  void display()
  {
    if(tire==true)
    {
      if(type==1)
      {
        strokeWeight(taille);
        stroke(255);
        line(pX,pY,pX,pY-5*taille); 
      }
      else
      {
        strokeWeight(taille-1);
        stroke(255);
        line(pX+taille,pY,pX-taille,pY-taille); 
        line(pX-taille,pY-taille,pX+taille,pY-2*taille); 
        line(pX+taille,pY-2*taille,pX-taille,pY-3*taille); 
        line(pX-taille,pY-3*taille,pX+taille,pY-4*taille);
       line(pX+taille,pY-4*taille,pX-taille,pY-5*taille);  
      }
    }
  }

  void move()
  {
    if(tire==true)
    {
      pY=pY - speedy; 
      if( pY < 0 || pY > height+5*taille )
      {
        pX=0;
        pY=0;
        tire=false;
      }
    }
  }

  void lancement(float x_)
  {
    if(tire==false)
    {
      tire=true;
      pX=x_;
      if(unedeux==true)
      {
         pY=9*height/10;
         unedeux=!unedeux;
      }
      else
      {
        pY=9*height/10-2;
        unedeux=!unedeux;
      }
      
    }
  }  

  void lancement(float x_,float y_)
  {
    if(tire==false)
    {
      tire=true;
      pX=x_;
      pY=y_;
      
     
    } 

  }
}




