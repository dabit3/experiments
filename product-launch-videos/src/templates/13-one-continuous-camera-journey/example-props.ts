import {config} from './config';

const edited = structuredClone(config);
edited.durations.opening = 5;
edited.durations.environment = 6;
edited.durations.closing = 6;
edited.copy.environment = 'Choose your hosted Mac.';
edited.canvas.stops.agent.y = 80;

process.stdout.write(JSON.stringify({config: edited}, null, 2) + '\n');
