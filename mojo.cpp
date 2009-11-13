
/*
mojo.cpp - Library for MojoBus communication.
Created by Henry Herman, October 18, 2009.
Released under the BSD License.
*/
extern "C" {
    #include <stdlib.h>
}

#include <avr/eeprom.h>
#include "WProgram.h"
#include "HardwareSerial.h"
#include "mojo.h"
#include "mojodispatch.h"
#include "mojomsg.h"

#include "mojodefs.h"
#include <inttypes.h>
#include <string.h>

/***********************************************
                MOJO METHODS
***********************************************/
Mojo::Mojo() {
    init();
    setSerial(Serial);
    setAddress('a');
    loadBaudrate();
}

Mojo::Mojo(HardwareSerial &S, char address) {
    
    init();
    setSerial(S);
    setAddress(address);
    loadBaudrate();
}

void Mojo::setSerial(HardwareSerial &S) {
  serial = &S;
}

void Mojo::init() {
    
    bufferLength = MAXMSGSIZE;
    reset();
}

void Mojo::setAddress(char address) {
    addy=address;
    eeprom_write_byte((unsigned char *)ADDRADDR, address);
}

void Mojo::loadAddressEEPROM() {
  char c;
  c = eeprom_read_byte((unsigned char *)ADDRADDR);
  setAddress(c);  
}

char Mojo::getAddress() {
  return addy;
}

void Mojo::reset() {
    //serial->println("RESET");
    bufferIndex = 0;
    msgBuffer[bufferIndex] = '\0';
    _messageState = _WAITING;
    
}

void Mojo::recieve() {
    char serialByte;
    
    //serial->print("Buffer:");
    //serial->println(msgBuffer);

    if (serial->available()>0) {
    msgBuffer[bufferIndex] = (char)serial->read();
    serialByte = msgBuffer[bufferIndex];
    msgBuffer[++bufferIndex]='\0';    
    } else { 
    return;
    }
    
    
    if (bufferIndex >= (MAXMSGSIZE -1)) {
    reset();
    return;
    }
    
    switch(_messageState) {
        serial->println("WAITING");
        case _WAITING:
            if (serialByte == STARTMSG) {
                _messageState = _STARTCHAR1;
            } else {
               reset();
            }
            break;
        case _STARTCHAR1:
            //serial->println("Start1");
            if (serialByte == STARTMSG) {
                _messageState = _STARTCHAR2;
                
            } else {
               reset();
            }
            break;
        case _STARTCHAR2:
            //serial->println("Start2");
            if (serialByte == addy || serialByte == BROADCASTADDY) {
                _messageState = _NEWMSG;
            } else {
                reset();
            }
            break;
        case _NEWMSG:
            //serial->println("NEW");
            if (serialByte == ENDMSG)
                _messageState = _COMPLETEMSG;
            break;
        case _COMPLETEMSG:
            //serial->println("COMPLETE");
            break;
        default:
            reset();
            break;
    }
}

uint8_t Mojo::messageReady() {
    if (_messageState == _COMPLETEMSG) return 1;
    else return 0;
}

Message *Mojo::getMessage() {
    char len;
    len = strlen(msgBuffer);
    msgBuffer[len-1] = '\0';
    msg.load(msgBuffer);
    reset();
    return &msg;
}

void Mojo::readyForNext() {
    msg.reset();
}


void Mojo::dispatch() {
  msgDispatch(&msg);
}

void Mojo::reply() {
  serial->print(msg.reply());
}


void Mojo::run() {
  recieve();
  if (messageReady()) {  
    getMessage();
    dispatch();
    reply();
    readyForNext();
 }
}

void Mojo::setBaudrate(char index){
    baudIndex  = index;
    loadBaudrate();
}

void Mojo::loadBaudrate(){
  serial->begin(getBaudrate());
}

void Mojo::loadBaudrateEEPROM(){
  baudIndex =  eeprom_read_byte((unsigned char *)BAUDADDR);
  loadBaudrate();
}

void Mojo::saveBaudrateEEPROM() {
  eeprom_write_byte((unsigned char *) BAUDADDR, baudIndex);
}

long Mojo::getBaudrate(){
  
  if (baudIndex > BAUDRATELEN || baudIndex < 0) {  //Default to 9600
    baudIndex = 2;
    setBaudrate(baudIndex);
  }
  return baudRates[baudIndex];
}

void Mojo::setDeviceType(char *s) {
    strcpy(deviceType, s);
}

char *Mojo::getDeviceType() {
    return deviceType;
}
Mojo mojo;
