import NextAuth, { type DefaultSession } from 'next-auth';
import Credentials from 'next-auth/providers/credentials';
import { userOperations } from '@/lib/database';

declare module 'next-auth' {
  interface User {
    walletAddress: string;
    username: string;
    profilePictureUrl: string;
    lastLoginAt: Date;
  }

  interface Session {
    user: {
      walletAddress: string;
      username: string;
      profilePictureUrl: string;
      lastLoginAt: Date;
    } & DefaultSession['user'];
  }
}

// Auth configuration for Wallet Auth based sessions
// For more information on each option (and a full list of options) go to
// https://authjs.dev/getting-started/authentication/credentials
export const { handlers, signIn, signOut, auth } = NextAuth({
  secret: process.env.NEXTAUTH_SECRET,
  session: { strategy: 'jwt' },
  trustHost: true,
  debug: process.env.NODE_ENV === 'development',
  providers: [
    Credentials({
      name: 'World App Wallet',
      credentials: {
        walletAddress: { label: 'Wallet Address', type: 'text' },
        username: { label: 'Username', type: 'text' },
        profilePictureUrl: { label: 'Profile Picture URL', type: 'text' },
      },
      authorize: async (credentials) => {
        const { walletAddress, username, profilePictureUrl } = credentials as {
          walletAddress: string;
          username: string;
          profilePictureUrl: string;
        };
        if (!walletAddress) {
          console.log('No wallet address provided');
          return null;
        }

        // Store or update user in database
        const dbUser = await userOperations.upsertUser(
          walletAddress,
          {
            username: username || 'Anonymous',
            profilePictureUrl: profilePictureUrl || '',
          }
        );

        return {
          id: dbUser.id.toString(), // Use database ID as the user ID
          walletAddress: walletAddress,
          username: dbUser.username || 'Anonymous',
          profilePictureUrl: dbUser.profilePictureUrl || '',
          lastLoginAt: dbUser.lastLoginAt,
        };
      },
    }),
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.userId = user.id;
        token.walletAddress = user.walletAddress;
        token.username = user.username;
        token.profilePictureUrl = user.profilePictureUrl;
        token.lastLoginAt = user.lastLoginAt;
      }

      return token;
    },
    session: async ({ session, token }) => {
      if (token.userId) {
        session.user.id = token.userId as string;
        session.user.walletAddress = token.walletAddress as string;
        session.user.username = token.username as string;
        session.user.profilePictureUrl = token.profilePictureUrl as string;
        session.user.lastLoginAt = token.lastLoginAt as Date;
      }

      return session;
    },
  },
});
