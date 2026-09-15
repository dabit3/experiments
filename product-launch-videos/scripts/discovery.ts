import {access, readdir, readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import type {TemplateManifest} from '../src/shared/contract';

export const projectRoot = fileURLToPath(new URL('../', import.meta.url));
export const slugPattern = /^(0[1-9]|1[0-9]|20)-[a-z0-9]+(?:-[a-z0-9]+)*$/;

export const parseManifest = (value: unknown, directory: string): TemplateManifest => {
  if (typeof value !== 'object' || value === null ||
    !('schemaVersion' in value) || value.schemaVersion !== 1 ||
    !('slug' in value) || typeof value.slug !== 'string' ||
    value.slug !== directory || !slugPattern.test(value.slug) ||
    !('name' in value) || typeof value.name !== 'string' || !value.name.trim() ||
    !('description' in value) || typeof value.description !== 'string' || !value.description.trim() ||
    !('compositionId' in value) || typeof value.compositionId !== 'string' ||
    !/^[A-Za-z0-9][A-Za-z0-9-]*$/.test(value.compositionId)) {
    throw new Error(`Invalid manifest for ${directory}; see TEMPLATE-CONTRACT.md`);
  }
  return {
    schemaVersion: 1, slug: value.slug, name: value.name,
    description: value.description, compositionId: value.compositionId,
  };
};

export type DiscoveredTemplate = TemplateManifest & {directory: string; entry: string};

export const discoverTemplates = async (): Promise<DiscoveredTemplate[]> => {
  const root = path.join(projectRoot, 'src/templates');
  const directories = await readdir(root, {withFileTypes: true}).catch(
    (error: NodeJS.ErrnoException) => {
      if (error.code === 'ENOENT') return [];
      throw error;
    },
  );
  const discovered: DiscoveredTemplate[] = [];
  for (const item of directories.sort((a, b) => a.name.localeCompare(b.name))) {
    if (!item.isDirectory()) continue;
    const directory = path.join(root, item.name);
    const manifest = parseManifest(
      JSON.parse(await readFile(path.join(directory, 'manifest.json'), 'utf8')),
      item.name,
    );
    for (const file of ['entry.tsx', 'index.ts', 'Template.tsx', 'config.ts', 'README.md', 'attribution.json']) {
      await access(path.join(directory, file));
    }
    if (discovered.some((other) => other.compositionId === manifest.compositionId)) {
      throw new Error(`Duplicate compositionId: ${manifest.compositionId}`);
    }
    discovered.push({...manifest, directory, entry: path.join(directory, 'entry.tsx')});
  }
  return discovered;
};
