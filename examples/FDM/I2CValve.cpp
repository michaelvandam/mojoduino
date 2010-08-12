

#include "WProgram.h"
#include "I2CValve.h"
#include <stdlib.h>
#include <Wire.h>

I2CValve::I2CValve(){
    init();
}

I2CValve::I2CValve(char addr, int sz){
    setAddress(addr);
    setValveSize(sz);
    init();
}

void I2CValve::setAddress(char addr){
    address = addr;
}

void I2CValve::setValveSize(int sz){
	size = sz;
}

void I2CValve::init(){
  vstatus = 0;
}

void I2CValve::reset(){
	vstatus = 0;
    goHome();
}

int I2CValve::getPosition(){
    int csum = CADDRESS^SUPDATE^EMPTY;
    byte value[2];
    Wire.beginTransmission(address);
    Wire.send(SUPDATE);
    Wire.send(EMPTY);
    Wire.send(csum);
    Wire.endTransmission(); 
    Wire.requestFrom(address, 2);
    if (Wire.available()) {
      value[0] = Wire.receive();
    }
    if (Wire.available()) {
      value[1] = Wire.receive();
    }
	
    vstatus = (int)value[0];
	return vstatus;
}

void I2CValve::setPosition(int position){          
    Wire.beginTransmission(address);
    Wire.send(CPOS);
    Wire.send(position);
    Wire.send(CADDRESS^CPOS^position);
    Wire.endTransmission();
}

void I2CValve::goHome(){
    Wire.beginTransmission(address);
    Wire.send(HOMEVP);
    Wire.send(EMPTY);
    Wire.send(CADDRESS^HOMEVP^EMPTY);
    Wire.endTransmission();
}

boolean I2CValve::isValidPosition(int position) {
    if (position > 0 && position <= size)
        return true;
    return false;
}
