# Makes the dev flavor's icon artwork from the production artwork:
#   - the near-black background (and the receipt's lines) become grey
#   - the logo is shrunk a little and a white "DEV" label is added below it
#
# Run from the project root (Windows PowerShell):
#   powershell -File tool/make_dev_icon.ps1
# Then generate the Android icons:
#   dart run flutter_launcher_icons
#
# Output: assets/branding/dev/icon.png and icon_foreground.png

Add-Type -AssemblyName System.Drawing

Add-Type -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class DevIcon {
  // Maps the old background brightness (0x0A) to the grey and keeps white as
  // white, so the anti-aliased edges stay smooth. Alpha is left alone.
  public static Bitmap Recolor(Bitmap src, int grey) {
    var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
    using (var g = Graphics.FromImage(bmp)) { g.DrawImage(src, 0, 0, src.Width, src.Height); }
    var rect = new Rectangle(0, 0, bmp.Width, bmp.Height);
    var data = bmp.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
    var bytes = new byte[data.Stride * data.Height];
    Marshal.Copy(data.Scan0, bytes, 0, bytes.Length);
    for (int i = 0; i < bytes.Length; i += 4) {
      for (int c = 0; c < 3; c++) {
        double v = (bytes[i + c] - 10) / 245.0;
        if (v < 0) v = 0;
        bytes[i + c] = (byte)Math.Round(grey + (255 - grey) * v);
      }
    }
    Marshal.Copy(bytes, 0, data.Scan0, bytes.Length);
    bmp.UnlockBits(data);
    return bmp;
  }
}
"@ -ReferencedAssemblies System.Drawing

$grey = 0x6B
$greyColor = [System.Drawing.Color]::FromArgb(255, $grey, $grey, $grey)
$size = 1024
$outDir = Join-Path $PSScriptRoot '..\assets\branding\dev'
New-Item -ItemType Directory -Force $outDir | Out-Null

$sourceForeground = [System.Drawing.Bitmap]::FromFile((Resolve-Path (Join-Path $PSScriptRoot '..\assets\branding\icon_foreground.png')))
$recolored = [DevIcon]::Recolor($sourceForeground, $grey)

function New-Foreground {
  $bmp = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.InterpolationMode = 'HighQualityBicubic'
  $g.TextRenderingHint = 'AntiAliasGridFit'

  # The logo, 80% size and nudged up to leave room for the label.
  $logo = [int]($size * 0.8)
  $g.DrawImage($recolored, [int](($size - $logo) / 2), 22, $logo, $logo)

  # White rounded label with grey text.
  $w = 380; $h = 150
  $x = [int](($size - $w) / 2); $y = 748
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $r = $h
  $path.AddArc($x, $y, $r, $r, 90, 180)
  $path.AddArc($x + $w - $r, $y, $r, $r, 270, 180)
  $path.CloseFigure()
  $g.FillPath([System.Drawing.Brushes]::White, $path)

  $font = New-Object System.Drawing.Font 'Arial', 104, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
  $format = New-Object System.Drawing.StringFormat
  $format.Alignment = 'Center'; $format.LineAlignment = 'Center'
  $brush = New-Object System.Drawing.SolidBrush $greyColor
  $g.DrawString('DEV', $font, $brush, (New-Object System.Drawing.RectangleF $x, ($y + 4), $w, $h), $format)
  $g.Dispose()
  return $bmp
}

$foreground = New-Foreground
$foreground.Save((Join-Path $outDir 'icon_foreground.png'), [System.Drawing.Imaging.ImageFormat]::Png)

# The full icon (older Android and iOS): grey square with the same artwork.
$icon = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($icon)
$g.Clear($greyColor)
$g.DrawImage($foreground, 0, 0, $size, $size)
$g.Dispose()
$icon.Save((Join-Path $outDir 'icon.png'), [System.Drawing.Imaging.ImageFormat]::Png)

$sourceForeground.Dispose(); $recolored.Dispose(); $foreground.Dispose(); $icon.Dispose()
Write-Host "Wrote $outDir"
