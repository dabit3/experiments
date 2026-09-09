import type { Airport } from '../types'

const a = (
  code: string,
  city: string,
  name: string,
  country: string,
  tz: string,
  lat: number,
  lon: number,
): Airport => ({ code, city, name, country, tz, lat, lon })

export const AIRPORTS: Airport[] = [
  a('SFO', 'San Francisco', 'San Francisco International', 'United States', 'America/Los_Angeles', 37.62, -122.38),
  a('LAX', 'Los Angeles', 'Los Angeles International', 'United States', 'America/Los_Angeles', 33.94, -118.41),
  a('SAN', 'San Diego', 'San Diego International', 'United States', 'America/Los_Angeles', 32.73, -117.19),
  a('SEA', 'Seattle', 'Seattle–Tacoma International', 'United States', 'America/Los_Angeles', 47.45, -122.31),
  a('PDX', 'Portland', 'Portland International', 'United States', 'America/Los_Angeles', 45.59, -122.6),
  a('LAS', 'Las Vegas', 'Harry Reid International', 'United States', 'America/Los_Angeles', 36.08, -115.15),
  a('PHX', 'Phoenix', 'Phoenix Sky Harbor International', 'United States', 'America/Phoenix', 33.43, -112.01),
  a('SLC', 'Salt Lake City', 'Salt Lake City International', 'United States', 'America/Denver', 40.79, -111.98),
  a('DEN', 'Denver', 'Denver International', 'United States', 'America/Denver', 39.86, -104.67),
  a('DFW', 'Dallas', 'Dallas/Fort Worth International', 'United States', 'America/Chicago', 32.9, -97.04),
  a('IAH', 'Houston', 'George Bush Intercontinental', 'United States', 'America/Chicago', 29.98, -95.34),
  a('AUS', 'Austin', 'Austin–Bergstrom International', 'United States', 'America/Chicago', 30.19, -97.67),
  a('ORD', 'Chicago', "Chicago O'Hare International", 'United States', 'America/Chicago', 41.98, -87.9),
  a('MSP', 'Minneapolis', 'Minneapolis–Saint Paul International', 'United States', 'America/Chicago', 44.88, -93.22),
  a('BNA', 'Nashville', 'Nashville International', 'United States', 'America/Chicago', 36.12, -86.68),
  a('DTW', 'Detroit', 'Detroit Metropolitan Wayne County', 'United States', 'America/Detroit', 42.21, -83.35),
  a('ATL', 'Atlanta', 'Hartsfield–Jackson Atlanta International', 'United States', 'America/New_York', 33.64, -84.43),
  a('CLT', 'Charlotte', 'Charlotte Douglas International', 'United States', 'America/New_York', 35.21, -80.94),
  a('MIA', 'Miami', 'Miami International', 'United States', 'America/New_York', 25.8, -80.29),
  a('MCO', 'Orlando', 'Orlando International', 'United States', 'America/New_York', 28.43, -81.31),
  a('JFK', 'New York', 'John F. Kennedy International', 'United States', 'America/New_York', 40.64, -73.78),
  a('EWR', 'Newark', 'Newark Liberty International', 'United States', 'America/New_York', 40.69, -74.17),
  a('LGA', 'New York', 'LaGuardia', 'United States', 'America/New_York', 40.78, -73.87),
  a('BOS', 'Boston', 'Boston Logan International', 'United States', 'America/New_York', 42.36, -71.01),
  a('PHL', 'Philadelphia', 'Philadelphia International', 'United States', 'America/New_York', 39.87, -75.24),
  a('IAD', 'Washington', 'Washington Dulles International', 'United States', 'America/New_York', 38.95, -77.46),
  a('DCA', 'Washington', 'Ronald Reagan Washington National', 'United States', 'America/New_York', 38.85, -77.04),
  a('HNL', 'Honolulu', 'Daniel K. Inouye International', 'United States', 'Pacific/Honolulu', 21.32, -157.92),
  a('YVR', 'Vancouver', 'Vancouver International', 'Canada', 'America/Vancouver', 49.19, -123.18),
  a('YYZ', 'Toronto', 'Toronto Pearson International', 'Canada', 'America/Toronto', 43.68, -79.63),
  a('MEX', 'Mexico City', 'Benito Juárez International', 'Mexico', 'America/Mexico_City', 19.44, -99.07),
  a('GRU', 'São Paulo', 'São Paulo/Guarulhos International', 'Brazil', 'America/Sao_Paulo', -23.43, -46.47),
  a('EZE', 'Buenos Aires', 'Ministro Pistarini International', 'Argentina', 'America/Argentina/Buenos_Aires', -34.82, -58.54),
  a('LHR', 'London', 'Heathrow', 'United Kingdom', 'Europe/London', 51.47, -0.46),
  a('LGW', 'London', 'Gatwick', 'United Kingdom', 'Europe/London', 51.15, -0.19),
  a('DUB', 'Dublin', 'Dublin Airport', 'Ireland', 'Europe/Dublin', 53.43, -6.27),
  a('CDG', 'Paris', 'Charles de Gaulle', 'France', 'Europe/Paris', 49.01, 2.55),
  a('AMS', 'Amsterdam', 'Amsterdam Schiphol', 'Netherlands', 'Europe/Amsterdam', 52.31, 4.76),
  a('FRA', 'Frankfurt', 'Frankfurt Airport', 'Germany', 'Europe/Berlin', 50.03, 8.57),
  a('MUC', 'Munich', 'Munich Airport', 'Germany', 'Europe/Berlin', 48.35, 11.79),
  a('ZRH', 'Zurich', 'Zurich Airport', 'Switzerland', 'Europe/Zurich', 47.46, 8.55),
  a('VIE', 'Vienna', 'Vienna International', 'Austria', 'Europe/Vienna', 48.11, 16.57),
  a('MAD', 'Madrid', 'Adolfo Suárez Madrid–Barajas', 'Spain', 'Europe/Madrid', 40.47, -3.56),
  a('BCN', 'Barcelona', 'Barcelona–El Prat', 'Spain', 'Europe/Madrid', 41.3, 2.08),
  a('LIS', 'Lisbon', 'Humberto Delgado Airport', 'Portugal', 'Europe/Lisbon', 38.77, -9.13),
  a('FCO', 'Rome', 'Leonardo da Vinci–Fiumicino', 'Italy', 'Europe/Rome', 41.8, 12.24),
  a('MXP', 'Milan', 'Milan Malpensa', 'Italy', 'Europe/Rome', 45.63, 8.72),
  a('CPH', 'Copenhagen', 'Copenhagen Airport', 'Denmark', 'Europe/Copenhagen', 55.62, 12.65),
  a('ARN', 'Stockholm', 'Stockholm Arlanda', 'Sweden', 'Europe/Stockholm', 59.65, 17.92),
  a('IST', 'Istanbul', 'Istanbul Airport', 'Türkiye', 'Europe/Istanbul', 41.26, 28.74),
  a('DXB', 'Dubai', 'Dubai International', 'United Arab Emirates', 'Asia/Dubai', 25.25, 55.36),
  a('DOH', 'Doha', 'Hamad International', 'Qatar', 'Asia/Qatar', 25.27, 51.61),
  a('DEL', 'New Delhi', 'Indira Gandhi International', 'India', 'Asia/Kolkata', 28.56, 77.1),
  a('SIN', 'Singapore', 'Singapore Changi', 'Singapore', 'Asia/Singapore', 1.36, 103.99),
  a('HKG', 'Hong Kong', 'Hong Kong International', 'Hong Kong', 'Asia/Hong_Kong', 22.31, 113.91),
  a('NRT', 'Tokyo', 'Narita International', 'Japan', 'Asia/Tokyo', 35.77, 140.39),
  a('HND', 'Tokyo', 'Haneda', 'Japan', 'Asia/Tokyo', 35.55, 139.78),
  a('ICN', 'Seoul', 'Incheon International', 'South Korea', 'Asia/Seoul', 37.46, 126.44),
  a('SYD', 'Sydney', 'Sydney Kingsford Smith', 'Australia', 'Australia/Sydney', -33.95, 151.18),
  a('AKL', 'Auckland', 'Auckland Airport', 'New Zealand', 'Pacific/Auckland', -37.01, 174.79),
]

