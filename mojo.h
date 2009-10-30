#ifndef Mojo_h
#define Mojo_h

#undef DEBUG


#include "WProgram.h"
#include "HardwareSerial.h"
#include "mojodefs.h"
#include "mojomsg.h"
#include <inttypes.h>


      
class Mojo
{
  public:
    Mojo();
    Mojo(HardwareSerial &S, char address);
    HardwareSerial *serial;
    void setSerial(HardwareSerial &S);
    void recieve();
    uint8_t messageReady();
    Message *getMessage();
    void setAddress(char address);
    void loadAddress();
    char getAddress();
    void readyForNext();
    void run();
    void dispatch();
    void reply();
    
    
  private:
  enum { _WAITING,
       _STARTCHAR1,
       _STARTCHAR2,
       _NEWMSG,
       _COMPLETEMSG
      };
    void init();
    void reset();
    uint8_t _messageState;
    Message msg;
    char msgBuffer[MAXMSGSIZE];
    char *current;
    char *last;
    char addy;
    uint8_t bufferIndex;
    uint8_t bufferLength;
   
};


extern Mojo mojo;
#endif
