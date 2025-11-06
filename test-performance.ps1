# Test script for BGE Reranker API
# Tests local Docker deployment performance

$API_URL = "http://localhost:8080"

Write-Host "`n=== BGE Reranker v2-m3 Performance Test ===" -ForegroundColor Cyan
Write-Host "Testing CPU performance locally...`n" -ForegroundColor Gray

# Test 1: Health Check
Write-Host "[1/5] Health Check" -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "$API_URL/health" -Method Get
    Write-Host "  Status: $($health.status)" -ForegroundColor Green
    Write-Host "  Device: $($health.device)" -ForegroundColor Gray
    Write-Host "  Threads: $($health.threads)" -ForegroundColor Gray
} catch {
    Write-Host "  ❌ Health check failed: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Single Pair Score
Write-Host "`n[2/5] Single Query-Document Scoring" -ForegroundColor Yellow
$body = @{
    query = "What is a panda?"
    document = "The giant panda (Ailuropoda melanoleuca), sometimes called a panda bear, is a bear species endemic to China."
    normalize = $true
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "$API_URL/score" -Method Post `
    -Body $body -ContentType "application/json"

Write-Host "  Score: $($response.score.ToString('F4'))" -ForegroundColor Green
Write-Host "  Time: $($response.processing_time_ms.ToString('F2'))ms" -ForegroundColor Gray

# Test 3: Small Batch (10 documents)
Write-Host "`n[3/5] Small Batch Reranking (10 documents)" -ForegroundColor Yellow
$documents = @(
    "The giant panda is a bear species endemic to China.",
    "Python is a high-level programming language.",
    "Pandas are black and white bears.",
    "Machine learning is a subset of artificial intelligence.",
    "Bamboo is the primary food source for pandas.",
    "Docker containers are lightweight virtualization.",
    "Red pandas are not closely related to giant pandas.",
    "Kubernetes orchestrates containerized applications.",
    "Pandas live in mountain ranges in central China.",
    "FastAPI is a modern Python web framework."
)

$body = @{
    query = "Tell me about pandas"
    documents = $documents
    top_k = 5
    normalize = $true
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "$API_URL/rerank" -Method Post `
    -Body $body -ContentType "application/json"

Write-Host "  Processing time: $($response.processing_time_ms.ToString('F2'))ms" -ForegroundColor Green
Write-Host "  Throughput: $([math]::Round(10 / ($response.processing_time_ms / 1000), 2)) docs/sec" -ForegroundColor Gray
Write-Host "`n  Top 3 Results:" -ForegroundColor Cyan
$response.results[0..2] | ForEach-Object {
    Write-Host "    [$($_.index)] Score: $($_.score.ToString('F4')) - $($_.document.Substring(0, [Math]::Min(60, $_.document.Length)))..." -ForegroundColor White
}

# Test 4: Medium Batch (100 documents)
Write-Host "`n[4/5] Medium Batch Reranking (100 documents)" -ForegroundColor Yellow
$largeDocs = @()
for ($i = 0; $i -lt 100; $i++) {
    if ($i % 10 -eq 0) {
        $largeDocs += "Pandas are fascinating animals that live in China. Document $i"
    } else {
        $largeDocs += "This is an unrelated document about technology, programming, or other topics. Document $i"
    }
}

$body = @{
    query = "What are pandas?"
    documents = $largeDocs
    top_k = 10
    normalize = $true
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "$API_URL/rerank" -Method Post `
    -Body $body -ContentType "application/json"

Write-Host "  Processing time: $($response.processing_time_ms.ToString('F2'))ms" -ForegroundColor Green
Write-Host "  Throughput: $([math]::Round(100 / ($response.processing_time_ms / 1000), 2)) docs/sec" -ForegroundColor Gray
Write-Host "  Top score: $($response.results[0].score.ToString('F4'))" -ForegroundColor Gray

# Test 5: Stress Test (multiple sequential requests)
Write-Host "`n[5/5] Stress Test (20 sequential requests)" -ForegroundColor Yellow
$times = @()
$testDocs = @(
    "Pandas eat bamboo and live in forests.",
    "Cloud computing enables scalable infrastructure.",
    "Pandas are endangered species."
)

for ($i = 1; $i -le 20; $i++) {
    $start = Get-Date
    
    $body = @{
        query = "panda information"
        documents = $testDocs
        top_k = 1
        normalize = $true
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$API_URL/rerank" -Method Post `
        -Body $body -ContentType "application/json" -ErrorAction Stop
    
    $end = Get-Date
    $duration = ($end - $start).TotalMilliseconds
    $times += $duration
    
    if ($i % 5 -eq 0) {
        Write-Host "  Request $i completed: $($duration.ToString('F2'))ms" -ForegroundColor Gray
    }
}

$avgTime = ($times | Measure-Object -Average).Average
$minTime = ($times | Measure-Object -Minimum).Minimum
$maxTime = ($times | Measure-Object -Maximum).Maximum

Write-Host "`n  Average: $($avgTime.ToString('F2'))ms" -ForegroundColor Green
Write-Host "  Min: $($minTime.ToString('F2'))ms" -ForegroundColor Gray
Write-Host "  Max: $($maxTime.ToString('F2'))ms" -ForegroundColor Gray
Write-Host "  Throughput: $([math]::Round(1000 / $avgTime, 2)) req/sec" -ForegroundColor Yellow

# Summary
Write-Host "`n`n=== PERFORMANCE SUMMARY ===" -ForegroundColor Cyan
Write-Host @"
Single pair:     ~$($response.processing_time_ms.ToString('F0'))ms
Small batch (10):  Target <100ms
Medium batch (100): Target <1000ms
Request throughput: $([math]::Round(1000 / $avgTime, 2)) req/sec

CPU Performance Assessment:
"@ -ForegroundColor White

if ($avgTime -lt 200) {
    Write-Host "✅ EXCELLENT - CPU is fast enough for production" -ForegroundColor Green
    Write-Host "   Recommendation: Deploy to Google Cloud Run" -ForegroundColor Green
    Write-Host "   Cost: ~`$0.0001 per request (much cheaper than GPU)" -ForegroundColor Green
} elseif ($avgTime -lt 500) {
    Write-Host "✅ GOOD - CPU is acceptable for most use cases" -ForegroundColor Yellow
    Write-Host "   Recommendation: Start with Google Cloud Run" -ForegroundColor Yellow
    Write-Host "   Can upgrade to GPU if needed" -ForegroundColor Yellow
} else {
    Write-Host "⚠️  SLOW - Consider GPU deployment" -ForegroundColor Red
    Write-Host "   Recommendation: Deploy to RunPod with GPU" -ForegroundColor Red
    Write-Host "   Expected GPU speedup: 5-10x faster" -ForegroundColor Red
}

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. If CPU is good: Deploy to Google Cloud Run" -ForegroundColor Gray
Write-Host "  2. If CPU is slow: Create GPU Dockerfile for RunPod" -ForegroundColor Gray
Write-Host "  3. Compare costs: Cloud Run (~`$0.0001/req) vs RunPod (~`$0.001/req)" -ForegroundColor Gray
