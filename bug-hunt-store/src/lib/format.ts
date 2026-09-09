const currency = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' })

export function money(amount: number): string {
  return currency.format(amount)
}

export function plural(count: number, noun: string): string {
  return `${count} ${noun}${count === 1 ? '' : 's'}`
}
