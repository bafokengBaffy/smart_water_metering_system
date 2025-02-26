// server.js (Node.js/Express backend for Smart Water Metering System)
const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs'); // For password hashing
const jwt = require('jsonwebtoken'); // For authentication

const app = express();
const port = 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// JWT secret key
const JWT_SECRET = 'your_jwt_secret_key';

// Database connection
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '1111',
  database: 'Smart_Water_Metering_System',
});

// Check database connection
db.connect((err) => {
  if (err) {
    console.error('Error connecting to MySQL:', err.stack);
    return;
  }
  console.log('Connected to MySQL');
});

// === User Routes ===

// Sign-Up API
app.post('/api/users/signup', (req, res) => {
  const { name, email, address, phone, password } = req.body;

  // Check if the email already exists
  const checkEmailQuery = 'SELECT * FROM Users WHERE email = ?';
  db.query(checkEmailQuery, [email], (err, result) => {
    if (err) return res.status(500).json({ message: 'Database error' });
    if (result.length > 0) return res.status(400).json({ message: 'Email already exists' });

    // Hash the password and insert the user
    bcrypt.hash(password, 10, (err, hashedPassword) => {
      if (err) return res.status(500).json({ message: 'Error hashing password' });

      const insertUserQuery =
        'INSERT INTO Users (name, email, address, phone, password) VALUES (?, ?, ?, ?, ?)';
      db.query(insertUserQuery, [name, email, address, phone, hashedPassword], (err, result) => {
        if (err) return res.status(500).json({ message: 'Database error' });
        return res.status(201).json({ message: 'User registered successfully' });
      });
    });
  });
});

// Sign-In API
app.post('/api/users/signin', (req, res) => {
  const { email, password } = req.body;

  const findUserQuery = 'SELECT * FROM Users WHERE email = ?';
  db.query(findUserQuery, [email], (err, result) => {
    if (err) return res.status(500).json({ message: 'Database error' });
    if (result.length === 0) return res.status(404).json({ message: 'User not found' });

    const user = result[0];

    // Compare password
    bcrypt.compare(password, user.password, (err, isMatch) => {
      if (err) return res.status(500).json({ message: 'Error comparing passwords' });
      if (!isMatch) return res.status(401).json({ message: 'Invalid credentials' });

      // Generate JWT token
      const token = jwt.sign({ userId: user.user_id }, JWT_SECRET, { expiresIn: '1h' });
      res.status(200).json({ token, message: 'Sign-in successful' });
    });
  });
});

// === Smart Meter Routes ===

// Get all smart meters
app.get('/api/meters', (req, res) => {
  const getMetersQuery = 'SELECT * FROM Smart_Meters';
  db.query(getMetersQuery, (err, result) => {
    if (err) return res.status(500).json({ message: 'Database error' });
    return res.status(200).json(result);
  });
});

// Add a new smart meter
app.post('/api/meters', (req, res) => {
  const { user_id, location, current_usage, status } = req.body;
  const insertMeterQuery =
    'INSERT INTO Smart_Meters (user_id, location, current_usage, status) VALUES (?, ?, ?, ?)';
  db.query(insertMeterQuery, [user_id, location, current_usage, status], (err, result) => {
    if (err) return res.status(500).json({ message: 'Database error' });
    return res.status(201).json({ message: 'Smart meter added successfully' });
  });
});

// === Billing Routes ===

// Get all bills for a user
app.get('/api/bills/:user_id', (req, res) => {
  const user_id = req.params.user_id;
  const getBillsQuery = 'SELECT * FROM Billing WHERE user_id = ?';
  db.query(getBillsQuery, [user_id], (err, result) => {
    if (err) return res.status(500).json({ message: 'Database error' });
    return res.status(200).json(result);
  });
});

// Add a bill
app.post('/api/bills', (req, res) => {
  const { user_id, meter_id, billing_period_start, billing_period_end, total_amount, billing_date, due_date, payment_status } =
    req.body;
  const insertBillQuery =
    'INSERT INTO Billing (user_id, meter_id, billing_period_start, billing_period_end, total_amount, billing_date, due_date, payment_status) VALUES (?, ?, ?, ?, ?, ?, ?, ?)';
  db.query(
    insertBillQuery,
    [user_id, meter_id, billing_period_start, billing_period_end, total_amount, billing_date, due_date, payment_status],
    (err, result) => {
      if (err) return res.status(500).json({ message: 'Database error' });
      return res.status(201).json({ message: 'Bill added successfully' });
    }
  );
});

// === Alerts Routes ===

// Get all alerts
app.get('/api/alerts', (req, res) => {
  const getAlertsQuery = 'SELECT * FROM Alerts';
  db.query(getAlertsQuery, (err, result) => {
    if (err) return res.status(500).json({ message: 'Database error' });
    return res.status(200).json(result);
  });
});

// Add an alert
app.post('/api/alerts', (req, res) => {
  const { meter_id, alert_type, alert_message, status } = req.body;
  const insertAlertQuery =
    'INSERT INTO Alerts (meter_id, alert_type, alert_message, status) VALUES (?, ?, ?, ?)';
  db.query(insertAlertQuery, [meter_id, alert_type, alert_message, status], (err, result) => {
    if (err) return res.status(500).json({ message: 'Database error' });
    return res.status(201).json({ message: 'Alert added successfully' });
  });
});

// === Server Listener ===
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});
