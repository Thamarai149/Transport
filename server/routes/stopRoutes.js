const express = require("express");
const { getStops, createStop } = require("../controllers/stopController");
const { protect, authorize } = require("../middleware/auth");

const router = express.Router();

router.route("/")
  .get(protect, getStops)
  .post(protect, authorize("Super Admin", "Transport Admin"), createStop);

module.exports = router;
