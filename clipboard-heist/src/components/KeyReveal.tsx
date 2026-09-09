import type { VaultKey } from '../data'
import CopyButton from './CopyButton'
import './KeyReveal.css'

interface Props {
  vaultKey: VaultKey
  note: string
  onCopy: (key: VaultKey) => Promise<boolean>
}

export default function KeyReveal({ vaultKey, note, onCopy }: Props) {
  return (
    <div className="key-reveal" role="region" aria-label={`Vault key ${vaultKey.label}`}>
      <div className="key-reveal__glyph" aria-hidden="true">
        <svg viewBox="0 0 24 24" width="26" height="26">
          <circle cx="8" cy="12" r="4.5" fill="none" stroke="currentColor" strokeWidth="1.9" />
          <path d="M12.5 12H21M18 12v3.5M15 12v2.5" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" />
        </svg>
      </div>
      <div className="key-reveal__body">
        <div className="key-reveal__eyebrow">Vault key recovered</div>
        <div className="key-reveal__value">
          <span className="key-reveal__label">{vaultKey.label}</span>
          <code>{vaultKey.value}</code>
        </div>
        <p className="key-reveal__note">{note}</p>
      </div>
      <CopyButton label={`Copy ${vaultKey.label} key`} onCopy={() => onCopy(vaultKey)} />
    </div>
  )
}
