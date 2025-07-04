import { PrismaClient } from '@prisma/client';

// Prisma client instance
let prisma: PrismaClient | null = null;

function getPrismaClient(): PrismaClient {
  if (!prisma) {
    prisma = new PrismaClient({
      log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
    });
  }
  return prisma;
}

// Get the Prisma client instance
export function getPrisma(): PrismaClient {
  return getPrismaClient();
}

// Close the Prisma client (useful for testing or cleanup)
export async function closePrisma(): Promise<void> {
  if (prisma) {
    await prisma.$disconnect();
    prisma = null;
  }
}

// Initialize database (create schema if needed)
export async function initializeDatabase(): Promise<void> {
  try {
    const prisma = getPrismaClient();
    
    // Test the connection
    await prisma.$queryRaw`SELECT 1`;
    console.log('Database connection test successful');
    
    // Check if the users table exists, if not create it
    const tableExists = await prisma.$queryRaw<Array<{ exists: boolean }>>`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'users'
      );
    `;
    
    console.log('Table exists check result:', tableExists);
    
    if (!tableExists[0].exists) {
      console.log('Creating users table...');
      
      // Create the users table with the schema from our Prisma schema
      await prisma.$executeRaw`
        CREATE TABLE "users" (
          "id" SERIAL NOT NULL,
          "wallet_address" VARCHAR(42) NOT NULL,
          "username" VARCHAR(255),
          "profile_picture_url" TEXT,
          "last_login_at" TIMESTAMP(3) NOT NULL,
          "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
          "updated_at" TIMESTAMP(3) NOT NULL,
          
          CONSTRAINT "users_pkey" PRIMARY KEY ("id")
        );
      `;
      
      // Create unique index on wallet_address
      await prisma.$executeRaw`
        CREATE UNIQUE INDEX "users_wallet_address_key" ON "users"("wallet_address");
      `;
      
      console.log('users table created successfully');
    } else {
      console.log('users table already exists');
    }
    
    console.log('Database initialization completed');
  } catch (error) {
    console.error('Error initializing database:', error);
    throw error;
  }
}

// User-related database operations
export const userOperations = {
  // Create or update user (used during authentication)
  async upsertUser(walletAddress: string, userData?: { username?: string; profilePictureUrl?: string }) {
    const prisma = getPrismaClient();
    
    try {
      // Try to upsert the user
      return await prisma.user.upsert({
        where: { walletAddress },
        update: {
          ...userData,
          lastLoginAt: new Date(), // Update last login timestamp
          updatedAt: new Date(),
        },
        create: {
          walletAddress,
          lastLoginAt: new Date(), // Set initial last login timestamp
          ...userData,
        },
      });
    } catch (error: unknown) {
      // If the error is about the table not existing, create it and retry
      if (
        (error as { code?: string })?.code === 'P2021' || 
        (error as { message?: string })?.message?.includes('relation "users" does not exist')
      ) {
        console.log('Users table does not exist, creating it...');
        await initializeDatabase();
        
        // Retry the upsert operation
        return await prisma.user.upsert({
          where: { walletAddress },
          update: {
            ...userData,
            lastLoginAt: new Date(),
            updatedAt: new Date(),
          },
          create: {
            walletAddress,
            lastLoginAt: new Date(),
            ...userData,
          },
        });
      }
      
      // Re-throw other errors
      throw error;
    }
  },

  // Get user by wallet address
  async getUserByWallet(walletAddress: string) {
    const prisma = getPrismaClient();
    return await prisma.user.findUnique({
      where: { walletAddress },
    });
  },

  // Get user by ID
  async getUserById(id: number) {
    const prisma = getPrismaClient();
    return await prisma.user.findUnique({
      where: { id },
    });
  },

  // Get users by last login time (useful for analytics)
  async getUsersByLastLogin(since: Date) {
    const prisma = getPrismaClient();
    return await prisma.user.findMany({
      where: {
        lastLoginAt: {
          gte: since,
        },
      },
      orderBy: {
        lastLoginAt: 'desc',
      },
    });
  },

  // Get recently active users (logged in within last X days)
  async getRecentlyActiveUsers(days: number = 7) {
    const prisma = getPrismaClient();
    const since = new Date();
    since.setDate(since.getDate() - days);
    
    return await prisma.user.findMany({
      where: {
        lastLoginAt: {
          gte: since,
        },
      },
      orderBy: {
        lastLoginAt: 'desc',
      },
    });
  },
}; 