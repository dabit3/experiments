import { useEffect, useRef } from 'react'

interface Particle {
  x: number
  y: number
  vx: number
  vy: number
  rot: number
  vr: number
  w: number
  h: number
  color: string
  wobble: number
}

const COLORS = ['#f6c453', '#ff7a59', '#7dd3fc', '#a78bfa', '#4ade80', '#f472b6', '#fef3c7']

export default function Confetti() {
  const ref = useRef<HTMLCanvasElement>(null)

  useEffect(() => {
    const canvas = ref.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const resize = () => {
      canvas.width = window.innerWidth
      canvas.height = window.innerHeight
    }
    resize()
    window.addEventListener('resize', resize)

    const particles: Particle[] = Array.from({ length: 220 }, () => ({
      x: Math.random() * canvas.width,
      y: -20 - Math.random() * canvas.height * 0.6,
      vx: (Math.random() - 0.5) * 2.5,
      vy: 2 + Math.random() * 3.5,
      rot: Math.random() * Math.PI * 2,
      vr: (Math.random() - 0.5) * 0.25,
      w: 7 + Math.random() * 8,
      h: 4 + Math.random() * 6,
      color: COLORS[Math.floor(Math.random() * COLORS.length)],
      wobble: Math.random() * Math.PI * 2,
    }))

    let frame = 0
    let raf = 0
    const tick = () => {
      frame++
      ctx.clearRect(0, 0, canvas.width, canvas.height)
      for (const p of particles) {
        p.wobble += 0.08
        p.x += p.vx + Math.sin(p.wobble) * 0.8
        p.y += p.vy
        p.rot += p.vr
        if (p.y > canvas.height + 20 && frame < 600) {
          p.y = -20
          p.x = Math.random() * canvas.width
        }
        ctx.save()
        ctx.translate(p.x, p.y)
        ctx.rotate(p.rot)
        ctx.fillStyle = p.color
        ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h)
        ctx.restore()
      }
      if (frame < 900) raf = requestAnimationFrame(tick)
    }
    raf = requestAnimationFrame(tick)

    return () => {
      cancelAnimationFrame(raf)
      window.removeEventListener('resize', resize)
    }
  }, [])

  return <canvas ref={ref} className="confetti" aria-hidden="true" />
}
