import os
import random
import psycopg2
from flask import Flask, request, jsonify

app = Flask(__name__)

DB_HOST = os.getenv("DB_HOST", "db")
DB_NAME = os.getenv("DB_NAME", "dicedb")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )

@app.route('/api/roll', methods=['POST'])
def roll_dice():
    data = request.json or {}
    p1_name = data.get('p1_name', 'Zorian')
    p2_name = data.get('p2_name', 'Veronika')

    p1_score = random.randint(1, 6)
    p2_score = random.randint(1, 6)

    if p1_score > p2_score:
        winner = p1_name
    elif p2_score > p1_score:
        winner = p2_name
    else:
        winner = "Draw"

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO game_history (player1, player2, score1, score2, winner) VALUES (%s, %s, %s, %s, %s)",
            (p1_name, p2_name, p1_score, p2_score, winner)
        )
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Database error: {e}")

    return jsonify({
        "p1_name": p1_name,
        "p2_name": p2_name,
        "p1_score": p1_score,
        "p2_score": p2_score,
        "winner": winner
    })

@app.route('/api/history', methods=['GET'])
def get_history():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, player1, player2, score1, score2, winner, created_at FROM game_history ORDER BY id DESC LIMIT 10")
        rows = cur.fetchall()
        cur.close()
        conn.close()

        history = [
            {"id": r[0], "p1": r[1], "p2": r[2], "s1": r[3], "s2": r[4], "winner": r[5], "time": str(r[6])}
            for r in rows
        ]
        return jsonify(history)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
