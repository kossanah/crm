import { io } from 'socket.io-client'
import { getCachedListResource, getCachedResource } from 'frappe-ui'

export function initSocket() {
  let host = window.location.hostname
  let siteName = window.site_name
  let port = ''
  if (
    window.location.protocol !== 'https:' &&
    (window.dev_server || ['localhost', '127.0.0.1'].includes(host) || window.location.port)
  ) {
    let socketio_port = window.socketio_port || 9000
    port = `:${socketio_port}`
  }
  let protocol = window.location.protocol === 'https:' ? 'https' : 'http'
  let url = `${protocol}://${host}${port}/${siteName}`

  let socket = io(url, {
    withCredentials: true,
    reconnectionAttempts: 5,
  })
  socket.on('refetch_resource', (data) => {
    if (data.cache_key) {
      let resource =
        getCachedResource(data.cache_key) ||
        getCachedListResource(data.cache_key)
      if (resource) {
        resource.reload()
      }
    }
  })
  return socket
}
