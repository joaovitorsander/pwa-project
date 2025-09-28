<template>
  <q-dialog ref="dialogRef" @hide="onDialogHide" persistent>
    <q-card class="q-dialog-plugin" style="width: 600px; max-width: 80vw">
      <q-card-section class="bg-green-8 text-white">
        <div class="text-h6">📊 Resumo do frete</div>
      </q-card-section>

      <q-card-section class="q-pt-md">
        <div class="text-subtitle1">
          O frete foi calculado com sucesso. Verifique os valores abaixo:
        </div>

        <div class="q-my-md q-pa-md bg-grey-2 rounded-borders">
          <div class="row justify-between">
            <span>Custo com combustível:</span>
            <span class="text-weight-bold">{{ formatBRL(resultados.custoTotalCombustivel) }}</span>
          </div>
          <div class="row justify-between">
            <span>Custo com pedágios:</span>
            <span class="text-weight-bold">{{ formatBRL(resultados.valorPedagio) }}</span>
          </div>
          <div class="row justify-between">
            <span>Comissão do motorista:</span>
            <span class="text-weight-bold">{{ formatBRL(resultados.valorComissaoMotorista) }}</span>
          </div>
          <q-separator class="q-my-sm" />
          <div class="row justify-between text-subtitle2 text-weight-medium">
            <span>CUSTO OPERACIONAL TOTAL:</span>
            <span class="text-weight-bold text-red-7"
              >{{ formatBRL(resultados.totalCustosOperacionais) }}</span
            >
          </div>
        </div>

        <div class="q-my-md q-pa-md bg-green-1 rounded-borders">
          <div class="row justify-between">
            <span>Valor bruto do frete:</span>
            <span class="text-weight-bold">{{ formatBRL(resultados.freteBruto) }}</span>
          </div>
          <div class="row justify-between text-subtitle2 text-weight-medium">
            <span>LUCRO ESTIMADO:</span>
            <span class="text-weight-bold text-green-8">{{ formatBRL(resultados.lucroEstimado) }}</span>
          </div>
        </div>
        <div class="text-caption text-grey-7">
          Valor mínimo sugerido pela ANTT: {{ formatBRL(resultados.valorAnttSugerido) }}
        </div>
      </q-card-section>

      <q-card-actions align="right" class="q-pa-md">
        <q-btn label="Fechar" color="grey-7" flat no-caps @click="onDialogCancel" />
        <q-btn label="Salvar cálculo" color="green-8" no-caps @click="onDialogOK" />
      </q-card-actions>
    </q-card>
  </q-dialog>
</template>

<script setup>
import { useDialogPluginComponent } from 'quasar'

defineProps({
  resultados: {
    type: Object,
    required: true,
  },
})

const formatBRL = (value) => {
  const numericValue = parseFloat(value)

  if (isNaN(numericValue)) {
    return 'R$ 0,00'
  }

  return numericValue.toLocaleString('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  })
}

defineEmits([...useDialogPluginComponent.emits])

const { dialogRef, onDialogHide, onDialogOK, onDialogCancel } = useDialogPluginComponent()
</script>
