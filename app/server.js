const express = require('express');
const AWS = require('aws-sdk');
const app = express();
const PORT = process.env.PORT || 3000;

// ============ CloudWatch Setup ============
const cloudwatch = new AWS.CloudWatch({
  region: process.env.AWS_REGION || 'us-east-1'
});

// ============ Metrics Tracking ============
let metrics = {
  requestCount: 0,
  errorCount: 0,
  totalDuration: 0,
  maxDuration: 0,
  minDuration: Infinity,
  statusCodes: {}
};

/**
 * Send custom metrics to CloudWatch
 */
async function sendMetricsToCloudWatch() {
  try {
    const avgDuration = metrics.requestCount > 0 
      ? Math.round(metrics.totalDuration / metrics.requestCount)
      : 0;

    const params = {
      Namespace: 'CustomApp/Metrics',
      MetricData: [
        {
          MetricName: 'RequestCount',
          Value: metrics.requestCount,
          Unit: 'Count',
          Timestamp: new Date(),
          Dimensions: [
            { Name: 'Environment', Value: process.env.ENVIRONMENT || 'dev' },
            { Name: 'InstanceId', Value: process.env.INSTANCE_ID || 'unknown' }
          ]
        },
        {
          MetricName: 'AverageLatency',
          Value: avgDuration,
          Unit: 'Milliseconds',
          Timestamp: new Date(),
          Dimensions: [
            { Name: 'Environment', Value: process.env.ENVIRONMENT || 'dev' },
            { Name: 'InstanceId', Value: process.env.INSTANCE_ID || 'unknown' }
          ]
        },
        {
          MetricName: 'MaxLatency',
          Value: metrics.maxDuration,
          Unit: 'Milliseconds',
          Timestamp: new Date(),
          Dimensions: [
            { Name: 'Environment', Value: process.env.ENVIRONMENT || 'dev' },
            { Name: 'InstanceId', Value: process.env.INSTANCE_ID || 'unknown' }
          ]
        },
        {
          MetricName: 'MinLatency',
          Value: metrics.minDuration === Infinity ? 0 : metrics.minDuration,
          Unit: 'Milliseconds',
          Timestamp: new Date(),
          Dimensions: [
            { Name: 'Environment', Value: process.env.ENVIRONMENT || 'dev' },
            { Name: 'InstanceId', Value: process.env.INSTANCE_ID || 'unknown' }
          ]
        },
        {
          MetricName: 'ErrorCount',
          Value: metrics.errorCount,
          Unit: 'Count',
          Timestamp: new Date(),
          Dimensions: [
            { Name: 'Environment', Value: process.env.ENVIRONMENT || 'dev' },
            { Name: 'InstanceId', Value: process.env.INSTANCE_ID || 'unknown' }
          ]
        }
      ]
    };

    await cloudwatch.putMetricData(params).promise();
    console.log(`[METRICS] Sent to CloudWatch: requests=${metrics.requestCount}, avg_latency=${avgDuration}ms, errors=${metrics.errorCount}`);

    // Reset counters after sending
    metrics.requestCount = 0;
    metrics.errorCount = 0;
    metrics.totalDuration = 0;
    metrics.maxDuration = 0;
    metrics.minDuration = Infinity;
    metrics.statusCodes = {};

  } catch (error) {
    console.error('[ERROR] Failed to send metrics to CloudWatch:', error.message);
  }
}

/**
 * Send startup metric
 */
async function sendStartupMetric() {
  try {
    const params = {
      Namespace: 'CustomApp/Events',
      MetricData: [
        {
          MetricName: 'AppStartup',
          Value: 1,
          Unit: 'Count',
          Timestamp: new Date(),
          Dimensions: [
            { Name: 'Environment', Value: process.env.ENVIRONMENT || 'dev' },
            { Name: 'InstanceId', Value: process.env.INSTANCE_ID || 'unknown' }
          ]
        }
      ]
    };

    await cloudwatch.putMetricData(params).promise();
    console.log(`[STARTUP] App started - Instance: ${process.env.INSTANCE_ID}, AZ: ${process.env.AZ}`);

  } catch (error) {
    console.error('[ERROR] Failed to send startup metric:', error.message);
  }
}

