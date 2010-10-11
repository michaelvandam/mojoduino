// Pressure Regulation Parameters
#include "wiring.h"
#include "PressureRegulator.h"
#include "MultiDAC.h"

PressureRegulator::PressureRegulator(){
    MultiDAC DAC1 = MultiDAC(0x41);
    MultiDAC DAC2 = MultiDAC(0x51);
    
    
    pins[AP0]  = {&DAC1, 0};
    pins[AP1]  = {&DAC1, 1};
    pins[AP2]  = {&DAC1, 2};
    pins[AP3]  = {&DAC1, 3};
    pins[AP4]  = {&DAC1, 4};
    pins[AP5]  = {&DAC1, 5};
    pins[AP6]  = {&DAC1, 6};
    pins[AP7]  = {&DAC1, 7};
    pins[AP8]  = {&DAC2, 0};
    pins[AP9]  = {&DAC2, 1};
    pins[AP10] = {&DAC2, 2};
    pins[AP11] = {&DAC2, 3};
    pins[AP12] = {&DAC2, 4};
    pins[AP13] = {&DAC2, 5};
    pins[AP14] = {&DAC2, 6};
    pins[AP15] = {&DAC2, 7};
            
}

PressureRegulator::setValue(char output, unsigned int value){
    pin[output].multidac->setValue(value);
}
