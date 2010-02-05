
extern "C" {
    #include <stdlib.h>
}
#include "WProgram.h"
#include "HardwareSerialRS485.h"
#include <string.h>
#include "AMComm.h"


AMComm::AMComm() {
    init();
}

AMComm::AMComm(HardwareSerial &S, char addr) {
    setSerial(S);
    setAddress(addr);
    init();
}

void AMComm::setSerial(HardwareSerial &S) {
    serial = &S;
}

void AMComm::setAddress(char addr){
    address = addr;
}

boolean AMComm::receive() {
    char c;
    boolean recievedByte = false;
    while (serial->available() > 0) {
       resetTimeout();
       recievedByte = true;
       c = serial->read();
       #ifdef DEBUGAM
       Serial.print("Received:");
       Serial.println(c);
       #endif
       switch(messageState) {
         case BEGIN:
           #ifdef DEBUGAM
           Serial.println("BEGIN");
           #endif
           if (c =='/')
             messageState = ADDRESS;
           break;
         case ADDRESS:
           #ifdef DEBUGAM
           Serial.println("ADDRESS");
            #endif
            delay(100);
           if (c == '0') {
             messageState = STATUS;
           } else 
             messageState = BEGIN;
           break;
         case STATUS:
            #ifdef DEBUGAM
            Serial.println("STATUS");
            #endif
            delay(100);
            messageState = END;
            status = c;
            break;
         case END:
           #ifdef DEBUGAM
           Serial.println("END");
           #endif
           readyToSend=true;
           break;
         default:
           messageState = BEGIN;       
        }
    
    }
    return recievedByte;
}


boolean AMComm::messageReady() {
  if (messageState == END) {
    messageState = BEGIN;
    return true;
  } else {
    return false;
  }
};

char AMComm::getStatus() {
    return status;
}

void AMComm::readyForNext() {
    reset();
}

void AMComm::init() {
    messageState = BEGIN;
    status = NULL;
    readyToSend = true;
    timeoutInterval = 0;
}

void AMComm::reset() {
    messageState = BEGIN;
    status = NULL;
    serial->flush();

}


void AMComm::send(char *str) {
    
    char buf[100];
    buf[0] = '/';
    buf[1] = address;
    buf[2] = '\0';
    strcat(buf, str);
    serial->println(buf);
    serial->println();
    readyToSend=false;
    //serial->flush();
    resetTimeout();
}


boolean AMComm::isInError() {
    return false;
}


boolean AMComm::isBusy() {
  #ifdef DEBUGAM
  Serial.println("Not Ready");
  #endif
    if (status & READYBIT)  {
      #ifdef DEBUGAM
      Serial.println("Ready");
      #endif
      return false;
    }
    #ifdef DEBUGAM
    Serial.println("Not Ready");  
    #endif
    return true;   
}


void AMComm::sendQuery() {
  static int count = 0;
  count++;
    if (readyToSend && (count > 100) ) {
      send("Q");
      count = 0;
    }
}

boolean AMComm::isInTimeout() {
    #ifdef DEBUGAM
    serial->println("Check timeout");
    #endif
    if (timeoutInterval == 0) {
      return false;
    }
    if (millis() - previousMillis > timeoutInterval) {
        resetTimeout();
        #ifdef DEBUGAM
        serial->println("Now in ERR");
        #endif
        return true;
    } else {
        return false; 
    }
}

void AMComm::resetTimeout() {
  previousMillis = millis();
}

void AMComm::setTimeout(long timeout) {
  timeoutInterval=timeout;
}