/**
 * Send error metric to CloudWatch
 */
async function sendErrorMetric(errorType) {
  try {
    const params = {
      Namespace: 'CustomApp/Errors',
      MetricData: [
        {
          MetricName: 'Error',
          Value: 1,
          Unit: 'Count',
          Timestamp: new Date(),
          Dimensions: [
            { Name: 'Environment', Value: process.env.ENVIRONMENT || 'dev' },
            { Name: 'InstanceId', Value: process.env.INSTANCE_ID || 'unknown' },
            { Name: 'ErrorType', Value: errorType }
          ]
        }
      ]
    };

    await cloudwatch.putMetricData(params).promise();

  } catch (error) {
    console.error('[ERROR] Failed to send error metric:', error.message);
  }
}

// ============ Request Tracking Middleware ============
app.use((req, res, next) => {
  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;

    // Update metrics
    metrics.requestCount++;
    metrics.totalDuration += duration;
    metrics.maxDuration = Math.max(metrics.maxDuration, duration);
    metrics.minDuration = Math.min(metrics.minDuration, duration);

    // Track status codes
    const statusCode = res.statusCode;
    metrics.statusCodes[statusCode] = (metrics.statusCodes[statusCode] || 0) + 1;

    // Track errors
    if (statusCode >= 400) {
      metrics.errorCount++;
      sendErrorMetric(`HTTP_${statusCode}`);
    }

    // Log request
    console.log(
      `[${new Date().toISOString()}] ${req.method} ${req.path} - Status: ${statusCode} - Duration: ${duration}ms`
    );
  });

  next();
});

// ============ Routes ============

/**
 * Main endpoint - HTML page
 */
