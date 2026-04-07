const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

io.on('connection', (socket) => {
  console.log('A client connected:', socket.id);

  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

// Endpoint for FastAPI to hit to broadcast to clients
app.post('/api/layout-update', (req, res) => {
  const layoutConfig = req.body;
  console.log('Received new layout config form FastAPI, broadcasting to Flutter clients:', layoutConfig);
  io.emit('layout_update', layoutConfig);
  res.status(200).send({ success: true, message: 'Layout broadcasted' });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Node real-time server running on port ${PORT}`);
});
