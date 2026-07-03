const express = require("express");
const { matchFace, optimizeRoute, predictETA } = require("../controllers/aiController");
const { protect, authorize } = require("../middleware/auth");

const router = express.Router();

// Face recognition attendance (students and drivers can call this)
router.post("/face-match", protect, matchFace);

// Route optimization (admin only)
router.post("/optimize-route", protect, authorize("Super Admin", "Transport Admin"), optimizeRoute);

// ETA prediction (all authenticated users)
router.post("/predict-eta", protect, predictETA);

module.exports = router;
