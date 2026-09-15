export interface LevelDef {
  id: number
  name: string
  /** Rows of the classic Sokoban text format: # wall, @ player, $ crate, . target, * crate on target, + player on target. */
  rows: string[]
  /** Minimum number of moves needed to solve the level (3-star threshold). */
  par: number
}

/*
 * Eight small warehouses ordered by difficulty. Level 1 is a warm-up; the rest
 * are classic layouts from David W. Skinner's freely distributable "Microban"
 * collection. `par` is the optimal move count found by
 * scripts/verify-levels.mjs (a breadth-first solver).
 */
export const LEVELS: LevelDef[] = [
  {
    id: 1,
    name: 'Loading Dock',
    rows: [
      '########',
      '#      #',
      '# @$ . #',
      '#      #',
      '# $  . #',
      '#      #',
      '########',
    ],
    par: 10,
  },
  {
    id: 2,
    name: 'Two-Bay',
    rows: [
      '######',
      '#    #',
      '# #@ #',
      '# $* #',
      '# .* #',
      '#    #',
      '######',
    ],
    par: 16,
  },
  {
    id: 3,
    name: 'Corner Store',
    rows: [
      '####  ',
      '# .#  ',
      '#  ###',
      '#*@  #',
      '#  $ #',
      '#  ###',
      '####  ',
    ],
    par: 33,
  },
  {
    id: 4,
    name: 'Long Haul',
    rows: [
      '########',
      '#      #',
      '# .**$@#',
      '#      #',
      '#####  #',
      '    ####',
    ],
    par: 23,
  },
  {
    id: 5,
    name: 'Conveyor',
    rows: [
      '  ####   ',
      '###  ####',
      '#     $ #',
      '# #  #$ #',
      '# . .#@ #',
      '#########',
    ],
    par: 41,
  },
  {
    id: 6,
    name: 'Cross-Dock',
    rows: [
      ' #######',
      ' #     #',
      ' # .$. #',
      '## $@$ #',
      '#  .$. #',
      '#      #',
      '########',
    ],
    par: 25,
  },
  {
    id: 7,
    name: 'Checkerboard',
    rows: [
      '#######',
      '#     #',
      '# .$. #',
      '# $.$ #',
      '# .$. #',
      '# $.$ #',
      '#  @  #',
      '#######',
    ],
    par: 26,
  },
  {
    id: 8,
    name: 'The Chute',
    rows: [
      '  ######',
      '  # ..@#',
      '  # $$ #',
      '  ## ###',
      '   # #  ',
      '   # #  ',
      '#### #  ',
      '#    ## ',
      '# #   # ',
      '#   # # ',
      '###   # ',
      '  ##### ',
    ],
    par: 97,
  },
]
