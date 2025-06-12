import os
import gc
from flask import Flask, request, jsonify
from sentence_transformers import SentenceTransformer

app = Flask(__name__)

# Load model at startup for maximum speed
print("Loading embedding model...")
print("This may take a few minutes on first run...")
try:
    # Load model with explicit device specification for CPU
    model = SentenceTransformer('all-mpnet-base-v2', device='cpu')  # 768-dim embeddings
    print("Model loaded successfully!")
    # Force garbage collection to free up memory after loading
    gc.collect()
    print("Memory cleanup completed.")
except Exception as e:
    print(f"Error loading model: {e}")
    model = None

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None,
        'model_name': 'all-mpnet-base-v2' if model else 'none'
    })

@app.route('/embed', methods=['POST'])
def embed():
    if model is None:
        return jsonify({'error': 'Model not loaded'}), 500

    data = request.get_json()
    if not data or 'text' not in data:
        return jsonify({'error': "Missing 'text' field"}), 400

    text = data['text']
    try:
        embedding = model.encode(text).tolist()
        return jsonify({'embedding': embedding})
    except Exception as e:
        print(f"Error generating embedding: {e}")
        return jsonify({'error': 'Failed to generate embedding'}), 500

if __name__ == '__main__':
    # For local development only
    port = int(os.environ.get('PORT', 5001))
    app.run(host='0.0.0.0', port=port, debug=False)
    
