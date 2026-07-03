require("dotenv").config();
const mongoose = require("mongoose");
const User = require("./models/User");
const Student = require("./models/Student");
const Driver = require("./models/Driver");

const resetDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("Connected to MongoDB for reset...");
    
    // Clear user, student, and driver collections
    const userResult = await User.deleteMany({});
    const studentResult = await Student.deleteMany({});
    const driverResult = await Driver.deleteMany({});
    
    console.log(`Cleared: ${userResult.deletedCount} users, ${studentResult.deletedCount} students, ${driverResult.deletedCount} drivers.`);
    console.log("Database reset completed successfully!");
    process.exit(0);
  } catch (error) {
    console.error("Error resetting database:", error);
    process.exit(1);
  }
};

resetDB();
