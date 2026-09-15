import { Clause, Fill, Paper } from '../components/Paper'
import { Checkbox, RadioGroup, TextField } from '../components/Field'
import { engagementLabel, formatMoney, paymentLabel, rateLabel, rateSuffix } from '../lib/format'
import { textProps } from '../lib/formApi'
import type { FormApi } from '../lib/formApi'
import { ENGAGEMENT_OPTIONS, PAYMENT_OPTIONS } from '../types'

export function PageTwo({ form }: { form: FormApi }) {
  const { values } = form

  return (
    <Paper
      page={2}
      documentId={form.documentId}
      initials={form.signatures.initialsPage2}
      initialsError={form.visibleError('initialsPage2')}
      onInitials={(img, reason) => form.setSignature('initialsPage2', img, reason)}
    >
      <Clause title="4. Compensation">
        <p className="clause__body">
          The Client will pay the Contractor on a{' '}
          <Fill value={engagementLabel(values.engagementType).toLowerCase()} placeholder="engagement type" /> basis at{' '}
          <Fill value={values.rate.trim() ? `${formatMoney(values.rate)}${rateSuffix(values.engagementType)}` : ''} placeholder="fee" />.
          Invoices are payable on <Fill value={paymentLabel(values.paymentTerms)} placeholder="terms" /> terms from the invoice date.
        </p>
        <div className="field-grid">
          <RadioGroup
            id="engagementType"
            label="Engagement type"
            required
            className="span-12"
            row
            value={values.engagementType}
            options={ENGAGEMENT_OPTIONS}
            onChange={(v) => {
              form.setValue('engagementType', v)
              form.commit('engagementType')
            }}
            error={form.visibleError('engagementType')}
            shaking={form.isShaking('engagementType')}
          />
          <TextField
            {...textProps(form, 'rate')}
            label={rateLabel(values.engagementType)}
            type="text"
            inputMode="decimal"
            prefix="$"
            placeholder="0.00"
            required
            className="span-6"
            hint={values.engagementType === 'hourly' ? 'Billed against approved timesheets' : undefined}
          />
          <RadioGroup
            id="paymentTerms"
            label="Payment terms"
            required
            className="span-6"
            row
            value={values.paymentTerms}
            options={PAYMENT_OPTIONS}
            onChange={(v) => {
              form.setValue('paymentTerms', v)
              form.commit('paymentTerms')
            }}
            error={form.visibleError('paymentTerms')}
            shaking={form.isShaking('paymentTerms')}
          />
        </div>
      </Clause>

      <Clause title="5. Intellectual property & confidentiality">
        <div className="field-grid">
          <div className="span-12 choice-group">
            <Checkbox
              id="acceptIp"
              label="I assign all right, title and interest in the deliverables to the Client upon payment in full."
              hint="Required · IP assignment"
              checked={values.acceptIp}
              onChange={(v) => {
                form.setValue('acceptIp', v)
                form.commit('acceptIp')
              }}
              error={form.visibleError('acceptIp')}
            />
            <Checkbox
              id="acceptConfidentiality"
              label="I will keep the Client’s non-public business, technical and financial information confidential for three (3) years."
              hint="Required · Confidentiality"
              checked={values.acceptConfidentiality}
              onChange={(v) => {
                form.setValue('acceptConfidentiality', v)
                form.commit('acceptConfidentiality')
              }}
              error={form.visibleError('acceptConfidentiality')}
            />
            <Checkbox
              id="acceptUpdates"
              label="Send me project updates and invoice reminders by email."
              hint="Optional"
              checked={values.acceptUpdates}
              onChange={(v) => {
                form.setValue('acceptUpdates', v)
                form.commit('acceptUpdates')
              }}
            />
          </div>
        </div>
      </Clause>

      <Clause title="6. Additional terms">
        <div className="field-grid">
          <TextField
            {...textProps(form, 'notes')}
            label="Additional terms"
            multiline
            placeholder="Anything else both parties have agreed to, e.g. equipment, travel, or reporting cadence."
            className="span-12"
          />
        </div>
      </Clause>
    </Paper>
  )
}
