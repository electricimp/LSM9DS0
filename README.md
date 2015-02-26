Driver for the LSM9DS0 Inertial Measurement Unit
===================================

Author: [Tom Byrne](https://github.com/ersatzavian/)

The [LSM9DS0](http://www.adafruit.com/datasheets/LSM9DS0.pdf) is a MEMS Inertial Measurement Unit (Accelerometer + Magnetometer + Angular Rate Sensor). This sensor has extensive functionality and this class has not implemented all of it.

The LSM9DS0 can interface over I2C or SPI. This class addresses only I2C for the time being.

The LSM9DS0 has two separate I2C Student addresses: one for the Gyroscope and one for the Accelerometer/Magnetometer. All three functional blocks can be enabled or disabled separately.

## Usage

## constructor(i2cBus, [enableAll], [i2cAccelAddress], [i2cGyroAddress])
The constructor takes one required parameter, and three optional parameters:

| Parameter     | Type         | Default | Description |
| ------------- | ------------ | ------- | ----------- |
| i2cBus        | hardware.i2c | N/A     | A pre-configured I2C bus |
| enableAll     | boolean      | true    | True if you want to enable gyro, accel, mag, and temp at constructor time |
| i2cAccellAddr | byte         | 0x3C    | The I2C address of the accelerometer |
| i2cGyroAddr   | byte         | 0xD4    | The I2C address of the gyro |


```
hardware.i2c89.configure(CLOCK_SPEED_400_KHZ);
imu <- LSM9DS0(hardware.i2c89);
```

## enableTemp(state)
Enables (when state = 1) or disables (when state = 0) the temperature sensor inside the IC.

```
imu.enableTemp(1);  // disable temperature sensor
```

## enableAccel(state)
Enables (when state = 1) or disables (when state = 0) the accelerometer inside the IC.

```
imu.enableAccel(0);  // disable accelerometer
```

## enableGyro(state)
Enables (when state = 1) or disables (when state = 0) the gyroscope inside the IC.

```
imu.enableGyro(0);  // disable gyroscope
```

## enableMag(state)
Enables (when state = 1) or disables (when state = 0) the magnetometer inside the IC.

```
imu.enableMag(0);  // disable magnetometer
```

## readTemp()
Reads and returns the current internal temperature of the IC in degrees celsius (note: running the gyroscope will significantly increase the internal temperature of the IC)

```
server.log(imu.readTemp() "C"); // log degrees celsius
```

## readAccel()
Reads and returns the current state of the accelerometer as a table: { x: <xData>, y: <yData>, z: <zData> }:

```
local accel = imu.readAccel();
server.log("X axis: " + accel.x);
server.log("Y axis: " + accel.y);
server.log("Y axis: " + accel.z);
```

## readGyro()
Reads and returns the current state of the accelerometer as a table: { x: <xData>, y: <yData>, z: <zData> }:

```
local accel = imu.readAccel();
server.log("X axis: " + accel.x);
server.log("Y axis: " + accel.y);
server.log("Y axis: " + accel.z);
```

## readMag()
Reads and returns the current state of the magnetometer as a table: { x: <xData>, y: <yData>, z: <zData> }:

```
local mag = imu.readMag();
server.log("X axis: " + mag.x);
server.log("Y axis: " + mag.y);
server.log("Y axis: " + mag.z);
```

# License
The LSM9DS0TR class is licensed under [MIT License](./LICENSE).
