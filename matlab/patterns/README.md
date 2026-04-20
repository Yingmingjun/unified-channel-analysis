# `share/matlab/patterns/`

Drop point for antenna patterns consumed by the NYU 142 GHz pipeline.
**Not shipped** — stage your own.

## Expected files

| File | Consumer | Contract |
|---|---|---|
| `HPLANE Pattern Data 261D-27.DAT` | `processing/nyu_142/NYU142GHz_Method_Comparison.m` | NYU 261D-27 horn H-plane pattern in .DAT text format (angle, gain columns) |
| `EPLANE Pattern Data 261D-27.DAT` | same | Same horn E-plane pattern |

If your measurement campaign uses different antenna hardware, either
(a) drop equivalently-formatted files at the same filenames, or
(b) edit `paths().nyu_142_hplane_pattern` / `nyu_142_eplane_pattern`
to point at your pattern files.
