<#
MIT License

Copyright (c) 2026 Martin

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

# ============================================================
# FFmpeg Auto-Convert Pipeline (PowerShell)
# Converts AVI / MP4 / MKV into clean HEVC MKV files.
#
# Features:
# - Smart MKV analysis (skip if already HEVC)
# - MP3 → AAC upgrade
# - Preserve all high-quality audio (AAC, AC3, DTS, TrueHD, etc.)
# - AVI repair pipeline (MP3 fix + unpack B-frames)
# - Optional upscale for SD content (<720p)
# - No dependencies except ffmpeg.exe + ffprobe.exe
#
# IMPORTANT:
# Set $rootDir to the folder where:
# - Your video files are located
# - The "codecs" folder (with ffmpeg.exe and ffprobe.exe) exists
# - The "converted" folder will be created automatically
#
# Example:
#   C:\Media\Convert
#   D:\VideoTools\Convert
# ============================================================

# -------------------------
# CONFIGURATION
# -------------------------
$rootDir = "C:\Path\To\Your\ConvertFolder"   # <-- CHANGE THIS TO YOUR FOLDER

# Paths to FFmpeg binaries
$ffmpeg       = "$rootDir\codecs\ffmpeg.exe"
$ffprobe      = "$rootDir\codecs\ffprobe.exe"

# Output folder
$convertedDir = "$rootDir\converted"
$codecsDir    = "$rootDir\codecs"

# Ensure required folders exist
if (!(Test-Path $convertedDir)) { New-Item -ItemType Directory -Path $convertedDir | Out-Null }
if (!(Test-Path $codecsDir))    { New-Item -ItemType Directory -Path $codecsDir    | Out-Null }

