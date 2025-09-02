<template>
  <q-page class="q-pa-md">
    <div class="row items-center justify-between q-mb-md">
      <div class="row items-center q-gutter-sm">
        <q-icon name="local_shipping" color="green-7" size="22px" />
        <div class="text-subtitle1 text-weight-medium">Meus Caminhões</div>
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
          <div class="text-subtitle1 text-weight-medium">{{ tituloFormulario }}</div>
        </q-card-section>

        <q-separator />

        <q-card-section class="q-pa-md">
          <q-form @submit.prevent="salvar" class="q-gutter-md">
            <q-input
              v-model="form.modelo"
              label="Modelo *"
              placeholder="Ex: Scania R450, Volvo FH540"
              :rules="[(val) => !!val || 'Informe o modelo']"
              filled
            />
            <q-input
              v-model="form.placa"
              label="Placa *"
              placeholder="ABC-1234"
              :rules="[(val) => !!val || 'Informe a placa']"
              filled
            />

            <div class="row q-col-gutter-md">
              <div class="col-12 col-md-6">
                <q-input
                  v-model.number="form.ano"
                  type="number"
                  label="Ano *"
                  :rules="[(val) => !!val || 'Informe o ano']"
                  filled
                />
              </div>
              <div class="col-12 col-md-6">
                <q-input
                  v-model.number="form.quantidade_eixos"
                  type="number"
                  label="Quantidade de Eixos *"
                  :rules="[(val) => !!val || 'Informe os eixos']"
                  filled
                />
              </div>
            </div>

            <div class="row q-col-gutter-md">
              <div class="col-12 col-md-6">
                <q-input
                  v-model.number="form.consumo_km_por_l_vazio"
                  type="number"
                  step="0.1"
                  label="Consumo (km/L) vazio*"
                  :rules="[(val) => !!val || 'Informe o consumo']"
                  filled
                />
              </div>
              <div class="col-12 col-md-6">
                <q-input
                  v-model.number="form.consumo_km_por_l_carregado"
                  type="number"
                  step="0.1"
                  label="Consumo (km/L) carregado*"
                  :rules="[(val) => !!val || 'Informe o consumo']"
                  filled
                />
              </div>
            </div>

            <div class="row q-col-gutter-md">
              <div class="col-12 col-md-6">
                <q-input
                  v-model.number="form.capacidade_ton"
                  type="number"
                  step="0.1"
                  label="Capacidade (ton) *"
                  :rules="[(val) => !!val || 'Informe a capacidade']"
                  filled
                />
              </div>
            </div>

            <div class="row justify-end q-gutter-sm q-mt-md">
              <q-btn :label="labelBotaoSalvar" type="submit" color="green-6" no-caps />
            </div>
          </q-form>
        </q-card-section>
      </q-card>
    </div>
  </q-page>
</template>

<script>
import * as caminhaoService from 'src/services/caminhaoService'

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

export default {
  name: 'CaminhoesPage',
  data() {
    return {
      modoLista: true,
      carregando: false,
      caminhoes: [],
      form: { ...formVazio },
      filtros: {
        termo: '',
        campo: 'modelo',
      },
      opcoesDeFiltro: [
        { label: 'Modelo', value: 'modelo' },
        { label: 'Placa', value: 'placa' },
        { label: 'Ano', value: 'ano' },
      ],
    }
  },
  computed: {
    placeholderPesquisa() {
      const selecionado = this.opcoesDeFiltro.find((opt) => opt.value === this.filtros.campo)
      return `Pesquisar por ${selecionado.label}...`
    },
    tipoInputPesquisa() {
      return this.filtros.campo === 'ano' ? 'number' : 'text'
    },
    modoEdicao() {
      return this.form.id !== null
    },
    tituloFormulario() {
      return this.modoEdicao ? 'Editar Caminhão' : 'Cadastrar Novo Caminhão'
    },
    labelBotaoSalvar() {
      return this.modoEdicao ? 'Salvar Alterações' : 'Cadastrar Caminhão'
    },
  },
  methods: {
    fecharFormulario() {
      this.modoLista = true
      this.form = { ...formVazio }
    },
    abrirFormularioCadastro() {
      this.modoLista = false
      this.form = { ...formVazio }
    },
    abrirFormularioEdicao(caminhao) {
      this.modoLista = false
      this.form = { ...caminhao }
    },

    async carregarCaminhoes() {
      this.carregando = true
      const filtrosParaApi = {}

      const campo = this.filtros.campo
      const termo = this.filtros.termo

      if (termo) {
        filtrosParaApi[campo] = termo
      }

      const result = await caminhaoService.buscarCaminhoes(filtrosParaApi)

      if (result.success) {
        this.caminhoes = result.data
      } else {
        this.$q.notify({ type: 'negative', message: result.message })
      }
      this.carregando = false
    },

    async salvar() {
      let result

      if (this.modoEdicao) {
        result = await caminhaoService.atualizarCaminhao(this.form.id, this.form)
      } else {
        result = await caminhaoService.cadastrarCaminhao(this.form)
      }

      if (result.success) {
        this.$q.notify({ type: 'positive', message: result.message })
        this.fecharFormulario()
        await this.carregarCaminhoes()
      } else {
        this.$q.notify({ type: 'negative', message: result.message })
      }
    },

    confirmarExclusao(caminhao) {
      this.$q
        .dialog({
          title: 'Excluir caminhão',
          message: `Deseja excluir o caminhão ${caminhao.modelo} (${caminhao.placa})? Esta ação não pode ser desfeita.`,
          cancel: true,
          persistent: true,
          ok: { label: 'Excluir', color: 'red-5', flat: true },
          cancel: { label: 'Cancelar', flat: true },
        })
        .onOk(() => {
          this.excluir(caminhao.id)
        })
    },

    async excluir(id) {
      const result = await caminhaoService.excluirCaminhao(id)

      if (result.success) {
        this.$q.notify({ type: 'positive', message: result.message })
        await this.carregarCaminhoes()
      } else {
        this.$q.notify({ type: 'negative', message: result.message })
      }
    },
  },
  mounted() {
    this.carregarCaminhoes()
  },
}
</script>
