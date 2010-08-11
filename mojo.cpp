
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
    eeprom_write_byte((unsigned char *)ADDRADDR, (unsigned char)addy);
}

void Mojo::loadAddressEEPROM() {
  unsigned char c;
  c = eeprom_read_byte((unsigned char *)ADDRADDR);
  setAddress(c);  
}

char Mojo::getAddress() {
  return addy;
}

void Mojo::reset() {
    
    #ifdef DEBUGMOJO
    serial->println("RESET");
    #endif
    
    bufferIndex = 0;
    msgBuffer[bufferIndex] = '\0';
    _messageState = _WAITING;
    
}

boolean Mojo::recieve() {
    char serialByte;
    
    #ifdef DEBUGMOJO
    serial->print("Buffer:");
    serial->println(msgBuffer);
    #endif
    
    if (serial->available()>0) {
    msgBuffer[bufferIndex] = (char)serial->read();
    serialByte = msgBuffer[bufferIndex];
    msgBuffer[++bufferIndex]='\0';    
    } else { 
    return false;
    }
    
    
    if (bufferIndex >= (MAXMSGSIZE -1)) {
    reset();
    return true;
    }
    
    switch(_messageState) {
        
        #ifdef DEBUGMOJO
        serial->println("WAITING");
        #endif
        
        case _WAITING:
            if (serialByte == STARTMSG) {
                _messageState = _STARTCHAR1;
            } else {
               reset();
            }
            break;
        case _STARTCHAR1:
            #ifdef DEBUGMOJO
            serial->println("Start1");
            #endif
            if (serialByte == STARTMSG) {
                _messageState = _STARTCHAR2;
                
            } else {
               reset();
            }
            break;
        case _STARTCHAR2:
            #ifdef DEBUGMOJO
            serial->println("Start2");
            #endif
            if (serialByte == addy || serialByte == BROADCASTADDY) {
                _messageState = _NEWMSG;
            } else {
                reset();
            }
            break;
        case _NEWMSG:
            #ifdef DEBUGMOJO
            serial->println("NEW");
            #endif
            if (serialByte == ENDMSG)
                _messageState = _COMPLETEMSG;
            break;
        case _COMPLETEMSG:
            #ifdef DEBUGMOJO
            serial->println("COMPLETE");
            #endif
            break;
        default:
            reset();
            break;
    }
    return true;
}

uint8_t Mojo::messageReady() {
    if (_messageState == _COMPLETEMSG) return 1;
    else return 0;
}

Message *Mojo::getMessage() {
    msgBuffer[strlen(msgBuffer)-1] = '\0';
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
  #ifdef DEBUGMOJO
  serial->println("Reply:");
  #endif
  serial->print(msg.reply());
}


void Mojo::run() {
  while(recieve())
    continue;
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

void Mojo::setDeviceType_P(PGM_P s) {
    strcpy_P(deviceType, s);
}

char *Mojo::getDeviceType() {
    return deviceType;
}
Mojo mojo;
