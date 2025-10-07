<template>
  <q-page class="q-pa-md">
    <q-card flat bordered class="q-mb-md">
      <q-card-section class="q-pa-none">
        <MapaComponent ref="mapComponentRef" style="height: 350px" />
      </q-card-section>

      <q-banner v-if="resultadoRota" inline-actions class="text-white bg-green-8">
        <div class="text-weight-bold">
          Distância: {{ resultadoRota.distancia }} | Duração Estimada: {{ resultadoRota.duracao }}
        </div>
      </q-banner>
    </q-card>

    <q-card flat bordered>
      <q-card-section>
        <div class="text-subtitle1 text-weight-medium text-green-8 flex items-center q-gutter-sm">
          <q-icon name="calculate" size="30px" />
          Calcular frete
        </div>
      </q-card-section>

      <q-separator />

      <q-card-section>
        <q-form ref="formRef" @submit.prevent="calcularFrete" class="q-gutter-y-md">
          <div class="text-h6 text-green-8 q-mb-sm">Detalhes da rota</div>
          <div class="row q-col-gutter-md items-start">
            <div class="col-12 col-md-5">
              <q-select
                v-model="form.origem"
                label="Origem *"
                outlined
                color="green-6"
                :options="opcoesOrigem"
                use-input
                fill-input
                hide-selected
                input-debounce="0"
                @filter="filtrarOrigem"
                :rules="[(val) => !!val || 'Campo obrigatório']"
              >
                <template v-slot:no-option>
                  <q-item>
                    <q-item-section class="text-grey">
                      Digite 3 ou mais letras para buscar...
                    </q-item-section>
                  </q-item>
                </template>
              </q-select>
            </div>
            <div class="col-12 col-md-5">
              <q-select
                v-model="form.destino"
                label="Destino *"
                outlined
                color="green-6"
                :options="opcoesDestino"
                use-input
                fill-input
                hide-selected
                input-debounce="0"
                @filter="filtrarDestino"
                :rules="[(val) => !!val || 'Campo obrigatório']"
              >
                <template v-slot:no-option>
                  <q-item>
                    <q-item-section class="text-grey">
                      Digite 3 ou mais letras para buscar...
                    </q-item-section>
                  </q-item>
                </template>
              </q-select>
            </div>

            <div class="col-12 col-md-9">
              <q-input
                v-model.number="form.distancia"
                type="number"
                label="Distância total (km) *"
                readonly
                outlined
                color="green-6"
                hint="Distância calculada automaticamente após a busca da rota."
              />
            </div>
            <div class="col-12 col-md-3">
              <q-btn
                label="Buscar rota"
                color="green-7"
                class="full-width full-height"
                no-caps
                @click="buscarRota"
              />
            </div>
          </div>

          <q-separator spaced="lg" />

          <div class="text-h6 text-green-8 q-mb-sm">Informações do veículo e carga</div>
          <div class="row q-col-gutter-md">
            <div class="col-12 col-md-6">
              <q-select
                v-model="form.veiculo"
                :options="caminhoes"
                label="Veículo *"
                :rules="[(val) => !!val || 'Campo obrigatório']"
                outlined
                color="green-6"
                emit-value
                map-options
              />
            </div>
            <div class="col-12 col-md-6">
              <q-select
                v-model="form.tipoCarga"
                :options="tiposCarga"
                label="Tipo de carga *"
                :rules="[(val) => !!val || 'Campo obrigatório']"
                outlined
                color="green-6"
                emit-value
                map-options
              />
            </div>
          </div>

          <div class="row q-col-gutter-md">
            <div class="col-12 col-md-4">
              <q-input
                v-model.number="form.consumo_km_por_l_vazio"
                type="number"
                step="0.1"
                label="Consumo vazio (km/L)"
                outlined
                color="green-6"
                hint="Preenchido automaticamente pelo veículo."
              />
            </div>
            <div class="col-12 col-md-4">
              <q-input
                v-model.number="form.consumo_km_por_l_carregado"
                type="number"
                step="0.1"
                label="Consumo carregado (km/L)"
                outlined
                color="green-6"
                hint="Preenchido automaticamente pelo veículo."
              />
            </div>
            <div class="col-12 col-md-4">
              <q-input
                v-model.number="form.quantidade_eixos"
                type="number"
                label="Qtd. de eixos"
                outlined
                color="green-6"
                hint="Preenchido automaticamente pelo veículo."
              />
            </div>
          </div>

          <div class="row q-col-gutter-md">
            <div class="col-12 col-md-4">
              <q-input
                v-model.number="form.toneladaCarga"
                type="number"
                step="0.1"
                label="Toneladas da carga *"
                :rules="[(val) => !!val || 'Campo obrigatório']"
                outlined
                color="green-6"
              />
            </div>
            <div class="col-12 col-md-4">
              <q-input
                v-model.number="form.kmCarregado"
                type="number"
                label="KM rodado carregado *"
                :rules="[(val) => !!val || 'Campo obrigatório']"
                outlined
                color="green-6"
                hint="Distância percorrida com carga."
              />
            </div>
            <div class="col-12 col-md-4">
              <q-input
                v-model.number="form.kmVazio"
                type="number"
                label="KM rodado vazio"
                outlined
                color="green-6"
                hint="Distância percorrida sem carga."
              />
            </div>
          </div>

          <q-separator spaced="lg" />

          <div class="text-h6 text-green-8 q-mb-sm">Custos e Valores</div>
          <div class="row q-col-gutter-md">
            <div class="col-12 col-md-4">
              <q-input
                v-model.number="form.precoCombustivel"
                type="number"
                step="0.01"
                label="Preço combustível (R$/L) *"
                :rules="[(val) => !!val || 'Campo obrigatório']"
                outlined
                color="green-6"
                prefix="R$"
              />
            </div>
            <div class="col-12 col-md-4">
              <q-input
                v-model.number="form.pedagio"
                type="number"
                step="0.01"
                label="Pedágio (R$)"
                outlined
                color="green-6"
                prefix="R$"
                hint="Valor estimado (editável)"
              >
                <template v-slot:append>
                  <q-btn
                    v-if="valorPedagioFoiEditado"
                    icon="restart_alt"
                    flat
                    round
                    dense
                    color="orange-8"
                    @click="resetarPedagio"
                  >
                    <q-tooltip class="bg-orange-9 text-body2">Restaurar valor estimado</q-tooltip>
                  </q-btn>

                  <q-icon name="info" color="grey-7" class="cursor-pointer">
                    <q-tooltip
                      anchor="top middle"
                      self="bottom middle"
                      :offset="[10, 10]"
                      class="bg-grey-9 text-body2 shadow-2"
                    >
                      {{ mensagemHintDadosPedagio }}
                    </q-tooltip>
                  </q-icon>
                </template>
              </q-input>
            </div>
            <div class="col-12 col-md-4">
              <q-input
                v-model.number="form.valor_tonelada"
                type="number"
                step="0.01"
                label="Valor por tonelada (R$) *"
                :rules="[(val) => !!val || 'Campo obrigatório']"
                outlined
                color="green-6"
                prefix="R$"
              />
            </div>
          </div>

          <div class="row q-col-gutter-md">
            <div class="col-12 col-md-4">
              <q-input
                v-model.number="form.commissao_motorista"
                type="number"
                label="Comissão do motorista (%) *"
                :rules="[(val) => !!val || 'Campo obrigatório']"
                mask="##"
                outlined
                color="green-6"
                prefix="%"
              />
            </div>
          </div>

          <q-separator spaced="lg" />

          <div class="row justify-between q-mt-md">
            <q-btn label="Calcular frete" type="submit" color="green-8" size="lg" no-caps />
            <q-btn label="Limpar" flat color="grey-7" @click="limparFormulario" />
          </div>
        </q-form>
      </q-card-section>
    </q-card>
  </q-page>
