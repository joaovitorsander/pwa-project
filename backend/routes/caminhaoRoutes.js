const express = require('express');
const router = express.Router();
const caminhaoController = require('../controllers/caminhaoController');

router.post('/', caminhaoController.criarCaminhao);
router.get('/', caminhaoController.buscarCaminhoes);
router.delete('/:id', caminhaoController.excluirCaminhao);
router.patch('/:id', caminhaoController.atualizarCaminhao);
router.get('/', caminhaoController.filtrarCaminhoes);

module.exports = router;