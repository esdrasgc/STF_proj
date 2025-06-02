#!/bin/bash
set -e

# Update system packages
yum update -y
yum install -y git docker python3 python3-pip

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Create app directory
mkdir -p /app/STF_proj

# Clone the application repository
git clone https://github.com/yourusername/STF_proj.git /app/STF_proj
cd /app/STF_proj

# Create environment file
cat > .env << EOF
KAFKA_BROKER_HOST=${kafka_endpoint}
KAFKA_BROKER_PORT=9092
MONGO_INITDB_ROOT_USERNAME=${mongodb_username}
MONGO_INITDB_ROOT_PASSWORD=${mongodb_password}
MONGO_HOST=${mongodb_endpoint}
MONGO_PORT=27017
MONGO_DB=${mongodb_db}
INSTANCE_REGION=${region}
INSTANCE_ID=${replica_id}
EOF

# Install Python dependencies
pip3 install -r requirements.txt

# Create systemd service file for the worker
cat > /etc/systemd/system/coleta-aba.service << EOF
[Unit]
Description=STF Coleta Aba Worker
After=network.target

[Service]
User=root
WorkingDirectory=/app/STF_proj
ExecStart=/usr/bin/python3 coleta_aba.py
Restart=always
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
EnvironmentFile=/app/STF_proj/.env

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable coleta-aba
systemctl start coleta-aba

# Add metrics and logging configuration
cat > /etc/cloudwatch-agent-config.json << EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/app/STF_proj/coleta_aba.log",
            "log_group_name": "/stf-proj/coleta-aba",
            "log_stream_name": "{instance_id}-${region}-${replica_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "metrics_collected": {
      "cpu": {
        "resources": [
          "*"
        ],
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_user",
          "cpu_usage_system"
        ]
      },
      "memory": {
        "measurement": [
          "mem_used_percent"
        ]
      },
      "disk": {
        "resources": [
          "/"
        ],
        "measurement": [
          "disk_used_percent"
        ]
      }
    }
  }
}
EOF

# Install CloudWatch agent
yum install -y amazon-cloudwatch-agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/etc/cloudwatch-agent-config.json -s

echo "Instance setup completed"
