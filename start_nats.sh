#!/bin/bash
# Quick script to start NATS with Docker

echo "🚀 Starting NATS server..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if NATS container already exists
if docker ps -a | grep -q nats-dev; then
    echo "📦 NATS container exists. Starting it..."
    docker start nats-dev
else
    echo "📦 Creating and starting new NATS container..."
    docker run -d --name nats-dev -p 4222:4222 -p 8222:8222 nats:latest -js
fi

# Wait for NATS to be ready
sleep 2

echo "✅ NATS is running!"
echo "📡 NATS client port: 4222"
echo "🔍 NATS monitoring: http://localhost:8222"
echo ""
echo "To stop NATS: docker stop nats-dev"
echo "To remove NATS: docker rm nats-dev"
