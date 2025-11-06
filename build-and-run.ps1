# Build and test the reranker locally with Docker

Write-Host "`n=== Building BGE Reranker Docker Image ===" -ForegroundColor Cyan
Write-Host "This will take a few minutes as it downloads the model (~600MB)`n" -ForegroundColor Gray

# Build the Docker image
Write-Host "Building Docker image..." -ForegroundColor Yellow
docker build -t bge-reranker:cpu .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Docker image built successfully`n" -ForegroundColor Green

# Stop any existing container
Write-Host "Stopping any existing containers..." -ForegroundColor Gray
docker stop bge-reranker-test 2>$null
docker rm bge-reranker-test 2>$null

# Run the container
Write-Host "`nStarting container..." -ForegroundColor Yellow
Write-Host "Container will be available at http://localhost:8080" -ForegroundColor Gray
docker run -d `
    --name bge-reranker-test `
    -p 8080:8080 `
    bge-reranker:cpu

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to start container!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Container started successfully" -ForegroundColor Green

# Wait for model to load
Write-Host "`nWaiting for model to load..." -ForegroundColor Yellow
$maxWait = 60
$waited = 0
$ready = $false

while ($waited -lt $maxWait -and -not $ready) {
    Start-Sleep -Seconds 2
    $waited += 2
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method Get -TimeoutSec 2
        if ($response.status -eq "ready") {
            $ready = $true
            Write-Host "✅ Model loaded and ready!" -ForegroundColor Green
        }
    } catch {
        Write-Host "  Waiting... ($waited/$maxWait seconds)" -ForegroundColor Gray
    }
}

if (-not $ready) {
    Write-Host "❌ Model failed to load within $maxWait seconds" -ForegroundColor Red
    Write-Host "`nContainer logs:" -ForegroundColor Yellow
    docker logs bge-reranker-test
    exit 1
}

# Show container logs
Write-Host "`nContainer logs:" -ForegroundColor Cyan
docker logs bge-reranker-test

Write-Host "`n`n=== Container is Running ===" -ForegroundColor Green
Write-Host "API URL: http://localhost:8080" -ForegroundColor Cyan
Write-Host "Docs: http://localhost:8080/docs" -ForegroundColor Cyan
Write-Host "`nRun performance tests with: .\test-performance.ps1" -ForegroundColor Yellow
Write-Host "`nTo stop the container: docker stop bge-reranker-test" -ForegroundColor Gray
Write-Host "To view logs: docker logs -f bge-reranker-test" -ForegroundColor Gray
