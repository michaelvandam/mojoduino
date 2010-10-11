#include "wiring.h"
#include "MultiDAC.h"
#include "Wire.h"

MultiDAC::MultiDAC(){
    MultiDAC::setAddress(0);
    init();
}

MultiDAC::MultiDAC(char addr){
    MultiDAC::setAddress(addr);
    init();
}

void MultiDAC::setAddress(char addr){
    address = addr;
}
char MultiDAC::getAddress(){
    return address;
}
void MultiDAC::init(){
     for(char x=0;x<MAX_OUT;x++){
       outputs[x]= Output(x,address); 
      }
}


Output::Output(){
}			



Output::Output(char addr, char dacaddress){
   setPinAddress(addr);
   DACaddress = dacaddress;
}		
void Output::setPinAddress(char addr){
   pinaddress = addr;
} 

char Output::getAddress(){
  return pinaddress;
}			

void Output::setValue(unsigned int value){
   int highbyte = value>>8;
   int lowbyte  = value;
      Wire.beginTransmission(DACaddress);
      Wire.send((WRITE_PWR<<4) | (pinaddress));
      //00020000
      Wire.send(highbyte);
      Wire.send(lowbyte);
      Wire.endTransmission();    
 }



