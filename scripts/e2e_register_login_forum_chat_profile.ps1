param(
  [string]$BaseUrl = "http://localhost:8080",
  [string]$Name = "E2E Tester",
  [string]$Password = "Pass123!",
  [string]$NewPassword = "Pass123!9",
  [string]$PeerFallbackUserId = "u2"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Host ""
  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Invoke-Api {
  param(
    [Parameter(Mandatory = $true)][string]$Method,
    [Parameter(Mandatory = $true)][string]$Path,
    [object]$Body = $null,
    [string]$Token = "",
    [int[]]$AllowedStatusCodes = @(200)
  )

  $uri = "$BaseUrl$Path"
  $headers = @{
    "Accept" = "application/json"
  }
  if (-not [string]::IsNullOrWhiteSpace($Token)) {
    $headers["Authorization"] = "Bearer $Token"
  }

  $curlHeaders = @()
  $payloadTemp = $null
  foreach ($key in $headers.Keys) {
    $curlHeaders += "-H"
    $curlHeaders += "${key}: $($headers[$key])"
  }

  $tempOut = Join-Path $env:TEMP ("e2e_out_" + [guid]::NewGuid().ToString("N") + ".txt")
  $tempErr = Join-Path $env:TEMP ("e2e_err_" + [guid]::NewGuid().ToString("N") + ".txt")

  $args = @("-sS", "-o", $tempOut, "-w", "%{http_code}", "-X", $Method)
  $args += $curlHeaders
  if ($null -ne $Body) {
    $payload = $Body | ConvertTo-Json -Depth 20 -Compress
    $payloadTemp = Join-Path $env:TEMP ("e2e_payload_" + [guid]::NewGuid().ToString("N") + ".json")
    Set-Content -Path $payloadTemp -Value $payload -Encoding UTF8
    $args += @("-H", "Content-Type: application/json", "--data-binary", "@$payloadTemp")
  }
  $args += $uri

  $rawStatus = & curl.exe @args 2> $tempErr
  $curlExitCode = $LASTEXITCODE

  $rawContent = ""
  if (Test-Path $tempOut) {
    $rawContent = Get-Content -Path $tempOut -Raw
  }
  $curlErr = ""
  if (Test-Path $tempErr) {
    $curlErr = Get-Content -Path $tempErr -Raw
  }
  Remove-Item -Path $tempOut -ErrorAction SilentlyContinue
  Remove-Item -Path $tempErr -ErrorAction SilentlyContinue
  if ($null -ne $payloadTemp) {
    Remove-Item -Path $payloadTemp -ErrorAction SilentlyContinue
  }

  if ($curlExitCode -ne 0) {
    throw "Request failed for ${Method} ${uri}: curl exit $curlExitCode. $curlErr"
  }

  $statusCode = 0
  [void][int]::TryParse(($rawStatus | Out-String).Trim(), [ref]$statusCode)
  if ($statusCode -le 0) {
    throw "Request failed for ${Method} ${uri}: invalid status code from curl: '$rawStatus'"
  }

  $json = $null

  if (-not [string]::IsNullOrWhiteSpace($rawContent)) {
    try {
      $json = $rawContent | ConvertFrom-Json
    }
    catch {
      $json = $null
    }
  }

  if ($AllowedStatusCodes -notcontains $statusCode) {
    throw "HTTP $statusCode for $Method $uri failed. Body: $rawContent"
  }

  return [PSCustomObject]@{
    StatusCode = $statusCode
    Json       = $json
    Content    = $rawContent
    Method     = $Method
    Uri        = $uri
  }
}

function Require-Value {
  param(
    [Parameter(Mandatory = $true)][object]$Value,
    [Parameter(Mandatory = $true)][string]$ErrorMessage
  )
  if ($null -eq $Value -or ([string]$Value).Trim() -eq "") {
    throw $ErrorMessage
  }
}

try {
  $timestamp = Get-Date -Format "yyyyMMddHHmmss"
  $email = "e2e_$timestamp@example.com"
  $postTitle = "E2E forum post $timestamp"
  $postContent = "This is an automated end-to-end post created at $timestamp."

  Write-Step "0) Health check"
  $health = $null
  for ($i = 1; $i -le 20; $i++) {
    try {
      $health = Invoke-Api -Method "GET" -Path "/health"
      break
    }
    catch {
      if ($i -eq 20) {
        throw
      }
      Start-Sleep -Seconds 1
    }
  }
  Write-Host "Health status: $($health.Json.status)"

  Write-Step "1) Register"
  $registerBody = @{
    name     = $Name
    email    = $email
    password = $Password
  }
  $register = Invoke-Api -Method "POST" -Path "/auth/register" -Body $registerBody
  Require-Value -Value $register.Json.user.id -ErrorMessage "Register did not return user.id"
  $userId = [string]$register.Json.user.id
  Write-Host "Registered userId: $userId"
  Write-Host "Registered email:  $email"

  Write-Step "2) Login"
  $loginBody = @{
    email    = $email
    password = $Password
  }
  $login = Invoke-Api -Method "POST" -Path "/auth/login" -Body $loginBody
  Require-Value -Value $login.Json.token -ErrorMessage "Login did not return token"
  $token = [string]$login.Json.token
  Write-Host "Login token acquired."

  Write-Step "3) Home data smoke (categories + profile)"
  $categories = Invoke-Api -Method "GET" -Path "/categories" -Token $token
  $profile = Invoke-Api -Method "GET" -Path "/profile" -Token $token
  Write-Host "Categories count: $($categories.Json.Count)"
  Write-Host "Profile user:      $($profile.Json.name) ($($profile.Json.id))"

  Write-Step "4) Community post create"
  $createPostBody = @{
    title   = $postTitle
    content = $postContent
    tag     = "General"
  }
  $createdPost = Invoke-Api -Method "POST" -Path "/forum-posts" -Body $createPostBody -Token $token
  Require-Value -Value $createdPost.Json.id -ErrorMessage "Create post did not return post id"
  $createdPostId = [string]$createdPost.Json.id
  Write-Host "Created postId: $createdPostId"

  Write-Step "5) Simulate avatar->chat flow (pick another forum author, create direct conversation)"
  $forumPosts = Invoke-Api -Method "GET" -Path "/forum-posts" -Token $token
  $peerPost = $forumPosts.Json | Where-Object {
    $_.authorId -and $_.authorId -ne $userId
  } | Select-Object -First 1

  $peerUserId = ""
  if ($null -ne $peerPost -and $null -ne $peerPost.authorId) {
    $peerUserId = [string]$peerPost.authorId
  }
  if ([string]::IsNullOrWhiteSpace($peerUserId)) {
    $peerUserId = $PeerFallbackUserId
  }
  if ($peerUserId -eq $userId) {
    throw "Peer user id equals current user id, cannot continue chat test."
  }
  Write-Host "Selected peerUserId: $peerUserId"

  $directBody = @{
    peerUserId = $peerUserId
  }
  $conversation = Invoke-Api -Method "POST" -Path "/chat/conversations/direct" -Body $directBody -Token $token
  Require-Value -Value $conversation.Json.conversationId -ErrorMessage "Direct conversation id missing"
  $conversationId = [string]$conversation.Json.conversationId
  Write-Host "conversationId: $conversationId"

  Write-Step "6) Send chat text + image"
  $sendTextBody = @{
    conversationId = $conversationId
    content        = "E2E text message at $timestamp"
  }
  $sentText = Invoke-Api -Method "POST" -Path "/chat/messages/text" -Body $sendTextBody -Token $token
  Require-Value -Value $sentText.Json.id -ErrorMessage "Text message send failed"
  Write-Host "Text message id: $($sentText.Json.id)"

  $smallPngDataUri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO6XnfsAAAAASUVORK5CYII="
  $sendImageBody = @{
    conversationId = $conversationId
    imageUrl       = $smallPngDataUri
  }
  $sentImage = Invoke-Api -Method "POST" -Path "/chat/messages/image" -Body $sendImageBody -Token $token
  Require-Value -Value $sentImage.Json.id -ErrorMessage "Image message send failed"
  Write-Host "Image message id: $($sentImage.Json.id)"

  $messages = Invoke-Api -Method "GET" -Path "/chat/messages?conversationId=$conversationId&limit=50" -Token $token
  Write-Host "Fetched messages: $($messages.Json.Count)"

  $markReadBody = @{
    conversationId = $conversationId
  }
  [void](Invoke-Api -Method "POST" -Path "/chat/conversations/read" -Body $markReadBody -Token $token)
  Write-Host "Conversation marked as read."

  Write-Step "7) Change password in profile"
  $changePasswordBody = @{
    currentPassword = $Password
    newPassword     = $NewPassword
  }
  [void](Invoke-Api -Method "POST" -Path "/profile/change-password" -Body $changePasswordBody -Token $token)
  Write-Host "Password changed."

  Write-Step "8) Verify old password fails and new password succeeds"
  $oldLogin = Invoke-Api -Method "POST" -Path "/auth/login" -Body @{
    email    = $email
    password = $Password
  } -AllowedStatusCodes @(400)
  Write-Host "Old password login status: $($oldLogin.StatusCode) (expected 400)"

  $newLogin = Invoke-Api -Method "POST" -Path "/auth/login" -Body @{
    email    = $email
    password = $NewPassword
  }
  Require-Value -Value $newLogin.Json.token -ErrorMessage "New password login failed"
  Write-Host "New password login succeeded."

  Write-Step "E2E PASSED"
  Write-Host "Summary:"
  Write-Host "  userId         = $userId"
  Write-Host "  email          = $email"
  Write-Host "  postId         = $createdPostId"
  Write-Host "  conversationId = $conversationId"
}
catch {
  Write-Host ""
  Write-Host "E2E FAILED" -ForegroundColor Red
  Write-Host $_.Exception.Message -ForegroundColor Red
  exit 1
}
