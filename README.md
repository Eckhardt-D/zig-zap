## Zig Zap ⚡

A very basic tool to list all the zig-out folders recursively in the current directory.

> [!NOTE]
> Most likely useless, built for fun and to learn more about Zig.

- Does not do anything with them
- No FS write operations performed
- ignores common big directories like .git, node_modules, target and any dotfolders

### Usage

```bash
git clone https://github.com/Eckhardt-D/zig-zap.git
```

```bash
cd zig-zap
```

```bash
zig build -Doptimize=ReleaseFast
```

Add it to your path

```bash
export PATH=$PATH:/path/to/zig-zap/zig-out/bin
```

Run it in any directory to find all zig-out folders recursively

```bash
zig-zap
```


