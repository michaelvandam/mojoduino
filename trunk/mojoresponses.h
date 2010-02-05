#ifndef Mojoresponses_h
#define Mojoresponses_h
#include <avr/pgmspace.h>
#include "mojodefs.h"

const char BADCMD[] PROGMEM = "?BADCMD";
const char BADPARAM[] PROGMEM = "?BADPARAM";
const char DONERESP[] PROGMEM = "DONE";
const char GOPARAM[] PROGMEM = "GO";
const char TRUERESP[] PROGMEM = "TRUE";
const char FALSERESP[] PROGMEM = "FALSE";
const char ONRESP[] PROGMEM = "ON";
const char OFFRESP[] PROGMEM = "OFF";
const char BUSYRESP[] PROGMEM = "BUSY";
const char OPENPARAM[] PROGMEM = "OPEN";
const char CLOSEPARAM[] PROGMEM = "CLOSE";

#endif
