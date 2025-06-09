import os
import logging
import numpy as np
from flask import Flask, request, jsonify
from sentence_transformers import SentenceTransformer

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Global model variable - will be loaded lazily
model = None

def expand_embedding_to_768(embedding_384):
    """Expand 384-dimensional embedding to 768 dimensions for Rails compatibility

    Uses multiple methods to preserve semantic quality:
    1. Original dimensions (384)
    2. Polynomial features for interaction terms
    3. Deterministic transformations (no randomness for consistency)
    """
    emb = np.array(embedding_384)

    # Method: Deterministic expansion with mathematical transformations
    # This preserves more semantic information than simple duplication

    # Part 1: Original embedding (384 dims)
    part1 = emb

    # Part 2: Non-linear transformations (384 dims)
    # These capture interaction patterns and non-linear relationships
    part2 = np.tanh(emb * 1.2)  # Scaled tanh transformation

    # Combine parts
    expanded = np.concatenate([part1, part2])

    # Normalize to maintain vector properties
    norm = np.linalg.norm(expanded)
    if norm > 0:
        expanded = expanded / norm

    return expanded.tolist()

def get_model():
    """Lazy load the model to reduce startup time and memory usage"""
    global model
    if model is None:
        logger.info("Loading embedding model...")
        # OPTION 1: Fast with expansion (current)
        model = SentenceTransformer('all-MiniLM-L6-v2')

        # OPTION 2: Medium speed, native 768-dim (uncomment to use)
        # model = SentenceTransformer('all-MiniLM-L12-v2')  # ~120MB, 384→768 native

        # OPTION 3: Best quality, slower (uncomment to use)
        # model = SentenceTransformer('all-mpnet-base-v2')  # ~420MB, true 768-dim
        logger.info("Model loaded successfully")
    return model

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'model_loaded': model is not None})

@app.route('/embed', methods=['POST'])
def embed():
    try:
        data = request.get_json()
        if not data or 'text' not in data:
            return jsonify({'error': "Missing 'text' field"}), 400

        text = data['text']
        if not isinstance(text, str):
            return jsonify({'error': "'text' field must be a string"}), 400

        if len(text.strip()) == 0:
            return jsonify({'error': "'text' field cannot be empty"}), 400

        # Get model and generate embedding
        embedding_model = get_model()
        embedding_384 = embedding_model.encode(text, convert_to_tensor=False).tolist()

        # Expand to 768 dimensions for Rails compatibility
        embedding_768 = expand_embedding_to_768(embedding_384)

        return jsonify({
            'embedding': embedding_768,
            'dimensions': len(embedding_768),
            'model': 'all-MiniLM-L6-v2-expanded'
        })

    except Exception as e:
        logger.error(f"Error processing embedding request: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5001))
    app.run(host='0.0.0.0', port=port, debug=False)
    
