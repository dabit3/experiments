import { Clause, Fill, Paper } from '../components/Paper'
import { SelectField, TextField } from '../components/Field'
import { formatLongDate } from '../lib/format'
import { textProps } from '../lib/formApi'
import type { FormApi, TextKey } from '../lib/formApi'
import { CLIENT, US_STATES } from '../types'

export function PageOne({ form }: { form: FormApi }) {
  const { values } = form
  const text = (key: TextKey) => textProps(form, key)

  return (
    <Paper
      page={1}
      documentId={form.documentId}
      initials={form.signatures.initialsPage1}
      initialsError={form.visibleError('initialsPage1')}
      onInitials={(img, reason) => form.setSignature('initialsPage1', img, reason)}
    >
      <Clause title="1. Parties">
        <p className="clause__body">
          This Contractor Agreement (the “Agreement”) is entered into as of{' '}
          <Fill value={formatLongDate(values.startDate)} placeholder="start date" /> between <strong>{CLIENT.name}</strong>, with
          offices at {CLIENT.address} (the “Client”), and{' '}
          <Fill value={values.fullName.trim()} placeholder="contractor name" /> (the “Contractor”). The Contractor’s details are
          recorded below.
        </p>
        <div className="field-grid">
          <TextField {...text('fullName')} label="Contractor full name" placeholder="First and last name" required className="span-6" autoComplete="name" />
          <TextField
            {...text('company')}
            label="Business name"
            placeholder="Leave blank if sole proprietor"
            className="span-6"
            hint="Shown on the agreement if you invoice through a business"
          />
          <TextField {...text('email')} label="Email address" type="email" placeholder="name@example.com" required className="span-6" inputMode="email" />
          <TextField {...text('phone')} label="Phone number" type="tel" placeholder="(555) 010-2030" required className="span-6" inputMode="tel" />
          <TextField {...text('street')} label="Street address" placeholder="Street and number" required className="span-12" />
          <TextField {...text('city')} label="City" placeholder="City" required className="span-4" />
          <SelectField
            id="state"
            label="State"
            required
            className="span-4"
            value={values.state}
            placeholder="Choose a state"
            options={US_STATES.map((s) => ({ value: s.code, label: `${s.name} (${s.code})` }))}
            onChange={(v) => {
              form.setValue('state', v)
              form.commit('state')
            }}
            error={form.visibleError('state')}
            valid={form.isValid('state')}
            shaking={form.isShaking('state')}
          />
          <TextField {...text('zip')} label="ZIP code" placeholder="94105" required className="span-4" inputMode="numeric" />
        </div>
      </Clause>

      <Clause title="2. Term">
        <p className="clause__body">
          The Contractor will provide services from <Fill value={formatLongDate(values.startDate)} placeholder="start date" /> through{' '}
          <Fill value={formatLongDate(values.endDate)} placeholder="end date" />, unless terminated earlier in accordance with Section 6.
          Either party may terminate this Agreement with fourteen (14) days written notice.
        </p>
        <div className="field-grid">
          <TextField {...text('startDate')} label="Start date" type="date" required className="span-6" />
          <TextField {...text('endDate')} label="End date" type="date" required className="span-6" min={values.startDate || undefined} />
        </div>
      </Clause>

      <Clause title="3. Services">
        <p className="clause__body">
          The Contractor agrees to perform the design and engineering services described in each written statement of work agreed by
          both parties. The Contractor determines the method, details and means of performing the services and is not an employee of the
          Client.
        </p>
      </Clause>
    </Paper>
  )
}
