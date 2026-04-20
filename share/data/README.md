# `share/data/`

This directory is the drop point for inputs the pipeline reads. Nothing
is shipped except `paper_reference/*.csv`.

```
share/data/
├── README.md           ← you are here
├── paper_reference/    ← SHIPPED — paper-asserted scalar values used by
│                          paper_parity.m (Table VI + Table VII). No
│                          measurements; just the printed numbers from
│                          main_final.tex so the parity checker can
│                          score your pipeline output vs the paper.
│
├── raw/                ← NOT shipped. Stage your raw PDPs here, one
│                          subfolder per measurement campaign:
│   ├── nyu_142/           142 GHz NYU PDP .mat files
│   ├── nyu_7/             6.75 GHz NYU PDP .mat files
│   ├── usc_145/           145 GHz USC PDPs (LoS/ + NLoS/ subdirs)
│   └── usc_7/             6.75 GHz USC PDPs (LOS Study/ + OLOS Study/)
│
└── point_data/         ← NOT shipped. Either stage hand-authored per-link
                          summary xlsx here, OR let run_all STEP 1
                          regenerate them from data/raw/.
```

See the repo's top-level `DATA_ORGANIZATION.md` for file naming, header
schema, and antenna-pattern contracts.
