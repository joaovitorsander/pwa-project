const express = require('express');
const router = express.Router();
const googlePlacesController = require('../controllers/googlePlacesController');

router.get('/autocomplete', googlePlacesController.buscarCidades);

module.exports = router;
