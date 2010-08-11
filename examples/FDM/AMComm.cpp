
extern "C" {
    #include <stdlib.h>
}
#include "WProgram.h"
#include "HardwareSerialRS485.h"
#include <string.h>
#include "AMComm.h"
//#define DEBUGAM
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
    boolean receivedByte = false;
    while (serial->available() > 0) {
       resetTimeout();
       receivedByte = true;
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
    return receivedByte;
}


boolean AMComm::receiveMessage() {
    #ifdef DEBUGAM
    Serial.println("*Waiting for receive message");
    #endif      
    while(true){
      #ifdef DEBUGAM
      Serial.println("Message receive loop");
      #endif
      
      if (isInTimeout()) {
          #ifdef DEBUGAM
          Serial.println("Timeout occured");
          #endif  
          return false;
      }
      else if( messageReady() ) {
          #ifdef DEBUGAM
          Serial.println("Message is ready, return");
          #endif
          return true; 
        
      } else {
          #ifdef DEBUGAM
          Serial.println("Need to send Query");
          #endif
          sendQuery();
          receive();
          //Dont return?
      }
      
    }
}


boolean AMComm::messageReady() {
  #ifdef DEBUGAM
  Serial.println("*Check message is ready");
  #endif 
  if (messageState == END) {
    #ifdef DEBUGAM
    Serial.println("Message is ready");
    #endif 
    messageState = BEGIN;
    return true;
  } else {
    #ifdef DEBUGAM
    Serial.println("Message not ready");
    #endif 
    return false;
  }
};

char AMComm::getStatus() {
    return status;
}

void AMComm::readyForNext() {
    serial->flush();
    reset();
}

void AMComm::init() {
    reset();
    timeoutInterval = 0;
    serial->flush();
}

void AMComm::reset() {
    messageState = BEGIN;
    status = NULL;
    readyToSend = true;
}


void AMComm::send(char *str) {  
    char buf[100];
    buf[0] = '/';
    buf[1] = address;
    buf[2] = '\0';
    
    #ifdef DEBUGAM
    Serial.println(str);
    #endif
    
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
    Serial.println("*Check if busy");
    #endif
    if (status & READYBIT)  {
      #ifdef DEBUGAM
      Serial.println("Motor Ready");
      #endif
      return false;
    } else {
      #ifdef DEBUGAM
      Serial.println("Not Ready");
      #endif
      return true;   
    }
}

void AMComm::sendQuery() {
  static int count = 0;
  #ifdef DEBUGAM
  Serial.println("*In Send Query");
  #endif
  count++;
  if (readyToSend && (count > 0) ) {
    send("Q");
    count = 0;
    #ifdef DEBUGAM
    Serial.println("Time to send");
    #endif
  } else {
    #ifdef DEBUGAM
    Serial.println("Not time to send");
    #endif 
  }
}

boolean AMComm::isInTimeout() {
    #ifdef DEBUGAM
    Serial.println("*Check if we are in timeout");
    #endif
    if (timeoutInterval == 0) {
      #ifdef DEBUGAM
      Serial.println("Always return not in timeout");
      #endif
      return false;
    }
    if (millis() - previousMillis > timeoutInterval) {
        resetTimeout();
        #ifdef DEBUGAM
        Serial.println("Now in ERR");
        #endif
        return true;
    } else {
        #ifdef DEBUGAM
        Serial.println("Not in timeout");
        #endif
        return false; 
    }
}

void AMComm::resetTimeout() {
  previousMillis = millis();
}

void AMComm::setTimeout(long timeout) {
  timeoutInterval=timeout;
}
