# Quick setup script for GitHub repository

Write-Host "`n=== Setting up GitHub Repository for BGE Reranker ===" -ForegroundColor Cyan

# Check if git is initialized
if (-not (Test-Path ".git")) {
    Write-Host "`n[1/6] Initializing Git repository..." -ForegroundColor Yellow
    git init
    git branch -M main
} else {
    Write-Host "`n[1/6] Git repository already initialized" -ForegroundColor Green
}

# Add all files
Write-Host "`n[2/6] Adding files to git..." -ForegroundColor Yellow
git add .

# Commit
Write-Host "`n[3/6] Creating initial commit..." -ForegroundColor Yellow
git commit -m "Initial commit: BGE Reranker v2-m3 with GitHub Actions CI/CD"

# Instructions for GitHub
Write-Host "`n[4/6] Next steps to push to GitHub:" -ForegroundColor Yellow
Write-Host @"

1. Create a new GitHub repository:
   → Go to: https://github.com/new
   → Repository name: bge-reranker
   → Description: Production-ready BGE Reranker v2-m3 API with auto-deployment
   → Public or Private (your choice)
   → Do NOT initialize with README

2. Link your local repo to GitHub:
   git remote add origin https://github.com/YOUR_USERNAME/bge-reranker.git

3. Push to GitHub:
   git push -u origin main

"@ -ForegroundColor Gray

Write-Host "[5/6] Configure GitHub Secrets for CI/CD:" -ForegroundColor Yellow
Write-Host @"

For Docker Hub deployment:
→ Go to: Settings → Secrets and variables → Actions → New repository secret
→ Add these secrets:
  - DOCKER_USERNAME: Your Docker Hub username
  - DOCKER_PASSWORD: Your Docker Hub password or access token

For Google Cloud Run deployment:
→ Add these secrets:
  - GCP_PROJECT_ID: Your Google Cloud project ID
  - GCP_SA_KEY: Service account JSON key (entire contents)

"@ -ForegroundColor Gray

Write-Host "[6/6] After pushing, GitHub Actions will:" -ForegroundColor Yellow
Write-Host @"

✓ Automatically build Docker image
✓ Run tests
✓ Push to Docker Hub (if secrets configured)
✓ Deploy to Cloud Run (if GCP secrets configured)
✓ Provide deployment summary in Actions tab

View progress at:
https://github.com/YOUR_USERNAME/bge-reranker/actions

"@ -ForegroundColor Gray

Write-Host "`n=== Setup Complete! ===" -ForegroundColor Green
Write-Host "Follow the steps above to push to GitHub and enable CI/CD" -ForegroundColor Cyan
