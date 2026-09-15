import {discoverTemplates} from './discovery';

console.log(JSON.stringify(await discoverTemplates(), null, 2));
