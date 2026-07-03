const User = require("./User");
const Bus = require("./Bus");
const Driver = require("./Driver");
const Route = require("./Route");
const Stop = require("./Stop");
const Student = require("./Student");
const Trip = require("./Trip");
const Attendance = require("./Attendance");

// ─── User ↔ Driver ──────────────────────────────────────────────────
User.hasOne(Driver, { foreignKey: "userId", onDelete: "CASCADE" });
Driver.belongsTo(User, { foreignKey: "userId", as: "user" });

// ─── User ↔ Student ─────────────────────────────────────────────────
User.hasOne(Student, { foreignKey: "userId", onDelete: "CASCADE" });
Student.belongsTo(User, { foreignKey: "userId", as: "user" });

// ─── Route ↔ Stop ───────────────────────────────────────────────────
Route.hasMany(Stop, { foreignKey: "routeId", as: "stops" });
Stop.belongsTo(Route, { foreignKey: "routeId", as: "route" });

// ─── Driver ↔ Bus ───────────────────────────────────────────────────
Bus.belongsTo(Driver, { foreignKey: "driverId", as: "assignedDriver" });
Driver.hasOne(Bus, { foreignKey: "driverId", as: "assignedBus" });

// ─── Bus ↔ Route ────────────────────────────────────────────────────
Bus.belongsTo(Route, { foreignKey: "routeId", as: "currentRoute" });
Route.hasMany(Bus, { foreignKey: "routeId" });

// ─── Driver ↔ Route ─────────────────────────────────────────────────
Driver.belongsTo(Route, { foreignKey: "routeId", as: "currentRoute" });

// ─── Student ↔ Route ────────────────────────────────────────────────
Student.belongsTo(Route, { foreignKey: "routeId", as: "route" });
Route.hasMany(Student, { foreignKey: "routeId" });

// ─── Student ↔ Stop (pickup stop) ───────────────────────────────────
Student.belongsTo(Stop, { foreignKey: "pickupStopId", as: "pickupStop" });

// ─── Trip ────────────────────────────────────────────────────────────
Trip.belongsTo(Driver, { foreignKey: "driverId", as: "driver" });
Trip.belongsTo(Bus, { foreignKey: "busId", as: "bus" });
Trip.belongsTo(Route, { foreignKey: "routeId", as: "route" });
Driver.hasMany(Trip, { foreignKey: "driverId" });
Bus.hasMany(Trip, { foreignKey: "busId" });
Route.hasMany(Trip, { foreignKey: "routeId" });

// ─── Attendance ──────────────────────────────────────────────────────
Attendance.belongsTo(Student, { foreignKey: "studentId", as: "student" });
Attendance.belongsTo(Trip, { foreignKey: "tripId", as: "trip" });
Attendance.belongsTo(Bus, { foreignKey: "busId", as: "bus" });
Student.hasMany(Attendance, { foreignKey: "studentId" });
Trip.hasMany(Attendance, { foreignKey: "tripId" });

module.exports = { User, Driver, Student, Bus, Route, Stop, Trip, Attendance };
