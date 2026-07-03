require("dotenv").config();
const express = require("express");
const http = require("http");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const { Server } = require("socket.io");
const connectDB = require("./config/db");

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(express.json());
app.use(cors());
app.use(helmet());
app.use(morgan("dev"));

// Database Connection
connectDB();

// Routes
const authRoutes = require("./routes/authRoutes");
const busRoutes = require("./routes/busRoutes");
const routeRoutes = require("./routes/routeRoutes");
const stopRoutes = require("./routes/stopRoutes");
const userRoutes = require("./routes/userRoutes");
const aiRoutes = require("./routes/aiRoutes");

app.use("/api/auth", authRoutes);
app.use("/api/buses", busRoutes);
app.use("/api/routes", routeRoutes);
app.use("/api/stops", stopRoutes);
app.use("/api/users", userRoutes);
app.use("/api/ai", aiRoutes);

app.get("/", (req, res) => {
  res.send("Smart TranspoNet API is running...");
});

const Stop = require("./models/Stop");

// Haversine formula for distance in metres between two GPS coords
function haversineMetres(lat1, lon1, lat2, lon2) {
  const R = 6371000;
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const dPhi = ((lat2 - lat1) * Math.PI) / 180;
  const dLam = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dPhi / 2) ** 2 +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(dLam / 2) ** 2;
  return 2 * R * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// Socket.io for Real-time GPS Tracking
io.on("connection", (socket) => {
  console.log("New client connected:", socket.id);

  socket.on("joinBusRoom", (busId) => {
    socket.join(`busRoom-${busId}`);
    console.log(`Socket ${socket.id} joined room: busRoom-${busId}`);
  });

  socket.on("driverLocationUpdate", async (data) => {
    // Broadcast the driver's live location to all students in the bus room
    io.to(`busRoom-${data.busId}`).emit("locationUpdate", data);

    // Geofence: check proximity to all stops for this route
    if (data.latitude && data.longitude && data.routeId) {
      try {
        const stops = await Stop.find({ routeId: data.routeId });
        for (const stop of stops) {
          if (stop.location && stop.location.coordinates) {
            const [stopLon, stopLat] = stop.location.coordinates;
            const dist = haversineMetres(
              parseFloat(data.latitude), parseFloat(data.longitude),
              stopLat, stopLon
            );
            if (dist <= 150) {
              io.to(`busRoom-${data.busId}`).emit("busApproaching", {
                busId: data.busId,
                stopId: stop._id,
                stopName: stop.stopName,
                distanceMetres: Math.round(dist),
              });
              console.log(`Bus ${data.busId} approaching stop: ${stop.stopName} (${Math.round(dist)}m)`);
            }
          }
        }
      } catch (err) {
        console.error("Geofence check failed:", err.message);
      }
    }
  });

  socket.on("disconnect", () => {
    console.log("Client disconnected:", socket.id);
  });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
