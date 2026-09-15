import { SignaturePad } from '../components/SignaturePad'
import { TextField } from '../components/Field'
import { textProps } from '../lib/formApi'
import type { FormApi } from '../lib/formApi'
import { CLIENT } from '../types'

export function SignStep({ form }: { form: FormApi }) {
  const sigError = form.visibleError('signature')
  const name = form.values.fullName.trim()

  return (
    <section className="sign-card" aria-labelledby="sign-title">
      <div className="sign-card__head">
        <div>
          <h2 id="sign-title">Sign the agreement</h2>
          <p>Draw your signature with the mouse, or type it and we will render it in a script typeface.</p>
        </div>
      </div>

      <div className="sign-card__grid">
        <div className="field is-signature" data-field="signature">
          <label className="field__label" htmlFor="signature">
            Contractor signature <span className="req">*</span>
          </label>
          <SignaturePad
            id="signature"
            width={640}
            height={220}
            value={form.signatures.signature}
            onChange={(img, reason) => form.setSignature('signature', img, reason)}
            allowTyped
            typedDefault={name}
            placeholder="Sign here"
            invalid={!!sigError}
          />
          {sigError && (
            <div className="field__error" role="alert">
              {sigError}
            </div>
          )}
        </div>

        <aside className="sign-card__side">
          <TextField {...textProps(form, 'signDate')} label="Date signed" type="date" required />
          <div className="legal-note">
            By signing, <strong>{name || 'the Contractor'}</strong> agrees to the terms of this Contractor Agreement with{' '}
            <strong>{CLIENT.name}</strong>. Your signature and initials are embedded as images in the generated PDF, together
            with an audit trail of this session.
          </div>
        </aside>
      </div>
    </section>
  )
}
