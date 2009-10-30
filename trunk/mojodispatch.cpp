extern "C" {
    #include <stdlib.h>
}

#include "WProgram.h"
#include "mojo.h"
#include "mojodispatch.h"
#include <inttypes.h>
#include <string.h>
#include "HardwareSerial.h"  //Remove me after debug
#include "mojoresponses.h"

Callback callbacks[MAXCMDS];

void addCallback(const char *callbackName, CALLBACKFXN f) {
    static int index = 0;
    if (index >= MAXCMDS) return;
    callbacks[index].setCallbackName(callbackName);    
    callbacks[index].setFxn(f); 
    #ifdef DEBUG
    Serial.print("Add Callback:");
    Serial.println(callbackName);
    #endif
    index++;
}

void msgDispatch( Message *msg) {
    Command *c;
    while((c = msg->getCmd())) {
        cmdDispatch(c);
    }
    
}


void cmdDispatch( Command *cmd ) {
    for (int cbIndex = 0; cbIndex < MAXCMDS;cbIndex++) {
        if (callbacks[cbIndex].forMe(*cmd)) {
            callbacks[cbIndex].callFxn(*cmd);
            return;
        }
    }
    #ifdef DEBUG
    Serial.print("Not found:");
    Serial.println(cmd->getCmd());
    #endif
    cmd->setReply(BADCMD);
}

Callback::Callback() {
    init();
}

int Callback::forMe(Command &cmd) {
    #ifdef DEBUG
    Serial.print("CMD:");
    Serial.print(cmd.getCmd());
    Serial.print("- CBNAME:");
    Serial.println(callbackName);
    #endif
    if (strcmp(cmd.getCmd(),callbackName) == 0)
        return true;
    else 
        return false;
}

void Callback::init() {
    strcpy(callbackName,"None");
    callbackfxn = NULL;
}

CALLBACKFXN Callback::getFxn() {
    return callbackfxn;
}

void Callback::setFxn(CALLBACKFXN fxn) {
    callbackfxn = fxn;
}

void Callback::setCallbackName(const char *cbname) {
    strcpy(callbackName, cbname);
}

void Callback::callFxn(Command &cmd) {
    #ifdef DEBUG
    Serial.print("Found:");
    Serial.println(callbackName);
    #endif
    callbackfxn(cmd);
}



