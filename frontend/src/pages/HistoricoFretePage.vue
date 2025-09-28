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
            <div class="text-caption text-grey-7">Total de Fretes</div>
            <div class="text-h6">{{ historico.length }}</div>
          </q-card-section>
        </q-card>
      </div>
      <div class="col-12 col-sm-6">
        <q-card flat bordered>
          <q-card-section class="q-pa-md">
            <div class="text-caption text-grey-7">Valor Médio</div>
            <div class="text-h6 text-positive">{{ formatBRL(valorMedio) }}</div>
          </q-card-section>
        </q-card>
      </div>
    </div>

    <q-card flat bordered class="q-mb-md">
      <q-card-section class="q-pa-md">
        <div class="row items-center q-col-gutter-md">
          <div class="col-12 col-sm">
            <q-input
              v-model="filtros.termo"
              label="Buscar por Origem, Destino ou Placa"
              dense
              outlined
              clearable
              @clear="carregarHistorico"
            >
              <template #prepend>
                <q-icon name="search" />
              </template>
            </q-input>
          </div>

          <div class="col-12 col-sm-auto">
            <q-input label="Filtrar por Período" dense outlined readonly>
              <template #prepend>
                <q-icon name="event" class="cursor-pointer">
                  <q-popup-proxy cover transition-show="scale" transition-hide="scale">
                    <q-date v-model="filtros.rangeData" range mask="YYYY-MM-DD">
                      <div class="row items-center justify-end">
                        <q-btn v-close-popup label="Fechar" color="primary" flat />
                      </div>
                    </q-date>
                  </q-popup-proxy>
                </q-icon>
              </template>
              <template #append>
                <span class="text-caption text-grey-7 q-mr-sm">
                  {{
                    filtros.rangeData
                      ? `${formatData(filtros.rangeData.from)} - ${formatData(filtros.rangeData.to)}`
                      : 'Selecione'
                  }}
                </span>
                <q-icon
                  v-if="filtros.rangeData"
                  name="cancel"
                  @click.stop.prevent="filtros.rangeData = null"
                  class="cursor-pointer"
                />
              </template>
            </q-input>
          </div>

          <div class="col-auto">
            <q-btn
              label="Buscar"
              color="green-6"
              no-caps
              class="q-px-md"
              @click="carregarHistorico"
            />
          </div>
        </div>
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
                <span class="text-grey-7">Distância:</span>
                <span class="text-weight-medium"> {{ item.distancia_km }} km</span>
              </div>
              <div class="col-auto">
                <span class="text-grey-7">Veículo:</span>
                <span class="text-weight-medium">
                  {{ item.veiculo_modelo }} ({{ item.placa }})
                </span>
              </div>
              <div class="col-auto">
                <span class="text-grey-7">Consumo:</span>
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

const filtros = reactive({
  termo: '',
  rangeData: null,
})

const valorTotal = computed(() => historico.value.reduce((acc, h) => acc + (h.valor_total || 0), 0))
const valorMedio = computed(() =>
  historico.value.length ? valorTotal.value / historico.value.length : 0,
)

async function carregarHistorico() {
  carregando.value = true

  const filtrosParaApi = {}

  if (filtros.termo) {
    filtrosParaApi.termo = filtros.termo
  }
  if (filtros.rangeData?.from) {
    filtrosParaApi.data_de = filtros.rangeData.from
  }
  if (filtros.rangeData?.to) {
    filtrosParaApi.data_ate = filtros.rangeData.to
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