</template>

<script setup>
import { ref, reactive, onMounted, watch, nextTick, computed } from 'vue'
import { useQuasar } from 'quasar'
import MapaComponent from 'src/components/MapaComponent.vue'
import ResultadoCalculoComponent from 'src/components/ResultadoCalculoComponent.vue'
import { calcularRotaComPedagio } from 'src/services/googleDirectionsService.js'
import { buscarCidadesDebounced } from 'src/services/googlePlacesService'
import {
  BuscarTiposCarga,
  simularCalculoFrete,
  salvarFreteCalculado,
} from 'src/services/calcularFreteService'
import { buscarCaminhoes } from 'src/services/caminhaoService'
import { useCalculoStore } from 'src/stores/calculo-store'

const mapComponentRef = ref(null)
const $q = useQuasar()

const formRef = ref(null)
const calculoStore = useCalculoStore()

const formVazio = {
  origem: '',
  destino: '',
  distancia: null,
  veiculo: null,
  tipoCarga: null,
  precoCombustivel: null,
  quantidade_eixos: null,
  consumo_km_por_l_vazio: null,
  consumo_km_por_l_carregado: null,
  toneladaCarga: null,
  kmCarregado: null,
  kmVazio: null,
  pedagio: null,
  valor_tonelada: null,
  commissao_motorista: null,
}

