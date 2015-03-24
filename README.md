# Driver for the LSM9DS0 Inertial Measurement Unit

Author: [Tom Byrne](https://github.com/ersatzavian/)

The [LSM9DS0](http://www.adafruit.com/datasheets/LSM9DS0.pdf) is a MEMS inertial measurement unit (accelerometer plus magnetometer plus angular rate sensor). This sensor has extensive functionality and this class has not yet implemented all of it.

The LSM9DS0 can interface over I&sup2;C or SPI. This class addresses only I&sup2;C for the time being.

The LSM9DS0 has two separate I&sup2;C sub-addresses: one for the gyroscope and one for the accelerometer/magnetometer. Each functional block can be enabled or disabled separately.

## Class Usage

### Constructor

The class’ constructor takes one required parameter (a configured imp I&sup2;C bus) and two optional parameters:

| Parameter     | Type         | Default | Description |
| ------------- | ------------ | ------- | ----------- |
| i2cBus        | hardware.i2c | N/A     | A pre-configured I&sup2;C bus |
| i2cAccellAddr | byte         | 0x3A    | The I&sup2;C address of the accelerometer/magnetometer |
| i2cGyroAddr   | byte         | 0xD4    | The I&sup2;C address of the angular rate sensor ("gyro") |


```Squirrel
i2c <- hardware.i2c89.configure(CLOCK_SPEED_400_KHZ);
imu <- LSM9DS0(i2c);
```

### Enabling and Reading Data

The LSM9DS0 comes out of reset with all functional blocks disabled. To read data from any of the sensors, they must first be enabled. 

```Squirrel
// Enable the gyro in all axes
imu.setPowerState_G(1);
// Enable Accelerometer in all axes
imu.setEnable_A(1);
// Enable the Magnetometer by setting the ODR to a non-zero value
imu.setDatarate_M(50); // 50 Hz
imu.setModeCont_M(); // enable continuous measurement

// Now read everything
local acc = imu.getAccel();
local mag = imu.getMag();
local gyr = imu.getGyro();
server.log(format("Accel: (%0.2f, %0.2f, %0.2f)", acc.x, acc.y, acc.z));
server.log(format("Mag:   (%0.2f, %0.2f, %0.2f)", mag.x, mag.y, mag.z));
server.log(format("Gyro:  (%0.2f, %0.2f, %0.2f)", gyr.x, gyr.y, gyr.z));
server.log(format("Temp: %dºC", imu.getTemp()));
```

### Using Interrupts

The LSM9DS0 has four interrupt lines:

* G_DRDY: Data Ready on Gyro 
* G_INT: Configurable Gyro Interrupt
* XM_INT1: Configurable Accelerometer / Magnetometer Interrupt 1
* XM_INT2: Configurable Accelerometer / Magnetometer Interrupt 2

All interrupts can be configured as Push-pull or open drain, and can can be set to either active-high or active-low. XM_INT1 and XM_INT2 have completely overlapping functionality; anything that one can do, the other can also do.

#### Gyro Data Ready

Used primarily when using the gyro's on-board FIFO to gather bursts of data.

```Squirrel
function myGyroDrdyCallback() {
	if (g_drdy.read()) {
		server.log("Data Ready on Gyro");
		// disable Gyro Data Ready
		imu.setIntDrdy_G(0);
	}
}

g_drdy      <- hardware.pin5; // angular rate Data Ready
g_drdy.configure(DIGITAL_IN, myGyroDrdyCallback);

// enable data ready line
imu.setDrdyEnable_G(1);
```

#### Gyro Interrupt

```Squirrel
function myGyroIntCallback() {
	if (g_int.read()) {
		server.log("Interrupt on Gyro");
		// read interrupt source to clear latched interrupt
		imu.getIntSrc_G();
	}
}

g_int       <- hardware.pin7; // angular rate Interrupt
g_int.configure(DIGITAL_IN, myGyroIntCallback);

// enable gyro interrupt
imu.setIntEnable_G(1);
// set active-high
imu.setIntActivehigh_G();
// interrupt is push-pull by default
// enable interrupt latch
imu.setIntLatchEn_G(1);
// Set threshold for each axis to one-half of full scale
// threshold value is in absolute value
imu.setIntThs_G(16000, 16000, 16000);
// throw interrupt if one reading is over threshold
imu.setIntDuration_G(1);
```

#### Accelerometer / Magnetometer Interrupt

The accelerometer and magnetometer can generate interrupts on a long list of configurable events. See the class methods list for more interrupt sources including tap detection, click detection, free-fall detection, and others.

```Squirrel
// quality pun here
function myAccelIntCallback() {
	if (xm_int1.read()) {
		server.log("Interrupt on XM_INT1");
		// clear latched interrupt
		imu.getInt1Src_XM();
	}
}

xm_int1     <- hardware.pin2; // accel / magnetometer interrupt 1
xm_int1.configure(DIGITAL_IN, myAccelIntCallback);

// Enable inertial interrupt generator 1 on all axes
// Route inertial interrupt generator 1 to Interrupt Pin 1
imu.setInertInt1En_P1(1);
// active high
imu.setIntActivehigh_XM();
// latch
imu.setIntLatch_XM(1);
// enable interrupt 1 on over-threshold on any axis
imu.setInt1Duration_A(1);
// default full scale is 2G; this sets the threshold to 1G
imu.setInt1Ths_A(16000);
```

### All Class Methods

#### getGyro()
Reads and returns the latest measurement from the gyro as a table: `{ x: <xData>, y: <yData>, z: <zData> }`

```Squirrel
local gyro = imu.readGyro()
server.log("X axis: " + gyro.x)
server.log("Y axis: " + gyro.y)
server.log("Y axis: " + gyro.z)
```

#### getMag()
Reads and returns the latest measurement from the magnetometer as a table: `{ x: <xData>, y: <yData>, z: <zData> }`

```Squirrel 
local mag = imu.getMag();
server.log("X axis: " + mag.x);
server.log("Y axis: " + mag.y);
server.log("Y axis: " + mag.z);
```

#### getAccel()
Reads and returns the latest measurement from the accelerometer as a table: `{ x: <xData>, y: <yData>, z: <zData> }`

```Squirrel
local accel = imu.getAccel()
server.log("X axis: " + accel.x)
server.log("Y axis: " + accel.y)
server.log("Y axis: " + accel.z)
```

#### getTemp()
Reads and returns the latest measurement from the temperature sensor in degrees Celsius
```Squirrel
server.log(imu.getTemp() + "C")    // Log degrees Celsius
```

#### getDeviceId_G()
Returns the 1-byte device ID of the angular rate sensor (from the WHO_AM_I_G register).

```Squirrel
server.log(format("Gyro Device ID: 0x%02X", imu.getDeviceId_G()));
```

#### setPowerState_G(*state*)
Set the power state for the entire angular rate sensor (all three axes at once). Pass in TRUE to enable the Gyro.

#### setIntActivelow_G()
Set G_INT line active low. See example in "using interrupts" section above.

G_INT is active-high by default.

#### setIntActivehigh_G()
Set G_INT line active active high. See example in "using interrupts" section above.

G_INT is active-high by default.

#### setIntOpendrain_G()
Set G_INT line to open-drain drive. See example in "using interrupts" section above. 

G_INT is push-pull by default.

#### setIntPushpull_G()
Set G_INT line to push-pull drive. See example in "using interrupts" section above. 

G_INT is push-pull by default.

#### setDrdyEnable_G(*state*)
Enable/Disable Data Ready interrupt line for Gyro. Pass in TRUE to enable Data Ready line.

#### setIntEnable_G(*state*)
Enable/disable hardware interrupts on G_INT pin. Pass in TRUE to enable interrupts on the G_INT line. See example in "using interrupts" section above.

Enabling interrupts in the Gyro enables interrupts on all three axes in both the positive and negative directions. All six of these interrupts (each axis over threshold or under negative axis) can be individually configured by extending this library.

#### setIntLatchEn_G(*state*)
Enable/Disable interrupt request latching for gyro. If enabled, interrupts will persist until cleared by calling getIntSrc_G(). See the example in "using interrupts" above.

#### setIntDuration_G(*numsamples*)
Set the number of samples that must be measured over the threshold before throwing an interrupt.

#### setIntThs_G(*ths_x*, *ths_y*, *ths_z*)
Set the absolute value threshold for angular rate interrupts in each axis. Thesholds are given as integers and compared to full-scale. For example, the default full-scale range of the gyro is 245 degrees per second, corresponding to a value of +/-32000. To set the threshold to 125.5 degrees per second in either the positive or negative direction about Z:

```Squirrel
// enable interrupt
imu.setIntEnable_G(1);
// set active-high
imu.setIntActivehigh_G();
// throw interrupt after just one sample is over threshold
imu.setIntDuration_G(1);
// set threshold to 125.5 degrees per second about Z
imu.setIntThs_G(0,0, 16000);
```

#### getIntSrc_G() 
Returns the INT1_SRC_G register contents as an integer to allow the caller to determine why an interrupt was thrown. Reading INT1_SRC_G also clears any latched interrupts. See example in "using interrupts" section above.

#### setHpfEn_G(*state*) 
Enable/Disable the internal High-Pass Filter on the Gyro. Pass in TRUE to enable the HPF.

#### getDeviceId_XM()
Returns the 1-byte device ID of the accelerometer/magnetometer (from the WHO_AM_I_XM register).

```Squirrel
server.log(format("Accel/Mag Device ID: 0x%02X", imu.getDeviceId_XM()));
```

#### getStatus_M() 
Returns the 1-byte contents of the magnetometer's status register (STATUS_REG_M).

```Squirrel
server.log(format("Magnetometer Status: 0x%02X", imu.getStatus_M()));
```

#### setModeCont_M()
Place the magnetometer in continuous-measurement mode. Magnetometer is disabled by default. Note that the default data rate for the magnetometer is zero, so to get continuous measurements, a non-zero datarate must also be set.

```Squirrel
// take continuous measurements at 50 Hz
imu.setModeCont_M();
imu.setDatarate_M(50); 
```

#### setDatarate_M(*rate_Hz*) 
Set the data rate for continuous measurements from the Magnetometer. The closest datarate greater than or equal to the requested rate will be selected. Supported datarates are 3.125 Hz, 6.25 Hz, 12.5 Hz, 25 Hz, 50 Hz, and 100 Hz. 

#### setModeSingle_M()
Place the magnetometer in single-conversion mode. Will take measurements only when requested.

#### setModePowerDown_M()
Place the magnetometer in power-down mode. 

#### setIntEn_M(*state*)
Enable/Disable Interrupt Generation from the Magnetometer. Pass in TRUE to enable. Note that the desired axes must also be explicitly enabled, and the interrupt source routed to one of the interrupt pins in order to observe a hardware interrupt.

```Squirrel
imu.setIntEn_M(1);
// enable interrupts from magnetometer in all three axes
imu.setIntEn_M(1);
// route magnetometer interrupts to XM_INT1 pin
imu.setMagIntEn_P1(1);
```

#### setIntActivehigh_XM()
Set XM interrupt pins to active high. See example in "using interrupts" section above.

XM interrupt pins are active-low by default.

#### setIntActivelow_XM()
Set XM interrupt pins to active low. See example in "using interrupts" section above.

XM interrupt pins are active-low by default.

#### setIntOpendrain_XM()
Set XM interrupt driver to open-drain. See example in "using interrupts" section above.

XM interrupt drivers are push-pull by default.

#### setIntPushpull_XM()
Set XM interrupt driver to push-pull. See example in "using interrupts" section above.

XM interrupt drivers are push-pull by default.

#### setIntLatch_XM(*state*)
Set TRUE to latch interrupt requests for either of the XM interrupt sources. This globally latches interrupt requests; to clear a latched interrupt, call getInt1Src_XM(), getInt2Src_XM(), and getIntSrc_M().

#### setInt1LatchEn_XM(*state*)
Set TRUE to latch interrupt requests for XM_INT1. To clear a latched interrupt, call getInt1Src_XM();

#### setInt2LatchEn_XM(*state*)
Set TRUE to latch interrupt requests for XM_INT2. To clear a latched interrupt, call getInt2Src_XM();

#### getIntSrc_M()
Read the magnetometer's interrupt source register to determine what caused an interrupt. 

#### getInt1Src_XM()
Returns the contents of the INT_GEN_1_SRC register as an integer and clears latched interrupts on XM_INT1.

#### getInt2Src_XM()
Returns the contents of the INT_GEN_2_SRC register as an integer and clears latched interrupts on XM_INT2.

#### setIntThs_M(*threshold*)
Set the absolute value threshold for magnetometer interrupts in any axis. Thesholds are given as integers and compared to full-scale. For example, the default full-scale range of the magnetometer is +/- 4 gauss, corresponding to a value of +/-32000. To set the threshold to +/- 2 gauss.

```Squirrel
// enable magnetometer
imu.setModeContinuous_M();
imu.setDatarate_M(50);
// enable interrupt
imu.setIntEn_M(1);
// set active-high
imu.setIntActivehigh_G();
// throw interrupt on angular rate over threshold in either direction
imu.setIntThs_M(16000);
```

#### setHpfClick_XM(*state*)
Enable/Disable internal high-pass filter on click detection.

#### setHpfInt1_XM(*state*)
Enable/Disable internal high-pass filter on inertial interrupt generator 1.

#### setHpfInt2_XM(*state*)
Enable/Disable internal high-pass filter on inertial interrupt generator 2. 

#### setEnable_A(*state*)
Enable/Disable the Accelerometer in all axes.

Acclerometer axes can be enabled/disabled individually by extending this class.

#### setDatarate_A(*rate_Hz*)
Set the data rate for continuous measurements from the Accelerometer. The closest datarate greater than or equal to the requested rate will be selected. Supported datarates are 3.125 Hz, 6.25 Hz, 12.5 Hz, 25 Hz, 50 Hz, 100 Hz, 200 Hz, 400 Hz, 800 Hz, and 1600 Hz. 

The device comes out of reset with the accelerometer disabled. The default data rate when the accelerometer is enabled is 3.125 Hz.

#### setTapIntEn_P1(*state*)
Enable/Disable Tap Detection Interrupt on XM_INT1 Pin. Pass in TRUE to enable interrupts on Tap detect. 

#### setInertInt1En_P1(*state*) 
Enable/Disable inertial interrupt generator 1 on XM_INT1 Pin. Inertial interrupts will be thrown when acceleration values are over/under thresholds for their respective axes, if enabled.

Note that there are two seperate interrupt generators and two separate interrupt pins. Either generator can be routed to either pin. Generators are configured separately.  

#### setInertInt2En_P1(*state*)
Enable/Disable inertial interrupt generator 2 on XM_INT1 Pin.

#### setMagIntEn_P1(*state*)
Enable/Disable magnetometer interrupt generator in XM_INT1 Pin. 

#### setAccelDrdyIntEn_P1(*state*)
Enable/Disable accelerometer Data Ready Interrupts on XM_INT1 Pin. 

#### setMagDrdyIntEn_P1(*state*)
Enable/Disable magnetometer Data Ready Interrupts on XM_INT1 Pin.

#### setInertInt1En_P2(*state*)
Enable/Disable inertial interrupt generator 1 on XM_INT2 Pin.

#### setInertInt2En_P2(*state*)
Enable/Disable inertial interrupt generator 2 on XM_INT2 Pin. 

#### setMagIntEn_P2(*state*)
Enable/Disable magnetometer interrupt on XM_INT2 Pin. 

#### setAccelDrdyIntEn_P2(*state*)
Enable/Disable interrupt on accelerometer data ready on XM_INT2 Pin. 

#### setMagDrdyIntEn_P2(*state*)
Enable/Disable interrupt on magnetometer data readon XM_INT2 Pin. 

#### getStatus_A()
Returns the contents of STATUS_REG_A as an integer.

#### setInt1Ths_A(*threshold*) 
Set the absolute value threshold for inertial interrupt generator 1 in any axis. Thesholds are given as integers and compared to full-scale. For example, the default full-scale range of the accelerometer is +/- 2 G, corresponding to a value of +/-32000. To set the threshold to +/- 1 G:

```Squirrel
// enable accelerometer
imu.setDatarate_A(50);
imu.setEnable_A(1);
// enable inertial interrupts on all axes on interrupt generator 1, routed to XM_INT2 pin
imu.setInertInt1En_P2(1);
// set active-high
imu.setIntActivehigh_XM();
// throw interrupt on 1G in Z
imu.setInt1Ths_A(16000);
```

#### setInt2Ths_A(*threshold*) 
Set the absolute value threshold for inertial interrupt generator 1 in any axis.

#### setInt1Duration_A(*numsamples*)
Set the number of samples that must be measured over the threshold before throwing an interrupt on generator 1.

#### setInt2Duration_A(*numsamples*)
Set the number of samples that must be measured over the threshold before throwing an interrupt on generator 2.

#### setTempEn(*state*)
Enable/Disable onboard temperature sensor. Note that the temperature on-die may be several degrees different from ambient temperature. In bare-board testing, enabling the gyro increased the value returned by the on-die temperature sensor by over 6&deg;C.

#### setSnglclickIntEn(*state*)
Enable/Disable double-click interrupts. Single- and double-click interrupts can be enabled and disabled on each individual axis by extending this class. Click interrupts can be detected in each individual axis and direction by extending this class.

#### setDblclickIntEn(*state*)
Enable/Disable double-click interrupts.

#### setClickDetThs(*threshold*) 
Set the Click Detection Threshold relative to full-scale values on the accelerometer (+/- 32000).

#### clickIntActive()
Returns TRUE if a click interrupt is active.

#### snglclickDet()
Returns TRUE if a single-click interrupt is active.

#### dblclickDet()
Returns TRUE if a double-click interrupt is active. 


## License

The LSM9DS0TR class is licensed under [MIT License](./LICENSE).
