import { useState } from 'react'
import type { ScreenProps } from '../types'
import './screens.css'

export function DisguisedAd({ onDefeat, onTrap }: ScreenProps) {
  const [adOpen, setAdOpen] = useState(false)

  return (
    <div className="screen">
      <span className="eyebrow">Step 7 · Almost there</span>
      <h1 className="title">Continue to the final steps</h1>
      <p className="lead">
        We&apos;ve saved your progress. Continue below to finish cancelling your Streamly+
        subscription.
      </p>

      <div className="ad-slot">
        <button
          type="button"
          className="btn btn-primary btn-wide ad-button"
          onClick={() => {
            onTrap('Clicked a sponsored advert disguised as the primary button')
            setAdOpen(true)
          }}
        >
          <span className="ad-tag" aria-hidden="true">
            Ad
          </span>
          Continue
          <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
            <path
              d="M5 12h14m-6-6 6 6-6 6"
              stroke="currentColor"
              strokeWidth="2.4"
              fill="none"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        </button>
        <span className="ad-disclosure">Sponsored · CloudVault Backup</span>
      </div>

      <div className="divider">
        <span>or</span>
      </div>

      <div className="actions">
        <button type="button" className="btn btn-ghost" onClick={onDefeat}>
          Continue to cancellation
        </button>
        <button
          type="button"
          className="btn btn-secondary"
          onClick={() => onTrap('Kept the subscription (decoy)')}
        >
          Keep Streamly+
        </button>
      </div>

      {adOpen && (
        <div className="overlay" role="dialog" aria-modal="true" aria-labelledby="ad-title">
          <div className="upsell ad-modal">
            <span className="upsell-badge ad-badge">Advertisement</span>
            <h2 id="ad-title" className="upsell-title">
              CloudVault — 2 TB of backup, free for 3 months
            </h2>
            <p className="upsell-copy">
              That button wasn&apos;t part of the cancellation flow. It was a sponsored placement
              styled to look like one.
            </p>
            <div className="actions">
              <button
                type="button"
                className="btn btn-primary"
                onClick={() => onTrap('Signed up for CloudVault (decoy)')}
              >
                Start free trial
              </button>
              <button type="button" className="btn btn-ghost" onClick={() => setAdOpen(false)}>
                Close advert
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
