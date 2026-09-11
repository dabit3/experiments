import type { MenuItem, ModifierGroup } from '../types'

const temperature: ModifierGroup = {
  id: 'temp',
  name: 'Temperature',
  required: true,
  min: 1,
  max: 1,
  options: [
    { id: 'rare', name: 'Rare', delta: 0 },
    { id: 'mr', name: 'Medium rare', delta: 0 },
    { id: 'med', name: 'Medium', delta: 0 },
    { id: 'mw', name: 'Medium well', delta: 0 },
    { id: 'well', name: 'Well done', delta: 0 },
  ],
}

const side: ModifierGroup = {
  id: 'side',
  name: 'Side',
  required: true,
  min: 1,
  max: 1,
  options: [
    { id: 'fries', name: 'Hand-cut fries', delta: 0 },
    { id: 'mash', name: 'Garlic mash', delta: 0 },
    { id: 'salad', name: 'House salad', delta: 0 },
    { id: 'asparagus', name: 'Grilled asparagus', delta: 300 },
    { id: 'truffle', name: 'Truffle fries', delta: 400 },
  ],
}

const steakAddons: ModifierGroup = {
  id: 'steak-addons',
  name: 'Add-ons',
  required: false,
  min: 0,
  max: 3,
  options: [
    { id: 'peppercorn', name: 'Peppercorn sauce', delta: 300 },
    { id: 'bluecheese', name: 'Blue cheese crust', delta: 400 },
    { id: 'shrimp', name: 'Grilled shrimp (3)', delta: 900 },
  ],
}

const burgerAddons: ModifierGroup = {
  id: 'burger-addons',
  name: 'Add-ons',
  required: false,
  min: 0,
  max: 4,
  options: [
    { id: 'bacon', name: 'Smoked bacon', delta: 250 },
    { id: 'avocado', name: 'Avocado', delta: 200 },
    { id: 'egg', name: 'Fried egg', delta: 150 },
    { id: 'extra-patty', name: 'Extra patty', delta: 600 },
  ],
}

const allergies: ModifierGroup = {
  id: 'allergy',
  name: 'Allergies',
  required: false,
  min: 0,
  max: 5,
  options: [
    { id: 'nut', name: 'Nut allergy', delta: 0 },
    { id: 'gluten', name: 'Gluten-free', delta: 0 },
    { id: 'dairy', name: 'Dairy-free', delta: 0 },
    { id: 'shellfish', name: 'Shellfish allergy', delta: 0 },
    { id: 'egg-allergy', name: 'Egg allergy', delta: 0 },
  ],
}

const wingSauce: ModifierGroup = {
  id: 'sauce',
  name: 'Sauce',
  required: true,
  min: 1,
  max: 1,
  options: [
    { id: 'buffalo', name: 'Buffalo', delta: 0 },
    { id: 'bbq', name: 'Smoked BBQ', delta: 0 },
    { id: 'honey', name: 'Honey garlic', delta: 0 },
    { id: 'gochujang', name: 'Gochujang', delta: 100 },
  ],
}

const salmonPrep: ModifierGroup = {
  id: 'salmon-side',
  name: 'Side',
  required: false,
  min: 0,
  max: 1,
  options: [
    { id: 'rice', name: 'Jasmine rice', delta: 0 },
    { id: 'greens', name: 'Charred greens', delta: 0 },
    { id: 'asparagus', name: 'Grilled asparagus', delta: 300 },
  ],
}

const salad: ModifierGroup = {
  id: 'salad-protein',
  name: 'Add protein',
  required: false,
  min: 0,
  max: 1,
  options: [
    { id: 'chicken', name: 'Grilled chicken', delta: 600 },
    { id: 'shrimp', name: 'Shrimp', delta: 800 },
  ],
}

const wineSize: ModifierGroup = {
  id: 'pour',
  name: 'Pour',
  required: true,
  min: 1,
  max: 1,
  options: [
    { id: 'glass', name: 'Glass', delta: 0 },
    { id: 'bottle', name: 'Bottle', delta: 3400 },
  ],
}

const espressoStyle: ModifierGroup = {
  id: 'espresso',
  name: 'Style',
  required: false,
  min: 0,
  max: 1,
  options: [
    { id: 'single', name: 'Single', delta: 0 },
    { id: 'double', name: 'Double', delta: 150 },
    { id: 'decaf', name: 'Decaf', delta: 0 },
  ],
}

