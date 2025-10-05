const routes = [
  {
    path: '/',
    component: () => import('layouts/MainLayout.vue'),
    children: [
      { path: '', component: () => import('src/pages/CalcularFretePage.vue'), name:'CalcularFrete' },
      { path: 'cadastrar-caminhao', component: () => import('pages/CadastrarCaminhaoPage.vue'), name:'CadastrarCaminhao'},
      { path: 'historico', component: () => import('pages/HistoricoFretePage.vue'), name: 'HistoricoFrete'}
    ],
  },
  // Always leave this as last one,
  // but you can also remove it
  {
    path: '/:catchAll(.*)*',
    component: () => import('pages/ErrorNotFound.vue'),
  },
]

export default routes
