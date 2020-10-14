//test bleep
#include <Arduino.h>
const int SOUNDER = 13;  // bleeper output GPIO

void bleep(){

    
    digitalWrite(SOUNDER, HIGH);
    delay(500);
    digitalWrite(SOUNDER, LOW);
    delay (100);
    digitalWrite(SOUNDER, HIGH);
    delay(500);
    digitalWrite(SOUNDER, LOW);
    delay (100);

}