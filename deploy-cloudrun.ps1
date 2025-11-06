# Deploy BGE Reranker to Google Cloud Run
# Prerequisites: gcloud CLI installed and authenticated

param(
    [string]$ProjectId = "",
    [string]$Region = "us-central1",
    [string]$ServiceName = "bge-reranker"
)

if (-not $ProjectId) {
    Write-Host "ERROR: Please provide your Google Cloud project ID" -ForegroundColor Red
    Write-Host "Usage: .\deploy-cloudrun.ps1 -ProjectId 'your-project-id'" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n=== Deploying BGE Reranker to Google Cloud Run ===" -ForegroundColor Cyan
Write-Host "Project: $ProjectId" -ForegroundColor Gray
Write-Host "Region: $Region" -ForegroundColor Gray
Write-Host "Service: $ServiceName`n" -ForegroundColor Gray

# Step 1: Configure project
Write-Host "[1/4] Configuring gcloud project..." -ForegroundColor Yellow
gcloud config set project $ProjectId

# Step 2: Build and push to Google Container Registry
Write-Host "`n[2/4] Building and pushing Docker image to GCR..." -ForegroundColor Yellow
Write-Host "This will take 5-10 minutes..." -ForegroundColor Gray

$imageName = "gcr.io/$ProjectId/$ServiceName"

gcloud builds submit --tag $imageName

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Image built and pushed: $imageName" -ForegroundColor Green

# Step 3: Deploy to Cloud Run
Write-Host "`n[3/4] Deploying to Cloud Run..." -ForegroundColor Yellow

gcloud run deploy $ServiceName `
    --image $imageName `
    --platform managed `
    --region $Region `
    --memory 2Gi `
    --cpu 2 `
    --timeout 60s `
    --min-instances 0 `
    --max-instances 10 `
    --allow-unauthenticated `
    --port 8080

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Deployment failed!" -ForegroundColor Red
    exit 1
}

# Step 4: Get service URL
Write-Host "`n[4/4] Getting service URL..." -ForegroundColor Yellow
$serviceUrl = gcloud run services describe $ServiceName --region $Region --format "value(status.url)"

Write-Host "`n`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                  DEPLOYMENT SUCCESSFUL!                    ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`nService URL: $serviceUrl" -ForegroundColor Cyan
Write-Host "API Docs: $serviceUrl/docs" -ForegroundColor Cyan
Write-Host "Health Check: $serviceUrl/health" -ForegroundColor Cyan

Write-Host "`nTest the deployment:" -ForegroundColor Yellow
Write-Host @"
curl -X POST $serviceUrl/rerank \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is a panda?",
    "documents": [
      "The giant panda is a bear species endemic to China.",
      "Python is a programming language."
    ],
    "top_k": 1
  }'
"@ -ForegroundColor Gray

Write-Host "`nEstimated costs (with 2 vCPU, 2GB RAM):" -ForegroundColor Yellow
Write-Host "  - First 2 million requests/month: FREE" -ForegroundColor Green
Write-Host "  - After that: ~`$0.0001 per request" -ForegroundColor Gray
Write-Host "  - Idle time: `$0.00 (scale to zero)" -ForegroundColor Green

Write-Host "`nMonitoring:" -ForegroundColor Yellow
Write-Host "  gcloud run services logs tail $ServiceName --region $Region" -ForegroundColor Gray
