from flask import Flask, request, jsonify, render_template  
from pymongo import MongoClient
from datetime import datetime
import traceback  

# Inisialisasi aplikasi Flask
app = Flask(__name__)
CORS(app)

# Koneksi ke MongoDB
try:
    client = MongoClient('mongodb+srv://renaheryani152:rena1234@cluster0.gftbv.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0') 
    db = client['sensor_db'] 
    collection = db['sensor_data']  
    print("Koneksi ke MongoDB berhasil.")
except Exception as e:
    print(f"Error menghubungkan ke MongoDB: {e}")
    exit(1)

# Route untuk  HTML
@app.route('/')
def index():
    return render_template('index.html')

# Endpoint untuk menerima data dari ESP32
@app.route('/data', methods=['POST'])
def add_data():
    try:
        # Ambil data JSON dari request
        data = request.get_json()

        # Validasi data yang diterima
        required_keys = ['sensor_value_gas', 'sensor_value_humidity', 'sensor_value_temp']
        if not data or not all(key in data for key in required_keys):
            return jsonify({"error": f"Data tidak lengkap, harus mengandung {required_keys}"}), 400

        # Tambahkan timestamp
        data['timestamp'] = datetime.utcnow().isoformat() + "Z"

        # Simpan ke MongoDB
        result = collection.insert_one(data)
        print(f"Data berhasil disimpan dengan ID: {result.inserted_id}")

        return jsonify({"message": "Data berhasil disimpan", "id": str(result.inserted_id)}), 201
    except Exception as e:
        print(f"Error: {traceback.format_exc()}")  # Log kesalahan
        return jsonify({"error": "Terjadi kesalahan pada server"}), 500

# Endpoint untuk mendapatkan data dari MongoDB
@app.route('/data', methods=['GET'])
def get_data():
    try:
        # Ambil data dari MongoDB
        data = list(collection.find())
        for item in data:
            # Konversi ObjectId ke string
            item['_id'] = str(item['_id'])
        return jsonify(data), 200
    except Exception as e:
        print(f"Error: {traceback.format_exc()}")  # Log kesalahan
        return jsonify({"error": "Terjadi kesalahan saat mengambil data"}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
