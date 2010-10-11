


#ifndef PRESSREG_h
#define PRESSREG_h
#endif

#include "MultiDAC.h"

#define DACADDR0    0x41
#define DACADDR1    0x51

enum {  AP0,
        AP1,
        AP2,
        AP3,
        AP4,
        AP5,
        AP6,
        AP7,
        AP8,
        AP9,
        AP10,
        AP11,
        AP12,
        AP13,
        AP14,
        AP15
    };

class PressureRegulator{
  public:
    PressureRegulator(); 				
    void setValue(char output, unsigned int value);
    
  private:
    MultiDAC DAC1;
    MultiDAC DAC2;
    struct Pin {
        *MultiDAC multidac;
        char outputpin;
    };
    
    Pin pins[16];
    
};

#endif