# ============================================================
# PROCESS FILES
# ============================================================
Get-ChildItem -Path $rootDir -File | Where-Object { $_.Extension -in ".avi", ".mp4", ".mkv" } | ForEach-Object {

    $inputFile  = $_.FullName
    $baseName   = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    $outputFile = Join-Path $convertedDir ($baseName + ".mkv")

    Write-Host "FOUND: $inputFile"

    # Skip if output already exists
    if (Test-Path $outputFile) {
        Write-Host "SKIPPING: $outputFile already exists."
        return
    }

    # ============================================================
    # MKV SMART ANALYSIS
    # ============================================================
    if ($_.Extension -eq ".mkv") {

        Write-Host "MKV detected → analyzing streams..."

        $probeV = & $ffprobe -v error -show_streams -select_streams v:0 -of json "$inputFile" | ConvertFrom-Json
        $vcodec = $probeV.streams.codec_name

        $probeA = & $ffprobe -v error -show_streams -select_streams a:0 -of json "$inputFile" | ConvertFrom-Json
        $acodec = $probeA.streams.codec_name

        Write-Host "Video codec: $vcodec"
        Write-Host "Audio codec: $acodec"

        $convertVideo = $true
        $convertAudio = $false

        # Video decision logic
        if ($vcodec -eq "hevc") { $convertVideo = $false }
        if ($vcodec -eq "vp9" -or $vcodec -eq "av1") { $convertVideo = $false }
        if ($vcodec -eq "h264") { $convertVideo = $true }
        if ($vcodec -eq "mpeg4" -or $vcodec -eq "msmpeg4v3" -or $vcodec -eq "xvid") { $convertVideo = $true }

        # Audio decision logic
        if ($acodec -eq "mp3") { $convertAudio = $true }

        # Skip if nothing needs conversion
        if (-not $convertVideo -and -not $convertAudio) {
            Write-Host "MKV already optimal → SKIPPING"
            return
        }

        # Only audio needs fixing (MP3 → AAC)
        if (-not $convertVideo -and $convertAudio) {
            Write-Host "MKV HEVC + MP3 → fixing audio only..."

            $tempAudioFix = Join-Path $codecsDir ($baseName + "_audiofix.mkv")

            & $ffmpeg -y -i "$inputFile" -c:v copy -c:a aac -b:a 160k "$tempAudioFix"

            Move-Item $tempAudioFix $outputFile -Force
            Write-Host "DONE (audio fixed only): $outputFile"
            return
        }

        Write-Host "MKV requires full conversion → continuing..."
    }

    # ============================================================
    # DETECT VIDEO CODEC (AVI/MP4)
    # ============================================================
    Write-Host "DETECTING CODEC: $inputFile"

    $codec = & $ffprobe -v error -select_streams v:0 -show_entries stream=codec_name `
              -of csv=p=0 "$inputFile" 2>$null

    $codec = $codec.Trim()
    Write-Host "Detected codec: $codec"

    # ============================================================
    # AVI AUDIO REPAIR (MP3 header fix)
    # ============================================================
    if ($_.Extension -eq ".avi") {

        $repairedFile = Join-Path $codecsDir ($baseName + "_repaired.avi")

        Write-Host "AVI detected → repairing audio if needed..."

        if (Test-Path $repairedFile) { Remove-Item $repairedFile -Force }

        & $ffmpeg -hide_banner -loglevel warning -err_detect ignore_err -y `
            -i "$inputFile" `
            -c:v copy `
            -c:a mp3 -b:a 128k `
            "$repairedFile"

        if (Test-Path $repairedFile) {
            Write-Host "AUDIO REPAIR OK → using $repairedFile"
            $sourceFile = $repairedFile
        } else {
            Write-Host "AUDIO REPAIR FAILED → using original file" -ForegroundColor Yellow
            $sourceFile = $inputFile
        }

    } else {
        # MP4/MKV → no repair, never convert to AVI
        $sourceFile = $inputFile
    }

    # ============================================================
    # UNPACK B-FRAMES (only for MPEG4 AVI)
    # ============================================================
    if ($_.Extension -eq ".avi" -and $codec -eq "mpeg4") {

        $tempFile = Join-Path $codecsDir ($baseName + "_unpacked.avi")

        Write-Host "MPEG4 detected → unpacking packed B-frames..."

        if (Test-Path $tempFile) { Remove-Item $tempFile -Force }

        & $ffmpeg -hide_banner -loglevel warning -y `
            -i "$sourceFile" `
            -c:v copy -bsf:v mpeg4_unpack_bframes `
            -c:a copy `
            "$tempFile"

        if (Test-Path $tempFile) {
            Write-Host "UNPACK OK → using $tempFile"
            $sourceFile = $tempFile
        } else {
            Write-Host "UNPACK FAILED → using repaired file" -ForegroundColor Yellow
        }
    }

    # ============================================================
    # RESOLUTION DETECTION (ffprobe JSON)
    # ============================================================
    Write-Host "READING RESOLUTION: $sourceFile"

    $probeRes = & $ffprobe -v error -select_streams v:0 `
        -show_entries "stream=width,height" `
        -of json "$sourceFile" | ConvertFrom-Json

    $width  = $probeRes.streams.width
    $height = $probeRes.streams.height

    if (-not $width -or -not $height) {
        Write-Host "WARNING: Could not detect resolution, assuming SD"
        $width = 640
        $height = 480
    }

    Write-Host "Detected resolution: ${width}x${height}"

    # ============================================================
    # UPSCALE LOGIC (SD → 720p)
    # ============================================================
    $args = @()

    if ($height -lt 720) {
        Write-Host "UPSCALE: applying upscale"
        $args += "-vf"
        $args += "scale=1280:-1:flags=lanczos"
    } else {
        Write-Host "NO UPSCALE"
    }

    # ============================================================
    # FINAL CONVERSION (H.264 → HEVC)
    # ============================================================
    Write-Host "CONVERTING: $sourceFile -> $outputFile"

    # Audio policy:
    # - If MP3 → re-encode to AAC 160k
    # - Else → preserve original audio
    $probeAudio = & $ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$sourceFile"
    $audioCodec = $probeAudio.Trim()

    if ($audioCodec -eq "mp3") {
        $audioArgs = "-c:a aac -b:a 160k"
    } else {
        $audioArgs = "-c:a copy"
    }

    & $ffmpeg -y -i "$sourceFile" `
        -c:v hevc_nvenc `
        -preset p5 `
        -profile:v main10 `
        -rc constqp `
        -qp 20 `
        @args `
        $audioArgs `
        "$outputFile"

    Write-Host "DONE: $outputFile"

    # ============================================================
    # CLEANUP TEMP FILES
    # ============================================================
    if ($_.Extension -eq ".avi") {
        if (Test-Path $repairedFile) { Remove-Item $repairedFile -Force }
        if (Test-Path $tempFile)     { Remove-Item $tempFile -Force }
    }
}
