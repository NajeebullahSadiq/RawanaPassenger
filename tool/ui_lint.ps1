# Fails when screens bypass the Rawana design system.
# Usage (from the app root):  pwsh tool/ui_lint.ps1
# Add a file to $Allow only with a reason; prefer fixing the screen.
param([string]$Root = (Join-Path $PSScriptRoot '..'))

$ErrorActionPreference = 'Stop'

$Rules = @(
  @{ Pattern = 'TextStyle\(';                                    Why = 'use context.text.* (copyWith for tweaks)' },
  @{ Pattern = '\bAlertDialog\b|showDialog\(';                   Why = 'use RawanaActionSheet' },
  @{ Pattern = '\bSnackBar\(';                                   Why = 'use showRawanaToast / showRawanaError' },
  @{ Pattern = 'Color\(0x';                                      Why = 'use RawanaColors tokens' },
  @{ Pattern = 'LucideIcons\.(arrowLeft|arrowRight|chevronLeft|chevronRight)\b(?!Dir)'; Why = 'use RawanaIcons (mirrors in RTL)' },
  @{ Pattern = 'Icons\.arrow_back\b|Icons\.chevron_(left|right)\b'; Why = 'use RawanaIcons (mirrors in RTL)' }
)

# Relative paths (forward slashes) exempt from specific rules.
$Allow = @{
}

$screens = Join-Path $Root 'lib/screens'
$files = Get-ChildItem -Path $screens -Recurse -Filter *.dart
$violations = @()
foreach ($f in $files) {
  $rel = $f.FullName.Substring((Resolve-Path $Root).Path.Length + 1).Replace('\', '/')
  $lines = Get-Content -LiteralPath $f.FullName -Encoding UTF8
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match '^\s*//') { continue }
    foreach ($r in $Rules) {
      if ($line -match $r.Pattern) {
        if ($Allow.ContainsKey($rel) -and ($Allow[$rel] -contains $r.Pattern)) { continue }
        $violations += "{0}:{1}: {2}  ({3})" -f $rel, ($i + 1), $line.Trim(), $r.Why
      }
    }
  }
}

if ($violations.Count -gt 0) {
  $violations | ForEach-Object { Write-Output $_ }
  Write-Output ""
  Write-Output "ui_lint: $($violations.Count) violation(s)."
  exit 1
}
Write-Output "ui_lint: clean ($($files.Count) screen files)."
