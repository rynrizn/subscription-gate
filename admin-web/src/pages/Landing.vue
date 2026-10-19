<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

// Preguntas frecuentes
const faqs = ref([
  {
    pregunta: '¿En cuántos equipos puedo utilizar mi licencia?',
    respuesta: 'Cada suscripción está vinculada a un único ordenador para garantizar la máxima seguridad y rendimiento de la aplicación.',
    abierto: false,
  },
  {
    pregunta: '¿Qué sucede si cambio de ordenador o formateo mi disco?',
    respuesta: 'Solo necesitas contactar al administrador. Desde el panel web, el administrador puede desvincular tu equipo anterior en segundos para que vincules tu nueva máquina.',
    abierto: false,
  },
  {
    pregunta: '¿Cómo funciona la renovación de la suscripción?',
    respuesta: 'Cuando tu período esté por finalizar, puedes solicitar una extensión (+30, +90 o +365 días). Tu software actualizará los días disponibles en su próximo inicio.',
    abierto: false,
  },
  {
    pregunta: '¿Requiere conexión a internet permanente?',
    respuesta: 'La aplicación verifica el estado de tu licencia y el equipo al iniciar sesión mediante conexión segura con el servidor.',
    abierto: false,
  },
])

function toggleFaq(index) {
  faqs.value[index].abierto = !faqs.value[index].abierto
}
</script>

