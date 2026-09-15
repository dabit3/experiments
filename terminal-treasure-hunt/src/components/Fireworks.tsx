import { useEffect, useState } from 'react'
import { FLAG } from '../shell/filesystem'
import { BANNER, CHEST, FRAME_COUNT, FRAME_MS, fireworksFrame } from '../shell/fireworks'
import { OutputLines } from './OutputLines'

const LOOPS = 4

interface Props {
  commands: number
  onSettled: () => void
}

export function Fireworks({ commands, onSettled }: Props) {
  const [tick, setTick] = useState(0)

  useEffect(() => {
    if (tick >= FRAME_COUNT * LOOPS) return
    const id = window.setTimeout(() => setTick((t) => t + 1), FRAME_MS)
    return () => window.clearTimeout(id)
  }, [tick])

  const bannerVisible = tick >= FRAME_COUNT
  useEffect(() => {
    if (bannerVisible) onSettled()
  }, [bannerVisible, onSettled])

  const frame = tick >= FRAME_COUNT * LOOPS ? fireworksFrame(FRAME_COUNT - 1) : fireworksFrame(tick % FRAME_COUNT)

  return (
    <div className="fireworks" data-testid="fireworks" aria-live="polite">
      <pre className="fireworks-sky">
        <OutputLines lines={frame} />
      </pre>
      {bannerVisible && (
        <div className="fireworks-banner">
          <pre className="banner-text">{BANNER.join('\n')}</pre>
          <div className="banner-row">
            <pre className="banner-chest">{CHEST.join('\n')}</pre>
            <div className="banner-copy">
              <div className="banner-title">Flag accepted</div>
              <code className="banner-flag">{FLAG}</code>
              <p>
                Solved in <strong>{commands}</strong> command{commands === 1 ? '' : 's'}: hidden dotfiles, a grep across the
                logs, a base64 blob and a file only <code>ls -a</code> would show.
              </p>
              <p className="banner-hint">
                Keep exploring, or type <code>clear</code> to tidy up.
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
