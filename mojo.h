#ifndef Mojo_h
#define Mojo_h

#undef DEBUG


#include "WProgram.h"
#include "HardwareSerial.h"
#include "mojodefs.h"
#include "mojomsg.h"
#include <inttypes.h>
#include "mojodispatch.h"
#include "mojocallbacks.h"
#include "mojoresponses.h"


      
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
    void loadAddressEEPROM();
    char getAddress();
    
    void setBaudrate(char index);
    void loadBaudrate();
    long getBaudrate();
    
    void loadBaudrateEEPROM();
    void saveBaudrateEEPROM();
    
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
    unsigned char addy;
    char baudIndex;
    uint8_t bufferIndex;
    uint8_t bufferLength;
   
};


extern Mojo mojo;
#endif
