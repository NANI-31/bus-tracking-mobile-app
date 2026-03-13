import ws from 'k6/ws';
import { check, sleep } from 'k6';
import { SharedArray } from 'k6/data';
import papaparse from 'https://jslib.k6.io/papaparse/5.1.1/index.js';

// Load tokens from CSV
const tokens = new SharedArray('tokens', function () {
  return papaparse.parse(open('./tokens.csv'), { header: true }).data;
});

export const options = {
  stages: [
    { duration: '30s', target: 20 }, // Warm-up
    { duration: '1m', target: 50 },  // Ramp-up
    { duration: '1m', target: 50 },  // Sustained load
    { duration: '30s', target: 0 },  // Cool-down
  ],
};

export default function () {
  const user = tokens[Math.floor(Math.random() * tokens.length)];
  const token = user.token;
  const collegeId = user.collegeId;
  const role = user.role;

  // Socket.IO v4 Handshake URL
  const url = `ws://127.0.0.1:5000/socket.io/?EIO=4&transport=websocket&token=${encodeURIComponent(token)}`;

  const res = ws.connect(url, {}, function (socket) {
    socket.on('open', () => {
      // Socket.IO "Connect" packet (40)
      socket.send('40');

      // Join college room
      socket.send(`42["join_college","${collegeId}"]`);

      // If driver, send periodic location updates
      if (role === 'driver') {
        socket.setInterval(() => {
          const lat = 12.9716 + (Math.random() - 0.5) * 0.01;
          const lng = 77.5946 + (Math.random() - 0.5) * 0.01;
          socket.send(`42["update_location",{"lat":${lat},"lng":${lng}}]`);
        }, 5000);
      }
    });

    socket.on('message', (data) => {
      // Optional: Log or check messages
      check(data, {
        'received message': (d) => d.length > 0,
      });
    });

    socket.on('error', (e) => {
      console.error(`WebSocket error: ${e.error()}`);
    });

    // Stay connected for a duration
    sleep(30);
    socket.close();
  });

  check(res, { 'status is 101': (r) => r && r.status === 101 });
}
