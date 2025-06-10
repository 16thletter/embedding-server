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



def get_model():
    """Lazy load the model to reduce startup time and memory usage"""
    global model
    if model is None:
        logger.info("Loading embedding model...")
        # Using all-mpnet-base-v2 for native 768-dimensional embeddings
        # - Size: ~420MB
        # - Dimensions: 768 (native, high quality)
        # - Best quality embeddings
        model = SentenceTransformer('all-mpnet-base-v2')
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
        embedding = embedding_model.encode(text, convert_to_tensor=False).tolist()

        return jsonify({
            'embedding': embedding,
            'dimensions': len(embedding),
            'model': 'all-mpnet-base-v2'
        })

    except Exception as e:
        logger.error(f"Error processing embedding request: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5001))
    app.run(host='0.0.0.0', port=port, debug=False)
    