const form = reactive({ ...formVazio })
const resultadoRota = ref(null)
const dadosPedagio = ref(null)
const caminhoes = ref([])
const tiposCarga = ref([])
const carregandoDados = ref(true)
const resultadoCalculo = ref(null)
const caminhoesListaCompleta = ref([])

const opcoesOrigem = ref([])
const opcoesDestino = ref([])

const filtrarOrigem = (val, update) => {
  buscarCidadesDebounced(val, (resultados) => {
    update(() => {
      opcoesOrigem.value = resultados
    })
  })
}

const filtrarDestino = (val, update) => {
  buscarCidadesDebounced(val, (resultados) => {
    update(() => {
      opcoesDestino.value = resultados
    })
  })
}

const carregarTiposCarga = async () => {
  const result = await BuscarTiposCarga()
  if (result.success) {
    tiposCarga.value = result.data.map((item) => ({
      label: item.nome,
      value: item.id,
    }))
  } else {
    $q.notify({ type: 'negative', message: result.message })
  }
}

const carregarCaminhoes = async () => {
  const result = await buscarCaminhoes()
  if (result.success) {
    caminhoesListaCompleta.value = result.data

    caminhoes.value = result.data.map((item) => ({
      label: item.modelo,
      value: item.id,
    }))
  } else {
    $q.notify({ type: 'negative', message: result.message })
  }
}

const calcularFrete = async () => {
  if (!form.distancia) {
    $q.notify({ type: 'negative', message: 'Por favor, busque a rota primeiro.' })
    return
  }

  $q.loading.show({ message: 'Calculando custos...' })

  try {
    const result = await simularCalculoFrete(form)

    if (result.success) {
      resultadoCalculo.value = result.data

      await $q
        .dialog({
          component: ResultadoCalculoComponent,
          componentProps: {
            resultados: result.data,
          },
        })
        .onOk(async () => {
          $q.loading.show({ message: 'Salvando cálculo...' })
          try {
            await salvarCalculo()
          } finally {
            $q.loading.hide()
          }
        })
    } else {
      $q.notify({ type: 'negative', message: result.message })
    }
  } catch (error) {
    console.error('Erro no processo de cálculo:', error)
    $q.notify({ type: 'negative', message: 'Ocorreu um erro inesperado.' })
  } finally {
    $q.loading.hide()
  }
}

const salvarCalculo = async () => {
  const calculoCompleto = {
    ...resultadoCalculo.value,
    ...form,
  }

  console.log('Dados que estão sendo enviados para o backend:', calculoCompleto);

  const result = await salvarFreteCalculado(calculoCompleto)

  if (result.success) {
    $q.notify({ type: 'positive', message: result.message })
    limparFormulario()
    resultadoCalculo.value = null
  } else {
    $q.notify({ type: 'negative', message: result.message })
  }
}

const buscarRota = async () => {
  if (!form.origem || !form.destino) {
    $q.notify({
      type: 'negative',
      message: 'Por favor, preencha a origem e o destino para buscar a rota.',
      icon: 'warning',
    })
    return
  }

  if (!form.veiculo) {
    $q.notify({
      type: 'warning',
      message: 'Por favor, selecione um veículo primeiro.',
    })
    return
  }

  if (!form.quantidade_eixos || form.quantidade_eixos <= 0) {
    $q.notify({
      type: 'warning',
      message: 'A quantidade de eixos do veículo deve ser informada e maior que zero.',
    })
    return
  }

  $q.loading.show({ message: 'Calculando rota e pedágios...' })

  try {
    const data = await calcularRotaComPedagio(form.origem, form.destino, form.quantidade_eixos)
    if (data && data.ok) {
      const rota = data.route

      if (mapComponentRef.value && rota.polyline.encodedPolyline) {
        await mapComponentRef.value.desenharRotaPorPolyline(rota.polyline.encodedPolyline)
      }

      const distanciaEmKm = Math.round(rota.distanceMeters / 1000)
      form.distancia = distanciaEmKm
      form.kmCarregado = distanciaEmKm

      form.pedagio = rota.tollInfo.cost.toFixed(2)
      dadosPedagio.value = data.route.tollInfo

      const duracaoFormatada = formatarDuracao(rota.duration)
      resultadoRota.value = {
        distancia: `${distanciaEmKm} km`,
        duracao: duracaoFormatada,
      }
    }
  } catch (error) {
    console.log('Erro ao buscar a rota', error)
    $q.notify({ type: 'negative', message: 'Não foi possível encontrar a rota.' })
  } finally {
    $q.loading.hide()
  }
}

