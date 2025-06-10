from flask import Flask, request, jsonify
from sentence_transformers import SentenceTransformer

app = Flask(__name__)

# Load model at startup (like your fast version)
print("Loading embedding model...")
model = SentenceTransformer('all-mpnet-base-v2')  # 768-dim embeddings
print("Model loaded successfully!")

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'model_loaded': True})

@app.route('/embed', methods=['POST'])
def embed():
    data = request.get_json()
    if not data or 'text' not in data:
        return jsonify({'error': "Missing 'text' field"}), 400

    text = data['text']
    embedding = model.encode(text).tolist()

    return jsonify({'embedding': embedding})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
    
