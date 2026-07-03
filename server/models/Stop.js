const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const Stop = sequelize.define(
  "Stop",
  {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    stopName: { type: DataTypes.STRING, allowNull: false },
    latitude: { type: DataTypes.DECIMAL(10, 7), allowNull: false },
    longitude: { type: DataTypes.DECIMAL(10, 7), allowNull: false },
    pickupTime: { type: DataTypes.STRING }, // e.g., "08:30 AM"
    dropTime: { type: DataTypes.STRING },
    // FK: routeId set in associations.js
  },
  { timestamps: true }
);

module.exports = Stop;
