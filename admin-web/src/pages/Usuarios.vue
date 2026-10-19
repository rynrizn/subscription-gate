<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../lib/supabase'

const router = useRouter()

// Estados
const licencias = ref([])
const cargando = ref(true)
const busqueda = ref('')
const filtroEstado = ref('todos')
const adminEmail = ref('')
const accionEnProgreso = ref({}) // { [usuario_id]: 'accion_nombre' }
const feedback = ref(null) // { tipo: 'exito' | 'error', mensaje: '' }

// Modal de confirmación
const modalConfirmacion = ref({
  abierto: false,
  titulo: '',
  mensaje: '',
  textoBoton: 'Confirmar',
  peligroso: false,
  ejecutar: null,
})

// Cargar sesión del administrador y lista de licencias
onMounted(async () => {
  const { data: { session } } = await supabase.auth.getSession()
  if (session?.user?.email) {
    adminEmail.value = session.user.email
  }
  await cargarLicencias()
})

async function cargarLicencias() {
  cargando.value = true
  feedback.value = null

  try {
    const { data, error } = await supabase
      .from('licencias')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      throw error
    }

    licencias.value = data || []
  } catch (err) {
    console.error('Error al cargar licencias:', err)
    mostrarFeedback('error', 'Error al obtener las licencias: ' + (err.message || 'Error desconocido'))
  } finally {
    cargando.value = false
  }
}

// Calcular estado de una licencia
function calcularEstado(lic) {
  if (lic.bloqueada) return 'bloqueada'
  const ahora = new Date()
  const expira = new Date(lic.fecha_fin)
  const diffDias = Math.ceil((expira - ahora) / (1000 * 60 * 60 * 24))

  if (diffDias <= 0) return 'vencida'
  if (diffDias <= 7) return 'por_vencer'
  return 'vigente'
}

function calcularDiasRestantes(fechaFin) {
  const ahora = new Date()
  const expira = new Date(fechaFin)
  const diffDias = Math.ceil((expira - ahora) / (1000 * 60 * 60 * 24))
  return diffDias
}

