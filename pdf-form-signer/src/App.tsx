import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { AuditTrail } from './components/AuditTrail'
import { BrandMark } from './components/BrandMark'
import { formatMoney, paymentLabel, engagementLabel, stateName } from './lib/format'
import type { FormApi, SignatureReason } from './lib/formApi'
import { downloadBlob, generateAgreementPdf, makeDocumentId } from './lib/pdf'
import type { PdfResult } from './lib/pdf'
import { errorsForStep, FIELD_LABELS, FIELD_STEP, REQUIRED_COUNT, validateAll } from './lib/validation'
import { PageOne } from './steps/PageOne'
import { PageTwo } from './steps/PageTwo'
import { ReviewStep } from './steps/ReviewStep'
import { SignStep } from './steps/SignStep'
import { EMPTY_SIGNATURES, EMPTY_VALUES, STEPS } from './types'
import type { AuditEvent, AuditKind, FieldKey, FormValues, RequirementKey, SignatureImage, SignatureKey, Signatures, StepId } from './types'

interface Toast {
  id: number
  kind: 'error' | 'success' | 'info'
  text: string
}

function describeValue(key: FieldKey, values: FormValues): string {
  const v = values[key]
  if (typeof v === 'boolean') return v ? 'checked' : 'unchecked'
  switch (key) {
    case 'state':
      return v ? stateName(v) : '(empty)'
    case 'engagementType':
      return engagementLabel(values.engagementType) || '(empty)'
    case 'paymentTerms':
      return paymentLabel(values.paymentTerms) || '(empty)'
    case 'rate':
      return v ? formatMoney(v) : '(empty)'
    default:
      return v.trim() ? `“${v.trim()}”` : '(empty)'
  }
}