export const AIRPORT_BY_CODE: Record<string, Airport> = Object.fromEntries(
  AIRPORTS.map((ap) => [ap.code, ap]),
)

export function searchAirports(query: string, exclude?: string | null): Airport[] {
  const q = query.trim().toLowerCase()
  if (!q) return []
  const scored = AIRPORTS.filter((ap) => ap.code !== exclude)
    .map((ap) => {
      let score = 0
      if (ap.code.toLowerCase() === q) score = 100
      else if (ap.code.toLowerCase().startsWith(q)) score = 80
      else if (ap.city.toLowerCase().startsWith(q)) score = 60
      else if (ap.city.toLowerCase().includes(q)) score = 40
      else if (ap.name.toLowerCase().includes(q)) score = 30
      else if (ap.country.toLowerCase().includes(q)) score = 10
      return { ap, score }
    })
    .filter((s) => s.score > 0)
    .sort((x, y) => y.score - x.score || x.ap.city.localeCompare(y.ap.city))
  return scored.slice(0, 8).map((s) => s.ap)
}

export const NATIONALITIES = [
  'United States',
  'United Kingdom',
  'Canada',
  'Australia',
  'Germany',
  'France',
  'Spain',
  'Italy',
  'Netherlands',
  'Ireland',
  'Japan',
  'South Korea',
  'Singapore',
  'India',
  'Brazil',
  'Mexico',
  'New Zealand',
  'Other',
]
