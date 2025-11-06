# GitHub Actions CI/CD Setup Summary

## ✅ What's Ready

Your BGE Reranker project is now configured with:

### 📁 Files Created
- ✅ `.github/workflows/docker-build.yml` - Auto-build to Docker Hub
- ✅ `.github/workflows/google-cloud-build.yml` - Auto-deploy to Cloud Run
- ✅ `Dockerfile` - CPU-optimized container
- ✅ `app.py` - FastAPI server
- ✅ `requirements.txt` - Python dependencies
- ✅ `.gitignore` - Git ignore rules
- ✅ `DEPLOYMENT.md` - Complete deployment guide
- ✅ Git repository initialized with initial commit

## 🚀 Quick Start Guide

### Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `bge-reranker`
3. Description: `Production-ready BGE Reranker v2-m3 API with auto-deployment`
4. Choose Public or Private
5. **Do NOT** check "Initialize with README"
6. Click "Create repository"

### Step 2: Push to GitHub

```bash
cd c:\my1\huggingface\bge-reranker
git remote add origin https://github.com/YOUR_USERNAME/bge-reranker.git
git push -u origin main
```

### Step 3: Configure Secrets (Choose Your Path)

#### Option A: Docker Hub Only (Simpler, Free)

**Create Docker Hub account:**
- Go to https://hub.docker.com/signup
- Create account (free)
- Create access token: Account Settings → Security → New Access Token

**Add GitHub Secrets:**
1. Go to your repo: `Settings` → `Secrets and variables` → `Actions`
2. Click `New repository secret`
3. Add:
   - Name: `DOCKER_USERNAME` | Value: `your-dockerhub-username`
   - Name: `DOCKER_PASSWORD` | Value: `your-access-token`

**Result:**
- ✅ Push to main → Auto-builds Docker image
- ✅ Published to Docker Hub as `your-username/bge-reranker:latest`
- ✅ You can `docker pull` from anywhere

**Deploy to Cloud Run manually:**
```bash
# Pull from Docker Hub and deploy
gcloud run deploy bge-reranker \
  --image docker.io/YOUR_USERNAME/bge-reranker:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

#### Option B: Full Auto-Deploy to Cloud Run (Production)

**Create GCP Service Account:**
```bash
# 1. Set project
gcloud config set project YOUR_PROJECT_ID

# 2. Enable APIs
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# 3. Create service account
gcloud iam service-accounts create github-actions \
  --display-name "GitHub Actions CI/CD"

# 4. Grant permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# 5. Create key
gcloud iam service-accounts keys create key.json \
  --iam-account=github-actions@YOUR_PROJECT_ID.iam.gserviceaccount.com

# 6. Copy key contents (you'll paste this into GitHub)
cat key.json
```

**Add GitHub Secrets:**
1. Name: `GCP_PROJECT_ID` | Value: `your-gcp-project-id`
2. Name: `GCP_SA_KEY` | Value: Entire contents of `key.json` file

**Result:**
- ✅ Push to main → Auto-builds → Auto-deploys to Cloud Run
- ✅ Live URL returned in GitHub Actions summary
- ✅ Zero manual steps!

#### Option C: Both! (Recommended)

Use both workflows:
- Docker Hub for sharing/development
- GCR + Cloud Run for production
- Just configure both sets of secrets

## 🔄 How It Works

### Docker Hub Workflow

```mermaid
Push to main
    ↓
GitHub Actions triggered
    ↓
Build Docker image (5-10 min)
    ↓
Push to Docker Hub
    ↓
Available: docker.io/YOUR_USERNAME/bge-reranker:latest
```

### Cloud Run Workflow

```mermaid
Push to main
    ↓
GitHub Actions triggered
    ↓
Build Docker image (5-10 min)
    ↓
Push to Google Container Registry
    ↓
Deploy to Cloud Run
    ↓
Test health endpoint
    ↓
