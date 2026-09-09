import { useState } from 'react'
import type { ScreenProps } from '../types'
import './screens.css'

export function FakeClose({ onDefeat, onTrap }: ScreenProps) {
  const [upsellOpen, setUpsellOpen] = useState(false)

  const openUpsell = () => {
    onTrap('Fake × — that opened an upsell')
    setUpsellOpen(true)
  }

  return (
    <div className="screen">
      <button
        type="button"
        className="fake-x"
        aria-label="Close"
        onClick={openUpsell}
        title="Close"
      >
        <svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true">
          <path
            d="M6 6l12 12M18 6L6 18"
            stroke="currentColor"
            strokeWidth="2.4"
            strokeLinecap="round"
          />
        </svg>
      </button>

      <span className="eyebrow">We&apos;re sad to see you go</span>
      <h1 className="title">Before you leave, take a look at what you&apos;d be giving up</h1>
      <p className="lead">
        Your Streamly+ membership includes 4K streaming on 5 screens, offline downloads and
        early access to every original. Members like you save an average of <strong>$212</strong>{' '}
        per year.
      </p>

      <ul className="perks">
        <li>
          <span className="perk-icon">4K</span>
          Ultra HD &amp; Dolby Atmos on every title
        </li>
        <li>
          <span className="perk-icon">5</span>
          Stream on five devices at the same time
        </li>
        <li>
          <span className="perk-icon">↓</span>
          Unlimited offline downloads
        </li>
      </ul>

      <div className="actions">
        <button type="button" className="btn btn-primary" onClick={() => onTrap('Kept the subscription (decoy)')}>
          Keep my membership
        </button>
        <button type="button" className="btn btn-secondary" onClick={openUpsell}>
          See special offers
        </button>
      </div>

      <p className="note fake-close-note">
        Questions? Visit the help centre or chat with us 24/7.{' '}
        <button type="button" className="link-tiny" onClick={onDefeat}>
          continue to cancellation
        </button>
      </p>

      {upsellOpen && (
        <div className="overlay" role="dialog" aria-modal="true" aria-labelledby="upsell-title">
          <div className="upsell">
            <span className="upsell-badge">Limited time</span>
            <h2 id="upsell-title" className="upsell-title">
              Stay for 50% off the next 3 months
            </h2>
            <p className="upsell-copy">
              That&apos;s just <s>$14.99</s> <strong>$7.49</strong>/month. The offer disappears
              the moment you close this window.
            </p>
            <div className="actions">
              <button
                type="button"
                className="btn btn-primary"
                onClick={() => onTrap('Claimed the upsell (decoy)')}
              >
                Claim 50% off
              </button>
              <button type="button" className="btn btn-ghost" onClick={() => setUpsellOpen(false)}>
                Back
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
