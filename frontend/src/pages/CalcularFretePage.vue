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
          Calcular Frete
        </div>
      </q-card-section>

      <q-separator />

      <q-card-section>
        <q-form @submit.prevent="calcularFrete" class="q-gutter-y-md">
          <div class="text-h6 text-green-8 q-mb-sm">Detalhes da Rota</div>
          <div class="row q-col-gutter-md">
            <div class="col-12 col-md-6">
              <q-input
                v-model="form.origem"
                label="Origem *"
                placeholder="Cidade de origem"
                :rules="[(val) => !!val || 'Campo obrigatório']"
                outlined
                color="green-6"
              />
            </div>
            <div class="col-12 col-md-6">
              <q-input
                v-model="form.destino"
                label="Destino *"
                placeholder="Cidade de destino"
                :rules="[(val) => !!val || 'Campo obrigatório']"
                outlined
                color="green-6"
              />
            </div>
            <div class="col-12">
              <q-input
                v-model.number="form.distancia"
                type="number"
                label="Distância (km) *"
                readonly
                outlined
                color="green-6"
                hint="Distância calculada automaticamente após a rota."
              />
            </div>
          </div>

          <q-separator spaced="lg" />

          <div class="text-h6 text-green-8 q-mb-sm">Informações do Veículo e Carga</div>
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
                label="Tipo de Carga *"
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
                label="Consumo Vazio (km/L)"
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
                label="Consumo Carregado (km/L)"
                outlined
                color="green-6"
                hint="Preenchido automaticamente pelo veículo."
              />
            </div>
            <div class="col-12 col-md-4">
              <q-input
                v-model.number="form.quantidade_eixos"
                type="number"
                label="Qtd. de Eixos"
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
                label="Toneladas da Carga *"
                :rules="[(val) => !!val || 'Campo obrigatório']"
                outlined
                color="green-6"
              />
            </div>
            <div class="col-12 col-md-4">
              <q-input
                v-model.number="form.kmCarregado"
                type="number"
                label="KM Rodado Carregado *"
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
                label="KM Rodado Vazio"
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
                label="Preço Combustível (R$/L) *"
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
              />
            </div>
            <div class="col-12 col-md-4">
              <q-input
                v-model.number="form.valor_tonelada"
                type="number"
                step="0.01"
                label="Valor por Tonelada (R$) *"
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
                label="Comissão do Motorista (%) *"
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
            <q-btn label="Calcular Rota e Frete" type="submit" color="green-8" size="lg" no-caps />
            <q-btn label="Limpar" flat color="grey-7" @click="limparFormulario" />
          </div>
        </q-form>
      </q-card-section>
    </q-card>
  </q-page>
</template>

<script setup>
import { ref, reactive, onMounted, watch } from 'vue'
import { useQuasar } from 'quasar'
import MapaComponent from 'src/components/MapaComponent.vue'
import ResultadoCalculoComponent from 'src/components/ResultadoCalculoComponent.vue'
import { calcularRotaGoogle } from 'src/services/directions.js'
import { BuscarTiposCarga, simularCalculoFrete } from 'src/services/calcularFreteService'
import { buscarCaminhoes } from 'src/services/caminhaoService'

const mapComponentRef = ref(null)
const $q = useQuasar()

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
const caminhoes = ref([])
const tiposCarga = ref([])
const carregandoDados = ref(true)
const resultadoCalculo = ref(null)
const caminhoesListaCompleta = ref([])

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
  if (!form.origem || !form.destino) {
    $q.notify({ type: 'negative', message: 'Por favor, preencha a origem e o destino.' })
    return
  }
  try {
    const response = await calcularRotaGoogle(form.origem, form.destino)
    if (mapComponentRef.value) {
      mapComponentRef.value.setDirections(response)
    }
    const rota = response.routes[0].legs[0]
    if (rota.distance) {
      form.distancia = Math.round(rota.distance.value / 1000)
      resultadoRota.value = {
        distancia: rota.distance.text,
        duracao: rota.duration.text,
      }
    }
    console.log('Dados para o cálculo final do frete:', form)
  } catch (error) {
    console.error('Erro ao buscar rota:', error)
    $q.notify({ type: 'negative', message: 'Não foi possível calcular a rota.' })
  }

  const result = await simularCalculoFrete(form)

  if (result.success) {
    resultadoCalculo.value = result.data
    $q.dialog({
      component: ResultadoCalculoComponent,
      componentProps: {
        resultados: result.data,
      },
    }).onOk(() => {
      // salvarCalculoFinal();
    })
  } else {
    $q.notify({ type: 'negative', message: result.message })
  }
}

const limparFormulario = () => {
  Object.assign(form, formVazio)
  resultadoRota.value = null
  if (mapComponentRef.value) {
    mapComponentRef.value.clearDirections()
  }
}

onMounted(async () => {
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
