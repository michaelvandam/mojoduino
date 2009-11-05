#include <string.h>
#include <ctype.h>

#define MFC1 Serial1
#define MFC2 Serial2


HardwareSerial *selectedSerial;

void setMFC(HardwareSerial &S,int val){
  S.print("S");
  S.print(val,DEC);
  S.print("\n\r");
}

void queryMFC(HardwareSerial &S) {
  S.print("S\r");
  delay(650);
  S.print("R\r");
}
void logIn(HardwareSerial &S) {
  Serial.println("Logging In...");
  S.print("E\n\r\r\n7346\n\r");
  delay(650);
  S.flush();
/*
  //delay(200);
  //Serial1.flush();
  //Serial1.print("\r\n");
  //delay(200);
  //Serial1.flush();
  //Serial1.print("7346\n\r");
  //delay(200);
  while(Serial1.available()>0) {
     int c = Serial1.read();
    Serial.print(c, BYTE);
  }
*/  
 
}


void setup() {
Serial.begin(9600);
MFC1.begin(9600);
MFC2.begin(9600);
logIn(MFC1);
logIn(MFC2);
selectedSerial = &Serial;
}


void loop() {
  
  if (Serial.available() > 0) {
    int c = Serial.read();
    int o = 0;
    switch (c) {
    case 'M':
       delay(500);
       //Serial.println("Got M");
       while (Serial.available() > 0 && (o=Serial.read())!= '\r') {
           if (o=='1') {
            Serial.println("Selected MFC 1:");
            selectedSerial = &MFC1;
           } else if (o=='2') {
             Serial.println("Selected MFC 2:");
             selectedSerial = &MFC2;
           } else if (o=='3') {
             Serial.println("Selected Loopback:");
             selectedSerial = &Serial;
           }else {
             selectedSerial = &Serial;
           }
       }
       break;
    case 'Q':
      queryMFC(MFC1);
      queryMFC(MFC2);
      break;
    
    case 'L':
      logIn(MFC1);
      logIn(MFC2);
      break;
    
    case 'A':
      {
      int index = 0;
      int anestesia = 0;
      char valStr[10];
      delay(650);
      while (Serial.available() > 0 && (o=Serial.read())!= '\r' && index < 10) {
          //Serial.print("Index:");
          //Serial.println(index,DEC);
          //Serial.print("O:");
          //Serial.println(o,BYTE);
          valStr[index] = o;
          index++;
          valStr[index]='\0';
      }
      anestesia = atoi(valStr);
      
      setMFC(MFC1, anestesia);
      setMFC(MFC2, 1000-anestesia);
      //Serial.print("ValStr:");
      //Serial.println(valStr);    
      //Serial.print("Anestesia:");
      //Serial.println(anestesia,DEC);
      break;   
      }   
    default:
      selectedSerial->print(c, BYTE);
      break;  
   
  }  
}  

  if (MFC1.available() > 0) {
    int c;
    delay(650);
    Serial.print("ANES:");
    while (MFC1.available() > 0) {
      c = MFC1.read();
      Serial.print(c, BYTE);
    }
  }  
  
  
  if (MFC2.available() > 0) {
    int c;
    delay(650);
    Serial.print("O2:");
    while (MFC2.available() > 0) {
      c = MFC2.read();
      Serial.print(c, BYTE);
    }
  }
}


