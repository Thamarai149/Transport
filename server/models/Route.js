const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const Route = sequelize.define(
  "Route",
  {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    routeName: { type: DataTypes.STRING, allowNull: false },
    routeNumber: { type: DataTypes.STRING, allowNull: false, unique: true },
    startPoint: { type: DataTypes.STRING, allowNull: false },
    endPoint: { type: DataTypes.STRING, allowNull: false },
    distance: { type: DataTypes.FLOAT }, // km
    estimatedTime: { type: DataTypes.INTEGER }, // minutes
    college: { type: DataTypes.STRING, allowNull: false },
  },
  { timestamps: true }
);

module.exports = Route;
