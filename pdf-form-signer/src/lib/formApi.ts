import type { Errors } from './validation'
import type { FieldKey, FormValues, RequirementKey, SignatureImage, SignatureKey, Signatures } from '../types'

export type SignatureReason = 'stroke' | 'undo' | 'clear' | 'typed'

/** Field keys whose value is a free-form string (text, date, number inputs). */
export type TextKey = { [K in FieldKey]: string extends FormValues[K] ? K : never }[FieldKey]

export interface FormApi {
  values: FormValues
  signatures: Signatures
  errors: Errors
  /** Error to display for a field right now (respects touched / revealed state). */
  visibleError: (key: RequirementKey) => string | undefined
  /** True once a field has been committed with a non-empty valid value. */
  isValid: (key: FieldKey) => boolean
  isShaking: (key: RequirementKey) => boolean
  setValue: <K extends FieldKey>(key: K, value: FormValues[K]) => void
  /** Text-style fields call this on blur; choice fields commit on change. */
  commit: (key: FieldKey) => void
  setSignature: (key: SignatureKey, img: SignatureImage | null, reason: SignatureReason) => void
  documentId: string
}

export function textProps(form: FormApi, key: TextKey) {
  return {
    id: key,
    value: form.values[key],
    onChange: (v: string) => form.setValue(key, v),
    onCommit: () => form.commit(key),
    error: form.visibleError(key),
    valid: form.isValid(key),
    shaking: form.isShaking(key),
  }
}
