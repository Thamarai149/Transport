const express = require("express");
const { getRoutes, createRoute } = require("../controllers/routeController");
const { protect, authorize } = require("../middleware/auth");

const router = express.Router();

router.route("/")
  .get(protect, getRoutes)
  .post(protect, authorize("Super Admin", "Transport Admin"), createRoute);

module.exports = router;
