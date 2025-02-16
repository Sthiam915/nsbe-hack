from flask import Flask, request, jsonify

app = Flask(__name__)

moisture_level = 50.0  # Default value

# Endpoint to receive moisture data from Raspberry Pi
@app.route('/api', methods=['POST'])
def receive_data():
    global moisture_level
    data = request.get_json()

    if 'moistureLevel' in data:
        moisture_level = data['moistureLevel']
        print(f"Updated moisture level: {moisture_level}")
        return jsonify({"message": "Moisture level updated"}), 200
    else:
        return jsonify({"error": "Invalid data"}), 400

# Endpoint for Flutter to fetch the latest moisture level
@app.route('/moisture', methods=['GET'])
def get_moisture():
    return jsonify({"moistureLevel": moisture_level})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
