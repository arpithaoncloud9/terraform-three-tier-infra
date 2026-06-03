const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>AWS 3-Tier App</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #f0f4f8; }
          h1 { color: #232f3e; }
          .badge { background: #ff9900; color: white; padding: 10px 20px; border-radius: 5px; font-size: 18px; }
          .info { margin-top: 30px; color: #555; }
        </style>
      </head>
      <body>
        <h1>🚀 Hello from AWS 3-Tier Infrastructure!</h1>
        <p class="badge">Powered by Terraform + Docker + GitHub Actions</p>
        <div class="info">
          <p>Running on: <strong>AWS EC2 (Auto Scaling Group)</strong></p>
          <p>Container: <strong>Docker → AWS ECR</strong></p>
          <p>Built by: <strong>Maria Arpitha</strong></p>
        </div>
      </body>
    </html>
  `);
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});