param(
  [string]$OutputPath = (Join-Path (Join-Path (Get-Location) 'docs') 'EcoSort_AI_Presentation_2026.pptx')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$repoRoot = (Get-Location).Path
$screensDir = Join-Path $repoRoot 'APP_screenshot'
$script:tempImageDir = Join-Path $env:TEMP ("ecosort_ppt_" + [guid]::NewGuid().ToString("N"))
$script:PhoneImageCache = @{}

if (-not (Test-Path $screensDir)) {
  throw "APP_screenshot directory not found: $screensDir"
}

$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path $outputDir)) {
  New-Item -Path $outputDir -ItemType Directory | Out-Null
}
if (-not (Test-Path $script:tempImageDir)) {
  New-Item -Path $script:tempImageDir -ItemType Directory | Out-Null
}

function Join-Lines([string[]]$lines) {
  return [string]::Join("`n", $lines)
}

function Rgb([int]$r, [int]$g, [int]$b) {
  return ($r + ($g * 256) + ($b * 65536))
}

$Colors = @{
  DeepGreen  = (Rgb 15 61 46)
  SeedGreen  = (Rgb 27 127 90)
  LeafGreen  = (Rgb 46 173 114)
  Sand       = (Rgb 246 241 231)
  Sky        = (Rgb 230 244 241)
  White      = (Rgb 255 255 255)
  TextDark   = (Rgb 29 45 38)
  TextMuted  = (Rgb 82 102 92)
  AccentBlue = (Rgb 217 235 255)
  AccentGold = (Rgb 236 180 52)
  AccentSoft = (Rgb 238 248 242)
  BorderSoft = (Rgb 201 220 210)
}

$SW = 960
$SH = 540

function New-Slide([object]$presentation) {
  return $presentation.Slides.Add($presentation.Slides.Count + 1, 12)
}

function Add-Background([object]$slide, [int]$rgb) {
  $shape = $slide.Shapes.AddShape(1, 0, 0, $script:SW, $script:SH)
  $shape.Fill.Visible = -1
  $shape.Fill.Solid()
  $shape.Fill.ForeColor.RGB = $rgb
  $shape.Line.Visible = 0
  return $shape
}

function Add-Text(
  [object]$slide,
  [double]$left,
  [double]$top,
  [double]$width,
  [double]$height,
  [string]$text,
  [double]$fontSize = 18,
  [bool]$bold = $false,
  [int]$rgb = 0,
  [int]$align = 1,
  [string]$fontName = 'Segoe UI'
) {
  $shape = $slide.Shapes.AddTextbox(1, $left, $top, $width, $height)
  $shape.TextFrame.WordWrap = -1
  $shape.TextFrame.AutoSize = 0
  $shape.TextFrame.TextRange.Text = $text
  $shape.TextFrame.TextRange.Font.Name = $fontName
  $shape.TextFrame.TextRange.Font.Size = $fontSize
  $shape.TextFrame.TextRange.Font.Bold = $(if ($bold) { -1 } else { 0 })
  $shape.TextFrame.TextRange.Font.Color.RGB = $rgb
  $shape.TextFrame.TextRange.ParagraphFormat.Alignment = $align
  return $shape
}

function Add-Card(
  [object]$slide,
  [double]$left,
  [double]$top,
  [double]$width,
  [double]$height,
  [int]$fill,
  [int]$line
) {
  $shape = $slide.Shapes.AddShape(5, $left, $top, $width, $height)
  $shape.Fill.Visible = -1
  $shape.Fill.Solid()
  $shape.Fill.ForeColor.RGB = $fill
  $shape.Line.Visible = -1
  $shape.Line.ForeColor.RGB = $line
  $shape.Line.Weight = 1.2
  return $shape
}

function Add-PictureFit(
  [object]$slide,
  [string]$path,
  [double]$left,
  [double]$top,
  [double]$width,
  [double]$height
) {
  $pic = $slide.Shapes.AddPicture($path, 0, -1, $left, $top, -1, -1)
  $pic.LockAspectRatio = -1
  $scale = [Math]::Min($width / $pic.Width, $height / $pic.Height)
  $pic.Width = $pic.Width * $scale
  $pic.Height = $pic.Height * $scale
  $pic.Left = $left + (($width - $pic.Width) / 2)
  $pic.Top = $top + (($height - $pic.Height) / 2)
  return $pic
}

