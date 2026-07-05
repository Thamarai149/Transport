const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const Trip = sequelize.define(
  "Trip",
  {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    startTime: { type: DataTypes.DATE },
    endTime: { type: DataTypes.DATE },
    status: {
      type: DataTypes.ENUM("Scheduled", "Ongoing", "Completed", "Cancelled"),
      defaultValue: "Scheduled",
    },
    passengerCount: { type: DataTypes.INTEGER, defaultValue: 0 },
    // Replaced GeoJSON with plain lat/lon decimals
    startLatitude: { type: DataTypes.DECIMAL(10, 7) },
    startLongitude: { type: DataTypes.DECIMAL(10, 7) },
    endLatitude: { type: DataTypes.DECIMAL(10, 7) },
    endLongitude: { type: DataTypes.DECIMAL(10, 7) },
    // FK: driverId, busId, routeId set in associations.js
  },
  { timestamps: true }
);

module.exports = Trip;
