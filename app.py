from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///flower'
db = SQLAlchemy(app)

class Plant(db.Model):
    id = db.Column(db.Integer)
    species = db.Column(db.String(80))
    threshold = db.Column(db.Float)
    maximum = db.Column(db.Float)
    moisture = db.Column(db.Float)

with app.app_context():
    db.create_all()


# Endpoint to receive moisture data from Raspberry Pi
@app.route('/api', methods=['POST'])
def receive_data():
    global moisture_level
    data = request.get_json()

    if 'moistureLevel' in data:
        plant = Plant.query.get(1)
        if plant:
            plant.moisture = data['moisturelevel']
            db.session.commit()
        else:
            return jsonify({"error": "Invalid data"}), 400
        moisture_level = data['moistureLevel']
        print(f"Updated moisture level: {moisture_level}")
        return jsonify({"message": "Moisture level updated"}), 200
    else:
        return jsonify({"error": "Invalid data"}), 400

# Endpoint for Flutter to fetch the latest moisture level
@app.route('/moisture', methods=['GET'])
def get_moisture():
    plant = Plant.query.get(1)
    if plant:
        return jsonify({"moistureLevel": plant.moisture})
    else:
        return jsonify({"error": "Invalid data"}), 400

@app.route('/add', methods=['POST'])
def add_plant():
    
    data = request.get_json()
    plant = Plant(id=1,species= data["plant"], moisture=0, 
                  threshold=data["minMoisture"], maximum=data["maxMoisture"])
    db.session.add(plant)
    
    
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
