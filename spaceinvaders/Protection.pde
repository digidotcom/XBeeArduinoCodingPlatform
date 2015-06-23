class Protection
{
  int x,y;
  int taillex,tailley;
  int[][]  protect = {
              {0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0},
              {0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0},
              {0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0},
              {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
              {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
              {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
              {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
              {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
              {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
              {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
              {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
              {1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,1,1,1,1,1},
              {1,1,1,1,1,1,0,0,0,0,0,0,0,0,1,1,1,1,1,1},
              {1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1},
              {1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1}
            };
            
   Protection(int x_, int y_)
  {
    x = x_;
    y = y_;
    
    taillex=2;
    tailley=2;
  }   
  
  void display()
  {
    
    noStroke();
    fill(0,255,0);
    rectMode(CENTER);
    for(int i =0; i<15;i++)
    {
      for(int j=0; j<20;j++)
      {
        if(protect[i][j]==1)
        {
          rect(j*taillex+x,i*tailley+y,taillex,tailley);
        }
      }
    }
  }
  
  boolean contact(float pX, float pY)
  {
    boolean flagtouch =false;
    for(int i =0; i<15;i++)
    {
      for(int j=0; j<20;j++)
      {
        if(pX >= j*taillex+x-taillex/2 && pX <= j*taillex+x+tailley/2 && pY >= i*tailley+y-tailley/2 && pY <= i*tailley+y+tailley/2 && protect[i][j]==1)
        {
          protect[i][j]=0;
          for(int t=i-2;t<=i+2;t++)
          {
            for(int r = j-2; r<=j+2;r++)
            {
              if( t>=0 && t <15 && r>=0 && r < 20)
              {
                if(random(100)>75)
                {
                  protect[t][r]=0;
                }
              }
            }
          }
          flagtouch = true;
        }
      }
    }
    return flagtouch;
  }
  
  
}
