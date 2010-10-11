#include <Wire.h>
#include <EEPROM.h>
#include <Button.h>
#include <FiniteStateMachine.h>
#include <mojo.h> 
#include "HardwareSerialRS485.h"
#include "MultiDAC.h"
#define DEBUGMTR
/*
* FDM Parameters
*/

MultiDAC DAC1; //MultiDAC(0x41);
MultiDAC DAC2; //MultiDAC(0x51);
MultiDAC *DACs[2] = {&DAC1, &DAC2};


/* Parsing Functions*/
boolean isEmpty(char *param) {
    if (strlen(param)==0)
        return true;
    return false;
}

boolean isPSTR(const char *param, PGM_P pstr) {
 if (strcmp_P(param, pstr) == 0) 
    return true;
  return false;
}

/* 
* Callbacks          
*/

//Callback POSX

void cbDacValue( Command &cmd  ) {
  char *param = cmd.getParam();
  char *cmdstr = cmd.getCmd();
  int selectedDAC;
  int selectedPin;
  long val;
  char * splitpos;
  
  selectedDAC = atoi(&cmdstr[3]);

  if (isEmpty(param)) {
        cmd.setReply("DUH");
        Serial.print("SDAC:");
        Serial.print(cmdstr);
        Serial.println(selectedDAC);
  } else {
        selectedPin = param[0]-'0';
        if (selectedPin < MAX_OUT) {
          splitpos = strchr(param,',');

          val = atol(splitpos+1);
          if (val < MAX_VAL && val > 0) {
            /*
            Serial.print("Selected DAC:");Serial.println(selectedDAC);
            Serial.print("Selected Pin:");Serial.println(selectedPin);
            Serial.print("Value:");Serial.println(val);        
            */       
            DACs[selectedDAC]->outputs[selectedPin].setValue((unsigned int)val);
            cmd.setReply(param);  
          } else {
            cmd.setReply_P(BADPARAM);
          }
          

          
 
        } else {
          cmd.setReply_P(BADPARAM);
        }        
  }
}



void setup()
{
  
  /*** SETUP MOJO COMMUNICATOR  ***/
  //downSensor.setup(PULLDOWN);
  Wire.begin();
  mojo.setDeviceType("REG-V0.1");
  mojo.setSerial(SerialRS485);  //Set which serial to listen on
  SerialRS485.setControlPin(4);
  mojo.loadBaudrateEEPROM(); //Load baudrate from EEPROM
  mojo.loadAddressEEPROM(); //Load address from EEPROM
  DAC1 = MultiDAC(0x41);
  DAC2 = MultiDAC(0x51);
  /*** ATTACH CALLBACKS HERE ***/
  addCallback("DAC0", cbDacValue);   
  addCallback("DAC1", cbDacValue);   

  /*** ATTACH DEFAULT CALLBACKS ***/
  setupDefaultCallbacks(); 
  
  /*** ADDITIONAL DEVICE SETUP CODE ***/
  analogReference(INTERNAL);
  
  /*** Default Digital Pin States ***/
  for(int i=23; i<53;i=i+2) {
    pinMode(i,OUTPUT);
    digitalWrite(i,LOW);
  }
} 


void loop() {  
    mojo.run(); // Run mojo communicator     
}


/*** UTILITY FUNCTIONS FOR DEVICE ***/


char *floatToStr(double number, char* buff, uint8_t digits) 
{ 
  // Handle negative numbers
  char *buf = buff;
  if (number < 0.0)
  {
     *buf++=('-');
     number = -number;
  }

  // Round correctly so that print(1.999, 2) prints as "2.00"
  double rounding = 0.5;
  for (uint8_t i=0; i<digits; ++i)
    rounding /= 10.0;
  
  number += rounding;

  // Extract the integer part of the number and print it
  unsigned long int_part = (unsigned long)number;
  double remainder = number - (double)int_part;
  ltoa(int_part,buf,10);
  
  
  while(*buf!='\0') {
    buf++;
   //Serial.println("Not in here");
  } //Move to end of buffer
  
  
  // Print the decimal point, but only if there are digits beyond
  if (digits > 0) {
    *buf++='.'; 
    *buf='\0';  
  }
  
  // Extract digits from the remainder one at a time
  while (digits-- > 0)
  {
    //Serial.println(digits,DEC);
    remainder *= 10.0;
    int toPrint = int(remainder);
    itoa(toPrint,buf,10);
    buf++;
    remainder -= toPrint; 
  } 
    //Terminate string
  return buff;
}

