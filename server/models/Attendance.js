const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const Attendance = sequelize.define(
  "Attendance",
  {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    date: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
    status: {
      type: DataTypes.ENUM("Present", "Absent", "Late"),
      defaultValue: "Present",
    },
    scanMethod: {
      type: DataTypes.ENUM("QR Code", "Face Recognition", "Manual", "RFID"),
      defaultValue: "QR Code",
    },
    latitude: { type: DataTypes.DECIMAL(10, 7) },
    longitude: { type: DataTypes.DECIMAL(10, 7) },
    // FK: studentId, tripId, busId set in associations.js
  },
  { timestamps: true }
);

module.exports = Attendance;
