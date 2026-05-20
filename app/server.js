const express = require('express');
const app = express();

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP', environment: process.env.NODE_ENV || 'development' });
});

module.exports = app;

if (require.main === module) {
  const port = process.env.PORT || 3000;
  app.listen(port, () => console.log(`Server running on port ${port}`));
}