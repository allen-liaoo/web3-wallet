"use client"

import { 
  // createConfig,
   WagmiProvider } from 'wagmi'
import { mainnet, sepolia } from 'wagmi/chains'
import { http } from 'viem'
// import { metaMask } from 'wagmi/connectors'
import {
  getDefaultConfig,
  RainbowKitProvider,
} from '@rainbow-me/rainbowkit';
import { Inter } from 'next/font/google'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import './globals.css'
import '@rainbow-me/rainbowkit/styles.css';

const rainbowkitConfig = getDefaultConfig({
  appName: 'My RainbowKit App',
  projectId: 'YOUR_PROJECT_ID',
  chains: [mainnet, sepolia],
  ssr: false, // If your dApp uses server side rendering (SSR)
  transports: {
    [mainnet.id]: http(`https://mainnet.infura.io/v3/${process.env.NEXT_METAMASK_API_KEY}`),
    [sepolia.id]: http(`https://sepolia.infura.io/v3/${process.env.NEXT_METAMASK_API_KEY}`)
  }
});

// Using rainbowkit makes wagmi's config unnecessary (and unusable). also don't need metaMask connector anymore
// const wagmiConfig = createConfig({
//   chains: [mainnet, sepolia],
//   connectors: [metaMask()],
//   transports: {
//     [mainnet.id]: http(`https://mainnet.infura.io/v3/${process.env.NEXT_MAINNET_API_KEY}`),
//     [sepolia.id]: http(`https://sepolia.infura.io/v3/${process.env.NEXT_SEPOLIA_API_KEY}`)
//   }
// })

const inter = Inter({ subsets: ['latin'] })
const queryClient = new QueryClient()

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <WagmiProvider config={rainbowkitConfig}>
          <QueryClientProvider client={queryClient}>
            <RainbowKitProvider>
              {children}
            </RainbowKitProvider>
          </QueryClientProvider>
        </WagmiProvider>
      </body>
    </html>
  )
}