export default function App() {
  const [values, setValues] = useState<FormValues>(EMPTY_VALUES)
  const valuesRef = useRef(values)
  const committedRef = useRef<FormValues>(EMPTY_VALUES)
  const [signatures, setSignatures] = useState<Signatures>(EMPTY_SIGNATURES)
  const [step, setStep] = useState<StepId>('page1')
  const [touched, setTouched] = useState<Set<RequirementKey>>(() => new Set())
  const [revealed, setRevealed] = useState<Set<StepId>>(() => new Set())
  const [shaking, setShaking] = useState<RequirementKey | null>(null)
  const [toast, setToast] = useState<Toast | null>(null)
  const [generating, setGenerating] = useState(false)
  const [result, setResult] = useState<PdfResult | null>(null)
  const [audit, setAudit] = useState<AuditEvent[]>(() => [
    { id: 1, time: new Date().toISOString(), kind: 'session', message: 'Session started · Contractor Agreement opened' },
  ])

  const log = useCallback((kind: AuditKind, message: string) => {
    setAudit((prev) => [...prev, { id: prev.length + 1, time: new Date().toISOString(), kind, message }])
  }, [])

  const showToast = useCallback((kind: Toast['kind'], text: string) => {
    setToast({ id: Date.now(), kind, text })
  }, [])

  useEffect(() => {
    if (!toast) return
    const t = window.setTimeout(() => setToast(null), 3200)
    return () => window.clearTimeout(t)
  }, [toast])

  useEffect(() => {
    if (!shaking) return
    const t = window.setTimeout(() => setShaking(null), 600)
    return () => window.clearTimeout(t)
  }, [shaking])

  /** Scroll a field into view and focus it once the target step has rendered. */
  const focusField = (key: RequirementKey) => {
    window.setTimeout(() => {
      document.querySelector<HTMLElement>(`[data-field="${key}"]`)?.scrollIntoView({ behavior: 'smooth', block: 'center' })
      const input = document.getElementById(key)
      if (input instanceof HTMLInputElement || input instanceof HTMLSelectElement || input instanceof HTMLTextAreaElement) {
        input.focus({ preventScroll: true })
      }
    }, 80)
  }

  const errors = useMemo(() => validateAll(values, signatures), [values, signatures])
  const documentId = useMemo(() => makeDocumentId(`${values.fullName}|${values.email}|${values.signDate}`), [values.fullName, values.email, values.signDate])

  const completed = REQUIRED_COUNT - Object.keys(errors).length
  const progress = Math.round((completed / REQUIRED_COUNT) * 100)

  const setValue = useCallback(<K extends FieldKey>(key: K, value: FormValues[K]) => {
    valuesRef.current = { ...valuesRef.current, [key]: value }
    setValues(valuesRef.current)
  }, [])

  const commit = useCallback(
    (key: FieldKey) => {
      const current = valuesRef.current
      setTouched((prev) => (prev.has(key) ? prev : new Set(prev).add(key)))
      if (current[key] !== committedRef.current[key]) {
        committedRef.current = { ...committedRef.current, [key]: current[key] }
        log('field', `${FIELD_LABELS[key]} set to ${describeValue(key, current)}`)
      }
      const err = validateAll(current, signatures)[key]
      if (err && (current[key] !== '' || touched.has(key))) log('validation', `${FIELD_LABELS[key]}: ${err}`)
    },
    [log, signatures, touched],
  )

  const setSignature = useCallback(
    (key: SignatureKey, img: SignatureImage | null, reason: SignatureReason) => {
      setSignatures((prev) => ({ ...prev, [key]: img }))
      setTouched((prev) => (prev.has(key) ? prev : new Set(prev).add(key)))
      const label = FIELD_LABELS[key]
      const kind: AuditKind = key === 'signature' ? 'signature' : 'initials'
      if (reason === 'stroke' && img) log(kind, `${label} drawn · stroke ${img.strokes}`)
      else if (reason === 'undo') log(kind, img ? `${label} · undid last stroke (${img.strokes} left)` : `${label} · undid last stroke (empty)`)
      else if (reason === 'clear') log(kind, `${label} cleared`)
      else if (reason === 'typed' && img) log(kind, `${label} adopted as typed text`)
    },
    [log],
  )

  const form: FormApi = {
    values,
    signatures,
    errors,
    documentId,
    visibleError: (key) => (touched.has(key) || revealed.has(FIELD_STEP[key]) ? errors[key] : undefined),
    isValid: (key) => touched.has(key) && !errors[key] && values[key] !== '' && values[key] !== false,
    isShaking: (key) => shaking === key,
    setValue,
    commit,
    setSignature,
  }

  const stepIndex = STEPS.findIndex((s) => s.id === step)

  const goTo = useCallback(
    (next: StepId, why: string) => {
      if (next === step) return
      setStep(next)
      window.scrollTo({ top: 0, behavior: 'smooth' })
      const label = STEPS.find((s) => s.id === next)?.label ?? next
      log('navigate', `${why} → ${label}`)
    },
    [log, step],
  )

  const revealStep = (id: StepId) => setRevealed((prev) => (prev.has(id) ? prev : new Set(prev).add(id)))

  const tryContinue = () => {
    const missing = errorsForStep(errors, step)
    if (missing.length) {
      revealStep(step)
      const first = missing[0]
      setShaking(first)
      focusField(first)
      log('validation', `Blocked on ${STEPS[stepIndex].label}: ${missing.length} required ${missing.length === 1 ? 'item' : 'items'} missing (${missing.map((k) => FIELD_LABELS[k]).join(', ')})`)
      showToast('error', `${missing.length === 1 ? 'One field needs' : `${missing.length} fields need`} attention before you continue`)
      return
    }
    goTo(STEPS[stepIndex + 1].id, 'Continued')
  }

  const jumpTo = (key: RequirementKey) => {
    const target = FIELD_STEP[key]
    revealStep(target)
    setShaking(key)
    focusField(key)
    goTo(target, `Jumped to ${FIELD_LABELS[key]}`)
  }

  const missingAll = useMemo(() => {
    const order: RequirementKey[] = Object.keys(FIELD_STEP) as RequirementKey[]
    return order.filter((k) => errors[k])
  }, [errors])

  const generate = () => {
    if (missingAll.length) return
    setGenerating(true)
    log('pdf', 'Generate PDF requested')
    window.setTimeout(() => {
      try {
        const res = generateAgreementPdf(values, signatures, [
          ...audit,
          { id: audit.length + 1, time: new Date().toISOString(), kind: 'pdf', message: 'PDF rendered and download started' },
        ])
        downloadBlob(res.blob, res.fileName)
        setResult(res)
        log('pdf', `PDF rendered · ${res.pages} pages · ${(res.bytes / 1024).toFixed(0)} KB · ${res.documentId}`)
        log('pdf', `Download started · ${res.fileName}`)
        showToast('success', `Downloaded ${res.fileName}`)
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err)
        log('pdf', `PDF generation failed: ${msg}`)
        showToast('error', 'PDF generation failed — see the audit trail')
      } finally {
        setGenerating(false)
      }
    }, 60)
  }

  const exportAudit = () => {
    const blob = new Blob([JSON.stringify({ documentId, events: audit }, null, 2)], { type: 'application/json' })
    downloadBlob(blob, `audit-trail-${documentId}.json`)
    log('pdf', 'Audit trail exported as JSON')
  }

  const stepClass = (id: StepId) => {
    const errs = errorsForStep(errors, id)
    const classes = ['step']
    if (id === step) classes.push('is-active')
    if (id === 'review' ? result !== null : errs.length === 0) classes.push('is-done')
    else if (revealed.has(id) && errs.length) classes.push('has-errors')
    return classes.join(' ')
  }

  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <BrandMark className="brand__mark" size={32} />
          <span className="brand__name">
            PDF Form Signer
            <span className="brand__tag">Agreements</span>
          </span>
        </div>
        <div className="topbar__divider" aria-hidden="true" />
        <div className="doc-chip">
          <span className="doc-chip__label">Document</span>
          <span className="doc-chip__value">Contractor Agreement</span>
          <span className="doc-chip__id">{documentId}</span>
        </div>
        <div className="topbar__spacer" />
        <div className="progress" aria-label={`${completed} of ${REQUIRED_COUNT} required items complete`}>
          <span className="progress__text">
            <strong>{completed}</strong>/{REQUIRED_COUNT} required
          </span>
          <div className="progress__bar">
            <div className={`progress__fill ${progress === 100 ? 'is-complete' : ''}`} style={{ width: `${progress}%` }} />
          </div>
        </div>
        <span className={`status-pill ${result ? 'is-signed' : progress === 100 ? 'is-ready' : ''}`}>
          {result ? 'Signed' : progress === 100 ? 'Ready to sign' : 'In progress'}
        </span>
      </header>

      <main className="layout">
        <div className="workspace">
          <nav className="stepper" aria-label="Steps">
            {STEPS.map((s, i) => (
              <button
                key={s.id}
                type="button"
                className={stepClass(s.id)}
                aria-current={s.id === step ? 'step' : undefined}
                onClick={() => goTo(s.id, 'Opened step')}
                data-step={s.id}
              >
                <span className="step__num">
                  <span className="step__digit">{i + 1}</span>
                  <svg className="step__check" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                    <path d="M5 12.5l4.5 4.5L19 7" />
                  </svg>
                </span>
                <span className="step__text">
                  <span className="step__label">{s.label}</span>
                  <span className="step__caption">{s.caption}</span>
                </span>
              </button>
            ))}
          </nav>

          {step === 'page1' && <PageOne form={form} />}
          {step === 'page2' && <PageTwo form={form} />}
          {step === 'sign' && <SignStep form={form} />}
          {step === 'review' && (
            <ReviewStep form={form} missing={missingAll} onJumpTo={jumpTo} onGenerate={generate} generating={generating} result={result} />
          )}

          <div className="navbar">
            <button
              type="button"
              className="btn btn--secondary"
              onClick={() => goTo(STEPS[stepIndex - 1].id, 'Went back')}
              disabled={stepIndex === 0}
              data-action="back"
            >
              ← Back
            </button>
            <div className="navbar__spacer" />
            <span className={`navbar__note ${revealed.has(step) && errorsForStep(errors, step).length ? 'is-warning' : ''}`}>
              {step === 'review'
                ? missingAll.length
                  ? `${missingAll.length} required ${missingAll.length === 1 ? 'item' : 'items'} missing`
                  : 'Ready to generate'
                : `${errorsForStep(errors, step).length} required ${errorsForStep(errors, step).length === 1 ? 'item' : 'items'} left on this step`}
            </span>
            {step !== 'review' && (
              <button type="button" className="btn btn--primary" onClick={tryContinue} data-action="continue">
                {step === 'sign' ? 'Review agreement →' : 'Continue →'}
              </button>
            )}
          </div>
        </div>

        <AuditTrail events={audit} onExport={exportAudit} />
      </main>

      {toast && (
        <div key={toast.id} className={`toast toast--${toast.kind}`} role="status">
          {toast.text}
        </div>
      )}
    </div>
  )
}
