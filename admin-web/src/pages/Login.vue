<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase, checkIsAdmin, isConfigured } from '../lib/supabase'

const router = useRouter()
const route = useRoute()

const email = ref('')
const password = ref('')
const cargando = ref(false)
const mensajeError = ref('')

onMounted(() => {
  if (route.query.error === 'no_admin') {
    mensajeError.value = 'Tu cuenta no tiene privilegios de administrador para acceder al panel.'
  }
})

async function manejarLogin() {
  mensajeError.value = ''

  if (!email.value.trim() || !password.value) {
    mensajeError.value = 'Por favor ingresa tu correo y contraseña.'
    return
  }

  cargando.value = true

  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email: email.value.trim(),
      password: password.value,
    })

    if (error) {
      if (error.message.includes('Invalid login credentials')) {
        mensajeError.value = 'Correo o contraseña incorrectos.'
      } else {
        mensajeError.value = `Error de autenticación: ${error.message}`
      }
      return
    }

    // Comprobar si el usuario registrado tiene rol de administrador
    const esAdmin = await checkIsAdmin()

    if (!esAdmin) {
      // Si no es admin, cerrar sesión de inmediato
      await supabase.auth.signOut()
      mensajeError.value = 'Acceso denegado: tu cuenta no está registrada en la lista de administradores.'
      return
    }

    // Redirigir a usuarios
    const destino = route.query.redirect || '/usuarios'
    router.push(destino)
  } catch (err) {
    console.error('Error durante el inicio de sesión:', err)
    mensajeError.value = 'Ocurrió un error inesperado al conectar con el servidor.'
  } finally {
    cargando.value = false
  }
}
</script>

<template>
  <main class="min-h-screen w-full flex items-center justify-center p-4 bg-background">
    <!-- Luz sutil de fondo para profundidad visual -->
    <div class="absolute inset-0 overflow-hidden pointer-events-none">
      <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-zinc-800/10 rounded-full blur-3xl"></div>
    </div>

    <div class="relative w-full max-w-md">
      <!-- Tarjeta principal -->
      <div class="bg-surface border border-border rounded-xl p-8 shadow-2xl backdrop-blur-sm">
        <!-- Encabezado con logotipo / icono -->
        <div class="flex flex-col items-center mb-8">
          <div class="w-12 h-12 rounded-xl bg-zinc-900 border border-zinc-700/60 flex items-center justify-center mb-3 shadow-inner">
            <svg class="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <rect width="18" height="11" x="3" y="11" rx="2" ry="2"/>
              <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
            </svg>
          </div>
          <h1 class="text-2xl font-bold tracking-tight text-white">subscription-gate</h1>
          <p class="text-xs text-muted mt-1 uppercase tracking-widest font-mono">Panel de Administración</p>
        </div>

        <!-- Alerta si faltan variables en .env -->
        <div v-if="!isConfigured" class="mb-6 p-3.5 rounded-lg bg-amber-950/40 border border-amber-800/60 text-amber-200 text-xs leading-relaxed flex items-start gap-2.5">
          <svg class="w-4 h-4 shrink-0 mt-0.5 text-amber-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
          </svg>
          <div>
            <span class="font-semibold block">Configuración pendiente:</span>
            Copia <code class="font-mono bg-black/40 px-1 py-0.5 rounded">.env.example</code> a <code class="font-mono bg-black/40 px-1 py-0.5 rounded">.env</code> con las credenciales de tu proyecto Supabase.
          </div>
        </div>

        <!-- Mensaje de error / denegación -->
        <div v-if="mensajeError" class="mb-6 p-3.5 rounded-lg bg-red-950/40 border border-red-800/60 text-red-200 text-xs leading-relaxed flex items-start gap-2.5">
          <svg class="w-4 h-4 shrink-0 mt-0.5 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <circle cx="12" cy="12" r="10" stroke-width="2"/>
            <line x1="12" y1="8" x2="12" y2="12" stroke-width="2" stroke-linecap="round"/>
            <line x1="12" y1="16" x2="12.01" y2="16" stroke-width="2" stroke-linecap="round"/>
          </svg>
          <span>{{ mensajeError }}</span>
        </div>

        <!-- Formulario -->
        <form @submit.prevent="manejarLogin" class="space-y-5">
          <div>
            <label for="email" class="block text-xs font-medium text-zinc-300 mb-1.5 uppercase tracking-wider">
              Correo Electrónico
            </label>
            <div class="relative">
              <input
                id="email"
                v-model="email"
                type="email"
                autocomplete="email"
                required
                placeholder="admin@ejemplo.com"
                class="w-full bg-zinc-950 border border-zinc-800 rounded-lg px-3.5 py-2.5 text-sm text-zinc-100 placeholder-zinc-500 focus:outline-none focus:ring-1 focus:ring-zinc-400 focus:border-zinc-400 transition-colors"
                :disabled="cargando"
              />
            </div>
          </div>

          <div>
            <label for="password" class="block text-xs font-medium text-zinc-300 mb-1.5 uppercase tracking-wider">
              Contraseña
            </label>
            <div class="relative">
              <input
                id="password"
                v-model="password"
                type="password"
                autocomplete="current-password"
                required
                placeholder="••••••••••••"
                class="w-full bg-zinc-950 border border-zinc-800 rounded-lg px-3.5 py-2.5 text-sm text-zinc-100 placeholder-zinc-500 focus:outline-none focus:ring-1 focus:ring-zinc-400 focus:border-zinc-400 transition-colors"
                :disabled="cargando"
              />
            </div>
          </div>

          <button
            type="submit"
            :disabled="cargando"
            class="w-full mt-2 bg-zinc-100 hover:bg-white text-zinc-950 font-medium py-2.5 px-4 rounded-lg text-sm transition-all duration-200 flex items-center justify-center gap-2 cursor-pointer disabled:opacity-60 disabled:cursor-not-allowed shadow-md hover:shadow-lg active:scale-[0.99]"
          >
            <svg v-if="cargando" class="animate-spin h-4 w-4 text-zinc-950" viewBox="0 0 24 24" fill="none">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path>
            </svg>
            <span>{{ cargando ? 'Verificando acceso...' : 'Iniciar Sesión' }}</span>
          </button>
        </form>

        <div class="mt-8 pt-6 border-t border-border/60 text-center">
          <p class="text-xs text-zinc-500">
            Plantilla de acceso seguro y control de licencias con Supabase.
          </p>
        </div>
      </div>
    </div>
  </main>
</template>
