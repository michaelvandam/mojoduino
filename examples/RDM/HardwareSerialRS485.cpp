#include <stdio.h>
#include <string.h>
#include <inttypes.h>
#include "wiring.h"
#include "wiring_private.h"

#include "HardwareSerial.h"
#include "HardwareSerialRS485.h"

HardwareSerialRS485::HardwareSerialRS485(ring_buffer *rx_buffer,
  volatile uint8_t *ubrrh, volatile uint8_t *ubrrl,
  volatile uint8_t *ucsra, volatile uint8_t *ucsrb,
  volatile uint8_t *udr,
  uint8_t rxen, uint8_t txen, uint8_t rxcie, uint8_t udre, uint8_t u2x, uint8_t txc):
  
  HardwareSerial(rx_buffer,
  ubrrh, ubrrl,
  ucsra, ucsrb,
  udr,
  rxen, txen, rxcie,udre,u2x) {
  
    _txc = txc;
  }
  
  
  
void HardwareSerialRS485::write(const char *str)
{
  digitalWrite(_pin,HIGH);
  while (*str)
    write(*str++);
  //while (( *_ucsra & (1<<_udre))==0 );
  while(!(*_ucsra & (1 << _txc)));
  //delayMicroseconds(5000);
  digitalWrite(_pin,LOW);
  
}


//default implementation: may be overridden 
void HardwareSerialRS485::write(const uint8_t *buffer, size_t size)
{
  digitalWrite(_pin,HIGH);
  while (size--)
    write(*buffer++);
  while ((*_ucsra & (1 << _txc)) == 0) {};
  digitalWrite(_pin,LOW);
}

void HardwareSerialRS485::setControlPin(int pin) {
    _pin = pin;
    pinMode(_pin,OUTPUT);
    digitalWrite(_pin,LOW);
}


void HardwareSerialRS485::begin(long baud,  int pin) {  
    HardwareSerial::begin(baud);
    _pin = pin;
    pinMode(_pin,OUTPUT);
    digitalWrite(_pin,LOW);
}


// Preinstantiate Objects //////////////////////////////////////////////////////

#if defined(__AVR_ATmega8__)
HardwareSerialRS485 SerialRS485(&rx_buffer, &UBRRH, &UBRRL, &UCSRA, &UCSRB, &UDR, RXEN, TXEN, RXCIE, UDRE, U2X,TXC);
#else
HardwareSerialRS485 SerialRS485(&rx_buffer, &UBRR0H, &UBRR0L, &UCSR0A, &UCSR0B, &UDR0, RXEN0, TXEN0, RXCIE0, UDRE0, U2X0, TXC0);
#endif

#if defined(__AVR_ATmega1280__)
HardwareSerialRS485 Serial1RS485(&rx_buffer1, &UBRR1H, &UBRR1L, &UCSR1A, &UCSR1B, &UDR1, RXEN1, TXEN1, RXCIE1, UDRE1, U2X1, TXC1);
HardwareSerialRS485 Serial2RS485(&rx_buffer2, &UBRR2H, &UBRR2L, &UCSR2A, &UCSR2B, &UDR2, RXEN2, TXEN2, RXCIE2, UDRE2, U2X2, TXC2);
HardwareSerialRS485 Serial3RS485(&rx_buffer3, &UBRR3H, &UBRR3L, &UCSR3A, &UCSR3B, &UDR3, RXEN3, TXEN3, RXCIE3, UDRE3, U2X3, TXC3);
#endif
