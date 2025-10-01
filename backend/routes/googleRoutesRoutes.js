const express = require('express');
const router = express.Router();
const googleRoutesController = require('../controllers/googleRoutesController');

router.post('/calcular', googleRoutesController.calcularRotaComPedagio);

module.exports = router;