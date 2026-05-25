# offenders-mv

Download and process data from the Maldives child offenders public registry ([aamahi.pgo.mv](https://aamahi.pgo.mv/child-offenders)).

## How it works

1. **Seed data** — Capture the JSON response from the registry's network requests and save it as `data.json`.
2. **Download images** — `download.sh` reads `data.json`, downloads each offender's photo, and embeds verdict details and judgement dates as EXIF metadata.
3. **Render text** — `render.sh` prints a human-readable summary of all entries.

## Prerequisites

- [`jq`](https://jqlang.github.io/jq/)
- [`curl`](https://curl.se/)
- [`exiftool`](https://exiftool.org/)
- `base64` (coreutils)

## Usage

### 1. Seed the data

Visit [aamahi.pgo.mv/child-offenders](https://aamahi.pgo.mv/child-offenders), open DevTools → Network, find the API response with the offender list, and save it to `data.json`.

### 2. Download images

```bash
./download.sh
```

Images are saved to `./images/`, named by NID (or passport number if NID is unavailable). EXIF metadata is written to each image:
- `ImageDescription` — name, NID, and verdict details
- `DateTimeOriginal` — earliest judgement date

### 3. Render text summary

```bash
./render.sh
```

## File structure

```
.
├── data.json       # Raw JSON from the registry API
├── download.sh     # Downloads photos and writes EXIF metadata
├── render.sh       # Prints human-readable summary to stdout
├── images/         # Downloaded offender photos (141 entries)
└── HUMAN.md        # Quick reference for seeding data
```

## Data source

All data is sourced from the publicly accessible [Maldives Child Offenders Registry](https://aamahi.pgo.mv/child-offenders) operated by the Prosecutor General's Office of the Maldives.
