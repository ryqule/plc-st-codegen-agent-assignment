param(
    [string]$InputPath = (Join-Path $PSScriptRoot '..\report\实验报告.md'),
    [string]$DocxPath = (Join-Path $PSScriptRoot '..\report\实验报告.docx'),
    [string]$PdfPath = (Join-Path $PSScriptRoot '..\report\实验报告.pdf')
)
$ErrorActionPreference = 'Stop'

function Convert-Inline([string]$Text) {
    $value = [System.Net.WebUtility]::HtmlEncode($Text)
    $value = [regex]::Replace($value, '`([^`]+)`', '<code>$1</code>')
    $value = [regex]::Replace($value, '\*\*(.+?)\*\*', '<strong>$1</strong>')
    $value = [regex]::Replace($value, '&lt;(https?://[^&]+)&gt;', '<a href="$1">$1</a>')
    return $value
}

function Close-Blocks([System.Text.StringBuilder]$Html, [ref]$ListType, [ref]$InTable) {
    if ($ListType.Value) { [void]$Html.AppendLine("</$($ListType.Value)>"); $ListType.Value = $null }
    if ($InTable.Value) { [void]$Html.AppendLine('</tbody></table>'); $InTable.Value = $false }
}

function Add-Flow([System.Text.StringBuilder]$Html) {
    [void]$Html.AppendLine('<table class="flow"><tbody>')
    $nodes = @(
        '题库 JSON',
        '任务选择与需求上下文组装',
        '共享模型接口：Pi 单轮基线 / 自研 Agent harness',
        'ST 提取与保存 → 轻量静态预检',
        '编译器 adapter → 有真实编译诊断时有限修复',
        '保存代码、诊断、token、费用与实验结果'
    )
    foreach ($i in 0..($nodes.Count - 1)) {
        if ($i -lt $nodes.Count - 1) {
            [void]$Html.AppendLine("<tr><td class=""flow-node"">$(Convert-Inline $nodes[$i])<br/><span class=""flow-arrow"">↓</span></td></tr>")
        } else {
            [void]$Html.AppendLine("<tr><td class=""flow-node"">$(Convert-Inline $nodes[$i])</td></tr>")
        }
    }
    [void]$Html.AppendLine('</tbody></table>')
}

$inputFull = [IO.Path]::GetFullPath($InputPath)
$docxFull = [IO.Path]::GetFullPath($DocxPath)
$pdfFull = [IO.Path]::GetFullPath($PdfPath)
if (!(Test-Path -LiteralPath $inputFull)) { throw "Report source not found: $inputFull" }
New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($docxFull)) | Out-Null

$lines = [IO.File]::ReadAllLines($inputFull, [Text.Encoding]::UTF8)
$html = [System.Text.StringBuilder]::new()
[void]$html.AppendLine('<!DOCTYPE html><html><head><meta charset="utf-8"><title>PLC 结构化文本代码生成与验证实验报告</title>')
[void]$html.AppendLine('<style>')
[void]$html.AppendLine('@page { size: A4; margin: 20mm 19mm 19mm 19mm; }')
[void]$html.AppendLine('body { font-family: "Microsoft YaHei", "SimSun", sans-serif; font-size: 10.5pt; line-height: 1.32; color: #222222; }')
[void]$html.AppendLine('h1,h2,h3 { color: #000000; font-family: "Microsoft YaHei", sans-serif; page-break-after: avoid; }')
[void]$html.AppendLine('h1 { font-size: 16pt; margin: 19pt 0 8pt; } h2 { font-size: 13pt; margin: 13pt 0 5pt; } h3 { font-size: 11pt; margin: 10pt 0 4pt; }')
[void]$html.AppendLine('p { margin: 4pt 0 7pt; text-align: justify; } .title { font-size: 23pt; font-weight: bold; text-align: center; margin: 68pt 0 28pt; color:#000000; }')
[void]$html.AppendLine('table { border-collapse: collapse; width: 100%; margin: 7pt 0 11pt; table-layout: auto; } th,td { border: 0.6pt solid #D9D9D9; padding: 5pt 6pt; vertical-align: middle; } th { background: #23395D; color: #FFFFFF; font-weight: bold; text-align: center; }')
[void]$html.AppendLine('tr { page-break-inside: avoid; } .flow { width: 82%; margin: 5pt auto 8pt; page-break-inside: avoid; } .flow-node { border: 1pt solid #8FA3B8; background: #EFF4F8; text-align: center; font-weight: bold; font-size:9pt; padding: 2pt; } .flow-arrow { text-align:center; border:0; padding:0; color:#23395D; font-size:9pt; line-height:0.8; } .num { margin-left:18pt; text-indent:-18pt; }')
[void]$html.AppendLine('pre { white-space: pre-wrap; font-family: Consolas, monospace; font-size: 8.5pt; background:#F5F7FA; border:0.6pt solid #D9D9D9; padding:7pt; } code { font-family: Consolas, monospace; font-size:9pt; background:#F5F7FA; } a { color:#1F5E8C; text-decoration:underline; }')
[void]$html.AppendLine('</style></head><body>')

