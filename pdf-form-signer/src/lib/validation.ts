import type { FieldKey, FormValues, RequirementKey, SignatureKey, Signatures, StepId } from '../types'

export type Errors = Partial<Record<RequirementKey, string>>

export const FIELD_LABELS: Record<RequirementKey, string> = {
  fullName: 'Contractor full name',
  email: 'Email address',
  phone: 'Phone number',
  company: 'Business name',
  street: 'Street address',
  city: 'City',
  state: 'State',
  zip: 'ZIP code',
  startDate: 'Start date',
  endDate: 'End date',
  engagementType: 'Engagement type',
  rate: 'Fee',
  paymentTerms: 'Payment terms',
  acceptIp: 'IP assignment acknowledgement',
  acceptConfidentiality: 'Confidentiality acknowledgement',
  acceptUpdates: 'Project updates',
  notes: 'Additional terms',
  signDate: 'Date signed',
  initialsPage1: 'Initials on page 1',
  initialsPage2: 'Initials on page 2',
  signature: 'Signature',
}

export const FIELD_STEP: Record<RequirementKey, StepId> = {
  fullName: 'page1',
  email: 'page1',
  phone: 'page1',
  company: 'page1',
  street: 'page1',
  city: 'page1',
  state: 'page1',
  zip: 'page1',
  startDate: 'page1',
  endDate: 'page1',
  initialsPage1: 'page1',
  engagementType: 'page2',
  rate: 'page2',
  paymentTerms: 'page2',
  acceptIp: 'page2',
  acceptConfidentiality: 'page2',
  acceptUpdates: 'page2',
  notes: 'page2',
  initialsPage2: 'page2',
  signDate: 'sign',
  signature: 'sign',
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/
const ZIP_RE = /^\d{5}(-\d{4})?$/

export function digitsOf(s: string): string {
  return s.replace(/\D/g, '')
}

function required(value: string, label: string): string | undefined {
  return value.trim() ? undefined : `${label} is required`
}

export function validateField(key: FieldKey, values: FormValues): string | undefined {
  const label = FIELD_LABELS[key]
  switch (key) {
    case 'fullName': {
      const v = values.fullName.trim()
      if (!v) return `${label} is required`
      if (v.split(/\s+/).length < 2) return 'Enter your first and last name'
      return undefined
    }
    case 'email': {
      const v = values.email.trim()
      if (!v) return `${label} is required`
      if (!EMAIL_RE.test(v)) return 'Enter a valid email like name@example.com'
      return undefined
    }
    case 'phone': {
      const v = values.phone.trim()
      if (!v) return `${label} is required`
      if (digitsOf(v).length < 10) return 'Enter a phone number with at least 10 digits'
      return undefined
    }
    case 'street':
    case 'city':
      return required(values[key], label)
    case 'state':
      return values.state ? undefined : 'Choose a state'
    case 'zip': {
      const v = values.zip.trim()
      if (!v) return `${label} is required`
      if (!ZIP_RE.test(v)) return 'Enter a 5-digit ZIP code'
      return undefined
    }
    case 'startDate':
      return required(values.startDate, label)
    case 'endDate': {
      if (!values.endDate) return `${label} is required`
      if (values.startDate && values.endDate < values.startDate) return 'End date must be on or after the start date'
      return undefined
    }
    case 'engagementType':
      return values.engagementType ? undefined : 'Choose an engagement type'
    case 'rate': {
      const v = values.rate.trim()
      if (!v) return `${label} is required`
      const n = Number(v.replace(/[,$\s]/g, ''))
      if (!Number.isFinite(n) || n <= 0) return 'Enter an amount greater than 0'
      return undefined
    }
    case 'paymentTerms':
      return values.paymentTerms ? undefined : 'Choose payment terms'
    case 'acceptIp':
      return values.acceptIp ? undefined : 'You must acknowledge the IP assignment clause'
    case 'acceptConfidentiality':
      return values.acceptConfidentiality ? undefined : 'You must acknowledge the confidentiality clause'
    case 'signDate':
      return required(values.signDate, label)
    case 'company':
    case 'acceptUpdates':
    case 'notes':
      return undefined
  }
}

const FIELD_KEYS = Object.keys(FIELD_STEP).filter(
  (k): k is FieldKey => !['initialsPage1', 'initialsPage2', 'signature'].includes(k),
)
const SIGNATURE_KEYS: SignatureKey[] = ['initialsPage1', 'initialsPage2', 'signature']

export function validateAll(values: FormValues, signatures: Signatures): Errors {
  const errors: Errors = {}
  for (const key of FIELD_KEYS) {
    const err = validateField(key, values)
    if (err) errors[key] = err
  }
  for (const key of SIGNATURE_KEYS) {
    if (!signatures[key]) {
      errors[key] = key === 'signature' ? 'Draw or type your signature' : `Add your initials to ${key === 'initialsPage1' ? 'page 1' : 'page 2'}`
    }
  }
  return errors
}

export function errorsForStep(errors: Errors, step: StepId): RequirementKey[] {
  return (Object.keys(errors) as RequirementKey[]).filter((k) => FIELD_STEP[k] === step)
}

export const REQUIRED_COUNT = FIELD_KEYS.filter((k) => !['company', 'acceptUpdates', 'notes'].includes(k)).length + SIGNATURE_KEYS.length