app.get('/', (req, res) => {
  const instanceId = process.env.INSTANCE_ID || 'unknown';
  const az = process.env.AZ || 'unknown';
  const environment = process.env.ENVIRONMENT || 'dev';

  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>AWS 3-Tier App</title>
        <style>
          body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            text-align: center; 
            padding: 50px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            margin: 0;
            color: #333;
          }
          .container {
            background: white;
            border-radius: 10px;
            padding: 40px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            max-width: 600px;
            margin: 0 auto;
          }
          h1 { 
            color: #667eea;
            margin: 0 0 10px 0;
            font-size: 2.5em;
          }
          .subtitle {
            color: #666;
            font-size: 1.1em;
            margin-bottom: 30px;
          }
          .badge { 
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            color: white; 
            padding: 12px 24px; 
            border-radius: 25px; 
            font-size: 0.95em;
            display: inline-block;
            margin: 10px 0;
            font-weight: bold;
          }
          .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-top: 30px;
            text-align: left;
          }
          .info-item {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #667eea;
          }
          .info-label {
            color: #666;
            font-size: 0.9em;
            margin-bottom: 5px;
          }
          .info-value {
            color: #333;
            font-size: 1.1em;
            font-weight: bold;
            font-family: 'Courier New', monospace;
            word-break: break-all;
          }
          .status {
            margin-top: 30px;
            padding: 20px;
            background: #d4edda;
            border: 1px solid #c3e6cb;
            border-radius: 5px;
            color: #155724;
          }
          .tech-stack {
            margin-top: 20px;
            text-align: left;
          }
          .tech-stack h3 {
            color: #667eea;
            margin-bottom: 10px;
          }
          .tech-list {
            list-style: none;
            padding: 0;
          }
          .tech-list li {
            padding: 5px 0;
            color: #555;
          }
          .tech-list li:before {
            content: "✓ ";
            color: #28a745;
            font-weight: bold;
            margin-right: 10px;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🚀 AWS 3-Tier Application</h1>
          <p class="subtitle">Terraform + Docker + GitHub Actions + CloudWatch</p>
          
          <div class="badge">✨ Production Ready Infrastructure ✨</div>

          <div class="info-grid">
            <div class="info-item">
              <div class="info-label">Instance ID</div>
              <div class="info-value">${instanceId}</div>
            </div>
            <div class="info-item">
              <div class="info-label">Availability Zone</div>
              <div class="info-value">${az}</div>
            </div>
            <div class="info-item">
              <div class="info-label">Environment</div>
              <div class="info-value">${environment}</div>
            </div>
            <div class="info-item">
              <div class="info-label">Load Balancer</div>
              <div class="info-value">✓ Behind ALB</div>
            </div>
          </div>

          <div class="status">
            <strong>✓ Status: HEALTHY</strong><br>
            App is running and monitored with CloudWatch
          </div>

          <div class="tech-stack">
            <h3>🛠️ Technology Stack</h3>
            <ul class="tech-list">
              <li>AWS EC2 with Auto Scaling</li>
              <li>Application Load Balancer</li>
              <li>Docker Containerization</li>
              <li>AWS ECR (Elastic Container Registry)</li>
              <li>RDS MySQL Database</li>
              <li>CloudWatch Monitoring & Logs</li>
              <li>Terraform Infrastructure as Code</li>
              <li>GitHub Actions CI/CD</li>
            </ul>
          </div>
        </div>
      </body>
    </html>
  `);
});

/**
 * Health check endpoint - used by ALB
 */
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy',
    instanceId: process.env.INSTANCE_ID || 'unknown',
    timestamp: new Date().toISOString()
  });
});

/**
 * Metrics endpoint - view current metrics
 */
app.get('/metrics', (req, res) => {
  const avgDuration = metrics.requestCount > 0 
    ? Math.round(metrics.totalDuration / metrics.requestCount)
    : 0;

  res.json({
    metrics: {
      requestCount: metrics.requestCount,
      errorCount: metrics.errorCount,
      averageLatency: `${avgDuration}ms`,
      maxLatency: `${metrics.maxDuration}ms`,
      minLatency: `${metrics.minDuration === Infinity ? 0 : metrics.minDuration}ms`,
      statusCodes: metrics.statusCodes
    },
    instance: {
      instanceId: process.env.INSTANCE_ID || 'unknown',
      az: process.env.AZ || 'unknown',
      environment: process.env.ENVIRONMENT || 'dev'
    },
    timestamp: new Date().toISOString()
  });
});

/**
 * Test endpoint - for load testing
 */
app.get('/test', (req, res) => {
  // Simulate some processing
  const delay = Math.random() * 100;
  setTimeout(() => {
    res.json({ message: 'Test endpoint', delay: `${delay.toFixed(2)}ms` });
  }, delay);
});

/**
 * Error handling middleware
 */
app.use((err, req, res, next) => {
  console.error('[ERROR]', err.message);
  sendErrorMetric('UNHANDLED_ERROR');
  res.status(500).json({ 
    error: 'Internal Server Error',
    message: err.message
  });
});

// ============ Server Startup ============
app.listen(PORT, async () => {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`[START] Server running on port ${PORT}`);
  console.log(`[INFO] Instance ID: ${process.env.INSTANCE_ID || 'unknown'}`);
  console.log(`[INFO] Availability Zone: ${process.env.AZ || 'unknown'}`);
  console.log(`[INFO] Environment: ${process.env.ENVIRONMENT || 'dev'}`);
  console.log(`[INFO] Region: ${process.env.AWS_REGION || 'us-east-1'}`);
  console.log(`${'='.repeat(60)}\n`);

  // Send startup metric
  await sendStartupMetric();

  // Send metrics to CloudWatch every 60 seconds
  setInterval(async () => {
    if (metrics.requestCount > 0) {
      await sendMetricsToCloudWatch();
    }
  }, 60000);  // 60 seconds
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('\n[SHUTDOWN] Received SIGTERM, shutting down gracefully...');
  
  // Send final metrics before shutdown
  if (metrics.requestCount > 0) {
    await sendMetricsToCloudWatch();
  }
  
  process.exit(0);
});