Live at: https://bge-reranker-xxx.run.app
```

## 📊 Expected Results

### First Push (After Configuring Secrets)

1. **GitHub Actions tab** will show:
   - 🟡 "Build and Push Docker Image" running
   - Progress: Checkout → Build → Push → Success ✅

2. **Duration:** ~5-10 minutes
   - Building takes time (downloads model)
   - Subsequent builds are cached, faster

3. **Output:**
   - Docker Hub: Image at `YOUR_USERNAME/bge-reranker:latest`
   - Cloud Run: Live URL in Actions summary

### Subsequent Pushes

- **Faster:** ~3-5 minutes (uses cache)
- **Automatic:** Just push to main branch
- **Smart:** Only rebuilds if app files changed

## 🧪 Test Your Deployment

### Test Docker Hub Image

```bash
# Pull and run
docker pull YOUR_USERNAME/bge-reranker:latest
docker run -p 8080:8080 YOUR_USERNAME/bge-reranker:latest

# Test
curl http://localhost:8080/health
```

### Test Cloud Run Deployment

```bash
# Get URL from GitHub Actions summary, or:
gcloud run services describe bge-reranker --region us-central1 --format 'value(status.url)'

# Test
curl https://YOUR-SERVICE-URL/health

# Rerank test
curl -X POST https://YOUR-SERVICE-URL/rerank \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is a panda?",
    "documents": ["The giant panda is a bear.", "Python is a language."],
    "top_k": 1
  }'
```

## 💰 Cost Breakdown

### Docker Hub
- **Free tier:** Unlimited public repos
- **Bandwidth:** Free
- **Storage:** Free
- **Total:** $0/month ✅

### Google Cloud Run
- **First 2M requests/month:** FREE ✅
- **After free tier:** ~$0.0001 per request
- **Container Registry storage:** ~$0.026/GB/month (~$0.015 for this 2GB image)
- **Estimated for 10K req/day:** ~$30/month

### GitHub Actions
- **Public repos:** Unlimited minutes FREE ✅
- **Private repos:** 2,000 minutes/month free
- **This workflow:** ~10 minutes per build
- **Estimated:** FREE for public repos

## 🎯 Recommended Workflow

1. **Development:**
   - Make changes locally
   - Test with Docker: `.\build-and-run.ps1`
   - Test performance: `.\test-performance.ps1`

2. **Commit & Push:**
   ```bash
   git add .
   git commit -m "Description of changes"
   git push
   ```

3. **Auto-Deploy:**
   - GitHub Actions builds automatically
   - Check progress: GitHub repo → Actions tab
   - Get URL from Actions summary

4. **Verify:**
   - Test live endpoint
   - Monitor Cloud Run metrics

## 🔍 Monitoring & Debugging

### View GitHub Actions Logs
- Go to: `https://github.com/YOUR_USERNAME/bge-reranker/actions`
- Click on latest workflow run
- Expand steps to see detailed logs

### View Cloud Run Logs
```bash
# Stream logs
gcloud run services logs tail bge-reranker --region us-central1

# View in console
https://console.cloud.google.com/run?project=YOUR_PROJECT
```

### Common Issues

**Build fails:**
- Check GitHub Actions logs
- Verify Dockerfile syntax
- Ensure requirements.txt is valid

**Push to Docker Hub fails:**
- Verify DOCKER_USERNAME and DOCKER_PASSWORD secrets
- Check Docker Hub access token is valid
- Ensure token has write permissions

**Cloud Run deploy fails:**
- Verify GCP_PROJECT_ID and GCP_SA_KEY secrets
- Check service account permissions
- Ensure APIs are enabled

## 📈 Next Steps

1. ✅ Push to GitHub
2. ✅ Configure secrets (Docker Hub or GCP)
3. ✅ Watch GitHub Actions build
4. ✅ Test deployed service
5. 🎯 Integrate with your RAG pipeline
6. 📊 Monitor usage and costs
7. 🚀 Scale as needed

## 🎓 Production Tips

- **Use Cloud Run** for production (auto-scaling, managed)
- **Use Docker Hub** for sharing and development
- **Monitor costs** in GCP Console
- **Set max instances** to control costs (default: 10)
- **Enable monitoring** in Cloud Run for metrics
- **Use Cloud Armor** for DDoS protection if needed
- **Add authentication** if API should be private

## 📚 Resources

- Docker Hub: https://hub.docker.com
- Google Cloud Run: https://cloud.google.com/run
- GitHub Actions: https://github.com/features/actions
- BGE Model: https://huggingface.co/BAAI/bge-reranker-v2-m3

---

**You're all set!** 🎉

Push to GitHub and watch the magic happen!
