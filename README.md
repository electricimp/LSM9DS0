# Driver for the LSM9DS0 Inertial Measurement Unit

Author: [Tom Byrne](https://github.com/ersatzavian/)

The [LSM9DS0](http://www.adafruit.com/datasheets/LSM9DS0.pdf) is a MEMS inertial measurement unit (accelerometer plus magnetometer plus angular rate sensor). This sensor has extensive functionality and this class has not yet implemented all of it.

The LSM9DS0 can interface over I&sup2;C or SPI. This class addresses only I&sup2;C for the time being.

The LSM9DS0 has two separate I&sup2;C sub-addresses: one for the gyroscope and one for the accelerometer/magnetometer. All three functional blocks can be enabled or disabled separately.

## Class Usage

### Constructor

The class’ constructor takes one required parameter (a configured imp I&sup2;C bus) and three optional parameters:

| Parameter     | Type         | Default | Description |
| ------------- | ------------ | ------- | ----------- |
| i2cBus        | hardware.i2c | N/A     | A pre-configured I&sup2;C bus |
| enableAll     | boolean      | true    | True if you want to enable gyro, accel, mag, and temp at constructor time |
| i2cAccellAddr | byte         | 0x3C    | The I&sup2;C address of the accelerometer |
| i2cGyroAddr   | byte         | 0xD4    | The I&sup2;C address of the gyro |


```
i2c <- hardware.i2c89.configure(CLOCK_SPEED_400_KHZ)
imu <- LSM9DS0(i2c)
```

### Class Methods

### enableTemp(*state*)

Enables (*state* = 1) or disables (*state* = 0) the temperature sensor inside the LSM9DS0.

```
imu.enableTemp(1)    // Enable temperature sensor
```

### enableAccel(*state*)

Enables (*state* = 1) or disables (*state* = 0) the LSM9DS0’s accelerometer.

```
imu.enableAccel(0)    // Disable accelerometer
```

### enableGyro(*state*)

Enables (*state* = 1) or disables (*state* = 0) the LSM9DS0’s gyroscope.

```
imu.enableGyro(0)    // Disable gyroscope
```

### enableMag(*state*)

Enables (*state* = 1) or disables (*state* = 0) the LSM9DS0’s magnetometer.

```
imu.enableMag(1)    // Enable magnetometer
```

### readTemp()

Reads and returns the current internal temperature of the IC in degrees Celsius. You should noted that running the gyroscope will significantly increase the internal temperature of the IC.

```
server.log(imu.readTemp() + "C")    // Log degrees Celsius
```

### readAccel()

Reads and returns the current state of the accelerometer as a table: `{ x: <xData>, y: <yData>, z: <zData> }`

```
local accel = imu.readAccel()
server.log("X axis: " + accel.x)
server.log("Y axis: " + accel.y)
server.log("Y axis: " + accel.z)
```

### readGyro()

Reads and returns the current state of the gyroscope as a table: `{ x: <xData>, y: <yData>, z: <zData> }`

```
local gyro = imu.readGyro()
server.log("X axis: " + gyro.x)
server.log("Y axis: " + gyro.y)
server.log("Y axis: " + gyro.z)
```

### readMag()

Reads and returns the current state of the magnetometer as a table: `{ x: <xData>, y: <yData>, z: <zData> }`

```
local mag = imu.readMag();
server.log("X axis: " + mag.x);
server.log("Y axis: " + mag.y);
server.log("Y axis: " + mag.z);
```

## License

The LSM9DS0TR class is licensed under [MIT License](./LICENSE).