$listType = $null; $inTable = $false; $inCode = $false; $paragraph = [System.Collections.Generic.List[string]]::new(); $code = [System.Collections.Generic.List[string]]::new()
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match '^```') {
        Close-Blocks $html ([ref]$listType) ([ref]$inTable)
        if ($paragraph.Count) { [void]$html.AppendLine('<p>' + (Convert-Inline (($paragraph -join ' ').Trim())) + '</p>'); $paragraph.Clear() }
        if (!$inCode) { $inCode = $true; $code.Clear(); continue }
        $inCode = $false
        $codeText = $code -join "`n"
        if ($codeText.Contains('题库 JSON')) { Add-Flow $html }
        else { [void]$html.AppendLine('<pre>' + [System.Net.WebUtility]::HtmlEncode($codeText) + '</pre>') }
        continue
    }
    if ($inCode) { $code.Add($line); continue }
    if ([string]::IsNullOrWhiteSpace($line)) {
        Close-Blocks $html ([ref]$listType) ([ref]$inTable)
        if ($paragraph.Count) { [void]$html.AppendLine('<p>' + (Convert-Inline (($paragraph -join ' ').Trim())) + '</p>'); $paragraph.Clear() }
        continue
    }
    if ($line -match '^\|') {
        if ($paragraph.Count) { [void]$html.AppendLine('<p>' + (Convert-Inline (($paragraph -join ' ').Trim())) + '</p>'); $paragraph.Clear() }
        if ($listType) { [void]$html.AppendLine("</$listType>"); $listType = $null }
        if ($line -match '^\|\s*:?-{3,}') { continue }
        $cells = @($line.Trim().Trim('|').Split('|') | ForEach-Object { (Convert-Inline $_.Trim()) })
        if (!$inTable) {
            [void]$html.AppendLine('<table><thead><tr>')
            foreach ($cell in $cells) { [void]$html.AppendLine("<th>$cell</th>") }
            [void]$html.AppendLine('</tr></thead><tbody>'); $inTable = $true
        } else {
            [void]$html.AppendLine('<tr>')
            foreach ($cell in $cells) { [void]$html.AppendLine("<td>$cell</td>") }
            [void]$html.AppendLine('</tr>')
        }
        continue
    }
    if ($line -match '^\s*(\d+)\.\s+') {
        Close-Blocks $html ([ref]$listType) ([ref]$inTable)
        if ($paragraph.Count) { [void]$html.AppendLine('<p>' + (Convert-Inline (($paragraph -join ' ').Trim())) + '</p>'); $paragraph.Clear() }
        $number = $Matches[1]
        $item = Convert-Inline ($line -replace '^\s*\d+\.\s+','')
        [void]$html.AppendLine("<p class=""num"">$number. $item</p>")
        continue
    }
    Close-Blocks $html ([ref]$listType) ([ref]$inTable)
    if ($line -match '^#{1,3}\s+') {
        if ($paragraph.Count) { [void]$html.AppendLine('<p>' + (Convert-Inline (($paragraph -join ' ').Trim())) + '</p>'); $paragraph.Clear() }
        $level = ([regex]::Match($line,'^#+')).Value.Length
        $heading = Convert-Inline ($line -replace '^#{1,3}\s+','')
        if ($level -eq 1) { [void]$html.AppendLine("<h1>$heading</h1>") }
        elseif ($level -eq 2 -and $heading -eq '参考资料') { [void]$html.AppendLine("<h2 style=""page-break-before:always"">$heading</h2>") }
        elseif ($level -eq 2) { [void]$html.AppendLine("<h2>$heading</h2>") }
        else { [void]$html.AppendLine("<h3>$heading</h3>") }
        continue
    }
    if ($line -match '^\s*[-*]\s+') {
        if ($paragraph.Count) { [void]$html.AppendLine('<p>' + (Convert-Inline (($paragraph -join ' ').Trim())) + '</p>'); $paragraph.Clear() }
        if ($listType -ne 'ul') { Close-Blocks $html ([ref]$listType) ([ref]$inTable); [void]$html.AppendLine('<ul>'); $listType = 'ul' }
        [void]$html.AppendLine('<li>' + (Convert-Inline ($line -replace '^\s*[-*]\s+','')) + '</li>')
        continue
    }
    if ($line -match '^\s*\d+\.\s+') {
        if ($paragraph.Count) { [void]$html.AppendLine('<p>' + (Convert-Inline (($paragraph -join ' ').Trim())) + '</p>'); $paragraph.Clear() }
        if ($listType -ne 'ol') { Close-Blocks $html ([ref]$listType) ([ref]$inTable); [void]$html.AppendLine('<ol>'); $listType = 'ol' }
        [void]$html.AppendLine('<li>' + (Convert-Inline ($line -replace '^\s*\d+\.\s+','')) + '</li>')
        continue
    }
    $paragraph.Add($line.Trim())
}
Close-Blocks $html ([ref]$listType) ([ref]$inTable)
if ($paragraph.Count) { [void]$html.AppendLine('<p>' + (Convert-Inline (($paragraph -join ' ').Trim())) + '</p>') }
[void]$html.AppendLine('</body></html>')

