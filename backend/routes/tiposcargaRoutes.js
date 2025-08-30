const express = require('express');
const router = express.Router();
const tiposcargaController = require('../controllers/tiposcargaController');

router.get('/', tiposcargaController.BuscarTiposCargas);

module.exports = router;