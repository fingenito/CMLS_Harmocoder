/*****************************************************************************/
//	Function:    Get the accelemeter of X/Y/Z axis and print out on the
//					serial monitor.
//  Hardware:    3-Axis Digital Accelerometer(��16g)
//	Arduino IDE: Arduino-1.0
//	Author:	 Frankie.Chu
//	Date: 	 Jan 11,2013
//	Version: v1.0
//	by www.seeedstudio.com
//
//  This library is free software; you can redistribute it and/or
//  modify it under the terms of the GNU Lesser General Public
//  License as published by the Free Software Foundation; either
//  version 2.1 of the License, or (at your option) any later version.
//
//  This library is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with this library; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//
/*******************************************************************************/

#include <Wire.h>
#include <ADXL345.h>


ADXL345 adxl;  //variable adxl is an instance of the ADXL345 library

unsigned long startTimerY;
bool flagUpY = false;
bool flagDownY = false;

bool flagUpZ = false;
bool flagDownZ = false;
unsigned long startTimerZ;

int maxTreshY = 1.3;
int minTreshY = -maxTreshY;

// add 1 because on Z we have gravity and so is steady at 1
int maxTreshZ = maxTreshY + 0.5;
int minTreshZ = minTreshY + 1;

float sensorValues[3];

void setup() {
  Serial.begin(9600);
  adxl.powerOn();

  //set activity/ inactivity thresholds (0-255)
  adxl.setActivityThreshold(75);    //62.5mg per increment
  adxl.setInactivityThreshold(75);  //62.5mg per increment
  adxl.setTimeInactivity(10);       // how many seconds of no activity is inactive?

  //look of activity movement on this axes - 1 == on; 0 == off
  adxl.setActivityX(1);
  adxl.setActivityY(1);
  adxl.setActivityZ(1);

  //look of inactivity movement on this axes - 1 == on; 0 == off
  adxl.setInactivityX(1);
  adxl.setInactivityY(1);
  adxl.setInactivityZ(1);

  //look of tap movement on this axes - 1 == on; 0 == off
  adxl.setTapDetectionOnX(0);
  adxl.setTapDetectionOnY(0);
  adxl.setTapDetectionOnZ(1);

  //set values for what is a tap, and what is a double tap (0-255)
  adxl.setTapThreshold(50);      //62.5mg per increment
  adxl.setTapDuration(15);       //625us per increment
  adxl.setDoubleTapLatency(80);  //1.25ms per increment
  adxl.setDoubleTapWindow(200);  //1.25ms per increment

  //set values for what is considered freefall (0-255)
  adxl.setFreeFallThreshold(7);  //(5 - 9) recommended - 62.5mg per increment
  adxl.setFreeFallDuration(45);  //(20 - 70) recommended - 5ms per increment

  //setting all interrupts to take place on int pin 1
  //I had issues with int pin 2, was unable to reset it
  adxl.setInterruptMapping(ADXL345_INT_SINGLE_TAP_BIT, ADXL345_INT1_PIN);
  adxl.setInterruptMapping(ADXL345_INT_DOUBLE_TAP_BIT, ADXL345_INT1_PIN);
  adxl.setInterruptMapping(ADXL345_INT_FREE_FALL_BIT, ADXL345_INT1_PIN);
  adxl.setInterruptMapping(ADXL345_INT_ACTIVITY_BIT, ADXL345_INT1_PIN);
  adxl.setInterruptMapping(ADXL345_INT_INACTIVITY_BIT, ADXL345_INT1_PIN);

  //register interrupt actions - 1 == on; 0 == off
  adxl.setInterrupt(ADXL345_INT_SINGLE_TAP_BIT, 1);
  adxl.setInterrupt(ADXL345_INT_DOUBLE_TAP_BIT, 1);
  adxl.setInterrupt(ADXL345_INT_FREE_FALL_BIT, 1);
  adxl.setInterrupt(ADXL345_INT_ACTIVITY_BIT, 1);
  adxl.setInterrupt(ADXL345_INT_INACTIVITY_BIT, 1);

  // initialize array to 0
  for (int i = 0; i<3; i++) {
    sensorValues[i] = 0.0;
  }
}

void loop() {

  
  
  // adding grayVal 
  sensorValues[0] = analogRead(A1);

  double xyz[3];
  double ax, ay, az;
  adxl.getAcceleration(xyz);
  ax = xyz[0];
  ay = xyz[1];
  az = xyz[2];



  // PRINT Y VALUES
  // Serial.print("ay:");
  // Serial.print(ay);
  // Serial.print(" ");
  // Serial.print("max:");
  // Serial.print(4);
  // Serial.print(" ");
  // Serial.print("min:");
  // Serial.print(-4);
  // Serial.println("");

  // PRINT Z VALUES
  // Serial.print("az:");
  // Serial.print(az);
  // Serial.print(" ");
  // Serial.print("max:");
  // Serial.print(4);
  // Serial.print(" ");
  // Serial.print("min:");
  // Serial.print(-4);
  // Serial.println("");



  // CONSIDERING Y DIRECTION----------------------------------------
  // form left to right 

  if (ay < minTreshY) {
    startTimerY = millis();
    flagDownY = true;
  }

  if (flagDownY && ay > maxTreshY) {
    //Serial.print("ON-Y on from left to right\n");
    sensorValues[1] = 1.0;
    startTimerY = millis();
    flagDownY = false;
  }


  if ((millis() - startTimerY) > 250 && flagDownY) {
    startTimerY = millis();
    flagDownY = false;
  }

  // form right to left

  if (ay > maxTreshY) {
    startTimerY = millis();
    flagUpY = true;
  }

  if (flagUpY && ay < minTreshY) {
    //Serial.print("OFF-Y (from right to left)\n");
    sensorValues[1] = 0.0;
    startTimerY = millis();
    flagUpY = false;
  }

  if ((millis() - startTimerY) > 250 && flagUpY) {
    startTimerY = millis();
    flagUpY = false;
  }


  // CONSIDERING Z DIRECTION----------------------------------------
  // form left to right 

  if (az < minTreshZ) {
    startTimerZ = millis();
    flagDownZ = true;
  }

  if (flagDownZ && az > maxTreshZ) {
    //Serial.print("OFF-Z from up to down\n");
    sensorValues[2] = 0.0;
    startTimerZ = millis();
    flagDownZ = false;
  }


  if ((millis() - startTimerZ) > 250 && flagDownZ) {
    startTimerZ = millis();
    flagDownZ = false;
    }

  // form right to left

  if (az > maxTreshZ) {
    startTimerZ = millis();
    flagUpZ = true;
  }

  if (flagUpZ && az < minTreshZ) {
    // Serial.print("ON-Z (form down to up)\n");
    sensorValues[2] = 1.0;
    startTimerZ = millis();
    flagUpZ = false;
  }

  if ((millis() - startTimerZ) > 250 && flagUpZ) {
    startTimerZ = millis();
    flagUpZ = false;
  }

  // create serial output message [grayScale, ]
  Serial.println(String(sensorValues[0]) + ", " + String(sensorValues[1]) + ", " + String(sensorValues[2]));

  delay(20);
}