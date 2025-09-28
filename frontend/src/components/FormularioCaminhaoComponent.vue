<template>
  <q-card flat bordered>
    <q-card-section>
      <div class="text-h6 text-green-8">{{ tituloFormulario }}</div>
    </q-card-section>

    <q-separator />

    <q-card-section class="q-pa-md">
      <q-form @submit.prevent="salvar" class="q-gutter-y-md">
        <div class="text-subtitle1 text-weight-medium text-grey-8">Identificação do veículo</div>
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
              @update:model-value="(value) => (form.placa = String(value || '').toUpperCase())"
              :rules="[
                (val) => !!val || 'Informe a placa',
                (val) => placaEhValida(val) || 'Formato de placa inválido.',
              ]"
              outlined
              color="green-6"
            />
          </div>
        </div>

        <q-separator spaced="sm" />

        <div class="text-subtitle1 text-weight-medium text-grey-8">Especificações técnicas</div>
        <div class="row q-col-gutter-md">
          <div class="col-12 col-sm-6 col-md-4">
            <q-input
              v-model.number="form.ano"
              type="number"
              label="Ano *"
              :rules="[
                (val) => !!val || 'Informe o ano',
                (val) => val > 0 || 'O valor não pode ser negativo ou zero',
              ]"
              outlined
              color="green-6"
            />
          </div>
          <div class="col-12 col-sm-6 col-md-4">
            <q-input
              v-model.number="form.quantidade_eixos"
              type="number"
              label="Qtd. de eixos *"
              :rules="[
                (val) => !!val || 'Informe os eixos',
                (val) => val > 0 || 'O valor não pode ser negativo ou zero',
              ]"
              outlined
              color="green-6"
            />
          </div>
          <div class="col-12 col-sm-6 col-md-4">
            <q-input
              v-model.number="form.capacidade_ton"
              type="number"
              step="0.1"
              label="Capacidade (ton) *"
              :rules="[
                (val) => !!val || 'Informe a capacidade',
                (val) => val > 0 || 'O valor não pode ser negativo ou zero',
              ]"
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
              step="0.01"
              label="Consumo vazio (km/L) *"
              :rules="[
                (val) => !!val || 'Informe o consumo',
                (val) => val > 0 || 'O valor não pode ser negativo ou zero',
              ]"
              outlined
              color="green-6"
            />
          </div>
          <div class="col-12 col-md-6">
            <q-input
              v-model.number="form.consumo_km_por_l_carregado"
              type="number"
              step="0.01"
              label="Consumo carregado (km/L) *"
              :rules="[
                (val) => !!val || 'Informe o consumo',
                (val) => val > 0 || 'O valor não pode ser negativo ou zero',
              ]"
              outlined
              color="green-6"
            />
          </div>
        </div>

        <div class="row justify-end items-center q-gutter-md q-mt-lg">
          <q-btn label="Cancelar" color="grey-7" flat no-caps @click="$emit('cancelado')" />
          <q-btn
            :label="labelBotaoSalvar"
            type="submit"
            color="green-8"
            no-caps
            size="md"
            class="q-px-lg"
          />
        </div>
      </q-form>
    </q-card-section>
  </q-card>
</template>

<script setup>
import { reactive, computed, watch } from 'vue'
import { useQuasar } from 'quasar'
import * as caminhaoService from 'src/services/caminhaoService'

const props = defineProps({
  caminhaoParaEditar: {
    type: Object,
    default: null,
  },
})
const emit = defineEmits(['salvo', 'cancelado'])

const $q = useQuasar()

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

const modoEdicao = computed(() => form.id !== null && form.id !== undefined)
const tituloFormulario = computed(() =>
  modoEdicao.value ? 'Editar caminhão' : 'Cadastrar novo caminhão',
)
const labelBotaoSalvar = computed(() =>
  modoEdicao.value ? 'Salvar alterações' : 'Cadastrar caminhão',
)

watch(
  () => props.caminhaoParaEditar,
  (novoCaminhao) => {
    if (novoCaminhao) {
      Object.assign(form, novoCaminhao)
    } else {
      Object.assign(form, formVazio)
    }
  },
  { immediate: true },
)

const salvar = async () => {
  let result
  if (modoEdicao.value) {
    result = await caminhaoService.atualizarCaminhao(form.id, form)
  } else {
    result = await caminhaoService.cadastrarCaminhao(form)
  }

  if (result.success) {
    $q.notify({ type: 'positive', message: result.message })
    emit('salvo')
  } else {
    $q.notify({ type: 'negative', message: result.message })
  }
}

function placaEhValida(placa) {
  if (!placa) return true

  const placaUpper = String(placa).toUpperCase()

  const regexPadrao = /^[A-Z]{3}[0-9]{4}$/

  const regexMercosul = /^[A-Z]{3}[0-9][A-Z][0-9]{2}$/

  return regexPadrao.test(placaUpper) || regexMercosul.test(placaUpper)
}
</script>
