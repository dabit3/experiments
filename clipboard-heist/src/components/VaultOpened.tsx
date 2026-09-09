import { KEYS, VAULT_ORDER } from '../data'
import type { Stats } from '../types'
import './VaultOpened.css'

interface Props {
  stats: Stats
  historyCount: number
  elapsed: string
  onReset: () => void
}

export default function VaultOpened({ stats, historyCount, elapsed, onReset }: Props) {
  return (
    <div className="opened" role="dialog" aria-modal="true" aria-labelledby="opened-title">
      <div className="opened__rings" aria-hidden="true">
        <span />
        <span />
        <span />
      </div>
      <div className="opened__card">
        <div className="opened__eyebrow">Mission complete</div>
        <h1 id="opened-title">Vault opened</h1>
        <p className="opened__lede">
          Three keys, pasted in order. Nothing was typed — every step went through the clipboard.
        </p>
        <div className="opened__keys">
          {VAULT_ORDER.map((id, i) => (
            <div key={id} className="opened__key">
              <span className="opened__key-num">{i + 1}</span>
              <span className="opened__key-label">{KEYS[id].label}</span>
              <code>{KEYS[id].value}</code>
            </div>
          ))}
        </div>
        <dl className="opened__stats">
          <div>
            <dt>Copies</dt>
            <dd>{stats.copies}</dd>
          </div>
          <div>
            <dt>Pastes</dt>
            <dd>{stats.pastes}</dd>
          </div>
          <div>
            <dt>Rejected</dt>
            <dd>{stats.rejected}</dd>
          </div>
          <div>
            <dt>History entries</dt>
            <dd>{historyCount}</dd>
          </div>
          <div>
            <dt>Elapsed</dt>
            <dd>{elapsed}</dd>
          </div>
        </dl>
        <button type="button" className="opened__reset" onClick={onReset}>
          Run the heist again
        </button>
      </div>
    </div>
  )
}
