module.exports = {
  setToken: setToken
};

function setToken(context, events, done) {
  // Get token from the payload (csv)
  const token = context.vars.token;
  
  // Set the auth object for the socket.io connection
  context.vars.socketio = {
    auth: {
      token: token
    },
    query: {
      token: token
    }
  };
  
  return done();
}