function formatearFecha(fechaIso) {
  if (!fechaIso) return '—'
  const d = new Date(fechaIso)
  return d.toLocaleDateString('es-ES', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

// Métricas de usuarios
const metricas = computed(() => {
  const total = licencias.value.length
  let vigentes = 0
  let porVencer = 0
  let vencidas = 0
  let bloqueadas = 0

  licencias.value.forEach(lic => {
    const estado = calcularEstado(lic)
    if (estado === 'bloqueada') bloqueadas++
    else if (estado === 'vencida') vencidas++
    else if (estado === 'por_vencer') porVencer++
    else if (estado === 'vigente') vigentes++
  })

  return { total, vigentes, porVencer, vencidas, bloqueadas }
})

// Filtrado de licencias
const licenciasFiltradas = computed(() => {
  return licencias.value.filter(lic => {
    // Filtro por búsqueda de correo o hardware_id
    const termino = busqueda.value.toLowerCase().trim()
    const coincideTexto = !termino ||
      (lic.email && lic.email.toLowerCase().includes(termino)) ||
      (lic.hardware_id && lic.hardware_id.toLowerCase().includes(termino))

    if (!coincideTexto) return false

    // Filtro por estado
    if (filtroEstado.value === 'todos') return true
    return calcularEstado(lic) === filtroEstado.value
  })
})

function mostrarFeedback(tipo, mensaje) {
  feedback.value = { tipo, mensaje }
  setTimeout(() => {
    if (feedback.value?.mensaje === mensaje) {
      feedback.value = null
    }
  }, 4500)
}

// Acciones Administrativas
async function renovar(lic, dias) {
  const uid = lic.usuario_id
  accionEnProgreso.value[uid] = `renovar_${dias}`

  try {
    const { data, error } = await supabase.rpc('admin_renovar', {
      p_usuario: uid,
      p_dias: dias,
    })

    if (error) throw error

    mostrarFeedback('exito', `Licencia de ${lic.email || 'usuario'} extendida por +${dias} días exitosamente.`)
    await cargarLicencias()
  } catch (err) {
    console.error('Error al renovar licencia:', err)
    mostrarFeedback('error', 'No se pudo renovar: ' + (err.message || 'Error'))
  } finally {
    delete accionEnProgreso.value[uid]
  }
}

function confirmarResetHardware(lic) {
  modalConfirmacion.value = {
    abierto: true,
    titulo: 'Resetear equipo vinculado',
    mensaje: `¿Deseas desvincular el equipo de "${lic.email}"? En su próximo inicio de sesión, el usuario podrá vincular un nuevo ordenador.`,
    textoBoton: 'Desvincular Equipo',
    peligroso: false,
    ejecutar: () => ejecutarResetHardware(lic),
  }
}

async function ejecutarResetHardware(lic) {
  const uid = lic.usuario_id
  cerrarModal()
  accionEnProgreso.value[uid] = 'reset_hw'

  try {
    const { error } = await supabase.rpc('admin_reset_hardware', {
      p_usuario: uid,
    })

    if (error) throw error

    mostrarFeedback('exito', `Equipo de ${lic.email} desvinculado correctamente.`)
    await cargarLicencias()
  } catch (err) {
    console.error('Error al resetear hardware:', err)
    mostrarFeedback('error', 'Error al resetear hardware: ' + (err.message || 'Error'))
  } finally {
    delete accionEnProgreso.value[uid]
  }
}

function confirmarBloqueo(lic) {
  const nuevoEstado = !lic.bloqueada
  modalConfirmacion.value = {
    abierto: true,
    titulo: nuevoEstado ? 'Bloquear cuenta de usuario' : 'Desbloquear cuenta',
    mensaje: nuevoEstado
      ? `¿Estás seguro de que deseas bloquear a "${lic.email}"? El usuario no podrá acceder a la aplicación aunque tenga días de suscripción disponibles.`
      : `¿Deseas reactivar el acceso para "${lic.email}"?`,
    textoBoton: nuevoEstado ? 'Bloquear Acceso' : 'Desbloquear Acceso',
    peligroso: nuevoEstado,
    ejecutar: () => ejecutarBloqueo(lic, nuevoEstado),
  }
}

async function ejecutarBloqueo(lic, nuevoEstado) {
  const uid = lic.usuario_id
  cerrarModal()
  accionEnProgreso.value[uid] = 'bloquear'

  try {
    const { error } = await supabase.rpc('admin_bloquear', {
      p_usuario: uid,
      p_bloquear: nuevoEstado,
    })

    if (error) throw error

    mostrarFeedback('exito', `Usuario ${lic.email} ${nuevoEstado ? 'bloqueado' : 'desbloqueado'} con éxito.`)
    await cargarLicencias()
  } catch (err) {
    console.error('Error al cambiar bloqueo:', err)
    mostrarFeedback('error', 'Error en operación: ' + (err.message || 'Error'))
  } finally {
    delete accionEnProgreso.value[uid]
  }
}

function cerrarModal() {
  modalConfirmacion.value.abierto = false
}

async function cerrarSesion() {
  await supabase.auth.signOut()
  router.push('/login')
}
</script>

<template>
  <div class="min-h-screen bg-background flex flex-col">
    <!-- Barra superior de navegación -->
    <header class="border-b border-border bg-surface/70 sticky top-0 z-20 backdrop-blur-md">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between gap-4">
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-zinc-900 border border-zinc-700/60 flex items-center justify-center text-white shadow-sm">
            <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <rect width="18" height="11" x="3" y="11" rx="2" ry="2"/>
              <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
            </svg>
          </div>
          <div>
            <span class="font-bold text-white tracking-tight text-sm sm:text-base">subscription-gate</span>
            <span class="hidden sm:inline-block ml-2 text-[10px] font-mono text-zinc-400 bg-zinc-800/80 px-2 py-0.5 rounded border border-zinc-700/40">admin</span>
          </div>
        </div>

        <div class="flex items-center gap-3">
          <div class="hidden md:flex flex-col text-right">
            <span class="text-xs text-zinc-300 font-medium">{{ adminEmail }}</span>
            <span class="text-[10px] text-zinc-500 font-mono">Sesión activa</span>
          </div>

          <button
            @click="cargarLicencias"
            :disabled="cargando"
            title="Recargar datos"
            class="p-2 text-zinc-400 hover:text-white bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 rounded-lg transition-colors cursor-pointer disabled:opacity-50"
          >
            <svg class="w-4 h-4" :class="{ 'animate-spin': cargando }" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
          </button>

          <button
            @click="cerrarSesion"
            class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-zinc-300 hover:text-white bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 rounded-lg transition-colors cursor-pointer"
          >
            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
            </svg>
            <span>Salir</span>
          </button>
        </div>
      </div>
    </header>

    <!-- Contenido principal -->
    <main class="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
      <!-- Notificación flotante de feedback -->
      <transition
        enter-active-class="transform transition ease-out duration-200"
        enter-from-class="translate-y-2 opacity-0"
        enter-to-class="translate-y-0 opacity-100"
        leave-active-class="transition ease-in duration-150"
        leave-from-class="opacity-100"
        leave-to-class="opacity-0"
      >
        <div
          v-if="feedback"
          class="p-4 rounded-xl border text-sm flex items-start justify-between gap-3 shadow-lg"
          :class="feedback.tipo === 'exito'
            ? 'bg-emerald-950/70 border-emerald-800/80 text-emerald-200'
            : 'bg-red-950/70 border-red-800/80 text-red-200'"
        >
          <div class="flex items-center gap-2">
            <svg v-if="feedback.tipo === 'exito'" class="w-5 h-5 text-emerald-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            <svg v-else class="w-5 h-5 text-red-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <circle cx="12" cy="12" r="10" stroke-width="2"/>
              <line x1="12" y1="8" x2="12" y2="12" stroke-width="2"/>
              <line x1="12" y1="16" x2="12.01" y2="16" stroke-width="2"/>
            </svg>
            <span>{{ feedback.mensaje }}</span>
          </div>
          <button @click="feedback = null" class="text-zinc-400 hover:text-white cursor-pointer text-xs">✕</button>
        </div>
      </transition>

      <!-- Tarjetas de métricas -->
      <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3.5">
        <div class="bg-surface border border-border p-4 rounded-xl">
          <span class="text-xs text-muted block mb-1">Total Usuarios</span>
          <span class="text-2xl font-bold text-white font-mono">{{ metricas.total }}</span>
        </div>
        <div class="bg-surface border border-border p-4 rounded-xl">
          <span class="text-xs text-emerald-400 block mb-1">Vigentes</span>
          <span class="text-2xl font-bold text-emerald-400 font-mono">{{ metricas.vigentes }}</span>
        </div>
        <div class="bg-surface border border-border p-4 rounded-xl">
          <span class="text-xs text-amber-400 block mb-1">Por vencer (≤7d)</span>
          <span class="text-2xl font-bold text-amber-400 font-mono">{{ metricas.porVencer }}</span>
        </div>
        <div class="bg-surface border border-border p-4 rounded-xl">
          <span class="text-xs text-red-400 block mb-1">Vencidas</span>
          <span class="text-2xl font-bold text-red-400 font-mono">{{ metricas.vencidas }}</span>
        </div>
        <div class="bg-surface border border-border p-4 rounded-xl col-span-2 sm:col-span-1">
          <span class="text-xs text-zinc-400 block mb-1">Bloqueadas</span>
          <span class="text-2xl font-bold text-zinc-400 font-mono">{{ metricas.bloqueadas }}</span>
        </div>
      </div>

      <!-- Barra de Filtros, Búsqueda y Ayuda de Alta -->
      <div class="flex flex-col sm:flex-row gap-3 items-stretch sm:items-center justify-between">
        <div class="flex-1 relative max-w-md">
          <input
            v-model="busqueda"
            type="text"
            placeholder="Buscar por correo o hardware ID..."
            class="w-full bg-surface border border-border rounded-lg pl-9 pr-4 py-2 text-sm text-zinc-100 placeholder-zinc-500 focus:outline-none focus:ring-1 focus:ring-zinc-400"
          />
          <svg class="w-4 h-4 text-zinc-500 absolute left-3 top-2.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
        </div>

        <div class="flex items-center gap-2 overflow-x-auto pb-1 sm:pb-0">
          <button
            v-for="opcion in [
              { id: 'todos', label: 'Todos' },
              { id: 'vigente', label: 'Vigentes' },
              { id: 'por_vencer', label: 'Por vencer' },
              { id: 'vencida', label: 'Vencidas' },
              { id: 'bloqueada', label: 'Bloqueadas' },
            ]"
            :key="opcion.id"
            @click="filtroEstado = opcion.id"
            :class="filtroEstado === opcion.id
              ? 'bg-zinc-200 text-zinc-950 font-medium'
              : 'bg-surface text-zinc-400 hover:text-zinc-200 border border-border'"
            class="px-3 py-1.5 rounded-lg text-xs transition-colors whitespace-nowrap cursor-pointer"
          >
            {{ opcion.label }}
          </button>
        </div>
      </div>

      <!-- Banner educativo sobre alta de usuarios -->
      <div class="bg-zinc-950/60 border border-zinc-800/80 rounded-xl p-4 flex flex-col md:flex-row items-start md:items-center justify-between gap-3 text-xs text-zinc-400">
        <div class="flex items-center gap-2.5">
          <svg class="w-5 h-5 text-zinc-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <div>
            <strong class="text-zinc-200">Alta de nuevos usuarios:</strong>
            Para registrar una nueva cuenta, agrégala desde el panel de Supabase (<span class="font-mono text-zinc-300">Authentication &rarr; Users &rarr; Add user</span>).
            El trigger creará automáticamente su licencia inicial de 30 días.
          </div>
        </div>
      </div>

      <!-- Estado: Cargando -->
      <div v-if="cargando" class="bg-surface border border-border rounded-xl p-12 flex flex-col items-center justify-center text-center">
        <svg class="animate-spin h-8 w-8 text-zinc-400 mb-3" viewBox="0 0 24 24" fill="none">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path>
        </svg>
        <span class="text-sm text-zinc-400">Cargando licencias...</span>
      </div>

      <!-- Estado: Sin usuarios / Sin resultados -->
      <div v-else-if="licenciasFiltradas.length === 0" class="bg-surface border border-border rounded-xl p-12 text-center">
        <svg class="w-12 h-12 text-zinc-600 mx-auto mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
        </svg>
        <h3 class="text-sm font-semibold text-zinc-200">No se encontraron usuarios</h3>
        <p class="text-xs text-zinc-500 mt-1">
          {{ busqueda ? 'Prueba con otro término de búsqueda o cambia el filtro de estado.' : 'Aún no hay usuarios registrados en el sistema.' }}
        </p>
      </div>

      <!-- Tabla / Lista de Licencias -->
      <div v-else class="space-y-4">
        <!-- Vista Desktop: Tabla completa -->
        <div class="hidden lg:block bg-surface border border-border rounded-xl overflow-hidden shadow-sm">
          <div class="overflow-x-auto">
            <table class="w-full text-left text-sm text-zinc-300">
              <thead class="bg-zinc-950/70 border-b border-border text-xs text-zinc-400 uppercase tracking-wider font-mono">
                <tr>
                  <th class="px-5 py-3.5">Usuario / Correo</th>
                  <th class="px-5 py-3.5">Estado</th>
                  <th class="px-5 py-3.5">Vencimiento</th>
                  <th class="px-5 py-3.5">Equipo Vinculado</th>
                  <th class="px-5 py-3.5 text-right">Acciones de Gestión</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-border/60">
                <tr v-for="lic in licenciasFiltradas" :key="lic.usuario_id" class="hover:bg-zinc-900/40 transition-colors">
                  <!-- Usuario / Email -->
                  <td class="px-5 py-4">
                    <div class="font-medium text-white">{{ lic.email || 'Sin correo registrado' }}</div>
                    <div class="text-[11px] font-mono text-zinc-500 truncate max-w-[200px]" :title="lic.usuario_id">
                      UID: {{ lic.usuario_id }}
                    </div>
                  </td>

                  <!-- Badge de Estado -->
                  <td class="px-5 py-4 whitespace-nowrap">
                    <span
                      v-if="calcularEstado(lic) === 'bloqueada'"
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium bg-red-950/60 text-red-300 border border-red-800/60"
                    >
                      <span class="w-1.5 h-1.5 rounded-full bg-red-500"></span>
                      Bloqueada
                    </span>
                    <span
                      v-else-if="calcularEstado(lic) === 'vencida'"
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium bg-rose-950/60 text-rose-300 border border-rose-800/60"
                    >
                      <span class="w-1.5 h-1.5 rounded-full bg-rose-500"></span>
                      Vencida
                    </span>
                    <span
                      v-else-if="calcularEstado(lic) === 'por_vencer'"
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium bg-amber-950/60 text-amber-300 border border-amber-800/60"
                    >
                      <span class="w-1.5 h-1.5 rounded-full bg-amber-400"></span>
                      Por vencer ({{ calcularDiasRestantes(lic.fecha_fin) }}d)
                    </span>
                    <span
                      v-else
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium bg-emerald-950/60 text-emerald-300 border border-emerald-800/60"
                    >
                      <span class="w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
                      Vigente ({{ calcularDiasRestantes(lic.fecha_fin) }}d)
                    </span>
                  </td>

                  <!-- Vencimiento -->
                  <td class="px-5 py-4 whitespace-nowrap">
                    <div class="font-mono text-xs text-zinc-200">{{ formatearFecha(lic.fecha_fin) }}</div>
                    <div class="text-[11px] text-zinc-500">
                      {{ calcularDiasRestantes(lic.fecha_fin) > 0 ? `Quedan ${calcularDiasRestantes(lic.fecha_fin)} días` : 'Expiró' }}
                    </div>
                  </td>

                  <!-- Hardware ID -->
                  <td class="px-5 py-4 whitespace-nowrap">
                    <div v-if="lic.hardware_id" class="flex items-center gap-2">
                      <span class="w-2 h-2 rounded-full bg-emerald-500"></span>
                      <span class="font-mono text-xs text-zinc-300" :title="lic.hardware_id">
                        {{ lic.hardware_id.slice(0, 8) }}...{{ lic.hardware_id.slice(-6) }}
                      </span>
                    </div>
                    <div v-else class="flex items-center gap-2 text-zinc-500 text-xs">
                      <span class="w-2 h-2 rounded-full bg-zinc-600"></span>
                      <span>Sin vincular</span>
                    </div>
                  </td>

                  <!-- Acciones -->
                  <td class="px-5 py-4 whitespace-nowrap text-right">
                    <div class="flex items-center justify-end gap-1.5">
                      <!-- Botones de renovación rápida -->
                      <button
                        @click="renovar(lic, 30)"
                        :disabled="Boolean(accionEnProgreso[lic.usuario_id])"
                        title="Extender 30 días"
                        class="px-2.5 py-1 text-xs font-medium bg-zinc-900 hover:bg-zinc-800 border border-zinc-700/60 text-zinc-200 rounded-md transition-colors cursor-pointer disabled:opacity-50"
                      >
                        +30d
                      </button>
                      <button
                        @click="renovar(lic, 90)"
                        :disabled="Boolean(accionEnProgreso[lic.usuario_id])"
                        title="Extender 90 días"
                        class="px-2.5 py-1 text-xs font-medium bg-zinc-900 hover:bg-zinc-800 border border-zinc-700/60 text-zinc-200 rounded-md transition-colors cursor-pointer disabled:opacity-50"
                      >
                        +90d
                      </button>
                      <button
                        @click="renovar(lic, 365)"
                        :disabled="Boolean(accionEnProgreso[lic.usuario_id])"
                        title="Extender 365 días"
                        class="px-2.5 py-1 text-xs font-medium bg-zinc-900 hover:bg-zinc-800 border border-zinc-700/60 text-zinc-200 rounded-md transition-colors cursor-pointer disabled:opacity-50"
                      >
                        +365d
                      </button>

                      <span class="h-4 w-px bg-zinc-800 mx-1"></span>

                      <!-- Reset hardware -->
                      <button
                        @click="confirmarResetHardware(lic)"
                        :disabled="!lic.hardware_id || Boolean(accionEnProgreso[lic.usuario_id])"
                        title="Desvincular hardware para permitir nuevo equipo"
                        class="px-2.5 py-1 text-xs font-medium bg-zinc-900 hover:bg-zinc-800 border border-zinc-700/60 text-zinc-300 rounded-md transition-colors cursor-pointer disabled:opacity-30 disabled:cursor-not-allowed"
                      >
                        Reset Equipo
                      </button>

                      <!-- Bloquear / Desbloquear -->
                      <button
                        @click="confirmarBloqueo(lic)"
                        :disabled="Boolean(accionEnProgreso[lic.usuario_id])"
                        :title="lic.bloqueada ? 'Desbloquear acceso' : 'Bloquear acceso'"
                        :class="lic.bloqueada
                          ? 'border-emerald-800/80 text-emerald-400 hover:bg-emerald-950/40'
                          : 'border-red-900/60 text-red-400 hover:bg-red-950/40'"
                        class="px-2.5 py-1 text-xs font-medium bg-zinc-900 border rounded-md transition-colors cursor-pointer disabled:opacity-50"
                      >
                        {{ lic.bloqueada ? 'Desbloquear' : 'Bloquear' }}
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Vista Móvil: Tarjetas individuales responsivas (Permite renovar y resetear desde el celular) -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:hidden gap-3.5">
          <div
            v-for="lic in licenciasFiltradas"
            :key="lic.usuario_id"
            class="bg-surface border border-border rounded-xl p-4 space-y-3.5 shadow-sm"
          >
            <!-- Cabecera de tarjeta -->
            <div class="flex items-start justify-between gap-2">
              <div class="min-w-0">
                <h4 class="font-medium text-white truncate text-sm">{{ lic.email || 'Sin correo' }}</h4>
                <p class="text-[11px] font-mono text-zinc-500 truncate">UID: {{ lic.usuario_id }}</p>
              </div>

              <!-- Badge de estado móvil -->
              <span
                v-if="calcularEstado(lic) === 'bloqueada'"
                class="px-2 py-0.5 rounded text-[11px] font-medium bg-red-950/80 text-red-300 border border-red-800 shrink-0"
              >
                Bloqueada
              </span>
              <span
                v-else-if="calcularEstado(lic) === 'vencida'"
                class="px-2 py-0.5 rounded text-[11px] font-medium bg-rose-950/80 text-rose-300 border border-rose-800 shrink-0"
              >
                Vencida
              </span>
              <span
                v-else-if="calcularEstado(lic) === 'por_vencer'"
                class="px-2 py-0.5 rounded text-[11px] font-medium bg-amber-950/80 text-amber-300 border border-amber-800 shrink-0"
              >
                Por vencer ({{ calcularDiasRestantes(lic.fecha_fin) }}d)
              </span>
              <span
                v-else
                class="px-2 py-0.5 rounded text-[11px] font-medium bg-emerald-950/80 text-emerald-300 border border-emerald-800 shrink-0"
              >
                Vigente ({{ calcularDiasRestantes(lic.fecha_fin) }}d)
              </span>
            </div>

            <!-- Detalles de vencimiento y hardware -->
            <div class="grid grid-cols-2 gap-2 text-xs bg-zinc-950/60 p-2.5 rounded-lg border border-border/50">
              <div>
                <span class="text-zinc-500 block text-[10px] uppercase font-mono">Vencimiento</span>
                <span class="font-mono text-zinc-200 text-[11px]">{{ formatearFecha(lic.fecha_fin) }}</span>
              </div>
              <div>
                <span class="text-zinc-500 block text-[10px] uppercase font-mono">Equipo</span>
                <span v-if="lic.hardware_id" class="font-mono text-emerald-400 text-[11px] truncate block" :title="lic.hardware_id">
                  {{ lic.hardware_id.slice(0, 10) }}...
                </span>
                <span v-else class="text-zinc-500 text-[11px]">Sin vincular</span>
              </div>
            </div>

            <!-- Botones de acción móvil -->
            <div class="space-y-2 pt-1 border-t border-border/50">
              <div class="flex items-center gap-1.5">
                <span class="text-[11px] text-zinc-400 mr-1">Renovar:</span>
                <button
                  @click="renovar(lic, 30)"
                  :disabled="Boolean(accionEnProgreso[lic.usuario_id])"
                  class="flex-1 py-1.5 text-xs font-medium bg-zinc-900 hover:bg-zinc-800 border border-zinc-700/60 text-zinc-200 rounded-md cursor-pointer disabled:opacity-50"
                >
                  +30d
                </button>
                <button
                  @click="renovar(lic, 90)"
                  :disabled="Boolean(accionEnProgreso[lic.usuario_id])"
                  class="flex-1 py-1.5 text-xs font-medium bg-zinc-900 hover:bg-zinc-800 border border-zinc-700/60 text-zinc-200 rounded-md cursor-pointer disabled:opacity-50"
                >
                  +90d
                </button>
                <button
                  @click="renovar(lic, 365)"
                  :disabled="Boolean(accionEnProgreso[lic.usuario_id])"
                  class="flex-1 py-1.5 text-xs font-medium bg-zinc-900 hover:bg-zinc-800 border border-zinc-700/60 text-zinc-200 rounded-md cursor-pointer disabled:opacity-50"
                >
                  +365d
                </button>
              </div>

              <div class="flex items-center gap-2">
                <button
                  @click="confirmarResetHardware(lic)"
                  :disabled="!lic.hardware_id || Boolean(accionEnProgreso[lic.usuario_id])"
                  class="flex-1 py-1.5 text-xs font-medium bg-zinc-900 hover:bg-zinc-800 border border-zinc-700/60 text-zinc-300 rounded-md cursor-pointer disabled:opacity-30 disabled:cursor-not-allowed"
                >
                  Reset Equipo
                </button>
                <button
                  @click="confirmarBloqueo(lic)"
                  :disabled="Boolean(accionEnProgreso[lic.usuario_id])"
                  :class="lic.bloqueada
                    ? 'border-emerald-800/80 text-emerald-400 hover:bg-emerald-950/40'
                    : 'border-red-900/60 text-red-400 hover:bg-red-950/40'"
                  class="flex-1 py-1.5 text-xs font-medium bg-zinc-900 border rounded-md cursor-pointer disabled:opacity-50"
                >
                  {{ lic.bloqueada ? 'Desbloquear' : 'Bloquear' }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- Modal genérico de confirmación de acciones -->
    <div
      v-if="modalConfirmacion.abierto"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm"
    >
      <div class="bg-surface border border-border rounded-xl max-w-md w-full p-6 shadow-2xl space-y-4">
        <h3 class="text-base font-semibold text-white">{{ modalConfirmacion.titulo }}</h3>
        <p class="text-xs text-zinc-300 leading-relaxed">{{ modalConfirmacion.mensaje }}</p>

        <div class="flex items-center justify-end gap-2.5 pt-3 border-t border-border/60">
          <button
            @click="cerrarModal"
            class="px-3 py-1.5 text-xs font-medium text-zinc-300 hover:text-white bg-zinc-900 hover:bg-zinc-800 border border-zinc-700/60 rounded-lg transition-colors cursor-pointer"
          >
            Cancelar
          </button>
          <button
            @click="modalConfirmacion.ejecutar"
            :class="modalConfirmacion.peligroso
              ? 'bg-red-600 hover:bg-red-500 text-white'
              : 'bg-zinc-100 hover:bg-white text-zinc-950'"
            class="px-3.5 py-1.5 text-xs font-medium rounded-lg transition-colors cursor-pointer shadow-sm"
          >
            {{ modalConfirmacion.textoBoton }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
