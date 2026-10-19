import { createRouter, createWebHistory } from 'vue-router'
import { supabase, checkIsAdmin } from '../lib/supabase'
import Login from '../pages/Login.vue'
import Usuarios from '../pages/Usuarios.vue'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: Login,
    meta: { guestOnly: true },
  },
  {
    path: '/usuarios',
    name: 'Usuarios',
    component: Usuarios,
    meta: { requiresAdmin: true },
  },
  {
    path: '/',
    redirect: '/usuarios',
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/usuarios',
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// Guardia de navegación para proteger rutas de administración
router.beforeEach(async (to, from, next) => {
  const { data: { session } } = await supabase.auth.getSession()

  if (to.meta.requiresAdmin) {
    if (!session) {
      return next({ path: '/login', query: { redirect: to.fullPath } })
    }

    const isAdmin = await checkIsAdmin()
    if (!isAdmin) {
      // El usuario inició sesión pero no está en la tabla admins
      await supabase.auth.signOut()
      return next({
        path: '/login',
        query: { error: 'no_admin' },
      })
    }

    return next()
  }

  if (to.meta.guestOnly && session) {
    const isAdmin = await checkIsAdmin()
    if (isAdmin) {
      return next({ path: '/usuarios' })
    }
  }

  next()
})

export default router
