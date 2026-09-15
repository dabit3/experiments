/**
 * Automated replay of the Beat Lab computer-use showcase scenario.
 *
 *   1. Reproduce the "Boom Bap" reference on all 8 tracks → Compare reports 0 differences
 *   2. Set tempo to 92 BPM and swing to 15 %
 *   3. Place a 4-note bass line in the piano roll
 *   4. Press Play and verify the playhead advances
 *   5. Save the pattern JSON (download), Clear the grid, re-upload the file
 *   6. Verify drums + bass + tempo are restored and Compare is a perfect match again
 *
 * Run with `npm run test:e2e`. The Vite dev server is started automatically.
 */
import { expect, test, type Page } from '@playwright/test'
import { readFile } from 'node:fs/promises'

const BOOM_BAP: Record<string, number[]> = {
  Kick: [1, 8, 11],
  Snare: [5, 13],
  'Closed hat': [1, 3, 5, 7, 9, 11, 13, 15],
  'Open hat': [7, 15],
  Clap: [5, 13],
  Rim: [4, 12],
  Tom: [14],
  Cowbell: [10],
}

const BASS_LINE: ReadonlyArray<readonly [step: number, note: string]> = [
  [1, 'C2'],
  [5, 'C2'],
  [9, 'D#2'],
  [13, 'G2'],
]

const drumStep = (page: Page, track: string, step: number) =>
  page.getByRole('gridcell', { name: new RegExp(`^${track} step ${step}:`) })

const bassNote = (page: Page, note: string, step: number) =>
  page.getByRole('gridcell', { name: `${note} step ${step}`, exact: true })

const setSlider = async (page: Page, label: string, value: number) => {
  const slider = page.getByLabel(label, { exact: true })
  await slider.fill(String(value))
  await expect(slider).toHaveValue(String(value))
}

test('Boom Bap reproduction, tempo/swing, bass line, playback and JSON round-trip', async ({
  page,
}, testInfo) => {
  await page.goto('/')
  await expect(page.getByRole('heading', { name: 'Beat Lab' })).toBeVisible()

  await test.step('Reproduce the Boom Bap reference on all 8 tracks', async () => {
    for (const [track, steps] of Object.entries(BOOM_BAP)) {
      for (const s of steps) {
        const cell = drumStep(page, track, s)
        await cell.click()
        await expect(cell).toHaveAttribute('aria-pressed', 'true')
      }
    }
    await expect(page.getByRole('tab', { name: /Drums/ })).toContainText('21')
  })

  await test.step('Compare with reference reports 0 differences', async () => {
    await page.getByRole('button', { name: 'Compare with reference' }).click()
    const result = page.getByRole('status').filter({ hasText: 'Perfect match' })
    await expect(result).toBeVisible()
    await expect(result).toContainText('0 differences')
  })

  await test.step('Set tempo to 92 BPM and swing to 15%', async () => {
    await setSlider(page, 'Tempo', 92)
    await setSlider(page, 'Swing', 15)
    await expect(page.locator('.statusbar')).toContainText('92 BPM · 15% swing')
  })

  await test.step('Add a 4-note bass line', async () => {
    await page.getByRole('tab', { name: /Bass/ }).click()
    for (const [step, note] of BASS_LINE) {
      const cell = bassNote(page, note, step)
      await cell.click()
      await expect(cell).toHaveAttribute('aria-pressed', 'true')
    }
    await expect(page.locator('.key-count')).toHaveText('4 notes')
    await page.getByRole('tab', { name: /Drums/ }).click()
  })

  await test.step('Play and verify the playhead moves', async () => {
    await page.getByRole('button', { name: 'Play' }).click()
    await expect(page.getByRole('button', { name: 'Stop' })).toBeVisible()

    const playhead = page.locator('.step-header .step-num.is-now')
    await expect(playhead).toBeVisible()
    const first = await playhead.textContent()
    await expect
      .poll(async () => playhead.textContent(), { timeout: 5_000 })
      .not.toBe(first)
    await expect(page.locator('.statusbar')).toContainText('Playing pattern A')

    await page.getByRole('button', { name: 'Stop' }).click()
    await expect(page.getByRole('button', { name: 'Play' })).toBeVisible()
    await expect(playhead).toHaveCount(0)
  })

  const savedPath = testInfo.outputPath('beat-lab-pattern.json')

  await test.step('Save pattern JSON', async () => {
    const downloadPromise = page.waitForEvent('download')
    await page.getByRole('button', { name: 'Save JSON' }).click()
    const download = await downloadPromise
    expect(download.suggestedFilename()).toBe('beat-lab-pattern.json')
    await download.saveAs(savedPath)

    const json = JSON.parse(await readFile(savedPath, 'utf8')) as {
      bpm: number
      swing: number
      patterns: { A: { drums: number[][]; bass: (number | null)[] } }
    }
    expect(json.bpm).toBe(92)
    expect(json.swing).toBe(15)
    expect(json.patterns.A.drums.flat().filter((v) => v > 0)).toHaveLength(21)
    expect(json.patterns.A.bass.filter((n) => n !== null)).toHaveLength(4)
  })

  await test.step('Clear the grid', async () => {
    await page.getByRole('button', { name: 'Clear' }).click()
    await expect(page.getByRole('tab', { name: /Drums/ })).toContainText('0')
    await expect(page.getByRole('tab', { name: /Bass/ })).toContainText('0')
    await expect(page.locator('.step[aria-pressed="true"]')).toHaveCount(0)
  })

  await test.step('Load the saved JSON and verify the round-trip', async () => {
    await page.getByLabel('Load pattern file').setInputFiles(savedPath)
    await expect(page.getByRole('status').filter({ hasText: 'Loaded beat-lab-pattern.json' })).toBeVisible()

    await expect(page.getByRole('tab', { name: /Drums/ })).toContainText('21')
    await expect(page.getByRole('tab', { name: /Bass/ })).toContainText('4')
    await expect(page.locator('.statusbar')).toContainText('92 BPM · 15% swing')

    for (const [track, steps] of Object.entries(BOOM_BAP)) {
      for (const s of steps) {
        await expect(drumStep(page, track, s)).toHaveAttribute('aria-pressed', 'true')
      }
    }

    await page.getByRole('button', { name: 'Compare with reference' }).click()
    await expect(page.getByRole('status').filter({ hasText: 'Perfect match' })).toBeVisible()

    await page.getByRole('tab', { name: /Bass/ }).click()
    for (const [step, note] of BASS_LINE) {
      await expect(bassNote(page, note, step)).toHaveAttribute('aria-pressed', 'true')
    }
  })
})
