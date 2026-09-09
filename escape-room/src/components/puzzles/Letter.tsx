import type { Stage } from '../../game'

interface Props {
  stage: Stage
}

/**
 * A long letter. The margin numerals beside book names give the shelf order.
 * The numerals are always present — the room simply doesn't tell you to look for them
 * until the sampler is decoded.
 */
export function Letter({ stage }: Props) {
  const numbered = stage >= 6
  return (
    <div className="letter-puzzle">
      <p className="puzzle-lead">
        {numbered
          ? 'Numbers the books. Read every page — the margins matter.'
          : 'Several close-written pages from a former tenant. Someone has scribbled in the margins.'}
      </p>
      <div className="letter-scroll" tabIndex={0} aria-label="Letter, scrollable">
        <article className="letter-paper">
          <p className="letter-date">Michaelmas, the year of the long rain</p>
          <p>My dear Ottoline,</p>
          <p>
            Forgive the length of this. I have been shut in the study for eleven days now with nothing but the
            books for company, and I find that once the pen is moving it does not like to stop. The lamp is
            behaving strangely again — it flickers when the wind is in the east — but I have grown fond of it.
          </p>
          <p>
            You asked after the shelf. I have rearranged it twice and settled on nothing. The volume on{' '}
            <Ref n="III" numbered={numbered}>
              Astronomy
            </Ref>{' '}
            is the one Father left; the plates are foxed but the star tables are still true. I read them at
            night when the corridor goes quiet.
          </p>
          <p>
            The house keeps its own counsel. Doors close when nobody is near them, and the rug in front of the
            hearth is forever tacked down as though someone feared it might wander. I do not ask.
          </p>
          <p>
            Of the others: the{' '}
            <Ref n="V" numbered={numbered}>
              Botany
            </Ref>{' '}
            is Mother's, pressed flowers and all, and ought really to go back to her. The{' '}
            <Ref n="I" numbered={numbered}>
              Cartography
            </Ref>{' '}
            I bought myself in the market at Leith — a sailor's atlas with half the coastlines wrong, which I
            think is why I love it.
          </p>
          <p>
            I have started stitching again. A sampler, of all things. I will not tell you what it says; you will
            have to come and read it, and you will need the little brass dial to do so, which I keep locked in the
            desk. Do not lose the key. I very nearly did — it went under the rug and I did not find it for a week.
          </p>
          <p>
            The winter is coming on early. There is frost on the inside of the panes by morning, and the ink
            freezes in the well if I leave the window open. I have taken to writing with lemon juice for the
            private things — it is invisible until you warm the page, and the housekeeper reads everything.
          </p>
          <p>
            I nearly forgot the last two. The{' '}
            <Ref n="IV" numbered={numbered}>
              Alchemy
            </Ref>{' '}
            is nonsense, but handsome nonsense, and the{' '}
            <Ref n="II" numbered={numbered}>
              Poetry
            </Ref>{' '}
            is the Wordsworth you gave me, which I will keep until I die and possibly after.
          </p>
          <p>
            Write soon. Tell me about the sea. Tell me anything that is not this room.
          </p>
          <p className="letter-sign">
            Ever yours,
            <br />
            H.
          </p>
          <p className="letter-ps">
            P.S. — If you should ever find yourself locked in here, remember: the shelf listens for the right
            order, and the order is in the margins.
          </p>
        </article>
      </div>
    </div>
  )
}

function Ref({ n, numbered, children }: { n: string; numbered: boolean; children: string }) {
  return (
    <span className={`book-ref ${numbered ? 'lit' : ''}`}>
      <span className="numeral" aria-label={`Roman numeral ${n}`}>
        {n}
      </span>
      {children}
    </span>
  )
}
