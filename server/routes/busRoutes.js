const express = require("express");
const { getBuses, getBusById, createBus, updateBus, deleteBus } = require("../controllers/busController");
const { protect, authorize } = require("../middleware/auth");

const router = express.Router();

router.route("/")
  .get(protect, getBuses)
  .post(protect, authorize("Super Admin", "Transport Admin"), createBus);

router.route("/:id")
  .get(protect, getBusById)
  .put(protect, authorize("Super Admin", "Transport Admin"), updateBus)
  .delete(protect, authorize("Super Admin", "Transport Admin"), deleteBus);

module.exports = router;
