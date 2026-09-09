export type EngagementType = '' | 'fixed' | 'hourly' | 'retainer'
export type PaymentTerms = '' | 'net15' | 'net30' | 'net45'

export interface FormValues {
  fullName: string
  email: string
  phone: string
  company: string
  street: string
  city: string
  state: string
  zip: string
  startDate: string
  endDate: string
  engagementType: EngagementType
  rate: string
  paymentTerms: PaymentTerms
  acceptIp: boolean
  acceptConfidentiality: boolean
  acceptUpdates: boolean
  notes: string
  signDate: string
}

export type FieldKey = keyof FormValues

export type SignatureKey = 'initialsPage1' | 'initialsPage2' | 'signature'

export type RequirementKey = FieldKey | SignatureKey

export type StepId = 'page1' | 'page2' | 'sign' | 'review'

export const STEPS: { id: StepId; label: string; caption: string }[] = [
  { id: 'page1', label: 'Parties & term', caption: 'Page 1 of 2' },
  { id: 'page2', label: 'Compensation & terms', caption: 'Page 2 of 2' },
  { id: 'sign', label: 'Sign', caption: 'Signature' },
  { id: 'review', label: 'Review & generate', caption: 'Finish' },
]

export interface SignatureImage {
  /** PNG data URL, transparent background */
  dataUrl: string
  width: number
  height: number
  mode: 'drawn' | 'typed'
  strokes: number
  /** Raw stroke points so a remounted pad can keep editing (undo) a drawn signature. */
  paths?: { x: number; y: number }[][]
}

export type Signatures = Record<SignatureKey, SignatureImage | null>

export type AuditKind =
  | 'session'
  | 'navigate'
  | 'field'
  | 'initials'
  | 'signature'
  | 'validation'
  | 'pdf'

export interface AuditEvent {
  id: number
  time: string
  kind: AuditKind
  message: string
}

export const EMPTY_VALUES: FormValues = {
  fullName: '',
  email: '',
  phone: '',
  company: '',
  street: '',
  city: '',
  state: '',
  zip: '',
  startDate: '',
  endDate: '',
  engagementType: '',
  rate: '',
  paymentTerms: '',
  acceptIp: false,
  acceptConfidentiality: false,
  acceptUpdates: false,
  notes: '',
  signDate: '',
}

export const EMPTY_SIGNATURES: Signatures = {
  initialsPage1: null,
  initialsPage2: null,
  signature: null,
}

export const US_STATES: { code: string; name: string }[] = [
  { code: 'AL', name: 'Alabama' },
  { code: 'AK', name: 'Alaska' },
  { code: 'AZ', name: 'Arizona' },
  { code: 'AR', name: 'Arkansas' },
  { code: 'CA', name: 'California' },
  { code: 'CO', name: 'Colorado' },
  { code: 'CT', name: 'Connecticut' },
  { code: 'DE', name: 'Delaware' },
  { code: 'FL', name: 'Florida' },
  { code: 'GA', name: 'Georgia' },
  { code: 'HI', name: 'Hawaii' },
  { code: 'ID', name: 'Idaho' },
  { code: 'IL', name: 'Illinois' },
  { code: 'IN', name: 'Indiana' },
  { code: 'IA', name: 'Iowa' },
  { code: 'KS', name: 'Kansas' },
  { code: 'KY', name: 'Kentucky' },
  { code: 'LA', name: 'Louisiana' },
  { code: 'ME', name: 'Maine' },
  { code: 'MD', name: 'Maryland' },
  { code: 'MA', name: 'Massachusetts' },
  { code: 'MI', name: 'Michigan' },
  { code: 'MN', name: 'Minnesota' },
  { code: 'MS', name: 'Mississippi' },
  { code: 'MO', name: 'Missouri' },
  { code: 'MT', name: 'Montana' },
  { code: 'NE', name: 'Nebraska' },
  { code: 'NV', name: 'Nevada' },
  { code: 'NH', name: 'New Hampshire' },
  { code: 'NJ', name: 'New Jersey' },
  { code: 'NM', name: 'New Mexico' },
  { code: 'NY', name: 'New York' },
  { code: 'NC', name: 'North Carolina' },
  { code: 'ND', name: 'North Dakota' },
  { code: 'OH', name: 'Ohio' },
  { code: 'OK', name: 'Oklahoma' },
  { code: 'OR', name: 'Oregon' },
  { code: 'PA', name: 'Pennsylvania' },
  { code: 'RI', name: 'Rhode Island' },
  { code: 'SC', name: 'South Carolina' },
  { code: 'SD', name: 'South Dakota' },
  { code: 'TN', name: 'Tennessee' },
  { code: 'TX', name: 'Texas' },
  { code: 'UT', name: 'Utah' },
  { code: 'VT', name: 'Vermont' },
  { code: 'VA', name: 'Virginia' },
  { code: 'WA', name: 'Washington' },
  { code: 'WV', name: 'West Virginia' },
  { code: 'WI', name: 'Wisconsin' },
  { code: 'WY', name: 'Wyoming' },
  { code: 'DC', name: 'District of Columbia' },
]

export const ENGAGEMENT_OPTIONS: { value: Exclude<EngagementType, ''>; label: string; hint: string }[] = [
  { value: 'fixed', label: 'Fixed price', hint: 'One agreed fee for the whole project' },
  { value: 'hourly', label: 'Hourly', hint: 'Billed per hour worked, invoiced with a timesheet' },
  { value: 'retainer', label: 'Monthly retainer', hint: 'A flat monthly fee for ongoing availability' },
]

export const PAYMENT_OPTIONS: { value: Exclude<PaymentTerms, ''>; label: string }[] = [
  { value: 'net15', label: 'Net 15' },
  { value: 'net30', label: 'Net 30' },
  { value: 'net45', label: 'Net 45' },
]

export const CLIENT = {
  name: 'Northwind Studio LLC',
  address: '410 Market Street, Suite 900, San Francisco, CA 94105',
  signatory: 'Avery Lindqvist, Managing Director',
}
