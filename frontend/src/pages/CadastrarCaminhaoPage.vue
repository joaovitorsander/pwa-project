<template>
  <q-page class="q-pa-md">
    <div class="row items-center justify-between q-mb-md">
      <div class="row items-center q-gutter-sm">
        <q-icon name="local_shipping" color="green-7" size="22px" />
        <div class="text-subtitle1 text-weight-medium">Meus caminhões</div>
      </div>
      <div>
        <q-btn
          v-if="modoLista"
          color="green-6"
          icon="add"
          label="Adicionar"
          no-caps
          @click="abrirFormularioCadastro"
        />
        <q-btn
          v-else
          color="grey-6"
          outline
          icon="close"
          label="Cancelar"
          no-caps
          @click="fecharFormulario"
        />
      </div>
    </div>

    <div v-if="modoLista">
      <q-card flat bordered class="q-mb-md">
        <q-card-section>
          <q-form @submit.prevent="carregarCaminhoes" class="row items-start q-col-gutter-md">
            <div class="col">
              <q-input
                v-model="filtros.termo"
                :label="placeholderPesquisa"
                :type="tipoInputPesquisa"
                dense
                outlined
                color="green-6"
              >
                <template v-slot:prepend>
                  <q-icon name="search" />
                </template>
              </q-input>
            </div>

            <div class="col-xs-12 col-sm-auto" style="min-width: 130px">
              <q-select
                v-model="filtros.campo"
                :options="opcoesDeFiltro"
                label="Filtrar por"
                dense
                outlined
                emit-value
                map-options
                color="green-6"
              />
            </div>

            <div class="col-auto">
              <q-btn label="Buscar" color="green-6" type="submit" no-caps class="q-px-md" />
            </div>
          </q-form>
        </q-card-section>
      </q-card>
      <q-skeleton v-if="carregando" type="rect" class="q-mb-md" height="110px" />
      <q-skeleton v-if="carregando" type="rect" class="q-mb-md" height="110px" />

      <div v-if="!carregando && caminhoes.length === 0" class="text-grey-7">
        Nenhum caminhão cadastrado ainda.
      </div>

      <q-card v-for="c in caminhoes" :key="c.id" flat bordered class="q-mb-md">
        <q-card-section>
          <div class="row items-start justify-between">
            <div class="column">
              <div class="text-subtitle1 text-weight-bold">{{ c.modelo }}</div>
              <div class="text-grey-7">
                Placa: <span class="text-weight-medium">{{ c.placa }}</span> • Ano:
                <span class="text-weight-medium">{{ c.ano }}</span>
              </div>

              <div class="row q-col-gutter-md q-mt-sm">
                <div class="col-auto">
                  <span class="text-grey-7">Consumo:</span>
                  <span class="text-weight-medium"> {{ c.consumo_km_l }} km/L</span>
                </div>
                <div class="col-auto">
                  <span class="text-grey-7">Capacidade:</span>
                  <span class="text-weight-medium"> {{ c.capacidade_ton }} ton</span>
                </div>
              </div>
              <div class="q-mt-xs">
                <span class="text-grey-7">Tipo:</span>
                <q-badge outline color="green-7" class="q-ml-xs">{{ c.tipo }}</q-badge>
              </div>
            </div>

            <div>
              <q-btn
                flat
                round
                dense
                color="grey-7"
                icon="edit"
                @click="abrirFormularioEdicao(c)"
              />
              <q-btn flat round dense color="red-5" icon="delete" @click="confirmarExclusao(c)" />
            </div>
          </div>
        </q-card-section>
      </q-card>
    </div>

    <div v-else>
      <q-card flat bordered>
        <q-card-section>
          <div class="text-h6 text-green-8">{{ tituloFormulario }}</div>
        </q-card-section>

        <q-separator />

        <q-card-section class="q-pa-md">
          <q-form @submit.prevent="salvar" class="q-gutter-y-md">
            <div class="text-subtitle1 text-weight-medium text-grey-8">
              Identificação do veículo
            </div>
            <div class="row q-col-gutter-md">
              <div class="col-12 col-md-6">
                <q-input
                  v-model="form.modelo"
                  label="Modelo *"
                  placeholder="Ex: Scania R450, Volvo FH540"
                  :rules="[(val) => !!val || 'Informe o modelo']"
                  outlined
                  color="green-6"
                />
              </div>
              <div class="col-12 col-md-6">
                <q-input
                  v-model="form.placa"
                  label="Placa *"
                  placeholder="ABC1D23"
                  :rules="[(val) => !!val || 'Informe a placa']"
                  outlined
                  color="green-6"
                />
              </div>
            </div>

            <q-separator spaced="sm" />

            <div class="text-subtitle1 text-weight-medium text-grey-8">Especificações técnicas</div>
            <div class="row q-col-gutter-md">
              <div class="col-12 col-sm-6 col-md-3">
                <q-input
                  v-model.number="form.ano"
                  type="number"
                  label="Ano *"
                  :rules="[(val) => !!val || 'Informe o ano']"
                  outlined
                  color="green-6"
                />
              </div>
              <div class="col-12 col-sm-6 col-md-3">
                <q-input
                  v-model.number="form.quantidade_eixos"
                  type="number"
                  label="Qtd. de eixos *"
                  :rules="[(val) => !!val || 'Informe os eixos']"
                  outlined
                  color="green-6"
                />
              </div>
              <div class="col-12 col-sm-6 col-md-3">
                <q-input
                  v-model.number="form.capacidade_ton"
                  type="number"
                  step="0.1"
                  label="Capacidade (ton) *"
                  :rules="[(val) => !!val || 'Informe a capacidade']"
                  outlined
                  color="green-6"
                />
              </div>
            </div>

            <div class="row q-col-gutter-md">
              <div class="col-12 col-md-6">
                <q-input
                  v-model.number="form.consumo_km_por_l_vazio"
                  type="number"
                  step="0.1"
                  label="Consumo vazio (km/L) *"
                  :rules="[(val) => !!val || 'Informe o consumo']"
                  outlined
                  color="green-6"
                />
              </div>
              <div class="col-12 col-md-6">
                <q-input
                  v-model.number="form.consumo_km_por_l_carregado"
                  type="number"
                  step="0.1"
                  label="Consumo carregado (km/L) *"
                  :rules="[(val) => !!val || 'Informe o consumo']"
                  outlined
                  color="green-6"
                />
              </div>
            </div>

            <div class="row justify-end q-mt-lg">
              <q-btn
                :label="labelBotaoSalvar"
                type="submit"
                color="green-8"
                no-caps
                size="lg"
                class="q-px-xl"
              />
            </div>
          </q-form>
        </q-card-section>
      </q-card>
    </div>
  </q-page>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useQuasar } from 'quasar'
