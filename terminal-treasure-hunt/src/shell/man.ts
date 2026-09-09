export interface ManPage {
  name: string
  synopsis: string
  summary: string
  description: string[]
  examples: string[]
}

export const MAN_PAGES: Record<string, ManPage> = {
  ls: {
    name: 'ls',
    synopsis: 'ls [-a] [-l] [path...]',
    summary: 'list directory contents',
    description: [
      'Lists the entries of each given directory (the current directory by default).',
      '-a   do not ignore entries starting with a dot (hidden files).',
      '-l   long listing: mode, links, owner, group, size, modification time, name.',
      'Flags may be combined, e.g. `ls -la`.',
    ],
    examples: ['ls', 'ls -a', 'ls -la projects/vault'],
  },
  cd: {
    name: 'cd',
    synopsis: 'cd [dir]',
    summary: 'change the working directory',
    description: [
      'With no argument, changes to the home directory (~).',
      '`cd -` returns to the previous directory; `..` is the parent directory.',
    ],
    examples: ['cd projects', 'cd ~/var/log', 'cd ..', 'cd -'],
  },
  pwd: {
    name: 'pwd',
    synopsis: 'pwd',
    summary: 'print the working directory',
    description: ['Prints the absolute path of the current directory.'],
    examples: ['pwd'],
  },
  cat: {
    name: 'cat',
    synopsis: 'cat [file...]',
    summary: 'print file contents',
    description: ['Prints each file in order. With no file, prints standard input (useful in a pipeline).'],
    examples: ['cat README.txt', 'cat .hunt/note.txt', 'cat notes/*.md'],
  },
  grep: {
    name: 'grep',
    synopsis: 'grep [-r] [-i] [-n] [-v] pattern [path...]',
    summary: 'search text for a pattern',
    description: [
      'Prints lines matching PATTERN (a regular expression, or a literal string if the regex is invalid).',
      '-r   search directories recursively.',
      '-i   ignore case distinctions.',
      '-n   prefix each match with its line number.',
      '-v   print lines that do NOT match.',
      'With no path, grep filters standard input from a pipe.',
    ],
    examples: ['grep -ri vault var/log', 'grep -n ERROR var/log/app/server.log', 'cat README.txt | grep -i clue'],
  },
  find: {
    name: 'find',
    synopsis: "find [path] [-name pattern] [-type f|d]",
    summary: 'walk a directory tree',
    description: [
      'Prints every path under PATH (default: the current directory), including hidden ones.',
      "-name PATTERN  keep only entries whose name matches the glob (quote it: -name '*.log').",
      '-type f | d    keep only files or only directories.',
    ],
    examples: ["find . -name '*.log'", 'find ~ -type d', "find projects -name '.*'"],
  },
  echo: {
    name: 'echo',
    synopsis: 'echo [text...]',
    summary: 'print text',
    description: ['Prints its arguments separated by spaces. $HOME, $USER, $PWD and $FLAG_FORMAT are expanded.'],
    examples: ['echo hello', 'echo $HOME', 'echo aGVsbG8K | base64 -d'],
  },
  base64: {
    name: 'base64',
    synopsis: 'base64 [-d] [file]',
    summary: 'encode or decode base64',
    description: [
      'Encodes FILE (or standard input) as base64. With -d, decodes instead.',
      'Whitespace in the input is ignored when decoding.',
    ],
    examples: ['base64 -d projects/archive/deep/deeper/key.b64', 'echo treasure | base64'],
  },
  head: {
    name: 'head',
    synopsis: 'head [-n N] [file]',
    summary: 'print the first lines',
    description: ['Prints the first N lines (default 10) of FILE or standard input. `-5` is shorthand for `-n 5`.'],
    examples: ['head -n 3 var/log/syslog', 'head -5 README.txt'],
  },
  tail: {
    name: 'tail',
    synopsis: 'tail [-n N] [file]',
    summary: 'print the last lines',
    description: ['Prints the last N lines (default 10) of FILE or standard input.'],
    examples: ['tail -n 3 var/log/app/worker.log', 'tail -2 README.txt'],
  },
  wc: {
    name: 'wc',
    synopsis: 'wc [-l] [-w] [-c] [file...]',
    summary: 'count lines, words and bytes',
    description: ['Prints line, word and byte counts. With -l, -w or -c only that column is printed.'],
    examples: ['wc README.txt', 'wc -l var/log/app/worker.log', 'grep -r vault var/log | wc -l'],
  },
  tree: {
    name: 'tree',
    synopsis: 'tree [-a] [path]',
    summary: 'draw a directory tree',
    description: ['Draws the directory tree rooted at PATH. -a includes hidden entries.'],
    examples: ['tree', 'tree -a projects'],
  },
  history: {
    name: 'history',
    synopsis: 'history',
    summary: 'show command history',
    description: ['Prints every command entered in this session, numbered. Use the Up/Down arrows to recall them.'],
    examples: ['history'],
  },
  clear: {
    name: 'clear',
    synopsis: 'clear',
    summary: 'clear the screen',
    description: ['Clears the terminal. Ctrl+L does the same.'],
    examples: ['clear'],
  },
  help: {
    name: 'help',
    synopsis: 'help',
    summary: 'list available commands',
    description: ['Prints a one-line summary of every command. See `man <command>` for details.'],
    examples: ['help'],
  },
  man: {
    name: 'man',
    synopsis: 'man <command>',
    summary: 'show the manual page for a command',
    description: ['Prints the synopsis, description and examples for COMMAND.'],
    examples: ['man grep', 'man base64'],
  },
  submit: {
    name: 'submit',
    synopsis: 'submit FLAG{...}',
    summary: 'hand in the flag',
    description: [
      'Checks the flag you found. The real flag has the form FLAG{...}.',
      'A correct flag ends the hunt with fireworks; a wrong one costs nothing but pride.',
    ],
    examples: ['submit FLAG{example}'],
  },
  whoami: {
    name: 'whoami',
    synopsis: 'whoami',
    summary: 'print the current user',
    description: ['Prints the user name.'],
    examples: ['whoami'],
  },
  hostname: {
    name: 'hostname',
    synopsis: 'hostname',
    summary: 'print the host name',
    description: ['Prints the machine name.'],
    examples: ['hostname'],
  },
  date: {
    name: 'date',
    synopsis: 'date',
    summary: 'print the (frozen) date',
    description: ['Time stands still on this machine so the hunt is reproducible.'],
    examples: ['date'],
  },
}

export const COMMAND_NAMES = Object.keys(MAN_PAGES).sort()
