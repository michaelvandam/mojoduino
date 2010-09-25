/*
Jumper Pin Addresses
JP1	JP2	JP3	BIN	HEX
GND	GND	GND	0010000 0x10 (ALL LOW)
GND	GND	FLOAT	0010001 0x11
GND	GND	VCC	0010010 0x12
GND	FLOAT	GND	0010011 0x13
GND	FLOAT	FLOAT	0100000 0x20
GND	FLOAT	VCC	0100001 0x21
GND	VCC	GND	0100010 0x22
GND	VCC	FLOAT	0100011 0x23
GND	VCC	VCC	0110000 0x30 
FLOAT	GND	GND	0110001 0x31
FLOAT	GND	FLOAT	0110010 0x32
FLOAT	GND	VCC	0110011 0x33
FLOAT	FLOAT	GND	1000000 0x40
FLOAT	FLOAT	FLOAT	1000001 0x41 (NO JUMPER)
FLOAT	FLOAT	VCC	1000010 0x42
FLOAT	VCC	GND	1000011 0x43
FLOAT	VCC	FLOAT	1010000 0x50
FLOAT	VCC	VCC	1010001 0x51
VCC	GND	GND	1010010 0x52
VCC	GND	FLOAT	1010011 0x53
VCC	GND	VCC	1100000 0x60
VCC	FLOAT	GND	1100001 0x61
VCC	FLOAT	FLOAT	1100010 0x62
VCC	FLOAT	VCC	1100011 0x63
VCC	VCC	GND	1110000 0x70
VCC	VCC	FLOAT	1110001 0x71
VCC	VCC	VCC	1110010 0x72 (ALL HIGH)
GLOBAL ADDRESS		1110011 0x73 (GLOBAL)


*/


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

