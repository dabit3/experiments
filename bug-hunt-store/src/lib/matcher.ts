import bugs from '../data/bugs.json'
import type { BugDefinition } from '../types'

export const BUGS: BugDefinition[] = bugs

export type MatchResult =
  | { kind: 'found'; bug: BugDefinition }
  | { kind: 'already'; bug: BugDefinition }
  | { kind: 'none' }

function bugMatches(bug: BugDefinition, text: string): boolean {
  return bug.keywords.every((group) => group.some((term) => text.includes(term.toLowerCase())))
}

export function matchReport(area: string, description: string, found: string[]): MatchResult {
  const text = `${area} ${description}`.toLowerCase().replace(/\s+/g, ' ')
  const matches = BUGS.filter((bug) => bugMatches(bug, text))
  if (matches.length === 0) return { kind: 'none' }
  const fresh = matches.find((bug) => !found.includes(bug.id))
  if (fresh) return { kind: 'found', bug: fresh }
  return { kind: 'already', bug: matches[0] }
}
