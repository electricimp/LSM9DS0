// Copyright (c) 2014 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

class LSM9DS0TR {
    static CTRL_REG1_G      = 0x20;

    static OUT_X_L_G        = 0x28;
    static OUT_X_H_G        = 0x29;
    static OUT_Y_L_G        = 0x2A;
    static OUT_Y_H_G        = 0x2B;
    static OUT_Z_L_G        = 0x2C;
    static OUT_Z_H_G        = 0x2D;

    static OUT_TEMP_L_XM    = 0x05;
    static OUT_TEMP_H_XM    = 0x06;

    static OUT_X_L_M        = 0x08;
    static OUT_X_H_M        = 0x09;
    static OUT_Y_L_M        = 0x0A;
    static OUT_Y_H_M        = 0x0B;
    static OUT_Z_L_M        = 0x0C;
    static OUT_Z_H_M        = 0x0D;

    static CTRL_REG0_XM     = 0x1F;
    static CTRL_REG1_XM     = 0x20;
    static CTRL_REG2_XM     = 0x21;
    static CTRL_REG3_XM     = 0x22;
    static CTRL_REG4_XM     = 0x23;
    static CTRL_REG5_XM     = 0x24;
    static CTRL_REG6_XM     = 0x25;
    static CTRL_REG7_XM     = 0x26;
    static STATUS_REG_A     = 0x27;

    static OUT_X_L_A        = 0x28;
    static OUT_X_H_A        = 0x29;
    static OUT_Y_L_A        = 0x2A;
    static OUT_Y_H_A        = 0x2B;
    static OUT_Z_L_A        = 0x2C;
    static OUT_Z_H_A        = 0x2D;

    _i2c        = null;
    _xm_addr    = null;
    _g_addr     = null;

    _temp_enabled = null;

    // -------------------------------------------------------------------------
    // 0x3C = 8-bit I2C Student Address for Accel / Magnetometer
    // 0xD4 = 8-bit I2C Student Address for Angular Rate Sensor
    constructor(i2c, enableAll = true, xm_addr = 0x3C, g_addr = 0xD4) {
        _i2c = i2c;
        _xm_addr = xm_addr;
        _g_addr = g_addr;

        _temp_enabled = false;

        if (enableAll) {
            enableGyro(1);
            enableAccel(1);
            enableMag(1);
            enableTemp(1);
        }
    }

    // set power state of the gyro device
    // note that if individual axes were previously disabled, they still will be
    function enableGyro(state) {
        _setRegBit(_g_addr, CTRL_REG1_G, 3, state);
    }

    // Put magnetometer into continuous-conversion mode
    // IMU comes up with magnetometer powered down
    function enableMag(state) {
        local val = _i2c.read(_xm_addr, format("%c",CTRL_REG7_XM), 1)[0] & 0xFC;
        if (state == 0) val = val | 0x01;

        _i2c.write(_xm_addr, format("%c%c",CTRL_REG7_XM, val));
    }

    // Enable temperature sensor
    function enableTemp(state) {
        _setRegBit(_xm_addr, CTRL_REG5_XM, 7, state);
        if (state == 0) {
            _temp_enabled = false;
        } else {
            _temp_enabled = true;
        }
    }

    // -------------------------------------------------------------------------
    // Set Accelerometer Data Rate in Hz
    // IMU comes up with accelerometer disabled; rate must be set to enable
    function enableAccel(state) {
        local val = _i2c.read(_xm_addr, format("%c",CTRL_REG1_XM), 1)[0] & 0x0F;

        if (state == true) val = val | 0x10;
        _i2c.write(_xm_addr, format("%c%c",CTRL_REG1_XM, val));
    }

    // -------------------------------------------------------------------------
    // Set Magnetometer Data Rate in Hz
    // IMU comes up with magnetometer data rate set to 3.125 Hz
    function setMagDataRate(rate) {
        local val = _i2c.read(_xm_addr, format("%c",CTRL_REG5_XM), 1)[0] & 0xE3;
        if (rate <= 3.125) {
            // rate already set
        } else if (rate <= 6.25) {
            val = val | 0x04;
        } else if (rate <= 12.5) {
            val = val | 0x08;
        } else if (rate <= 25) {
            val = val | 0x0C;
        } else if (rate <= 50) {
            val = val | 0x10;
        } else {
            // rate = 100 Hz
            val = val | 0x14;
        }
        _i2c.write(_xm_addr, format("%c%c",CTRL_REG5_XM, val));
    }

    // -------------------------------------------------------------------------
    // read the internal temperature sensor (C) in the accelerometer / magnetometer
    function readTemp() {
        if (!_temp_enabled) { enableTemp(1) };
        local temp = (_i2c.read(_xm_addr, format("%c", OUT_TEMP_H_XM), 1)[0] << 8) + _i2c.read(_xm_addr, format("%c", OUT_TEMP_L_XM), 1)[0];
        temp = temp & 0x0fff; // temp data is 12 bits, 2's comp, right-justified
        if (temp & 0x0800) {
            return (-1.0) * _twosComp(temp, 0x0fff);
        } else {
            return temp;
        }
    }