function Add-Arrow([object]$slide, [double]$x1, [double]$y1, [double]$x2, [double]$y2, [int]$rgb) {
  $line = $slide.Shapes.AddLine($x1, $y1, $x2, $y2)
  $line.Line.ForeColor.RGB = $rgb
  $line.Line.Weight = 2.0
  $line.Line.EndArrowheadStyle = 3
  return $line
}

function Add-Header([object]$slide, [string]$title, [string]$subtitle) {
  Add-Background $slide $script:Colors.Sand | Out-Null
  $bar = $slide.Shapes.AddShape(1, 0, 0, $script:SW, 74)
  $bar.Fill.Visible = -1
  $bar.Fill.Solid()
  $bar.Fill.ForeColor.RGB = $script:Colors.DeepGreen
  $bar.Line.Visible = 0

  $accent = $slide.Shapes.AddShape(9, 770, -16, 250, 120)
  $accent.Fill.Visible = -1
  $accent.Fill.Solid()
  $accent.Fill.ForeColor.RGB = $script:Colors.LeafGreen
  $accent.Fill.Transparency = 0.35
  $accent.Line.Visible = 0

  Add-Text $slide 28 14 700 34 $title 26 $true $script:Colors.White 1 | Out-Null
  Add-Text $slide 30 46 760 20 $subtitle 12 $false $script:Colors.Sky 1 | Out-Null
}

function Get-PhoneViewportPath([string]$imageName) {
  $sourcePath = Join-Path $script:screensDir $imageName
  if (-not (Test-Path $sourcePath)) {
    return $sourcePath
  }

  if ($script:PhoneImageCache.ContainsKey($sourcePath)) {
    return $script:PhoneImageCache[$sourcePath]
  }

  $img = [System.Drawing.Image]::FromFile($sourcePath)
  try {
    $targetHeight = [int][Math]::Round($img.Width * 2.22)
    if ($img.Height -le $targetHeight) {
      $script:PhoneImageCache[$sourcePath] = $sourcePath
      return $sourcePath
    }

    $bmp = New-Object System.Drawing.Bitmap($img.Width, $targetHeight)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    try {
      $dest = New-Object System.Drawing.Rectangle(0, 0, $img.Width, $targetHeight)
      $src = New-Object System.Drawing.Rectangle(0, 0, $img.Width, $targetHeight)
      $g.DrawImage($img, $dest, $src, [System.Drawing.GraphicsUnit]::Pixel)
    }
    finally {
      $g.Dispose()
    }

    $outPath = Join-Path $script:tempImageDir (
      ([System.IO.Path]::GetFileNameWithoutExtension($imageName)) + '_viewport.png'
    )
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()

    $script:PhoneImageCache[$sourcePath] = $outPath
    return $outPath
  }
  finally {
    $img.Dispose()
  }
}

function Add-TallPhoneCard(
  [object]$slide,
  [double]$left,
  [double]$top,
  [double]$width,
  [double]$height,
  [string]$imageName,
  [string]$title,
  [string]$subtitle
) {
  Add-Card $slide $left $top $width $height $script:Colors.White $script:Colors.BorderSoft | Out-Null
  $imgPath = Get-PhoneViewportPath $imageName
  if (Test-Path $imgPath) {
    Add-PictureFit $slide $imgPath ($left + 10) ($top + 12) ($width - 20) ($height - 86) | Out-Null
  }
  Add-Text $slide ($left + 8) ($top + $height - 66) ($width - 16) 26 $title 11 $true $script:Colors.DeepGreen 2 | Out-Null
  Add-Text $slide ($left + 8) ($top + $height - 42) ($width - 16) 30 $subtitle 9.5 $false $script:Colors.TextMuted 2 | Out-Null
}

function Add-StoryboardStep([object]$slide, [double]$left, [double]$top, [double]$width, [double]$height, [string]$imageName, [string]$stepTitle, [string]$desc) {
  Add-Card $slide $left $top $width $height $script:Colors.White $script:Colors.BorderSoft | Out-Null
  $imgPath = Join-Path $script:screensDir $imageName
  if (Test-Path $imgPath) {
    Add-PictureFit $slide $imgPath ($left + 8) ($top + 8) 58 ($height - 16) | Out-Null
  }
  Add-Text $slide ($left + 72) ($top + 10) ($width - 80) 24 $stepTitle 11 $true $script:Colors.DeepGreen 1 | Out-Null
  Add-Text $slide ($left + 72) ($top + 34) ($width - 80) ($height - 42) $desc 10 $false $script:Colors.TextMuted 1 | Out-Null
}

