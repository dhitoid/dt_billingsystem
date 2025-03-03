CREATE TABLE IF NOT EXISTS billing (
    id INT AUTO_INCREMENT PRIMARY KEY,
    citizenId VARCHAR(50) NOT NULL,
    amount INT NOT NULL,
    reason VARCHAR(255) NOT NULL,
    dueTime INT NOT NULL
);
