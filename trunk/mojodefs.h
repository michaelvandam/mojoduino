#ifndef Mojodefs_h
#define Mojodefs_h

#include <inttypes.h>

//Mojo Limits
#define MAXMSGSIZE 128
#define MAXCMDS 8
#define MAXCMDLEN 8
#define MAXPARAMLEN 17
#define REPLYLEN MAXCMDLEN + MAXPARAMLEN + 1


//Errors
#define NOERR 0
#define TOOLONGERR -1

//Device Specific
const char DEVICEID[] = "Default-0.1";


//Mojo Special Characters
const char ENDMSG = '$'; // Change to '\r'
const char STARTMSG = '>';
const char CMDSEP[] = ";";
const char ADDSEP1[] = ":";
const char ADDSEP2[] = ",";
const char PARAMSEP[] = "=";
const char BROADCASTADDY = '0';
const char RESPCHAR[] = "*";

const int ADDRADDR = 0;
const int BAUDADDR = 1;

const long baudRates [] =  {2400, 4800, 9600, 19200, 31250, 38400, 57600, 115200, 0};
const char BAUDRATELEN = 9;
#endif