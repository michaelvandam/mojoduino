// Pressure Regulation Parameters
#include "wiring.h"
#include "PressureRegulator.h"
#include "MultiDAC.h"

PressureRegulators::PressureRegulators(){
    MultiDAC DAC1 = MultiDAC(0x41);
    MultiDAC DAC2 = MultiDAC(0x51);
    
    initPin(pins[AP0], &DAC1, 1);
    initPin(pins[AP1], &DAC1, 2);
    initPin(pins[AP2], &DAC1, 3);
    initPin(pins[AP3], &DAC1, 4);
    initPin(pins[AP4], &DAC1, 5);
    initPin(pins[AP5], &DAC1, 6);
    initPin(pins[AP6], &DAC1, 7);
    initPin(pins[AP7], &DAC1, 8);
    initPin(pins[AP8], &DAC2, 9);
    initPin(pins[AP9], &DAC2, 10);
    initPin(pins[AP10], &DAC2, 11);
    initPin(pins[AP11], &DAC2, 12);
    initPin(pins[AP12], &DAC2, 13);
    initPin(pins[AP13], &DAC2, 14);
    initPin(pins[AP14], &DAC2, 15);
    initPin(pins[AP15], &DAC2, 16);

}

void PressureRegulators::initPin( Pin pin, MultiDAC *dac, char outputpin) {
    pin.multidac = dac;
    pin.outputpin = outputpin;
}

void PressureRegulators::setValue(char output, unsigned int value){
    pins[output].multidac->outputs[pins[output].outputpin].setValue(value);
}