$htmlPath = Join-Path ([IO.Path]::GetTempPath()) ('plc_st_report_' + [guid]::NewGuid().ToString('N') + '.html')
[IO.File]::WriteAllText($htmlPath, $html.ToString(), [Text.UTF8Encoding]::new($false))
$word = $null; $doc = $null
try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $doc = $word.Documents.Open($htmlPath, $false, $false, $false)
    $doc.PageSetup.PaperSize = 7
    $doc.PageSetup.TopMargin = 56.7; $doc.PageSetup.BottomMargin = 53.9
    $doc.PageSetup.LeftMargin = 53.9; $doc.PageSetup.RightMargin = 53.9
    if ($doc.Paragraphs.Count -gt 0) {
        $doc.Paragraphs.Item(1).Range.Style = -63
        $doc.Paragraphs.Item(1).Range.Font.Color = 0
    }
    $footer = $doc.Sections.Item(1).Footers.Item(1).Range
    $footer.Text = 'PLC ST Agent Report   |   '
    $footer.ParagraphFormat.Alignment = 1
    $footer.Collapse(0)
    [void]$doc.Fields.Add($footer, 33)
    foreach ($table in $doc.Tables) {
        $table.AllowAutoFit = $true
        $table.Rows.AllowBreakAcrossPages = $false
        $table.Borders.Enable = 1
        if ($table.Rows.Count -gt 0) {
            foreach ($cell in $table.Rows.Item(1).Cells) {
                $cell.Shading.BackgroundPatternColor = 6104355
                $cell.Range.Font.Color = 16777215
                $cell.Range.Font.Bold = $true
            }
            $headerText = ($table.Rows.Item(1).Range.Text -replace '[\r\a]', '').Trim()
            if ($headerText -match '题目|指标|作业要求|Agent 条件') { $table.Rows.Item(1).HeadingFormat = -1 }
        }
    }
    $doc.Fields.Update() | Out-Null
    $doc.SaveAs2($docxFull, 12)
    $doc.ExportAsFixedFormat($pdfFull, 17)
    $doc.Close(0)
    $word.Quit()
} finally {
    if ($doc -ne $null) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($doc) }
    if ($word -ne $null) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($word) }
    Remove-Item -LiteralPath $htmlPath -Force -ErrorAction SilentlyContinue
}
Write-Output "DOCX: $docxFull"
Write-Output "QA PDF: $pdfFull"

