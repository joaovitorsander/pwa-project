<template>
  <q-page class="q-pa-md">
    <div class="row items-center justify-between q-mb-md">
      <div class="row items-center q-gutter-sm">
        <q-icon name="history" color="green-7" size="22px" />
        <div class="text-subtitle1 text-weight-medium">Histórico de Cálculos</div>
      </div>
      <div>
        <q-btn
          color="red-5"
          outline
          icon="delete_sweep"
          label="Limpar Histórico"
          no-caps
          @click="confirmarLimpeza"
        />
      </div>
    </div>

    <div class="row q-col-gutter-md q-mb-md">
      <div class="col-12 col-sm-6">
        <q-card flat bordered>
          <q-card-section class="q-pa-md">
            <div class="text-caption text-grey-7">Total de fretes</div>
            <div class="text-h6">{{ historico.length }}</div>
          </q-card-section>
        </q-card>
      </div>
      <div class="col-12 col-sm-6">
        <q-card flat bordered>
          <q-card-section class="q-pa-md">
            <div class="text-caption text-grey-7">Valor médio</div>
            <div class="text-h6 text-positive">{{ formatBRL(valorMedio) }}</div>
          </q-card-section>
        </q-card>
      </div>
    </div>

    <q-card flat bordered class="q-mb-md">
      <q-card-section>
        <q-form @submit.prevent="carregarHistorico" class="row items-start q-col-gutter-md">
          <div v-if="filtros.campo !== 'periodo'" class="col">
            <q-input
              v-model="filtros.termo"
              :label="placeholderPesquisa"
              dense
              outlined
              color="green-6"
            >
              <template #prepend>
                <q-icon name="search" />
              </template>
            </q-input>
          </div>
          <div
            v-if="filtros.campo === 'periodo'"
            class="col row items-center q-col-gutter-x-md no-wrap"
          >
            <div class="col">
              <q-input
                v-model="filtros.data_de"
                label="Data Inicial"
                dense
                outlined
                mask="##/##/####"
                clearable
                @clear="filtros.data_de = null"
                color="green-6"
              >
                <template #prepend>
                  <q-icon name="event" class="cursor-pointer">
                    <q-popup-proxy cover transition-show="scale" transition-hide="scale">
                      <q-date v-model="filtros.data_de" mask="DD/MM/YYYY">
                        <div class="row items-center justify-end">
                          <q-btn v-close-popup label="Ok" color="primary" flat />
                        </div>
                      </q-date>
                    </q-popup-proxy>
                  </q-icon>
                </template>
              </q-input>
            </div>

            <div class="col">
              <q-input
                v-model="filtros.data_ate"
                label="Data Final"
                dense
                outlined
                mask="##/##/####"
                clearable
                @clear="filtros.data_ate = null"
                color="green-6"
              >
                <template #prepend>
                  <q-icon name="event" class="cursor-pointer">
                    <q-popup-proxy cover transition-show="scale" transition-hide="scale">
                      <q-date v-model="filtros.data_ate" mask="DD/MM/YYYY">
                        <div class="row items-center justify-end">
                          <q-btn v-close-popup label="Ok" color="primary" flat />
                        </div>
                      </q-date>
                    </q-popup-proxy>
                  </q-icon>
                </template>
              </q-input>
            </div>
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

    <div v-if="!carregando && historico.length === 0" class="text-grey-7">
      Nenhum cálculo encontrado.
    </div>

    <q-card v-for="item in historico" :key="item.id" flat bordered class="q-mb-md">
      <q-card-section>
        <div class="row items-start justify-between">
          <div class="column">
            <div class="row items-center q-gutter-sm q-mb-sm">
              <q-icon name="place" />
              <div class="text-subtitle1 text-weight-bold text-capitalize">
                {{ item.origem }} → {{ item.destino }}
              </div>
            </div>

            <div class="row q-col-gutter-md">
              <div class="col-auto">
                <span class="text-grey-7">Distância: </span>
                <span class="text-weight-medium"> {{ formatarKm(item.distancia_km) }}</span>
              </div>
              <div class="col-auto">
                <span class="text-grey-7">Veículo: </span>
                <span class="text-weight-medium">
                  {{ item.veiculo_modelo }} ({{ item.placa }})
                </span>
              </div>
              <div class="col-auto">
                <span class="text-grey-7">Consumo: </span>
                <span class="text-weight-medium"> {{ item.consumo_km_l }} km/L</span>
              </div>
            </div>

            <div class="q-mt-xs">
              <q-badge outline color="green-7">{{ item.tipo_carga }}</q-badge>
            </div>

            <div class="row items-center q-gutter-sm q-mt-sm">
              <q-icon name="event" />
              <div class="text-caption">{{ formatData(item.data_calculo) }}</div>
              <q-space />
              <div class="text-subtitle1 text-positive">{{ formatBRL(item.valor_total) }}</div>
            </div>
          </div>

          <div>
            <q-btn flat round dense color="red-5" icon="delete" @click="confirmarExclusao(item)" />
          </div>
        </div>
      </q-card-section>
    </q-card>

    <q-card flat bordered class="q-pa-lg q-mt-lg">
      <div class="text-caption text-grey-7">Valor Total dos Fretes</div>
      <div class="text-h6 text-positive q-mt-sm">{{ formatBRL(valorTotal) }}</div>
    </q-card>
  </q-page>
</template>

<script setup>
import { ref, computed, reactive, onMounted, watch } from 'vue'
import { useQuasar, date } from 'quasar'
import * as historicoService from 'src/services/historicoService'

const $q = useQuasar()

const carregando = ref(false)
const historico = ref([])

