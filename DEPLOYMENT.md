# BGE Reranker v2-m3 - Production Deployment

[![Build and Push Docker Image](https://github.com/YOUR_USERNAME/bge-reranker/actions/workflows/docker-build.yml/badge.svg)](https://github.com/YOUR_USERNAME/bge-reranker/actions/workflows/docker-build.yml)

Production-ready CPU-optimized reranker API for RAG pipelines.

## 🚀 Quick Start

### Pull from Docker Hub
```bash
docker pull YOUR_DOCKERHUB_USERNAME/bge-reranker:latest
docker run -p 8080:8080 YOUR_DOCKERHUB_USERNAME/bge-reranker:latest
```

### API Documentation
Once running, visit: http://localhost:8080/docs

## 📊 Performance

**Tested on laptop CPU:**
- Single pair: ~20-50ms
- 10 documents: ~1,167ms (8.57 docs/sec)
- 100 documents: ~4,750ms (21.05 docs/sec)
- Request throughput: ~5 req/sec

**Production (Google Cloud Run 2 vCPU):**
- Expected: 10-20 req/sec
- Auto-scales 0-10 instances
- First 2M requests/month FREE

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│  GitHub Repository                      │
│  - Push to main branch                  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  GitHub Actions                         │
│  - Build Docker image                   │
│  - Run tests                            │
│  - Push to registry                     │
└──────────────┬──────────────────────────┘
               │
        ┌──────┴──────┐
        │             │
        ▼             ▼
┌──────────────┐  ┌──────────────┐
│  Docker Hub  │  │  GCR         │
│  (Public)    │  │  (Private)   │
└──────┬───────┘  └──────┬───────┘
       │                 │
       │                 ▼
       │          ┌──────────────┐
       │          │ Cloud Run    │
       │          │ Auto-deploy  │
       │          └──────────────┘
       │
       ▼
┌──────────────────────────────────────────┐
│  Your Infrastructure                     │
│  - docker pull & run                     │
│  - RunPod / Other cloud                  │
└──────────────────────────────────────────┘
```

## 🔧 Setup GitHub Actions

### Option 1: Docker Hub (Public/Free)

1. **Create Docker Hub account**: https://hub.docker.com

2. **Create GitHub repository secrets**:
   - Go to: `Settings` → `Secrets and variables` → `Actions`
   - Add secrets:
     - `DOCKER_USERNAME`: Your Docker Hub username
     - `DOCKER_PASSWORD`: Your Docker Hub password or access token

3. **Push code to GitHub**:
   ```bash
   git init
   git add .
   git commit -m "Initial commit: BGE reranker with GitHub Actions"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/bge-reranker.git
   git push -u origin main
   ```

4. **GitHub Actions will automatically**:
   - Build Docker image
   - Push to Docker Hub
   - Tag as `latest` and with commit SHA

5. **Pull and use**:
   ```bash
   docker pull YOUR_USERNAME/bge-reranker:latest
   ```

### Option 2: Google Container Registry + Cloud Run (Private + Auto-deploy)

1. **Create GCP Service Account**:
   ```bash
   gcloud iam service-accounts create github-actions \
     --display-name "GitHub Actions"
   
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:github-actions@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/run.admin"
   
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:github-actions@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/storage.admin"
   
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:github-actions@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/iam.serviceAccountUser"
   
   gcloud iam service-accounts keys create key.json \
     --iam-account=github-actions@YOUR_PROJECT_ID.iam.gserviceaccount.com
   ```

2. **Add GitHub secrets**:
   - `GCP_PROJECT_ID`: Your GCP project ID
   - `GCP_SA_KEY`: Contents of `key.json` file (entire JSON)

3. **Push code** - it will automatically:
   - Build Docker image
   - Push to GCR
   - Deploy to Cloud Run
   - Test health endpoint
   - Report service URL

4. **Access your API**:
   - URL will be in GitHub Actions summary
   - Format: `https://bge-reranker-XXXXX-uc.a.run.app`

## 📝 API Usage

### Rerank documents
```python
import requests

response = requests.post(
    "https://your-url/rerank",
    json={
        "query": "What is a panda?",
        "documents": [
            "The giant panda is a bear species endemic to China.",
            "Python is a programming language.",
            "Pandas eat bamboo."
        ],
        "top_k": 2,
        "normalize": True
    }
)

results = response.json()
for result in results["results"]:
    print(f"Score: {result['score']:.4f} - {result['document']}")
```

### Score single pair
```bash
curl -X POST https://your-url/score \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is a panda?",
    "document": "The giant panda is a bear.",
    "normalize": true
  }'
```

## 💰 Costs

### Docker Hub
- Free: Unlimited public images
- Pro ($5/month): Private repos, more pulls

### Google Cloud Run
- **First 2M requests/month: FREE** ✨
- After free tier: ~$0.0001 per request
- Idle time: $0 (scale to zero)

**Example costs:**
- 10,000 req/day = $1/day = $30/month
- 100,000 req/day = $10/day = $300/month

Much cheaper than GPU alternatives! 🎉

## 🔄 Workflow Triggers

GitHub Actions run on:
- ✅ Push to `main` branch
- ✅ Changes to `app.py`, `requirements.txt`, or `Dockerfile`
- ✅ Manual trigger (workflow_dispatch)

## 🧪 Local Development

```bash
# Build locally
docker build -t bge-reranker:local .

# Run locally
docker run -p 8080:8080 bge-reranker:local

# Test
curl http://localhost:8080/health
```

## 📊 Monitoring

### Docker Hub
- View pulls: https://hub.docker.com/r/YOUR_USERNAME/bge-reranker

### Google Cloud Run
```bash
# View logs
gcloud run services logs tail bge-reranker --region us-central1

# View metrics
gcloud run services describe bge-reranker --region us-central1
```

## 🆚 Comparison: Docker Hub vs GCR

| Feature | Docker Hub | Google Container Registry |
|---------|-----------|---------------------------|
| **Cost** | Free (public) | Pay for storage (~$0.026/GB/month) |
| **Privacy** | Public by default | Private by default |
| **Auto-deploy** | No | Yes (to Cloud Run) |
| **Build speed** | ~5-10 min | ~5-10 min |
| **Pull speed** | Fast globally | Fast from GCP |
| **Best for** | Open source, sharing | Production, private |

## 🎯 Recommended Setup

**Use both!**
1. **Docker Hub**: For easy sharing and development
2. **GCR + Cloud Run**: For production deployment

GitHub Actions can push to both registries simultaneously.

## 📚 Related Projects

- Embedding: [nomic-embed-text](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5)
- LLM: [Qwen2.5-Coder-7B on RunPod](https://github.com/YOUR_USERNAME/qwen-coder-runpod)
- Model: [BAAI/bge-reranker-v2-m3](https://huggingface.co/BAAI/bge-reranker-v2-m3)

## 📄 License

Apache 2.0 (same as the BGE model)

## 🤝 Contributing

PRs welcome! Please test locally before submitting.