function Add-WireframePhone([object]$slide, [double]$left, [double]$top, [string]$label) {
  $outer = $slide.Shapes.AddShape(5, $left, $top, 110, 180)
  $outer.Fill.Visible = -1
  $outer.Fill.Solid()
  $outer.Fill.ForeColor.RGB = $script:Colors.White
  $outer.Line.Visible = -1
  $outer.Line.ForeColor.RGB = $script:Colors.TextMuted
  $outer.Line.Weight = 1.4

  $header = $slide.Shapes.AddShape(1, $left + 8, $top + 8, 94, 20)
  $header.Fill.Visible = -1
  $header.Fill.Solid()
  $header.Fill.ForeColor.RGB = $script:Colors.Sky
  $header.Line.Visible = 0

  for ($i = 0; $i -lt 4; $i++) {
    $line = $slide.Shapes.AddShape(1, $left + 12, $top + 40 + (24 * $i), 86, 12)
    $line.Fill.Visible = -1
    $line.Fill.Solid()
    $line.Fill.ForeColor.RGB = $(if ($i -eq 1) { $script:Colors.AccentBlue } else { $script:Colors.AccentSoft })
    $line.Line.Visible = 0
  }

  Add-Text $slide $left ($top + 186) 110 24 $label 11 $true $script:Colors.TextDark 2 | Out-Null
}

$ppt = $null
$presentation = $null