const opcoesDeFiltro = ref([
  { label: 'Origem', value: 'origem' },
  { label: 'Destino', value: 'destino' },
  { label: 'Placa', value: 'placa' },
  { label: 'Caminhão', value: 'caminhao' },
  { label: 'Período', value: 'periodo' },
])

const filtros = reactive({
  termo: '',
  campo: 'Origem',
  data_de: null,
  data_ate: null,
})

const placeholderPesquisa = computed(() => {
  if (filtros.campo === 'origem') return 'Buscar por cidade de origem...'
  if (filtros.campo === 'destino') return 'Buscar por cidade de destino...'
  if (filtros.campo === 'placa') return 'Buscar por placa do caminhão...'
  if (filtros.campo === 'caminhao') return 'Buscar por modelo do caminhão...'
  return ''
})

const valorTotal = computed(() => historico.value.reduce((acc, h) => acc + (h.valor_total || 0), 0))
const valorMedio = computed(() =>
  historico.value.length ? valorTotal.value / historico.value.length : 0,
)

async function carregarHistorico() {
  if (filtros.campo === 'periodo') {
    if (!dataEhValida(filtros.data_de)) {
      $q.notify({ type: 'warning', message: 'A Data Inicial inserida é inválida.' })
      return
    }
    if (!dataEhValida(filtros.data_ate)) {
      $q.notify({ type: 'warning', message: 'A Data Final inserida é inválida.' })
      return
    }

    const temApenasUmaData =
      (filtros.data_de && !filtros.data_ate) || (!filtros.data_de && filtros.data_ate)

    if (temApenasUmaData) {
      $q.notify({
        type: 'warning',
        message: 'Para filtrar por período, é necessário informar a Data Inicial e a Data Final.',
      })
      return
    }

    if (filtros.data_de && filtros.data_ate) {
      const dataInicio = new Date(converteDataFormatoBr(filtros.data_de))
      const dataFim = new Date(converteDataFormatoBr(filtros.data_ate))

      if (dataFim < dataInicio) {
        $q.notify({
          type: 'warning',
          message: 'A Data Final não pode ser anterior à Data Inicial.',
        })
        return
      }
    }
  }

  carregando.value = true
  const filtrosParaApi = {}

  if (filtros.campo === 'periodo') {
    filtrosParaApi.data_de = filtros.data_de
    filtrosParaApi.data_ate = filtros.data_ate
  } else if (filtros.termo) {
    filtrosParaApi[filtros.campo] = filtros.termo
  }

  const result = await historicoService.buscarHistorico(filtrosParaApi)

  if (result.success) {
    historico.value = result.data
  } else {
    $q.notify({ type: 'negative', message: result.message })
  }
  carregando.value = false
}

function confirmarLimpeza() {
  if (!historico.value.length) return
  $q.dialog({
    title: 'Limpar histórico',
    message: 'Esta ação removerá todos os cálculos salvos. Deseja continuar?',
    persistent: true,
    ok: { label: 'Limpar', color: 'red-5', flat: true },
    cancel: { label: 'Cancelar', flat: true },
  }).onOk(async () => {
    const res = await historicoService.limparHistorico()
    if (res?.success) {
      historico.value = []
      $q.notify({ type: 'positive', message: res.message || 'Histórico limpo.' })
    } else {
      $q.notify({ type: 'negative', message: res?.message || 'Não foi possível limpar.' })
    }
  })
}

function confirmarExclusao(item) {
  $q.dialog({
    title: 'Excluir cálculo',
    message: `Excluir o cálculo de ${item.origem} → ${item.destino}?`,
    persistent: true,
    ok: { label: 'Excluir', color: 'red-5', flat: true },
    cancel: { label: 'Cancelar', flat: true },
  }).onOk(async () => {
    const res = await historicoService.excluirCalculo(item.id)
    if (res?.success) {
      historico.value = historico.value.filter((h) => h.id !== item.id)
      $q.notify({ type: 'positive', message: res.message || 'Cálculo excluído.' })
    } else {
      $q.notify({ type: 'negative', message: res?.message || 'Falha ao excluir.' })
    }
  })
}

function formatBRL(v = 0) {
  return Number(v).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
}
function formatData(iso) {
  return date.formatDate(iso, 'DD/MM/YYYY')
}

function formatarKm(valor) {
  const numero = Number(valor)
  if (isNaN(numero)) {
    return '0,00 km'
  }

  const formatador = new Intl.NumberFormat('pt-BR', {
    style: 'decimal',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })

  return `${formatador.format(numero)} km`
}

function dataEhValida(dataStr) {
  if (!dataStr) return true

  if (!/^\d{2}\/\d{2}\/\d{4}$/.test(dataStr)) return false

  const partes = dataStr.split('/')
  const dia = parseInt(partes[0], 10)
  const mes = parseInt(partes[1], 10)
  const ano = parseInt(partes[2], 10)

  if (ano < 1000 || ano > 3000 || mes === 0 || mes > 12) return false

  const ultimoDiaDoMes = new Date(ano, mes, 0).getDate()
  if (dia === 0 || dia > ultimoDiaDoMes) return false

  return true
}

function converteDataFormatoBr(dataStr) {
  if (!dataStr) return null

  const [dia, mes, ano] = dataStr.split('/')

  return new Date(Number(ano), Number(mes) - 1, Number(dia))
}

onMounted(() => {
  carregarHistorico()
})

watch(
  () => filtros.rangeData,
  (novoValor, valorAntigo) => {
    if (novoValor === null && valorAntigo !== null) {
      carregarHistorico()
    }
  },
)
</script>

<style scoped>
.rounded-borders {
  border-radius: 16px;
}
</style>
