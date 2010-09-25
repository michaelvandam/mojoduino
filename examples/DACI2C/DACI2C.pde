#include <Wire.h>
#include <LiquidCrystal.h>
#include "MultiDAC.h"

MultiDAC DAC1 = MultiDAC(0x41);
MultiDAC DAC2 = MultiDAC(0x51);

LiquidCrystal lcd(22, 24, 26, 28, 30, 32);
int inputH = 8; 
int inputA = 15;
unsigned int x = 0x00;

void setup() {
  analogReference(EXTERNAL);
  lcd.begin(16, 2);
  Wire.begin();
  Serial.begin(9600);
}




void loop() {

  lcd.setCursor(0,0);
  lcd.print("RAMP ");
  lcd.print(x);
  DAC1.outputs[0].setValue(x);
  DAC2.outputs[0].setValue(0xFFFF-x);
  delay(100);
  lcd.setCursor(0,1);
  lcd.print(DAC1.getAddress());
  lcd.print((int) DAC1.outputs[0].getAddress());
  lcd.print(" ");
  lcd.print(DAC2.getAddress());
  lcd.print((int) DAC2.outputs[0].getAddress());
  x+=500;
  if( x > 0xFFFF)
    x=0;
    
}

float getPressure(int input){
  //MPa y = 0.001080x - 0.213979
  //psi y = 0.156647x - 31.035026
 return ((0.156647*analogRead(input)- 31.035026));
}