try {
  $ppt = New-Object -ComObject PowerPoint.Application
  $ppt.Visible = -1
  $presentation = $ppt.Presentations.Add()
  $presentation.PageSetup.SlideWidth = $SW
  $presentation.PageSetup.SlideHeight = $SH

  # 1 Title
  $s1 = New-Slide $presentation
  $bg1 = Add-Background $s1 $Colors.DeepGreen
  $bg1.Fill.BackColor.RGB = $Colors.SeedGreen
  $bg1.Fill.TwoColorGradient(1, 1)
  $orb1 = $s1.Shapes.AddShape(9, 650, -30, 360, 260)
  $orb1.Fill.Visible = -1
  $orb1.Fill.Solid()
  $orb1.Fill.ForeColor.RGB = $Colors.LeafGreen
  $orb1.Fill.Transparency = 0.55
  $orb1.Line.Visible = 0
  $orb2 = $s1.Shapes.AddShape(9, -120, 360, 420, 240)
  $orb2.Fill.Visible = -1
  $orb2.Fill.Solid()
  $orb2.Fill.ForeColor.RGB = $Colors.AccentGold
  $orb2.Fill.Transparency = 0.78
  $orb2.Line.Visible = 0

  Add-Text $s1 60 110 840 120 'EcoSort AI' 58 $true $Colors.White 1 'Segoe UI Semibold' | Out-Null
  Add-Text $s1 60 185 840 80 'AI-Based Intelligent Waste Sorting and Identification App' 25 $false $Colors.Sky 1 | Out-Null
  Add-Text $s1 60 255 840 54 'Presentation for Innovation Project Showcase' 18 $false $Colors.White 1 | Out-Null
  Add-Text $s1 60 295 840 40 'Built with Flutter + Dart Shelf + MySQL + Cloud AI Vision' 15 $false $Colors.Sky 1 | Out-Null
  Add-Text $s1 60 472 840 28 'International Student Innovation Project | 2026' 12 $false $Colors.Sky 1 | Out-Null

  # 2 Roadmap
  $s2 = New-Slide $presentation
  Add-Header $s2 'Presentation Roadmap' 'How this project moves from data to impact'
  Add-Card $s2 28 92 440 392 $Colors.White $Colors.BorderSoft | Out-Null
  Add-Text $s2 48 112 390 32 'Project Vision' 22 $true $Colors.TextDark 1 | Out-Null
  Add-Text $s2 48 152 390 310 (Join-Lines @(
    '• Promote green and low-carbon living through daily digital actions.',
    '• Teach accurate waste sorting through practical guidance.',
    '• Build motivation via eco points, badges, and social participation.',
    '• Connect learning, behavior, and measurable environmental outcomes.'
  )) 16 $false $Colors.TextMuted 1 | Out-Null

  Add-Card $s2 490 92 442 392 $Colors.AccentSoft $Colors.BorderSoft | Out-Null
  Add-Text $s2 510 112 400 32 'What This Talk Covers' 22 $true $Colors.TextDark 1 | Out-Null
  Add-Text $s2 510 154 400 320 (Join-Lines @(
    '1. Data collection and data processing in the app.',
    '2. Storyboard and wireframe-based UX flow design.',
    '3. App development and interaction with external services.',
    '4. Detailed improvement plan if more time is available.'
  )) 17 $false $Colors.TextDark 1 | Out-Null

  # 3 Architecture
  $s3 = New-Slide $presentation
  Add-Header $s3 'System Architecture and Core Modules' 'Decoupled Flutter frontend + Dart backend via REST APIs'
  Add-Card $s3 34 102 260 312 $Colors.White $Colors.BorderSoft | Out-Null
  Add-Text $s3 50 120 220 28 'Flutter Mobile Client' 16 $true $Colors.TextDark 1 | Out-Null
  Add-Text $s3 52 154 230 248 (Join-Lines @(
    '• Home | Classify | Rewards',
    '• Forum | Messages | Profile',
    '',
    'Single API entry:',
    'frontend/lib/core/services/api_client.dart',
    '',
    'Local fallback:',
    'frontend/lib/core/state/mock_data.dart'
  )) 13 $false $Colors.TextMuted 1 | Out-Null

  Add-Card $s3 332 102 292 312 $Colors.AccentBlue $Colors.BorderSoft | Out-Null
  Add-Text $s3 348 120 260 28 'Backend API Layer (Shelf)' 16 $true $Colors.TextDark 1 | Out-Null
  Add-Text $s3 350 154 252 248 (Join-Lines @(
    '• Route handling and auth validation',
    '• Explicit JSON error responses',
    '• Classification and reward logic',
    '• Forum and chat APIs',
    '',
    'Key files:',
    'backend/lib/src/routes.dart',
    'backend/lib/src/services/waste_data_service.dart'
  )) 13 $false $Colors.TextDark 1 | Out-Null

  Add-Card $s3 660 102 266 312 $Colors.White $Colors.BorderSoft | Out-Null
  Add-Text $s3 676 120 230 28 'Data and AI Services' 16 $true $Colors.TextDark 1 | Out-Null
  Add-Text $s3 678 154 230 248 (Join-Lines @(
    '• MySQL persistent storage',
    '• Vision classification logs',
    '• Eco action records',
    '• Point transactions',
    '• Badge and profile history',
    '',
    'Optional cloud AI:',
    'Aliyun image recognition'
  )) 13 $false $Colors.TextMuted 1 | Out-Null

  Add-Arrow $s3 294 258 330 258 $Colors.SeedGreen | Out-Null
  Add-Arrow $s3 624 258 658 258 $Colors.SeedGreen | Out-Null
  Add-Text $s3 36 435 890 72 'Code refs: app_shell.dart | api_client.dart | server.dart | routes.dart' 11 $false $Colors.TextMuted 1 | Out-Null

  # 4 Data collection
  $s4 = New-Slide $presentation
  Add-Header $s4 'Data Collection: What the App Captures' 'From user input to auditable eco records'
  Add-Card $s4 34 98 434 176 $Colors.White $Colors.BorderSoft | Out-Null
  Add-Text $s4 50 116 390 24 'A. Classification Data' 15 $true $Colors.TextDark 1 | Out-Null
  Add-Text $s4 50 146 390 118 (Join-Lines @(
    '• Image bytes or item text submitted by user',
    '• Category prediction + confidence score',
    '• Mapped disposal category and bin tips',
    '• Logs persisted in vision_classification_logs'
  )) 12 $false $Colors.TextMuted 1 | Out-Null

  Add-Card $s4 490 98 434 176 $Colors.White $Colors.BorderSoft | Out-Null
  Add-Text $s4 506 116 390 24 'B. Eco Behavior Data' 15 $true $Colors.TextDark 1 | Out-Null
  Add-Text $s4 506 146 390 118 (Join-Lines @(
    '• Action type, quantity, optional note',
    '• CO2 reduction and awarded points per action',
    '• User point balance and total CO2 updates',
    '• Point transactions for reward history'
  )) 12 $false $Colors.TextMuted 1 | Out-Null

  Add-Card $s4 34 292 434 176 $Colors.AccentSoft $Colors.BorderSoft | Out-Null
  Add-Text $s4 50 310 390 24 'C. Community and Social Data' 15 $true $Colors.TextDark 1 | Out-Null
  Add-Text $s4 50 340 390 118 (Join-Lines @(
    '• Forum posts, comments, likes, and tags',
    '• Direct chat and message metadata',
    '• Read and unread states for engagement',
    '• Peer learning around sorting behavior'
  )) 12 $false $Colors.TextDark 1 | Out-Null

  Add-Card $s4 490 292 434 176 $Colors.AccentSoft $Colors.BorderSoft | Out-Null
  Add-Text $s4 506 310 390 24 'D. Profile and Progress Data' 15 $true $Colors.TextDark 1 | Out-Null
  Add-Text $s4 506 340 390 118 (Join-Lines @(
    '• Green score, recycled weight, badge history',
    '• Recognition history with confidence trace',
    '• User-level sustainability trajectory',
    '• Supports feedback loop and motivation'
  )) 12 $false $Colors.TextDark 1 | Out-Null

  # 5 Data processing pipeline
  $s5 = New-Slide $presentation
  Add-Header $s5 'Data Processing Pipeline (Code-Based)' 'How input becomes guidance, records, and rewards'
  $stepW = 172
  $x0 = 24
  $y0 = 118
  $gap = 16
  $steps = @(
    @{ Title='1. Capture'; Body='Flutter pages collect image/text input and eco action quantities.' },
    @{ Title='2. Validate'; Body='Routes decode JSON or base64, validate fields, and enforce auth.' },
    @{ Title='3. Infer'; Body='Rules or Aliyun vision generate category and confidence.' },
    @{ Title='4. Persist'; Body='MySQL stores logs, records, points, and profile updates.' },
    @{ Title='5. Return'; Body='UI displays bin advice, tips, score changes, and history.' }
  )

  for ($i = 0; $i -lt $steps.Count; $i++) {
    $x = $x0 + (($stepW + $gap) * $i)
    Add-Card $s5 $x $y0 $stepW 220 $Colors.White $Colors.BorderSoft | Out-Null
    Add-Text $s5 ($x + 12) ($y0 + 12) ($stepW - 24) 30 $steps[$i].Title 13 $true $Colors.DeepGreen 1 | Out-Null
    Add-Text $s5 ($x + 12) ($y0 + 46) ($stepW - 24) 158 $steps[$i].Body 11 $false $Colors.TextMuted 1 | Out-Null
    if ($i -lt ($steps.Count - 1)) {
      Add-Arrow $s5 ($x + $stepW) 228 ($x + $stepW + $gap - 3) 228 $Colors.SeedGreen | Out-Null
    }
  }

  Add-Card $s5 28 358 904 118 $Colors.AccentSoft $Colors.BorderSoft | Out-Null
  Add-Text $s5 44 372 870 24 'Key formula in eco evaluation service' 14 $true $Colors.TextDark 1 | Out-Null
  Add-Text $s5 44 398 870 60 'co2ReductionKg = quantity × co2KgPerUnit | pointsAwarded = round(quantity × pointsPerUnit)' 14 $false $Colors.TextDark 1 'Consolas' | Out-Null
  Add-Text $s5 44 428 870 38 'Implemented in mysql_waste_data_service.dart: evaluateEcoAction().' 11 $false $Colors.TextMuted 1 | Out-Null

  # 6 Classification logic
  $s6 = New-Slide $presentation
  Add-Header $s6 'Classification Logic and Confidence Strategy' 'Prototype rule engine with cloud-vision extension'
  Add-Card $s6 30 100 438 376 $Colors.White $Colors.BorderSoft | Out-Null
  Add-Text $s6 48 118 400 26 'Text Classification (Rule-Based)' 16 $true $Colors.TextDark 1 | Out-Null
  Add-Text $s6 48 150 390 292 (Join-Lines @(
    'Processing path:',
    '• normalize itemName to lowercase',
    '• match keywords to 4 categories',
    '• map to UK disposal naming and bin guidance',
    '• compute confidence with deterministic rules',
    '',
    'Confidence policy:',
    '• length < 3: 0.62',
    '• high-signal keywords: 0.94',
    '• default: 0.82',
    '',
    'Code: classify(), _matchCategory(), _confidenceFor()'
  )) 12 $false $Colors.TextMuted 1 | Out-Null

  Add-Card $s6 490 100 438 376 $Colors.AccentBlue $Colors.BorderSoft | Out-Null
  Add-Text $s6 508 118 400 26 'Image Classification (Aliyun Vision)' 16 $true $Colors.TextDark 1 | Out-Null
  Add-Text $s6 508 150 390 292 (Join-Lines @(
    'Processing path:',
    '• frontend sends base64 image to /classify-image',
    '• backend calls Aliyun image recognition API',
    '• pick best element by rubbishScore',
    '• map labels to recyclable/organic/hazardous/residual',
    '• persist raw response and mapped result in logs',
    '',
    'Fail-safe behavior:',
    '• explicit error if credentials are missing',
    '• logs retained for diagnostics and model tuning'
  )) 12 $false $Colors.TextDark 1 | Out-Null

  # 7 Storyboard (optimized for readability)
  $s7 = New-Slide $presentation
  Add-Header $s7 'Storyboard: User Experience Journey' 'Larger screenshots for clearer UX storytelling'
  Add-Text $s7 28 80 900 20 'Flow: Login -> Classify -> Rewards -> Forum -> Profile' 11 $false $Colors.TextMuted 1 | Out-Null

  Add-TallPhoneCard $s7 20 102 176 374 'login.jpg'    'Step 1: Login'    'Enter personal eco space'
  Add-TallPhoneCard $s7 206 102 176 374 'Classify.jpg' 'Step 2: Classify' 'Detect waste category'
  Add-TallPhoneCard $s7 392 102 176 374 'Rewards.jpg'  'Step 3: Rewards'  'Get points and badges'
  Add-TallPhoneCard $s7 578 102 176 374 'Forum.jpg'    'Step 4: Forum'    'Discuss green actions'
  Add-TallPhoneCard $s7 764 102 176 374 'Profile.jpg'  'Step 5: Profile'  'Track long-term growth'

  Add-Arrow $s7 196 288 204 288 $Colors.SeedGreen | Out-Null
  Add-Arrow $s7 382 288 390 288 $Colors.SeedGreen | Out-Null
  Add-Arrow $s7 568 288 576 288 $Colors.SeedGreen | Out-Null
  Add-Arrow $s7 754 288 762 288 $Colors.SeedGreen | Out-Null

  # 8 Wireframe + corresponding screenshots
  $s8 = New-Slide $presentation
  Add-Header $s8 'Wireframe Design and Real Screen Mapping' 'Low-fidelity UX plan matched with implemented app pages'

  Add-Card $s8 20 96 452 340 $Colors.White $Colors.BorderSoft | Out-Null
  Add-Card $s8 486 96 454 340 $Colors.White $Colors.BorderSoft | Out-Null
  Add-Text $s8 36 112 420 22 'Wireframe Flow (Prototype)' 13 $true $Colors.DeepGreen 1 | Out-Null
  Add-Text $s8 502 112 420 22 'Corresponding Implemented Screens' 13 $true $Colors.DeepGreen 1 | Out-Null

  Add-WireframePhone $s8 52 168 'Home'
  Add-WireframePhone $s8 192 168 'Classify'
  Add-WireframePhone $s8 332 168 'Rewards'
  Add-Arrow $s8 162 258 190 258 $Colors.SeedGreen | Out-Null
  Add-Arrow $s8 302 258 330 258 $Colors.SeedGreen | Out-Null

  Add-TallPhoneCard $s8 500 124 136 300 'Home.jpg' 'Home' 'Dashboard and quick entry'
  Add-TallPhoneCard $s8 646 124 136 300 'Classify.jpg' 'Classify' 'Image AI recognition'
  Add-TallPhoneCard $s8 792 124 136 300 'Rewards.jpg' 'Rewards' 'Points and CO2 records'

  Add-Arrow $s8 442 258 498 258 $Colors.SeedGreen | Out-Null
  Add-Arrow $s8 442 278 644 278 $Colors.SeedGreen | Out-Null
  Add-Arrow $s8 442 298 790 298 $Colors.SeedGreen | Out-Null

  Add-Card $s8 20 446 920 66 $Colors.AccentSoft $Colors.BorderSoft | Out-Null
  Add-Text $s8 36 464 886 34 'Design validation result: core wireframe decisions (navigation order, action density, and feedback placement) were retained in the shipped UI.' 11.5 $false $Colors.TextMuted 1 | Out-Null

  # 9 Development process
  $s9 = New-Slide $presentation
  Add-Header $s9 'Application Development Process' 'Feature-first implementation with API contracts'
  Add-Card $s9 34 98 274 370 $Colors.White $Colors.BorderSoft | Out-Null
  Add-Text $s9 50 118 236 28 'Phase 1: UI Modules' 15 $true $Colors.TextDark 1 | Out-Null
  Add-Text $s9 50 152 236 294 (Join-Lines @(
    '• Build six-tab shell',
    '• Implement feature pages',
    '• Keep module boundaries clear',
    '',
    'Files:',
    'frontend/lib/app/app_shell.dart',
    'frontend/lib/features/*'
  )) 12 $false $Colors.TextMuted 1 | Out-Null

  Add-Card $s9 326 98 274 370 $Colors.AccentSoft $Colors.BorderSoft | Out-Null
  Add-Text $s9 342 118 236 28 'Phase 2: API + Service' 15 $true $Colors.TextDark 1 | Out-Null
  Add-Text $s9 342 152 236 294 (Join-Lines @(
    '• Centralized ApiClient',
    '• REST routes in shelf router',
    '• Service abstraction layer',
    '• MySQL implementation',
    '',
    'Files:',
    'api_client.dart, routes.dart, services/*'
  )) 12 $false $Colors.TextDark 1 | Out-Null

  Add-Card $s9 618 98 308 370 $Colors.White $Colors.BorderSoft | Out-Null
  Add-Text $s9 634 118 270 28 'Phase 3: Integration + QA' 15 $true $Colors.TextDark 1 | Out-Null
  Add-Text $s9 634 152 270 294 (Join-Lines @(
    '• Auth + profile + history',
    '• Forum, comments, and direct chat',
    '• Eco dashboard and badge redemption',
    '• Local Android + backend run workflow',
    '• Route and service tests in backend/test',
    '',
    'Script: dev-android.ps1'
  )) 12 $false $Colors.TextMuted 1 | Out-Null

  # 10 External services
  $s10 = New-Slide $presentation
  Add-Header $s10 'External Services and System Interaction' 'Cloud, database, and weather services in one workflow'

  Add-Card $s10 36 104 248 142 $Colors.White $Colors.BorderSoft | Out-Null
  Add-Text $s10 52 132 214 56 'Flutter App' 20 $true $Colors.DeepGreen 2 | Out-Null
  Add-Card $s10 356 104 248 142 $Colors.AccentBlue $Colors.BorderSoft | Out-Null
  Add-Text $s10 372 132 214 56 'EcoSort Backend' 20 $true $Colors.DeepGreen 2 | Out-Null
  Add-Card $s10 676 64 248 112 $Colors.White $Colors.BorderSoft | Out-Null
  Add-Text $s10 692 98 214 40 'MySQL Database' 16 $true $Colors.TextDark 2 | Out-Null
  Add-Card $s10 676 194 248 112 $Colors.White $Colors.BorderSoft | Out-Null
  Add-Text $s10 692 226 214 40 'Aliyun Vision API' 16 $true $Colors.TextDark 2 | Out-Null
  Add-Card $s10 36 274 248 112 $Colors.White $Colors.BorderSoft | Out-Null
  Add-Text $s10 52 306 214 40 'AMap Weather API' 16 $true $Colors.TextDark 2 | Out-Null

  Add-Arrow $s10 284 176 354 176 $Colors.SeedGreen | Out-Null
  Add-Arrow $s10 604 120 674 120 $Colors.SeedGreen | Out-Null
  Add-Arrow $s10 604 250 674 250 $Colors.SeedGreen | Out-Null
  Add-Arrow $s10 160 272 160 246 $Colors.SeedGreen | Out-Null

  Add-Card $s10 36 404 888 72 $Colors.AccentSoft $Colors.BorderSoft | Out-Null
  Add-Text $s10 52 424 852 40 (Join-Lines @(
    'Config-driven integration: API_BASE_URL, DB_* variables, and ALIYUN_* credentials are managed through',
    'central configuration files and environment variables, not hardcoded in UI pages.'
  )) 12 $false $Colors.TextMuted 1 | Out-Null

  # 11 Gallery (optimized for readability)
  $s11 = New-Slide $presentation
  Add-Header $s11 'Feature Gallery: High-Visibility Screens' 'Bigger UI previews for live presentation'

  Add-TallPhoneCard $s11 20 92 300 392 'Classify.jpg' 'Classify Module' 'AI recognition and guidance'
  Add-TallPhoneCard $s11 330 92 300 392 'Rewards.jpg' 'Rewards Module' 'CO2 tracking and incentives'
  Add-TallPhoneCard $s11 640 92 300 392 'Profile.jpg' 'Profile Module' 'History and progress dashboard'

  # 12 Future improvements
  $s12 = New-Slide $presentation
  Add-Header $s12 'If Given More Time: Detailed Improvement Plan' 'From robust prototype to production-ready platform'
  Add-Card $s12 28 96 904 386 $Colors.White $Colors.BorderSoft | Out-Null

  Add-Text $s12 44 116 180 26 'Track' 13 $true $Colors.TextDark 1 | Out-Null
  Add-Text $s12 226 116 340 26 'Planned Upgrade' 13 $true $Colors.TextDark 1 | Out-Null
  Add-Text $s12 570 116 170 26 'Expected Impact' 13 $true $Colors.TextDark 1 | Out-Null
  Add-Text $s12 744 116 170 26 'Execution Focus' 13 $true $Colors.TextDark 1 | Out-Null

  $rows = @(
    @('AI & Data', 'Build labeled image dataset and add lightweight ML + active learning.', 'Higher precision and trust.', 'Benchmarking and calibration.'),
    @('UX & Accessibility', 'User tests, one-hand flow optimization, multilingual and accessibility refinement.', 'Faster completion and broader adoption.', 'A/B tests and accessibility audit.'),
    @('Engineering Quality', 'Expand automated tests, CI checks, and observability dashboards.', 'More stable releases.', 'Contract tests and telemetry standards.'),
    @('Ecosystem Integration', 'Connect recycling map, policy knowledge base, and campus challenge events.', 'More real-world behavior change.', 'Partner APIs and campaign analytics.')
  )

  $rowTop = 150
  for ($i = 0; $i -lt $rows.Count; $i++) {
    $y = $rowTop + ($i * 80)
    if ($i % 2 -eq 0) {
      $stripe = $s12.Shapes.AddShape(1, 36, $y - 4, 888, 72)
      $stripe.Fill.Visible = -1
      $stripe.Fill.Solid()
      $stripe.Fill.ForeColor.RGB = $Colors.AccentSoft
      $stripe.Line.Visible = 0
    }
    Add-Text $s12 44 $y 180 64 $rows[$i][0] 12 $true $Colors.DeepGreen 1 | Out-Null
    Add-Text $s12 226 $y 340 64 $rows[$i][1] 10.5 $false $Colors.TextMuted 1 | Out-Null
    Add-Text $s12 570 $y 170 64 $rows[$i][2] 10.5 $false $Colors.TextMuted 1 | Out-Null
    Add-Text $s12 744 $y 170 64 $rows[$i][3] 10.5 $false $Colors.TextMuted 1 | Out-Null
  }

  Add-Text $s12 44 472 860 20 'Target next milestone: pilot deployment with measurable behavior-change metrics over one academic term.' 11 $false $Colors.TextMuted 1 | Out-Null

  # 13 Closing
  $s13 = New-Slide $presentation
  $bg13 = Add-Background $s13 $Colors.DeepGreen
  $bg13.Fill.BackColor.RGB = $Colors.SeedGreen
  $bg13.Fill.TwoColorGradient(1, 1)
  Add-Text $s13 90 120 780 80 'Thank You' 54 $true $Colors.White 2 'Segoe UI Semibold' | Out-Null
  Add-Text $s13 120 220 720 120 'EcoSort AI shows how data, UX design, and community engagement can turn waste sorting into an actionable daily habit.' 20 $false $Colors.Sky 2 | Out-Null
  Add-Text $s13 130 360 700 36 'Q&A' 28 $true $Colors.White 2 | Out-Null
  Add-Text $s13 130 446 700 26 'AI-Based Intelligent Waste Sorting and Identification App' 12 $false $Colors.Sky 2 | Out-Null

  if (Test-Path $OutputPath) {
    Remove-Item $OutputPath -Force
  }

  $presentation.SaveAs($OutputPath)
  $presentation.Close()
  $ppt.Quit()

  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($presentation) | Out-Null
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($ppt) | Out-Null

  Write-Output "PPT generated: $OutputPath"
}
catch {
  if ($presentation -ne $null) {
    try { $presentation.Close() } catch {}
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($presentation) | Out-Null
  }
  if ($ppt -ne $null) {
    try { $ppt.Quit() } catch {}
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($ppt) | Out-Null
  }
  throw
}
finally {
  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
  if (Test-Path $script:tempImageDir) {
    Remove-Item $script:tempImageDir -Recurse -Force -ErrorAction SilentlyContinue
  }
}
