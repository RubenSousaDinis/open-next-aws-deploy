#!/usr/bin/env node

/**
 * Database initialization script
 * Run this after deploying to set up the database schema
 */

const { execSync } = require('child_process');
const path = require('path');

console.log('🗄️  Initializing database...');

try {
  // Generate Prisma client
  console.log('📦 Generating Prisma client...');
  execSync('npx prisma generate', { stdio: 'inherit' });

  // Push schema to database
  console.log('🚀 Pushing schema to database...');
  execSync('npx prisma db push', { stdio: 'inherit' });

  console.log('✅ Database initialized successfully!');
  console.log('📝 Users will be automatically registered when they authenticate with their wallet.');
} catch (error) {
  console.error('❌ Error initializing database:', error.message);
  process.exit(1);
} 