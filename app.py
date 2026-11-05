"""Minimal Flask app exposing a single JSON endpoint."""
from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/")
def index():
    return jsonify(message="Hello from DevOps Intern Task!", status="running")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
