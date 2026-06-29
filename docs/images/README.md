# Portfolio images

Generated timing diagrams and block diagram for README / client proposals.

## Regenerate

```bash
python docs/images/generate_assets.py
```

Requires: Python 3 + `cairosvg` + `pillow` (PNG export).

## Files

| File | Description |
|------|-------------|
| `apb_block_diagram.svg` / `.png` | RTL hierarchy |
| `wave_write.svg` / `.png` | APB3 write beat |
| `wave_read.svg` / `.png` | APB3 read beat |
| `wave_slverr.svg` / `.png` | Illegal access + PSLVERR |
| `wave_wait.svg` / `.png` | Multi-cycle PREADY wait |
| `gtkwave/*.png` | GTKWave-style wave captures |
| `generate_assets.py` | Regenerate all images |
