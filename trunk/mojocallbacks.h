#ifndef Mojocallbacks_h
#define Mojocallbacks_h

void id( Command &cmd );

void baud( Command &cmd );

void savebaud( Command &cmd );

void who( Command &cmd );

void annc( Command &cmd );

void setupDefaultCallbacks();

#endif
