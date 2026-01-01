# 🎬 Video Convert HEVC (PowerShell)
A fast, dependency‑free PowerShell script that automatically converts mixed AVI / MP4 / MKV libraries into clean, modern HEVC MKV files — without installing anything.

This tool is ideal for:
- Cleaning old video collections
- Converting legacy AVI/XviD/DivX files
- Normalizing MP4/MKV libraries
- Preparing media for Plex, Jellyfin, Emby, Kodi, etc.
- GPU‑accelerated batch encoding using NVENC

The script uses **FFmpeg** for all video/audio processing and applies intelligent rules to avoid unnecessary re‑encoding.

---

## 🚀 Features

### 🎥 Video Handling
- Convert **H.264 → HEVC (H.265)** using NVENC
- Skip files already encoded in **HEVC**
- Skip **VP9** and **AV1** (already efficient)
- Repair old **AVI** files (MP3 header fix + unpack packed B‑frames)
- Optional upscale for SD content (<720p) using Lanczos

### 🔊 Audio Handling
- **Upgrade MP3 → AAC 160k**
- Preserve all high‑quality audio:
  - AAC (stereo / 5.1 / 7.1)
  - AC3 / E‑AC3
  - DTS / DTS‑HD
  - TrueHD / Atmos
  - FLAC
  - Opus
- Never downmix, never reduce channels, never reduce bitrate

### 🧠 Smart MKV Logic
- Skip MKV files that are already optimal
- Fix MKV files with HEVC video + MP3 audio (audio‑only repair)
- Convert MKV files with H.264 or MPEG4 video

### 🛡 Safe by Design
- Never overwrites input files
- Never moves or deletes your media
- Only cleans up its own temporary files
- No installation required

---

## 📁 Folder Structure

Your working directory should look like this:

Jasně, Martine — tady máš **čistý, správně zformátovaný Markdown blok**, přesně tak, jak má být v README.

Nic se nerozbije, žádné divné znaky, jen čistý GitHub‑ready code block.

---

# ✅ **Correct Markdown Folder Structure (copy‑paste ready)**

```markdown
convert-folder/
 ├─ video-convert-hevc.ps1
 ├─ codecs/
 │    ├─ ffmpeg.exe
 │    └─ ffprobe.exe
 ├─ converted/        (auto-created)
 └─ (your video files)
```

## 📥 Installation

### 1. Download FFmpeg (Official Build)

Download the latest **full** static build from:

👉 https://www.gyan.dev/ffmpeg/builds/

Under **Release builds**, download:

### **`ffmpeg-git-full.7z`**

This version includes:
- All codecs
- NVENC GPU encoding
- ffprobe
- No installation required

### 2. Extract FFmpeg

Extract the `.7z` file and copy:

```
ffmpeg.exe
ffplay.exe
ffprobe.exe
```

into:

```
convert-folder/codecs/
```

### 3. Set your working directory

Edit this line inside the script:

```powershell
$rootDir = "C:\Path\To\Your\ConvertFolder"
```

## ▶️ Usage

Open PowerShell in the folder and run:

```powershell
.\video-convert-hevc.ps1
```

Converted files will appear in:

```
convert-folder/converted/
```

---

## 🧠 How It Works

### Video Rules
| Codec | Action |
|-------|--------|
| HEVC | Skip |
| H.264 | Convert to HEVC |
| MPEG4 / XviD / DivX | Repair + Convert |
| VP9 / AV1 | Skip |

### Audio Rules
| Codec | Action |
|-------|--------|
| MP3 | Convert to AAC 160k |
| AAC | Keep |
| AC3 / E‑AC3 | Keep |
| DTS / DTS‑HD | Keep |
| TrueHD / Atmos | Keep |
| FLAC | Keep |
| Opus | Keep |

### Upscale Rules
- If height < 720 → upscale to 1280×(auto) using Lanczos
- Otherwise → keep original resolution

---

## 📝 License

This project is licensed under the **MIT License**.  
You are free to use, modify, and distribute it.

---

## 🙏 Acknowledgments

This project uses **FFmpeg**, a free and open‑source multimedia framework.

Huge thanks to the FFmpeg developers and contributors for their incredible work:

👉 https://ffmpeg.org

All actual video/audio processing is performed by FFmpeg —  
this script simply automates common workflows.

---

## ⭐ If you find this useful…

Feel free to star the repository or contribute improvements.  
Enjoy your clean, modern HEVC media library!
```
