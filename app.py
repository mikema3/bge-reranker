# BGE Reranker v2-m3 - CPU Optimized FastAPI Server
# Designed for Google Cloud Run deployment

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import List, Optional
import torch
from transformers import AutoModelForSequenceClassification, AutoTokenizer
import time
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="BGE Reranker v2-m3 API",
    description="CPU-optimized reranker for production RAG pipelines",
    version="1.0.0"
)

# Global model and tokenizer
model = None
tokenizer = None
device = None

class RerankRequest(BaseModel):
    query: str = Field(..., description="The search query")
    documents: List[str] = Field(..., description="List of documents to rerank")
    top_k: Optional[int] = Field(None, description="Return top K results. If None, returns all")
    normalize: Optional[bool] = Field(True, description="Normalize scores to [0,1] using sigmoid")

class RerankResult(BaseModel):
    index: int
    document: str
    score: float

class RerankResponse(BaseModel):
    query: str
    results: List[RerankResult]
    processing_time_ms: float
    model: str = "BAAI/bge-reranker-v2-m3"

@app.on_event("startup")
async def load_model():
    """Load model on startup - happens once per container"""
    global model, tokenizer, device
    
    logger.info("🚀 Loading BGE Reranker v2-m3...")
    start_time = time.time()
    
    model_name = "BAAI/bge-reranker-v2-m3"
    
    # Use CPU for Cloud Run compatibility
    # In future, can detect CUDA availability: torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    device = torch.device('cpu')
    logger.info(f"📍 Using device: {device}")
    
    # Load tokenizer
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    
    # Load model with optimizations
    model = AutoModelForSequenceClassification.from_pretrained(
        model_name,
        torch_dtype=torch.float32  # FP32 for CPU, use FP16 for GPU
    )
    model.to(device)
    model.eval()
    
    # Enable inference optimizations
    torch.set_num_threads(4)  # Adjust based on Cloud Run CPU allocation
    
    load_time = time.time() - start_time
    logger.info(f"✅ Model loaded in {load_time:.2f}s")
    logger.info(f"📊 Model size: ~568 MB")
    logger.info(f"🧵 PyTorch threads: {torch.get_num_threads()}")

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "model": "BAAI/bge-reranker-v2-m3",
        "device": str(device),
        "ready": model is not None
    }

@app.get("/health")
async def health():
    """Detailed health check for Cloud Run"""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    return {
        "status": "ready",
        "model_loaded": True,
        "device": str(device),
        "threads": torch.get_num_threads()
    }

def compute_scores(query: str, documents: List[str], normalize: bool = True) -> List[float]:
    """Compute relevance scores for query-document pairs"""
    
    # Create pairs: [query, doc1], [query, doc2], ...
    pairs = [[query, doc] for doc in documents]
    
    with torch.no_grad():
        # Tokenize with padding and truncation
        inputs = tokenizer(
            pairs,
            padding=True,
            truncation=True,
            return_tensors='pt',
            max_length=512
        )
        inputs = inputs.to(device)
        
        # Get scores from model
        scores = model(**inputs, return_dict=True).logits.view(-1, ).float()
        
        # Convert to Python list
        scores = scores.cpu().numpy().tolist()
        
        # Apply sigmoid normalization if requested
        if normalize:
            import math
            scores = [1 / (1 + math.exp(-score)) for score in scores]
    
    return scores

@app.post("/rerank", response_model=RerankResponse)
async def rerank(request: RerankRequest):
    """
    Rerank documents based on query relevance
    
    Example:
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
    """
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded yet")
    
    if not request.documents:
        raise HTTPException(status_code=400, detail="No documents provided")
    
    if len(request.documents) > 1000:
        raise HTTPException(
            status_code=400,
            detail="Too many documents. Maximum 1000 per request"
        )
    
    start_time = time.time()
    
    try:
        # Compute scores
        scores = compute_scores(request.query, request.documents, request.normalize)
        
        # Create results with original indices
        results = [
            RerankResult(
                index=i,
                document=doc,
                score=score
            )
            for i, (doc, score) in enumerate(zip(request.documents, scores))
        ]
        
        # Sort by score (descending)
        results.sort(key=lambda x: x.score, reverse=True)
        
        # Apply top_k filter if specified
        if request.top_k is not None:
            results = results[:request.top_k]
        
        processing_time = (time.time() - start_time) * 1000  # Convert to ms
        
        logger.info(
            f"Reranked {len(request.documents)} docs in {processing_time:.2f}ms "
            f"(top_k={request.top_k})"
        )
        
        return RerankResponse(
            query=request.query,
            results=results,
            processing_time_ms=processing_time
        )
        
    except Exception as e:
        logger.error(f"Error during reranking: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Reranking failed: {str(e)}")

@app.post("/rerank/simple")
async def rerank_simple(query: str, documents: List[str], top_k: int = 5):
    """
    Simplified rerank endpoint with query parameters
    Returns just scores without full document text
    """
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded yet")
    
    start_time = time.time()
    scores = compute_scores(query, documents, normalize=True)
    
    # Get top-k indices
    indexed_scores = list(enumerate(scores))
    indexed_scores.sort(key=lambda x: x[1], reverse=True)
    top_results = indexed_scores[:top_k]
    
    processing_time = (time.time() - start_time) * 1000
    
    return {
        "top_k_indices": [idx for idx, _ in top_results],
        "top_k_scores": [score for _, score in top_results],
        "processing_time_ms": processing_time
    }

@app.post("/score")
async def score_single(query: str, document: str, normalize: bool = True):
    """Score a single query-document pair"""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded yet")
    
    start_time = time.time()
    scores = compute_scores(query, [document], normalize)
    processing_time = (time.time() - start_time) * 1000
    
    return {
        "query": query,
        "document": document,
        "score": scores[0],
        "processing_time_ms": processing_time
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
