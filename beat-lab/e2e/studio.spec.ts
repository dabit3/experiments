import { expect, test } from '@playwright/test'

test('Pattern overview keeps independent edits and reports the playing pattern while chaining', async ({
  page,
}) => {
  await page.goto('/')
  const patternA = page.getByRole('button', { name: 'Pattern A', exact: true })
  const patternB = page.getByRole('button', { name: 'Pattern B', exact: true })
  const kick = page.getByRole('gridcell', { name: /^Kick step 1:/ })

  await kick.click()
  await kick.click({ button: 'right' })
  await expect(kick).toHaveAttribute('aria-label', 'Kick step 1: medium')
  await expect(patternA).toContainText('1 hit · 0 notes')
  await page.getByRole('button', { name: 'Mute Kick', exact: true }).click()
  await expect(kick.locator('..').locator('..')).toHaveClass(/is-silenced/)
  await page.getByRole('button', { name: 'Solo Kick', exact: true }).click()
  await expect(kick.locator('..').locator('..')).not.toHaveClass(/is-silenced/)
  await page.getByRole('button', { name: 'Mute Kick', exact: true }).click()
  await page.getByRole('button', { name: 'Solo Kick', exact: true }).click()

  await patternB.click()
  await expect(patternB).toHaveAttribute('aria-pressed', 'true')
  await expect(kick).toHaveAttribute('aria-pressed', 'false')
  await page
    .getByRole('gridcell', { name: 'Snare step 5: off', exact: true })
    .click()
  await page.getByRole('tab', { name: /Bass/ }).click()
  await page.getByRole('gridcell', { name: 'D#2 step 9', exact: true }).click()
  await expect(patternB).toContainText('1 hit · 1 note')
  await expect(patternB.locator('.has-notes')).toHaveCount(2)

  await page.getByRole('button', { name: 'Chain A→B' }).click()
  await page.getByRole('button', { name: 'Play', exact: true }).click()
  await expect(patternA).toContainText('Playing')
  await expect(patternB).toHaveAttribute('aria-pressed', 'true')
  await expect(patternB).toContainText('Playing', { timeout: 5_000 })
  await page.getByRole('button', { name: 'Stop', exact: true }).click()
  await page.getByRole('button', { name: 'Clear', exact: true }).click()
  await expect(patternB).toContainText('Empty')
  await expect(patternB.locator('.has-notes')).toHaveCount(0)
  await expect(patternA).toContainText('1 hit · 0 notes')
  await patternA.click()
  await page.getByRole('tab', { name: /Drums/ }).click()
  await expect(kick).toHaveAttribute('aria-label', 'Kick step 1: medium')
})

test('The studio contains scrolling inside editors and aligns piano steps with their ruler', async ({
  page,
}) => {
  for (const width of [360, 375, 768, 1024, 1440, 1600]) {
    await page.setViewportSize({ width, height: 1100 })
    await page.goto('/')
    await page.getByRole('heading', { name: 'Beat Lab', exact: true }).waitFor()
    expect(
      await page.evaluate(() => document.documentElement.scrollWidth),
    ).toBeLessThanOrEqual(width)
    await page.getByRole('tab', { name: /Bass/ }).click()
    expect(
      await page.evaluate(() => document.documentElement.scrollWidth),
    ).toBeLessThanOrEqual(width)

    const viewport = page.getByRole('tabpanel')
    const cell = page.getByRole('gridcell', { name: 'C2 step 16', exact: true })
    await cell.click()
    await expect(cell).toHaveAttribute('aria-pressed', 'true')
    await expect(cell).toBeInViewport()
    const viewportBox = await viewport.boundingBox()
    expect(viewportBox).not.toBeNull()
    expect(viewportBox!.height).toBeLessThanOrEqual(480)

    const headerBox = await page
      .locator('.step-header .step-num')
      .last()
      .boundingBox()
    const cellBox = await cell.boundingBox()
    expect(headerBox).not.toBeNull()
    expect(cellBox).not.toBeNull()
    expect(Math.abs(headerBox!.x - cellBox!.x)).toBeLessThan(1)
    expect(Math.abs(headerBox!.width - cellBox!.width)).toBeLessThan(1)
  }
})
