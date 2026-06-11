const AWS = require('aws-sdk');

const cloudwatch = new AWS.CloudWatch({
  region: process.env.AWS_REGION || 'us-east-1'
});

/**
 * Send custom metric to CloudWatch
 */
async function putMetric(metricName, value, unit = 'Count') {
  try {
    await cloudwatch.putMetricData({
      Namespace: 'CustomApp/Metrics',
      MetricData: [
        {
          MetricName: metricName,
          Value: value,
          Unit: unit,
          Timestamp: new Date(),
          Dimensions: [
            {
              Name: 'Environment',
              Value: process.env.ENVIRONMENT || 'dev'
            },
            {
              Name: 'InstanceId',
              Value: process.env.INSTANCE_ID || 'unknown'
            }
          ]
        }
      ]
    }).promise();

    console.log(`Metric sent: ${metricName}=${value} ${unit}`);
  } catch (error) {
    console.error(`Failed to put metric ${metricName}:`, error.message);
  }
}

module.exports = { putMetric };