Add-Type -AssemblyName System.Windows.Forms

[System.Windows.Forms.Application]::EnableVisualStyles()

$workspacePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$targetFilePath = Join-Path $workspacePath "kit-athletes.js"

function Get-NamesFromCsv {
  param(
    [string]$CsvPath
  )

  $rows = Import-Csv -LiteralPath $CsvPath
  if (-not $rows) {
    return @()
  }

  $firstColumnName = ($rows[0].PSObject.Properties | Select-Object -First 1).Name
  if (-not $firstColumnName) {
    return @()
  }

  $names = $rows |
    ForEach-Object { $_.$firstColumnName } |
    ForEach-Object { [string]$_ } |
    ForEach-Object { $_.Trim() } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    Sort-Object -Unique

  return @($names)
}

function Write-AthleteNamesFile {
  param(
    [string]$Path,
    [string[]]$Names
  )

  $lines = @(
    "window.KIT_ATHLETE_NAMES = ["
  )

  foreach ($name in $Names) {
    $escapedName = $name.Replace("\", "\\").Replace('"', '\"')
    $lines += "  ""$escapedName"","
  }

  $lines += "];"
  $content = ($lines -join "`r`n") + "`r`n"
  $utf8 = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($Path, $content, $utf8)
}

$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Title = "Selecione o CSV exportado do Excel"
$dialog.Filter = "Arquivo CSV (*.csv)|*.csv"
$dialog.InitialDirectory = $workspacePath

if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
  exit 0
}

try {
  $names = Get-NamesFromCsv -CsvPath $dialog.FileName

  if (-not $names.Count) {
    [System.Windows.Forms.MessageBox]::Show(
      "Nenhum nome foi encontrado no CSV. Verifique se a primeira coluna contém os nomes dos atletas.",
      "Importação de atletas"
    )
    exit 1
  }

  Write-AthleteNamesFile -Path $targetFilePath -Names $names

  [System.Windows.Forms.MessageBox]::Show(
    "Importação concluída com sucesso.`r`n`r`n$total = $($names.Count) atletas adicionados ao kit-athletes.js",
    "Importação de atletas"
  )
} catch {
  [System.Windows.Forms.MessageBox]::Show(
    "Não foi possível importar o arquivo.`r`n$($_.Exception.Message)",
    "Erro na importação"
  )
  exit 1
}
