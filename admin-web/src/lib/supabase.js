import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || ''
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || ''

export const isConfigured = Boolean(supabaseUrl && supabaseAnonKey)

if (!isConfigured && import.meta.env.DEV) {
  console.warn(
    '[subscription-gate] Faltan las variables de entorno VITE_SUPABASE_URL o VITE_SUPABASE_ANON_KEY. ' +
    'Por favor copia .env.example a .env y completa tus credenciales públicas de Supabase.'
  )
}

// Inicialización del cliente Supabase estándar con la anon key (nunca service_role)
export const supabase = createClient(
  supabaseUrl || 'https://placeholder.supabase.co',
  supabaseAnonKey || 'placeholder-anon-key',
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
    },
  }
)

/**
 * Comprueba si el usuario autenticado actual tiene el rol de administrador
 * llamando a la función RPC segura es_admin().
 */
export async function checkIsAdmin() {
  const { data: { session } } = await supabase.auth.getSession()
  if (!session) return false

  const { data, error } = await supabase.rpc('es_admin')
  if (error) {
    console.error('Error al verificar permisos de administrador:', error)
    return false
  }

  return Boolean(data)
}
