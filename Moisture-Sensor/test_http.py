# from flask import Flask, jsonify
# import random

# app = Flask(__name__)

# # Endpoint to get mock moisture level
# @app.route('/moisture', methods=['GET'])
# def get_moisture_level():
#     # Simulate a moisture level between 30% and 80%
#     moisture_level = round(random.uniform(30, 80), 1)
#     return jsonify({"moistureLevel": moisture_level})

# if __name__ == '__main__':
#     # Run the server on localhost:5000
#     app.run(host='0.0.0.0', port=5000)

from flask import Flask, jsonify, request

app = Flask(__name__)

# Global variable to hold the latest moisture level
latest_moisture_level = None

# @app.route('/moisture', methods=['GET'])
# # def moisture():
# #     global latest_moisture_level

@app.route('/api', methods=['POST'])
def receive_data():
    data = request.get_json()
    print("Received:", data)
    return jsonify({"message": "Data received"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
