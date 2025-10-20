# cradle – BASH Utilities

## What’s inside

- **japg.sh** – generate a capitalised, delimiter-separated passphrase with one random digit appended to a word  
- **jascp.sh** – bidirectional SCP helper: download-only (`-d`), upload-only (`-u`), or download-edit
- **jau.sh** – DNF and flatpak updater  
- **install.sh** – installer that drops the tools into `/usr/local/bin` and `/usr/share/dict`
- **dict/japg.list** – word list used by **japg.sh**

## Quick start

```bash
git clone https://github.com/emptyproduce/cradle.git
./cradle/install.sh 
```

## Usage

### japg.sh
```
japg.sh [NUM_WORDS] [DELIMITER]     # default: 3 words, delimiter “-”
```

### jascp.sh
```
jascp.sh          # download → edit (default codium)
jascp.sh -d       # download only
jascp.sh -u       # upload only
```

### jau.sh
```
jau.sh
```

## Requirements

- `bash`, `scp`, `ssh`, `xclip`, `shuf`, `paste`, `tr`  
- Root privileges only for **install.sh** and **jau.sh** when system updates occur

## License

GNU Affero General Public License v3.0 – see LICENSE file.
