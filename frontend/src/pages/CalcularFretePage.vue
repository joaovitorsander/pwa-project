<template>
  <q-page class="q-pa-md">
    <!-- Seção de visualização da rota -->
    <q-card flat bordered class="q-mb-md">
      <q-card-section class="q-pa-none">
        <MapaComponent :center="{ lat: -23.55052, lng: -46.633308 }" :zoom="10" style="width: 100%; height: 300px">
        </MapaComponent>
      </q-card-section>
    </q-card>

    <!-- Formulário de cálculo do frete -->
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
          <q-input v-model="form.origem" label="Origem *" placeholder="Cidade de origem" :dense="true" required
            prefix-icon="location_on" />
          <q-input v-model="form.destino" label="Destino *" placeholder="Cidade de destino" :dense="true" required
            prefix-icon="location_on" />
          <q-input v-model.number="form.distancia" type="number" label="Distância (km) *" required />

          <q-select v-model="form.veiculo" :options="veiculos" label="Veículo *" required emit-value map-options />

          <q-select v-model="form.tipoCarga" :options="tiposCarga" label="Tipo de Carga *" required emit-value
            map-options />

          <div class="row q-col-gutter-md">
            <div class="col-6">
              <q-input v-model.number="form.precoCombustivel" type="number" label="Preço Combustível (R$/L) *" required
                prefix="R$" />
            </div>
            <div class="col-6">
              <q-input v-model.number="form.consumo" type="number" label="Consumo (km/L) *" required />
            </div>
          </div>

          <q-input v-model.number="form.pedagio" type="number" label="Pedágio (R$)" prefix="R$" />

          <div class="row justify-between q-mt-md">
            <q-btn label="Calcular Frete" type="submit" color="green" />
            <q-btn label="Limpar" flat @click="limparFormulario" />
          </div>
        </q-form>
      </q-card-section>
    </q-card>
  </q-page>
</template>

<script>
import MapaComponent from 'src/components/MapaComponent.vue';

export default {
  name: 'CalcularFretePage',
  data() {
    return {
      form: {
        origem: '',
        destino: '',
        distancia: null,
        veiculo: null,
        tipoCarga: null,
        precoCombustivel: null,
        consumo: null,
        pedagio: null
      },
      veiculos: [
        { label: 'Caminhão Truck', value: 'truck' },
        { label: 'Carreta Simples', value: 'carreta_simples' }
      ],
      tiposCarga: [
        { label: 'Granel Sólido', value: 'granel_solido' },
        { label: 'Granel Líquido', value: 'granel_liquido' },
        { label: 'Carga Geral', value: 'carga_geral' }
      ]
    };
  },
  methods: {
    calcularFrete() {
      console.log('Calculando com os dados:', this.form);
      // lógica de cálculo virá depois
    },
    limparFormulario() {
      this.form = {
        origem: '',
        destino: '',
        distancia: null,
        veiculo: null,
        tipoCarga: null,
        precoCombustivel: null,
        consumo: null,
        pedagio: null
      };
    }
  },
  components: {
    MapaComponent
  }
};

</script>
