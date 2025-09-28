<template>
  <q-page class="q-pa-md">
    <div class="row items-center justify-between q-mb-md">
      <div class="row items-center q-gutter-sm">
        <q-icon name="local_shipping" color="green-7" size="22px" />
        <div class="text-subtitle1 text-weight-medium">Meus caminhões</div>
      </div>
      <div>
        <q-btn
          v-if="!exibirFormulario"
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

    <div v-if="!exibirFormulario">
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
                clearable
                @clear="carregarCaminhoes"
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

      <div v-if="!carregando && caminhoes.length === 0" class="text-grey-7 q-pa-sm">
        <span v-if="buscaRealizadaSemResultados">
          Nenhum caminhão encontrado para a busca realizada.
        </span>
        <span v-else> Nenhum caminhão cadastrado ainda. </span>
      </div>

      <q-card v-for="c in caminhoes" :key="c.id" flat bordered class="q-mb-md">
        <q-card-section>
          <div class="row items-start justify-between no-wrap">
            <div class="column">
              <div class="text-subtitle1 text-weight-bold">{{ c.modelo }}</div>
              <div class="text-grey-7">
                Placa: <span class="text-weight-medium">{{ c.placa }}</span> • Ano:
                <span class="text-weight-medium">{{ c.ano }}</span>
              </div>

              <div class="row q-mt-sm">
                <div class="column q-mt-sm q-gutter-y-xs">
                  <div class="text-grey-7">
                    Consumo:
                    <span class="text-weight-medium text-black"
                      >{{ c.consumo_km_por_l_carregado }} km/L (Carregado)</span
                    >
                    <span class="q-mx-xs text-grey-5">|</span>
                    <span class="text-weight-medium text-black"
                      >{{ c.consumo_km_por_l_vazio }} km/L (Vazio)</span
                    >
                  </div>
                  <div class="text-grey-7">
                    Capacidade:
                    <span class="text-weight-medium text-black">{{ c.capacidade_ton }} ton</span>
                  </div>
                </div>
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

    <FormularioCaminhao
      v-else
      :caminhao-para-editar="caminhaoSelecionado"
      @salvo="onFormularioSalvo"
      @cancelado="fecharFormulario"
    />
  </q-page>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useQuasar } from 'quasar'
import * as caminhaoService from 'src/services/caminhaoService'
import FormularioCaminhao from 'src/components/FormularioCaminhaoComponent.vue'

const $q = useQuasar()

const carregando = ref(false)
const caminhoes = ref([])

const exibirFormulario = ref(false)
const caminhaoSelecionado = ref(null)
const buscaRealizadaSemResultados = ref(false)

const filtros = reactive({
  termo: '',
  campo: 'modelo',
})
const opcoesDeFiltro = ref([
  { label: 'Modelo', value: 'modelo' },
  { label: 'Placa', value: 'placa' },
  { label: 'Ano', value: 'ano' },
])
const placeholderPesquisa = computed(() => {
  const selecionado = opcoesDeFiltro.value.find((opt) => opt.value === filtros.campo)
  return `Pesquisar por ${selecionado?.label || '...'}...`
})
const tipoInputPesquisa = computed(() => (filtros.campo === 'ano' ? 'number' : 'text'))

const fecharFormulario = () => {
  exibirFormulario.value = false
  caminhaoSelecionado.value = null
}

const abrirFormularioCadastro = () => {
  caminhaoSelecionado.value = null
  exibirFormulario.value = true
}

const abrirFormularioEdicao = (caminhao) => {
  caminhaoSelecionado.value = caminhao
  exibirFormulario.value = true
}

const onFormularioSalvo = async () => {
  fecharFormulario()
  await carregarCaminhoes()
}

const carregarCaminhoes = async () => {
  carregando.value = true
  const filtroAtivo = filtros.termo && filtros.termo.trim() !== ''
  const filtrosParaApi = {}
  if (filtros.termo) {
    filtrosParaApi[filtros.campo] = filtros.termo
  }
  const result = await caminhaoService.buscarCaminhoes(filtrosParaApi)
  if (result.success) {
    caminhoes.value = result.data
    buscaRealizadaSemResultados.value = filtroAtivo && result.data.length === 0
  } else {
    $q.notify({ type: 'negative', message: result.message })
  }
  carregando.value = false
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
