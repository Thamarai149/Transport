const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const Student = sequelize.define(
  "Student",
  {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    rollNumber: { type: DataTypes.STRING, allowNull: false, unique: true },
    college: { type: DataTypes.STRING, allowNull: false },
    department: { type: DataTypes.STRING },
    qrCode: { type: DataTypes.STRING }, // URL or hash for the QR
    faceEncoding: { type: DataTypes.TEXT }, // JSON-serialized face encoding array
    feeStatus: {
      type: DataTypes.ENUM("Paid", "Pending", "Overdue"),
      defaultValue: "Pending",
    },
    emergencyContact: { type: DataTypes.STRING },
    // FK: userId, routeId, pickupStopId set in associations.js
  },
  { timestamps: true }
);

module.exports = Student;