import * as caminhaoService from 'src/services/caminhaoService'

const $q = useQuasar()

const modoLista = ref(true)
const carregando = ref(false)
const caminhoes = ref([])

const formVazio = {
  id: null,
  modelo: '',
  placa: '',
  ano: null,
  quantidade_eixos: null,
  consumo_km_por_l_vazio: null,
  consumo_km_por_l_carregado: null,
  capacidade_ton: null,
}
const form = reactive({ ...formVazio })

const filtros = reactive({
  termo: '',
  campo: 'modelo',
})

const opcoesDeFiltro = ref([
  { label: 'Modelo', value: 'modelo' },
  { label: 'Placa', value: 'placa' },
  { label: 'Ano', value: 'ano' },
])

const modoEdicao = computed(() => form.id !== null && form.id !== undefined)
const tituloFormulario = computed(() =>
  modoEdicao.value ? 'Editar caminhão' : 'Cadastrar novo Caminhão',
)
const labelBotaoSalvar = computed(() =>
  modoEdicao.value ? 'Salvar alterações' : 'Cadastrar caminhão',
)

const placeholderPesquisa = computed(() => {
  const selecionado = opcoesDeFiltro.value.find((opt) => opt.value === filtros.campo)
  return `Pesquisar por ${selecionado?.label || '...'}...`
})

const tipoInputPesquisa = computed(() => (filtros.campo === 'ano' ? 'number' : 'text'))

const fecharFormulario = () => {
  modoLista.value = true
  Object.assign(form, formVazio)
}

const abrirFormularioCadastro = () => {
  modoLista.value = false
  Object.assign(form, formVazio)
}

const abrirFormularioEdicao = (caminhao) => {
  modoLista.value = false
  Object.assign(form, caminhao)
}

const carregarCaminhoes = async () => {
  carregando.value = true
  const filtrosParaApi = {}
  if (filtros.termo) {
    filtrosParaApi[filtros.campo] = filtros.termo
  }
  const result = await caminhaoService.buscarCaminhoes(filtrosParaApi)
  if (result.success) {
    caminhoes.value = result.data
  } else {
    $q.notify({ type: 'negative', message: result.message })
  }
  carregando.value = false
}

const salvar = async () => {
  let result
  if (modoEdicao.value) {
    result = await caminhaoService.atualizarCaminhao(form.id, form)
  } else {
    result = await caminhaoService.cadastrarCaminhao(form)
  }

  if (result.success) {
    $q.notify({ type: 'positive', message: result.message })
    fecharFormulario()
    await carregarCaminhoes()
  } else {
    $q.notify({ type: 'negative', message: result.message })
  }
}

const confirmarExclusao = (caminhao) => {
  $q.dialog({
    title: 'Excluir caminhão',
    message: `Deseja excluir o caminhão ${caminhao.modelo} (${caminhao.placa})? Esta ação não pode ser desfeita.`,
    persistent: true,
    ok: { label: 'Excluir', color: 'red-5', flat: true },
    cancel: { label: 'Cancelar', flat: true },
  }).onOk(() => {
    excluir(caminhao.id)
  })
}

const excluir = async (id) => {
  if (!id) {
    $q.notify({ type: 'negative', message: 'ID do caminhão não encontrado.' })
    return
  }
  const result = await caminhaoService.excluirCaminhao(id)
  if (result.success) {
    $q.notify({ type: 'positive', message: result.message })
    await carregarCaminhoes()
  } else {
    $q.notify({ type: 'negative', message: result.message })
  }
}

onMounted(() => {
  carregarCaminhoes()
})
</script>
