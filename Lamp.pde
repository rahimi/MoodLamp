// We want our MoodLamp to fade the colors, so we need some for loops and time
// Define the pins your LEDs are connected to here.
#define pinRed   5
#define pinGreen 6
#define pinBlue  3  
float stepRed   = 0;
float stepGreen = 0;
float stepBlue  = 0;
long timeStamp = 0;
long blinkFor = 20;
boolean UPDOWN = true;
int threshold = 5;
boolean signalStart = false;
long timetemp = 0;

void signalLamp(int ppm){
  timetemp = millis();
  if(signalStart){
    if( timetemp < (timeStamp+(blinkFor*1000)) ){
      //if( ((timetemp-timeStamp)/1000)%2 ){
      if( UPDOWN ){
        UPDOWN = false;
        for(int i =  0 ; i < 255 ; i++){
          setColor( i * stepRed , i * stepGreen , i * stepBlue );
          delay(10);
        }
      }else{
        UPDOWN = true;
         for(int i =  254 ; i >= 0 ; i--){
           setColor( i * stepRed , i * stepGreen ,  i * stepBlue );
           delay(10);
        }
        setColor( 0, 0, 0);
      }
    }else{
      timeStamp = 0;
      if(!UPDOWN){
        for(int i =  254 ; i >= 0 ; i--){
           setColor( i * stepRed , i * stepGreen ,  i * stepBlue );
           delay(10);
        }
        setColor( 0, 0, 0);
      }
      signalStart = false;
      UPDOWN = true;
    }
  }
  else{
    if(ppm > threshold){
      if(ppm<50){
        updateColorValues(0,0,255);
      }else if (ppm > 50 && ppm < 100){
        updateColorValues(0,255,0);
      }else{
        updateColorValues(255,0,0);
      }
      timeStamp = timetemp;
      signalStart = true;
    }
  }
}

void updateColorValues(int red , int green , int blue){
   stepRed   = red / 255.0f;
   stepGreen = green / 255.0f;
   stepBlue  = blue / 255.0f;
}

void setColor(int red , int green , int blue){
  analogWrite(pinRed   , red  );
  analogWrite(pinGreen , green);
  analogWrite(pinBlue  , blue );
}

