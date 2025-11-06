# README for BGE Reranker v2-m3 Deployment

## Overview

This is a CPU-optimized deployment of **BAAI/bge-reranker-v2-m3** for production RAG pipelines.

**Model Info:**
- Size: 568 MB (FP32)
- Type: Cross-encoder reranker
- Languages: 100+ (multilingual)
- License: Apache 2.0

## Quick Start (Local Testing)

1. **Build and run Docker container:**
   ```powershell
   cd c:\my1\huggingface\bge-reranker
   .\build-and-run.ps1
   ```

2. **Test performance:**
   ```powershell
   .\test-performance.ps1
   ```

3. **Access API documentation:**
   - Open browser: http://localhost:8080/docs

## API Endpoints

### POST /rerank
Rerank documents by relevance to query.

**Request:**
```json
{
  "query": "What is a panda?",
  "documents": [
    "The giant panda is a bear species endemic to China.",
    "Python is a programming language.",
    "Pandas are cute animals."
  ],
  "top_k": 2,
  "normalize": true
}
```

**Response:**
```json
{
  "query": "What is a panda?",
  "results": [
    {
      "index": 0,
      "document": "The giant panda is a bear species endemic to China.",
      "score": 0.9856
    },
    {
      "index": 2,
      "document": "Pandas are cute animals.",
      "score": 0.8234
    }
  ],
  "processing_time_ms": 45.2
}
```

### POST /score
Score a single query-document pair.

**Request:**
```json
{
  "query": "What is a panda?",
  "document": "The giant panda is a bear.",
  "normalize": true
}
```

## Deployment Options

### Option 1: Google Cloud Run (Recommended for CPU)

**Pros:**
- ✅ Serverless, auto-scaling
- ✅ Pay per request (~$0.0001 per request)
- ✅ Scale to zero (free when idle)
- ✅ No infrastructure management
- ✅ Global CDN

**Estimated costs:**
- 1,000 requests/day = $0.10/day = $3/month
- 10,000 requests/day = $1/day = $30/month

**Deploy command:**
```bash
# Build and push to Google Container Registry
gcloud builds submit --tag gcr.io/YOUR_PROJECT/bge-reranker

# Deploy to Cloud Run
gcloud run deploy bge-reranker \
  --image gcr.io/YOUR_PROJECT/bge-reranker \
  --platform managed \
  --region us-central1 \
  --memory 2Gi \
  --cpu 2 \
  --min-instances 0 \
  --max-instances 10 \
  --allow-unauthenticated
```

### Option 2: RunPod (If GPU needed)

**Pros:**
- ✅ 5-10x faster with GPU
- ✅ Scale to zero (free when idle)
- ✅ Good for high throughput

**Estimated costs:**
- RTX 4090: $0.34/hour
- ~100 req/sec throughput
- Only charged for execution time

**When to use GPU:**
- CPU performance <10 docs/sec
- Need <50ms latency
- Processing 100+ docs per request

## Performance Targets

**CPU (Cloud Run with 2 vCPU):**
- Single pair: ~20-50ms
- 10 documents: ~50-100ms
- 100 documents: ~500-1000ms
- Throughput: ~10-20 req/sec

**GPU (RunPod RTX 4090):**
- Single pair: ~2-5ms
- 10 documents: ~5-10ms
- 100 documents: ~50-100ms
- Throughput: ~100-200 req/sec

## Integration Example (Python)

```python
import requests

def rerank_documents(query: str, documents: list[str], top_k: int = 5):
    """Rerank documents using deployed API"""
    
    response = requests.post(
        "https://your-reranker-url.run.app/rerank",
        json={
            "query": query,
            "documents": documents,
            "top_k": top_k,
            "normalize": True
        }
    )
    
    return response.json()

# Example usage
docs = [
    "The giant panda lives in China.",
    "Python is a programming language.",
    "Pandas eat bamboo."
]

results = rerank_documents("Tell me about pandas", docs, top_k=2)

for result in results["results"]:
    print(f"Score: {result['score']:.4f} - {result['document']}")
```

## RAG Pipeline Integration

```python
# Complete RAG pipeline with reranking
def rag_with_reranker(query: str):
    # Step 1: Vector search (get top 100)
    embeddings = get_embeddings(query)
    candidates = vector_db.search(embeddings, top_k=100)
    
    # Step 2: Rerank (narrow to top 5)
    reranked = rerank_documents(
        query=query,
        documents=[doc.text for doc in candidates],
        top_k=5
    )
    
    # Step 3: Generate answer with LLM
    context = "\n".join([r["document"] for r in reranked["results"]])
    answer = llm.generate(query, context)
    
    return answer
```

## Cost Comparison

**Scenario: 1000 requests/day, 50 docs per request**

| Solution | Cost/Request | Daily Cost | Monthly Cost |
|----------|-------------|------------|--------------|
| Cloud Run CPU | $0.0001 | $0.10 | $3 |
| RunPod GPU (on-demand) | $0.0005 | $0.50 | $15 |
| Cloud Run GPU | $0.001 | $1.00 | $30 |

**Recommendation:** Start with Cloud Run CPU. Upgrade to GPU only if latency >500ms.

## Monitoring

**Cloud Run metrics:**
- Request latency
- Request count
- Container CPU usage
- Memory usage
- Cold starts

**Health check:**
```bash
curl https://your-url.run.app/health
```

## Next Steps

1. ✅ Test locally with `.\build-and-run.ps1`
2. ✅ Run performance tests with `.\test-performance.ps1`
3. 📊 Analyze CPU performance
4. 🚀 Deploy to Google Cloud Run (if CPU is good)
5. 🎯 Or deploy to RunPod (if GPU needed)

## Support

- HuggingFace: https://huggingface.co/BAAI/bge-reranker-v2-m3
- GitHub: https://github.com/FlagOpen/FlagEmbedding
