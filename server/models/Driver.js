const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const Driver = sequelize.define(
  "Driver",
  {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    licenseNumber: { type: DataTypes.STRING, allowNull: false, unique: true },
    licenseExpiry: { type: DataTypes.DATE, allowNull: false },
    isActive: { type: DataTypes.BOOLEAN, defaultValue: false }, // true when on trip
    behaviorScore: { type: DataTypes.FLOAT, defaultValue: 100 }, // AI driver behavior score
    // FK: userId, busId, routeId set in associations.js
  },
  { timestamps: true }
);

module.exports = Driver;