export const MENU: MenuItem[] = [
  // Starters
  {
    id: 'burrata',
    name: 'Burrata',
    description: 'Heirloom tomato, basil oil, grilled sourdough',
    price: 1400,
    category: 'Starters',
    defaultCourse: 1,
    modifierGroups: [allergies],
  },
  {
    id: 'calamari',
    name: 'Crispy Calamari',
    description: 'Lemon aioli, fresno chili',
    price: 1300,
    category: 'Starters',
    defaultCourse: 1,
    modifierGroups: [allergies],
  },
  {
    id: 'caesar',
    name: 'Caesar Salad',
    description: 'Little gem, parmesan crisp, anchovy',
    price: 1200,
    category: 'Starters',
    defaultCourse: 1,
    modifierGroups: [salad, allergies],
  },
  {
    id: 'onion-soup',
    name: 'French Onion Soup',
    description: 'Gruyère crouton',
    price: 1000,
    category: 'Starters',
    defaultCourse: 1,
    modifierGroups: [allergies],
  },
  {
    id: 'wings',
    name: 'Ember Wings',
    description: 'Half dozen, wood-fired',
    price: 1300,
    category: 'Starters',
    defaultCourse: 1,
    modifierGroups: [wingSauce, allergies],
  },
  // Mains
  {
    id: 'ribeye',
    name: 'Ribeye Steak',
    description: '14 oz prime, bone marrow butter',
    price: 4200,
    category: 'Mains',
    defaultCourse: 2,
    modifierGroups: [temperature, side, steakAddons, allergies],
  },
  {
    id: 'filet',
    name: 'Filet Mignon',
    description: '8 oz, red wine demi',
    price: 4800,
    category: 'Mains',
    defaultCourse: 2,
    modifierGroups: [temperature, side, steakAddons, allergies],
  },
  {
    id: 'burger',
    name: 'Ember Burger',
    description: 'Dry-aged blend, aged cheddar, brioche',
    price: 1800,
    category: 'Mains',
    defaultCourse: 2,
    modifierGroups: [temperature, side, burgerAddons, allergies],
  },
  {
    id: 'chicken',
    name: 'Roast Half Chicken',
    description: 'Lemon thyme jus',
    price: 2600,
    category: 'Mains',
    defaultCourse: 2,
    modifierGroups: [side, allergies],
  },
  {
    id: 'salmon',
    name: 'Cedar Plank Salmon',
    description: 'Miso glaze, pickled cucumber',
    price: 2900,
    category: 'Mains',
    defaultCourse: 2,
    modifierGroups: [salmonPrep, allergies],
  },
  {
    id: 'risotto',
    name: 'Mushroom Risotto',
    description: 'Porcini, parmesan, chive',
    price: 2200,
    category: 'Mains',
    defaultCourse: 2,
    modifierGroups: [allergies],
  },
  {
    id: 'pappardelle',
    name: 'Pappardelle Bolognese',
    description: 'Slow-braised beef and pork ragù',
    price: 2400,
    category: 'Mains',
    defaultCourse: 2,
    modifierGroups: [allergies],
  },
  // Sides
  {
    id: 'truffle-fries',
    name: 'Truffle Fries',
    description: 'Parmesan, herbs',
    price: 900,
    category: 'Sides',
    defaultCourse: 2,
    modifierGroups: [allergies],
  },
  {
    id: 'mac',
    name: 'Mac & Cheese',
    description: 'Three cheese, crispy top',
    price: 900,
    category: 'Sides',
    defaultCourse: 2,
    modifierGroups: [allergies],
  },
  {
    id: 'asparagus-side',
    name: 'Grilled Asparagus',
    description: 'Lemon, sea salt',
    price: 800,
    category: 'Sides',
    defaultCourse: 2,
    modifierGroups: [],
  },
  {
    id: 'spinach',
    name: 'Creamed Spinach',
    description: 'Nutmeg, cream',
    price: 800,
    category: 'Sides',
    defaultCourse: 2,
    modifierGroups: [allergies],
  },
  // Drinks
  {
    id: 'sparkling',
    name: 'Sparkling Water',
    description: '750 ml',
    price: 400,
    category: 'Drinks',
    defaultCourse: 1,
    modifierGroups: [],
  },
  {
    id: 'old-fashioned',
    name: 'Old Fashioned',
    description: 'Rye, demerara, orange',
    price: 1500,
    category: 'Drinks',
    defaultCourse: 1,
    modifierGroups: [],
  },
  {
    id: 'house-red',
    name: 'House Red',
    description: 'Sonoma Cabernet',
    price: 1200,
    category: 'Drinks',
    defaultCourse: 1,
    modifierGroups: [wineSize],
  },
  {
    id: 'ipa',
    name: 'Craft IPA',
    description: 'Local draft, 16 oz',
    price: 800,
    category: 'Drinks',
    defaultCourse: 1,
    modifierGroups: [],
  },
  {
    id: 'espresso',
    name: 'Espresso',
    description: 'Single origin',
    price: 400,
    category: 'Drinks',
    defaultCourse: 3,
    modifierGroups: [espressoStyle],
  },
  // Desserts
  {
    id: 'torte',
    name: 'Chocolate Torte',
    description: 'Flourless, raspberry',
    price: 1100,
    category: 'Desserts',
    defaultCourse: 3,
    modifierGroups: [allergies],
  },
  {
    id: 'brulee',
    name: 'Crème Brûlée',
    description: 'Vanilla bean',
    price: 1000,
    category: 'Desserts',
    defaultCourse: 3,
    modifierGroups: [allergies],
  },
  {
    id: 'cheesecake',
    name: 'NY Cheesecake',
    description: 'Graham crust, cherry',
    price: 1000,
    category: 'Desserts',
    defaultCourse: 3,
    modifierGroups: [allergies],
  },
]

export const MENU_BY_ID: Record<string, MenuItem> = Object.fromEntries(MENU.map((m) => [m.id, m]))

export function hasRequiredModifiers(item: MenuItem): boolean {
  return item.modifierGroups.some((g) => g.required)
}
