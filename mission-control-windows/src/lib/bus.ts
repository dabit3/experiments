import type { BusMessage } from './types'

export const CHANNEL_NAME = 'mission-control'

export interface Bus {
  post: (message: BusMessage) => void
  subscribe: (handler: (message: BusMessage) => void) => () => void
  close: () => void
}

export function createBus(): Bus {
  const channel = new BroadcastChannel(CHANNEL_NAME)
  return {
    post: (message) => channel.postMessage(message),
    subscribe: (handler) => {
      const listener = (event: MessageEvent<BusMessage>) => handler(event.data)
      channel.addEventListener('message', listener)
      return () => channel.removeEventListener('message', listener)
    },
    close: () => channel.close(),
  }
}
