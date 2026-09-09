import { useEffect, useState } from 'react'

/** True once the viewport has been resized at least once since load. */
export function useWindowResized(): boolean {
  const [resized, setResized] = useState(false)
  useEffect(() => {
    const onResize = () => setResized(true)
    window.addEventListener('resize', onResize)
    return () => window.removeEventListener('resize', onResize)
  }, [])
  return resized
}
