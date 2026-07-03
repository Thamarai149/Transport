const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const Bus = sequelize.define(
  "Bus",
  {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    busNumber: { type: DataTypes.STRING, allowNull: false, unique: true },
    registrationNumber: { type: DataTypes.STRING, allowNull: false, unique: true },
    capacity: { type: DataTypes.INTEGER, allowNull: false },
    status: {
      type: DataTypes.ENUM("Active", "Maintenance", "Inactive"),
      defaultValue: "Active",
    },
    insuranceExpiry: { type: DataTypes.DATE },
    lastMaintenance: { type: DataTypes.DATE },
    // FK fields set in associations.js: driverId, routeId
  },
  { timestamps: true }
);

module.exports = Bus;