function preencherFormulario(calculoCarregado) {
  form.origem = `${calculoCarregado.origem_cidade}, ${calculoCarregado.origem_uf}`
  form.destino = `${calculoCarregado.destino_cidade}, ${calculoCarregado.destino_uf}`
  form.distancia = calculoCarregado.km_total
  form.veiculo = calculoCarregado.caminhao_id
  form.tipoCarga = calculoCarregado.tipo_carga_id
  form.precoCombustivel = calculoCarregado.preco_combustivel_l
  form.pedagio = calculoCarregado.pedagios_total
  form.quantidade_eixos = calculoCarregado.quantidade_eixos
  form.consumo_km_por_l_vazio = calculoCarregado.consumo_km_por_l_vazio
  form.consumo_km_por_l_carregado = calculoCarregado.consumo_km_por_l_carregado
  form.toneladaCarga = calculoCarregado.toneladas_carga;
  form.kmCarregado = calculoCarregado.km_rodado_carregado;
  form.kmVazio = calculoCarregado.km_rodado_vazio;
  form.valor_tonelada = calculoCarregado.valor_por_tonelada;
  form.commissao_motorista = calculoCarregado.comissao_motorista;

  $q.notify({
    message: 'Cálculo carregado. Clique em "Buscar rota" para visualizar o mapa.',
    icon: 'history',
    color: 'info',
    position: 'top',
  })
}

const formatarDuracao = (duracaoString) => {
  if (!duracaoString || !duracaoString.endsWith('s')) {
    return '--'
  }
  const totalSegundos = parseInt(duracaoString, 10)
  if (isNaN(totalSegundos)) {
    return '--'
  }
  if (totalSegundos < 60) {
    return 'Menos de 1m'
  }
  const horas = Math.floor(totalSegundos / 3600)
  const minutos = Math.floor((totalSegundos % 3600) / 60)
  const partes = []
  if (horas > 0) {
    partes.push(`${horas}h`)
  }
  if (minutos > 0 || horas === 0) {
    partes.push(`${minutos}m`)
  }
  return partes.join(' ')
}

const mensagemHintDadosPedagio = computed(() => {
  if (!dadosPedagio.value || !dadosPedagio.value.baseCost) {
    return 'Busque uma rota para ver o detalhe do cálculo.'
  }

  const base = dadosPedagio.value.baseCost.toLocaleString('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  })
  const eixos = dadosPedagio.value.eixos

  return `Cálculo: ${base} (tarifa base) x ${eixos} eixos`
})

const valorPedagioFoiEditado = computed(() => {
  if (!dadosPedagio.value) {
    return false
  }

  const diff = Math.abs(Number(form.pedagio) - dadosPedagio.value.cost)
  return diff > 0.01
})

const resetarPedagio = () => {
  if (dadosPedagio.value) {
    form.pedagio = dadosPedagio.value.cost.toFixed(2)
    $q.notify({
      message: 'Valor do pedágio restaurado para a estimativa da API.',
      icon: 'history',
      color: 'info',
      position: 'top',
      timeout: 1500,
    })
  }
}

const limparFormulario = () => {
  Object.assign(form, formVazio)
  resultadoRota.value = null
  dadosPedagio.value = null
  if (mapComponentRef.value) {
    mapComponentRef.value.clearDirections()
  }

  nextTick(() => {
    if (formRef.value) {
      formRef.value.resetValidation()
    }
  })
}

onMounted(async () => {
  if (calculoStore.calculoParaCarregar) {
    preencherFormulario(calculoStore.calculoParaCarregar)

    calculoStore.limparCalculoParaCarregar()
  }

  carregandoDados.value = true
  await Promise.all([carregarTiposCarga(), carregarCaminhoes()])
  carregandoDados.value = false
})

watch(
  () => form.veiculo,
  (novoIdDoVeiculo) => {
    if (!novoIdDoVeiculo) {
      form.consumo_km_por_l_vazio = null
      form.consumo_km_por_l_carregado = null
      form.quantidade_eixos = null
      return
    }

    const veiculoSelecionado = caminhoesListaCompleta.value.find((v) => v.id === novoIdDoVeiculo)

    if (veiculoSelecionado) {
      form.consumo_km_por_l_vazio = veiculoSelecionado.consumo_km_por_l_vazio
      form.consumo_km_por_l_carregado = veiculoSelecionado.consumo_km_por_l_carregado
      form.quantidade_eixos = veiculoSelecionado.quantidade_eixos
    }
  },
)
</script>
