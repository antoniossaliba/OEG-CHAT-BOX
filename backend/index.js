const io = require('socket.io')(3000, {
  cors: {
    origin: '*',
  }
});

const users = {};

io.on('connection', socket => {
  console.log('User connected:', socket.id);

  socket.on('join', username => {
    users[username] = socket.id;
    socket.username = username;
    console.log(`${username} joined`);
  });

  socket.on('private_message', ({ sender, receiver, message }) => {
    console.log(`Private msg from ${sender} to ${receiver}: ${message}`);

    const receiverSocketId = users[receiver];
    if (receiverSocketId) {
      io.to(receiverSocketId).emit('private_message', { sender, message });
    }

    socket.emit('private_message', { sender, message });
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.username);
    if (socket.username) {
      delete users[socket.username];
    }
  });
});
