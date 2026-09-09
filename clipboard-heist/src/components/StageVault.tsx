import { useState } from 'react'
import { KEYS, VAULT_ORDER, type KeyId } from '../data'
import type { ClipboardApi } from '../types'
import PasteField from './PasteField'
import './StageVault.css'

interface Props {
  api: ClipboardApi
  onOpen: () => void
}

interface SlotState {
  value: string
  status: 'idle' | 'ok' | 'error'
  note: string
}

const emptySlot = (): SlotState => ({ value: '', status: 'idle', note: '' })

export default function StageVault({ api, onOpen }: Props) {
  const [slots, setSlots] = useState<SlotState[]>(() => VAULT_ORDER.map(emptySlot))
  const activeIndex = slots.findIndex((s) => s.status !== 'ok')

  function handlePaste(index: number, text: string) {
    const expected: KeyId = VAULT_ORDER[index]
    const next = slots.slice()
    if (text === KEYS[expected].value) {
      next[index] = { value: text, status: 'ok', note: `${KEYS[expected].label} accepted` }
      api.notePaste(true)
      setSlots(next)
      if (next.every((s) => s.status === 'ok')) window.setTimeout(onOpen, 650)
      return
    }
    const which = Object.values(KEYS).find((k) => k.value === text)
    next[index] = {
      value: text,
      status: 'error',
      note: which
        ? `${which.label} is a valid key, but slot ${index + 1} wants ${KEYS[expected].label}.`
        : 'Not a vault key.',
    }
    api.notePaste(false)
    setSlots(next)
  }

  return (
    <div className="stage stage-vault">
      <section className="panel vault-panel">
        <header className="panel__head">
          <h3>Vault door · triple-key interlock</h3>
          <span className="pill pill--amber">
            {slots.filter((s) => s.status === 'ok').length}/{VAULT_ORDER.length} ENGAGED
          </span>
        </header>
        <p className="vault-brief">
          The interlock takes the three keys <strong>in this exact order</strong>. Each slot only accepts a paste, and
          the next slot stays sealed until the previous one is engaged. Everything you need is in the clipboard history.
        </p>
        <ol className="vault-order" aria-label="Required order">
          {VAULT_ORDER.map((id, i) => (
            <li key={id} className={`vault-order__item ${slots[i].status === 'ok' ? 'is-ok' : i === activeIndex ? 'is-active' : ''}`}>
              <span className="vault-order__num">{i + 1}</span>
              <span className="vault-order__label">{KEYS[id].label}</span>
            </li>
          ))}
        </ol>
        <div className="vault-slots">
          {VAULT_ORDER.map((id, i) => (
            <div key={id} className={`vault-slot ${slots[i].status === 'ok' ? 'vault-slot--ok' : ''}`}>
              <div className="vault-slot__head">
                <span className="vault-slot__num">SLOT {i + 1}</span>
                <span className="vault-slot__want">wants {KEYS[id].label}</span>
                {slots[i].status === 'ok' && <span className="vault-slot__check">ENGAGED</span>}
              </div>
              <PasteField
                id={`vault-slot-${i + 1}`}
                value={slots[i].value}
                placeholder={i > activeIndex && activeIndex !== -1 ? 'Sealed until the slot above is engaged' : `Paste the ${KEYS[id].label} key`}
                disabled={activeIndex !== -1 && i > activeIndex}
                locked={slots[i].status === 'ok'}
                state={slots[i].status}
                onPaste={(text) => handlePaste(i, text)}
                onClear={() => {
                  const next = slots.slice()
                  next[i] = emptySlot()
                  setSlots(next)
                }}
              />
              {slots[i].note && slots[i].status !== 'ok' && (
                <div className="status status--error" role="status">
                  {slots[i].note}
                </div>
              )}
            </div>
          ))}
        </div>
      </section>
    </div>
  )
}
