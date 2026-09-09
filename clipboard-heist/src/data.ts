export type KeyId = 'alpha' | 'bravo' | 'charlie'

export interface VaultKey {
  id: KeyId
  label: string
  value: string
}

export const ACCESS_CODE = 'Q7X2KM9ZP4LR'
export const DECOY_CODE = 'MB3T7QLW2ZNX'

export const KEYS: Record<KeyId, VaultKey> = {
  alpha: { id: 'alpha', label: 'ALPHA', value: 'ALPHA-4F9C-QT27' },
  bravo: { id: 'bravo', label: 'BRAVO', value: 'BRAVO-8H2N-VX61' },
  charlie: { id: 'charlie', label: 'CHARLIE', value: 'CHARLIE-3D7R-KW90' },
}

export const VAULT_ORDER: KeyId[] = ['bravo', 'charlie', 'alpha']

export const TRANSMISSION_LINES: string[] = [
  '>>> RELAY 07 // 03:12:44Z // SIG 4/5',
  'FREQ ........ 144.390 MHz / AFSK',
  'ORIGIN ...... STATION KESTREL',
  'SUBJECT ..... KEYPAD ROTATION, SUBLEVEL 3',
  '',
  `OLD CODE .... ${DECOY_CODE}   [REVOKED 02:00Z]`,
  `ACCESS CODE . ${ACCESS_CODE}`,
  'CHECKSUM .... 9F3A',
  '',
  'BURN AFTER DECODING. DO NOT RELAY.',
  '>>> END OF INTERCEPT',
]

export const MANIFEST_COLUMNS = ['Codename', 'Sector', 'Cover', 'Clearance', 'Status'] as const

export const MANIFEST_ROWS: string[][] = [
  ['Kestrel', 'North', 'Cartographer', 'L4', 'Active'],
  ['Marlin', 'Harbor', 'Customs broker', 'L3', 'Active'],
  ['Osprey', 'Downtown', 'Courier', 'L2', 'Dormant'],
  ['Lynx', 'Airfield', 'Mechanic', 'L4', 'Active'],
  ['Heron', 'Riverside', 'Florist', 'L1', 'Burned'],
  ['Viper', 'Uptown', 'Sommelier', 'L3', 'Active'],
]

export const MANIFEST_EXPECTED_ROWS = MANIFEST_ROWS.length + 1
export const MANIFEST_EXPECTED_COLS = MANIFEST_COLUMNS.length

export function manifestToTsv(rows: readonly (readonly string[])[]): string {
  return rows.map((r) => r.join('\t')).join('\n')
}

export const SNIPPET_TEXT = 'Meet at pier nine. Midnight. Bring the ledger.'

export const SNIPPET_HTML =
  '<p style="font-family:Georgia,serif;font-size:18px;color:#f5f7fb">' +
  '<b>Meet</b> at <i style="color:#ffb547">pier nine</i>. ' +
  '<u>Midnight</u>. <span style="color:#ff5d7a;font-weight:700">Bring the ledger.</span></p>'

export const OBJECTIVES = [
  { code: 'OBJ-1', title: 'Intercept', blurb: 'Lift the access code from the transmission' },
  { code: 'OBJ-2', title: 'Manifest', blurb: 'Exfiltrate the whole agent roster' },
  { code: 'OBJ-3', title: 'Dead drop', blurb: 'Deliver the message with formatting stripped' },
  { code: 'OBJ-4', title: 'Callback', blurb: 'Prove you still hold the first key' },
  { code: 'OBJ-5', title: 'Vault', blurb: 'Three keys, one order' },
] as const
