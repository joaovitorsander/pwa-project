const express = require('express');
const router = express.Router();
const historicoController = require('../controllers/historicoController');

router.get('/', historicoController.buscarHistorico);
router.delete('/:id', historicoController.excluirCalculo);
router.delete('/', historicoController.limparHistorico);


module.exports = router;
