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
        <q-form @submit.prevent="calcularFrete" class="q-gutter-md">
          <q-input
            v-model="form.origem"
            label="Origem *"
            placeholder="Cidade de origem"
            :dense="true"
            required
          />
          <q-input
            v-model="form.destino"
            label="Destino *"
            placeholder="Cidade de destino"
            :dense="true"
            required
          />
          <q-input
            v-model.number="form.distancia"
            type="number"
            label="Distância (km) *"
            readonly
            required
          />

          <q-select
            v-model="form.veiculo"
            :options="veiculos"
            label="Veículo *"
            required
            emit-value
            map-options
          />

          <q-select
            v-model="form.tipoCarga"
            :options="tiposCarga"
            label="Tipo de Carga *"
            required
            emit-value
            map-options
          />

          <div class="row q-col-gutter-md">
            <div class="col-6">
              <q-input
                v-model.number="form.precoCombustivel"
                type="number"
                label="Preço Combustível (R$/L) *"
                required
                prefix="R$"
              />
            </div>
            <div class="col-6">
              <q-input
                v-model.number="form.consumo"
                type="number"
                label="Consumo (km/L) *"
                required
              />
            </div>
          </div>

          <q-input v-model.number="form.pedagio" type="number" label="Pedágio (R$)" prefix="R$" />

          <div class="row justify-between q-mt-md">
            <q-btn label="Calcular Rota e Frete" type="submit" color="green" />
            <q-btn label="Limpar" flat @click="limparFormulario" />
          </div>
        </q-form>
      </q-card-section>
    </q-card>
  </q-page>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useQuasar } from 'quasar'
import MapaComponent from 'src/components/MapaComponent.vue'
import { calcularRotaGoogle } from 'src/services/directions.js'
import { BuscarTiposCarga } from 'src/services/calcularFreteService'

const $q = useQuasar()
const mapComponentRef = ref(null)

const form = reactive({
  origem: '',
  destino: '',
  distancia: null,
  veiculo: null,
  tipoCarga: null,
  precoCombustivel: null,
  consumo: null,
  pedagio: null,
})
const resultadoRota = ref(null)

const veiculos = [
  { label: 'Caminhão Truck', value: 'truck' },
  { label: 'Carreta Simples', value: 'carreta_simples' },
]
const tiposCarga = ref([])

const carregarTiposCarga = async () => {
  const dados = await BuscarTiposCarga()

  tiposCarga.value = dados.map((item) => ({
    label: item.nome,
    value: item.id_tipo_carga,
  }))
}

onMounted(() => {
  carregarTiposCarga()
})

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
  }
}

const limparFormulario = () => {
  Object.assign(form, {
    origem: '',
    destino: '',
    distancia: null,
    veiculo: null,
    tipoCarga: null,
    precoCombustivel: null,
    consumo: null,
    pedagio: null,
  })
  resultadoRota.value = null

  if (mapComponentRef.value) {
    mapComponentRef.value.clearDirections()
  }
}
</script>
