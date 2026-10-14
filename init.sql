CREATE TABLE IF NOT EXISTS game_history (
    id SERIAL PRIMARY KEY,
    player1 VARCHAR(50),
    player2 VARCHAR(50),
    score1 INT,
    score2 INT,
    winner VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