<template>
  <div class="min-h-screen bg-background text-zinc-100 flex flex-col selection:bg-zinc-800 selection:text-white">
    <!-- Barra de Navegación -->
    <header class="border-b border-border/80 bg-background/80 sticky top-0 z-30 backdrop-blur-md">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        <!-- Logo / Marca -->
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-zinc-900 border border-zinc-700/60 flex items-center justify-center text-white shadow-inner">
            <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <rect width="18" height="11" x="3" y="11" rx="2" ry="2"/>
              <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
            </svg>
          </div>
          <span class="font-bold text-white tracking-tight text-base sm:text-lg">TuSoftware<span class="text-zinc-500 font-mono text-xs ml-1">App</span></span>
        </div>

        <!-- Enlaces navegación -->
        <nav class="hidden md:flex items-center gap-6 text-sm text-zinc-400">
          <a href="#caracteristicas" class="hover:text-white transition-colors">Características</a>
          <a href="#como-funciona" class="hover:text-white transition-colors">Cómo Funciona</a>
          <a href="#faq" class="hover:text-white transition-colors">Preguntas Frecuentes</a>
        </nav>

        <!-- Botón Acceso Admin -->
        <div class="flex items-center gap-3">
          <router-link
            to="/login"
            class="inline-flex items-center gap-1.5 px-3.5 py-1.5 text-xs font-medium text-zinc-300 hover:text-white bg-zinc-900 hover:bg-zinc-800 border border-zinc-700/60 rounded-lg transition-colors cursor-pointer"
          >
            <svg class="w-3.5 h-3.5 text-zinc-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
            </svg>
            <span>Acceso Admin</span>
          </router-link>
        </div>
      </div>
    </header>

    <!-- Hero Section -->
    <section class="relative pt-20 pb-16 md:pt-28 md:pb-24 overflow-hidden">
      <!-- Glow de fondo decorativo -->
      <div class="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[350px] bg-zinc-800/15 rounded-full blur-3xl pointer-events-none"></div>

      <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 text-center relative z-10">
        <!-- Badge superior -->
        <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-zinc-900/90 border border-zinc-800 text-xs text-zinc-300 mb-6">
          <span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
          <span>Versión de escritorio disponible</span>
        </div>

        <h1 class="text-4xl sm:text-5xl md:text-6xl font-bold tracking-tight text-white max-w-3xl mx-auto leading-tight">
          La solución de escritorio rápida para <span class="text-zinc-400">tu productividad</span>
        </h1>

        <p class="mt-6 text-base sm:text-lg text-zinc-400 max-w-2xl mx-auto leading-relaxed">
          Diseñada para profesionales que buscan velocidad nativa, interfaz moderna y control total sobre sus proyectos. Todo listo para instalar y comenzar en segundos.
        </p>

        <!-- Botones de Acción -->
        <div class="mt-8 flex flex-col sm:flex-row items-center justify-center gap-3.5">
          <a
            href="#descargar"
            class="w-full sm:w-auto px-6 py-3 rounded-xl bg-white hover:bg-zinc-200 text-zinc-950 font-semibold text-sm transition-all duration-200 flex items-center justify-center gap-2 shadow-lg shadow-white/5 active:scale-[0.98] cursor-pointer"
          >
            <svg class="w-4 h-4 text-zinc-950" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
            </svg>
            <span>Descargar Instalador</span>
          </a>

          <a
            href="#como-funciona"
            class="w-full sm:w-auto px-6 py-3 rounded-xl bg-zinc-900 hover:bg-zinc-800 border border-zinc-700/60 text-zinc-300 hover:text-white font-medium text-sm transition-colors flex items-center justify-center cursor-pointer"
          >
            Cómo funciona
          </a>
        </div>

        <!-- Vista previa estilizada de la App de Escritorio -->
        <div class="mt-14 max-w-3xl mx-auto rounded-2xl border border-zinc-800 bg-surface/90 shadow-2xl overflow-hidden backdrop-blur-sm text-left">
          <!-- Barra de ventana de escritorio -->
          <div class="h-10 bg-zinc-950/80 border-b border-zinc-800/80 px-4 flex items-center justify-between">
            <div class="flex items-center gap-2">
              <span class="w-3 h-3 rounded-full bg-zinc-700 inline-block"></span>
              <span class="w-3 h-3 rounded-full bg-zinc-700 inline-block"></span>
              <span class="w-3 h-3 rounded-full bg-zinc-700 inline-block"></span>
              <span class="text-xs text-zinc-400 font-mono ml-2">TuSoftware · v1.0.0</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded text-[10px] font-medium bg-emerald-950/70 text-emerald-300 border border-emerald-800/60 font-mono">
                <span class="w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
                Licencia Activa · 30 días restantes
              </span>
            </div>
          </div>

          <!-- Contenido simulado de la app -->
          <div class="p-6 md:p-8 space-y-4">
            <div class="flex items-center justify-between border-b border-zinc-800/60 pb-4">
              <div>
                <h3 class="text-sm font-semibold text-white">Panel de Trabajo</h3>
                <p class="text-xs text-zinc-500">Sesión iniciada con: cliente@ejemplo.com</p>
              </div>
              <span class="text-xs font-mono text-zinc-400 bg-zinc-900 px-2.5 py-1 rounded border border-zinc-800">
                Equipo vinculado ✓
              </span>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-2">
              <div class="p-4 rounded-xl bg-zinc-950/50 border border-zinc-800/60">
                <span class="text-[11px] text-zinc-500 uppercase font-mono block">Estado</span>
                <span class="text-sm font-medium text-emerald-400">Autorizado</span>
              </div>
              <div class="p-4 rounded-xl bg-zinc-950/50 border border-zinc-800/60">
                <span class="text-[11px] text-zinc-500 uppercase font-mono block">Hardware ID</span>
                <span class="text-sm font-mono text-zinc-300">9b6fae7...</span>
              </div>
              <div class="p-4 rounded-xl bg-zinc-950/50 border border-zinc-800/60">
                <span class="text-[11px] text-zinc-500 uppercase font-mono block">Servidor</span>
                <span class="text-sm font-medium text-zinc-300">Conectado (PostgreSQL)</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Características Clave -->
    <section id="caracteristicas" class="py-16 md:py-24 border-t border-border/80 bg-surface/30">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center max-w-2xl mx-auto mb-14">
          <h2 class="text-2xl sm:text-3xl font-bold tracking-tight text-white">Construido para fiabilidad y rendimiento</h2>
          <p class="text-sm text-zinc-400 mt-3">Diseño enfocado en la experiencia del usuario y en un consumo eficiente de recursos locales.</p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div class="p-6 rounded-2xl bg-surface border border-border space-y-3">
            <div class="w-10 h-10 rounded-xl bg-zinc-900 border border-zinc-700/60 flex items-center justify-center text-white mb-4">
              <svg class="w-5 h-5 text-zinc-200" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
            </div>
            <h3 class="text-base font-semibold text-white">Rendimiento Nativo</h3>
            <p class="text-xs text-zinc-400 leading-relaxed">
              Ejecución directa en tu sistema operativo, sin sobrecargas innecesarias ni lentitud en tus procesos diarios.
            </p>
          </div>

          <div class="p-6 rounded-2xl bg-surface border border-border space-y-3">
            <div class="w-10 h-10 rounded-xl bg-zinc-900 border border-zinc-700/60 flex items-center justify-center text-white mb-4">
              <svg class="w-5 h-5 text-zinc-200" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
              </svg>
            </div>
            <h3 class="text-base font-semibold text-white">Licencia Asegurada</h3>
            <p class="text-xs text-zinc-400 leading-relaxed">
              Tu acceso queda respaldado en la base de datos con verificación de equipo único y control de vencimiento confiable.
            </p>
          </div>

          <div class="p-6 rounded-2xl bg-surface border border-border space-y-3">
            <div class="w-10 h-10 rounded-xl bg-zinc-900 border border-zinc-700/60 flex items-center justify-center text-white mb-4">
              <svg class="w-5 h-5 text-zinc-200" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
            </div>
            <h3 class="text-base font-semibold text-white">Actualizaciones Continuas</h3>
            <p class="text-xs text-zinc-400 leading-relaxed">
              Renovación de suscripción transparente y soporte continuo para mantenerte siempre con las últimas funciones.
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- Cómo Funciona (3 Pasos) -->
    <section id="como-funciona" class="py-16 md:py-24 border-t border-border/80">
      <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center max-w-2xl mx-auto mb-14">
          <h2 class="text-2xl sm:text-3xl font-bold tracking-tight text-white">Comienza en 3 sencillos pasos</h2>
          <p class="text-sm text-zinc-400 mt-3">Sin configuraciones engorrosas. Listo para trabajar de inmediato.</p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div class="relative p-6 rounded-xl bg-zinc-950/60 border border-zinc-800/80 space-y-3">
            <span class="text-xs font-mono font-bold text-zinc-500 bg-zinc-900 px-2 py-1 rounded border border-zinc-800 inline-block mb-1">01</span>
            <h4 class="text-base font-semibold text-white">Descarga la App</h4>
            <p class="text-xs text-zinc-400 leading-relaxed">
              Obtén el ejecutable correspondiente a tu sistema operativo (Windows, macOS o Linux).
            </p>
          </div>

          <div class="relative p-6 rounded-xl bg-zinc-950/60 border border-zinc-800/80 space-y-3">
            <span class="text-xs font-mono font-bold text-zinc-500 bg-zinc-900 px-2 py-1 rounded border border-zinc-800 inline-block mb-1">02</span>
            <h4 class="text-base font-semibold text-white">Inicia Sesión</h4>
            <p class="text-xs text-zinc-400 leading-relaxed">
              Ingresa con el correo y contraseña proporcionados por el administrador de tu cuenta.
            </p>
          </div>

          <div class="relative p-6 rounded-xl bg-zinc-950/60 border border-zinc-800/80 space-y-3">
            <span class="text-xs font-mono font-bold text-zinc-500 bg-zinc-900 px-2 py-1 rounded border border-zinc-800 inline-block mb-1">03</span>
            <h4 class="text-base font-semibold text-white">Listo para Trabajar</h4>
            <p class="text-xs text-zinc-400 leading-relaxed">
              Tu equipo se vincula de manera automática en el primer acceso y la aplicación inicia sin demoras.
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- Descarga / CTA Section -->
    <section id="descargar" class="py-16 border-t border-border/80 bg-zinc-950/80">
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center space-y-6">
        <h2 class="text-2xl sm:text-3xl font-bold tracking-tight text-white">¿Listo para comenzar?</h2>
        <p class="text-sm text-zinc-400 max-w-xl mx-auto">
          Descarga la última versión o contacta a tu administrador para solicitar credenciales de acceso.
        </p>

        <div class="flex flex-wrap items-center justify-center gap-3 pt-2">
          <a
            href="#"
            class="px-5 py-2.5 rounded-lg bg-zinc-100 hover:bg-white text-zinc-950 font-medium text-xs flex items-center gap-2 transition-all cursor-pointer shadow-sm"
          >
            <span>Descargar para Windows (.exe)</span>
          </a>
          <a
            href="#"
            class="px-5 py-2.5 rounded-lg bg-zinc-900 hover:bg-zinc-800 border border-zinc-700/60 text-zinc-300 font-medium text-xs flex items-center gap-2 transition-all cursor-pointer"
          >
            <span>macOS / Linux (.dmg / .AppImage)</span>
          </a>
        </div>
      </div>
    </section>

    <!-- Preguntas Frecuentes (FAQ) -->
    <section id="faq" class="py-16 md:py-24 border-t border-border/80 bg-surface/20">
      <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-12">
          <h2 class="text-2xl sm:text-3xl font-bold tracking-tight text-white">Preguntas Frecuentes</h2>
          <p class="text-xs text-zinc-400 mt-2">Respuestas rápidas a las dudas más comunes sobre la aplicación y las licencias.</p>
        </div>

        <div class="space-y-3">
          <div
            v-for="(faq, i) in faqs"
            :key="i"
            class="rounded-xl border border-border bg-surface overflow-hidden transition-colors"
          >
            <button
              @click="toggleFaq(i)"
              class="w-full px-5 py-4 text-left text-sm font-medium text-zinc-200 flex items-center justify-between gap-3 cursor-pointer hover:text-white"
            >
              <span>{{ faq.pregunta }}</span>
              <span class="text-zinc-500 font-mono text-sm shrink-0">{{ faq.abierto ? '−' : '+' }}</span>
            </button>
            <div v-if="faq.abierto" class="px-5 pb-4 text-xs text-zinc-400 leading-relaxed border-t border-border/40 pt-3">
              {{ faq.respuesta }}
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Pie de Página -->
    <footer class="border-t border-border/80 bg-background py-8 text-xs text-zinc-500">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-4">
        <div>
          <span>© 2026 TuSoftware. Todos los derechos reservados.</span>
        </div>

        <div class="flex items-center gap-4">
          <router-link to="/login" class="text-zinc-400 hover:text-white transition-colors underline-offset-4 hover:underline">
            Panel de Administración &rarr;
          </router-link>
        </div>
      </div>
    </footer>
  </div>
</template>