    // -------------------------------------------------------------------------
    // Read data from the Gyro
    // Returns a table {x: <data>, y: <data>, z: <data>}
    function readGyro() {
        local x_raw = (_i2c.read(_g_addr, format("%c", OUT_X_H_G), 1)[0] << 8) + _i2c.read(_g_addr, format("%c", OUT_X_L_G), 1)[0];
        local y_raw = (_i2c.read(_g_addr, format("%c", OUT_Y_H_G), 1)[0] << 8) + _i2c.read(_g_addr, format("%c", OUT_Y_L_G), 1)[0];
        local z_raw = (_i2c.read(_g_addr, format("%c", OUT_Z_H_G), 1)[0] << 8) + _i2c.read(_g_addr, format("%c", OUT_Z_L_G), 1)[0];

        local result = {};
        if (x_raw & 0x8000) {
            result.x <- (-1.0) * _twosComp(x_raw, 0xffff);
        } else {
            result.x <- x_raw;
        }

        if (y_raw & 0x8000) {
            result.y <- (-1.0) * _twosComp(y_raw, 0xffff);
        } else {
            result.y <- y_raw;
        }

        if (z_raw & 0x8000) {
            result.z <- (-1.0) * _twosComp(z_raw, 0xffff);
        } else {
            result.z <- z_raw;
        }

        return result;
    }

    // Read data from the Magnetometer
    // Returns a table {x: <data>, y: <data>, z: <data>}
    function readMag() {
        local x_raw = (_i2c.read(_xm_addr, format("%c", OUT_X_H_M), 1)[0] << 8) + _i2c.read(_xm_addr, format("%c", OUT_X_L_M), 1)[0];
        local y_raw = (_i2c.read(_xm_addr, format("%c", OUT_Y_H_M), 1)[0] << 8) + _i2c.read(_xm_addr, format("%c", OUT_Y_L_M), 1)[0];
        local z_raw = (_i2c.read(_xm_addr, format("%c", OUT_Z_H_M), 1)[0] << 8) + _i2c.read(_xm_addr, format("%c", OUT_Z_L_M), 1)[0];

        local result = {};
        if (x_raw & 0x8000) {
            result.x <- (-1.0) * _twosComp(x_raw, 0xffff);
        } else {
            result.x <- x_raw;
        }

        if (y_raw & 0x8000) {
            result.y <- (-1.0) * _twosComp(y_raw, 0xffff);
        } else {
            result.y <- y_raw;
        }

        if (z_raw & 0x8000) {
            result.z <- (-1.0) * _twosComp(z_raw, 0xffff);
        } else {
            result.z <- z_raw;
        }

        return result;
    }

    // Read data from the Accelerometer
    // Returns a table {x: <data>, y: <data>, z: <data>}
    function readAccel() {
        local x_raw = (_i2c.read(_xm_addr, format("%c", OUT_X_H_A), 1)[0] << 8) + _i2c.read(_xm_addr, format("%c", OUT_X_L_A), 1)[0];
        local y_raw = (_i2c.read(_xm_addr, format("%c", OUT_Y_H_A), 1)[0] << 8) + _i2c.read(_xm_addr, format("%c", OUT_Y_L_A), 1)[0];
        local z_raw = (_i2c.read(_xm_addr, format("%c", OUT_Z_H_A), 1)[0] << 8) + _i2c.read(_xm_addr, format("%c", OUT_Z_L_A), 1)[0];

        //server.log(format("%02X, %02X, %02X",x_raw, y_raw, z_raw));

        local result = {};
        if (x_raw & 0x8000) {
            result.x <- (-1.0) * _twosComp(x_raw, 0xffff);
        } else {
            result.x <- x_raw;
        }

        if (y_raw & 0x8000) {
            result.y <- (-1.0) * _twosComp(y_raw, 0xffff);
        } else {
            result.y <- y_raw;
        }

        if (z_raw & 0x8000) {
            result.z <- (-1.0) * _twosComp(z_raw, 0xffff);
        } else {
            result.z <- z_raw;
        }

        return result;
    }

    /******************** PRIVATE FUNCTIONS ********************/
    function _twosComp(value, mask) {
        value = ~(value & mask) + 1;
        return value & mask;
    }

    function _setRegBit(addr, reg, bit, state) {
        local val = _i2c.read(addr, format("%c",reg), 1)[0];
        if (state == 0) {
            val = val & ~(0x01 << bit);
        } else {
            val = val | (0x01 << bit);
        }
        _i2c.write(addr, format("%c%c", reg, val));
    }
}

