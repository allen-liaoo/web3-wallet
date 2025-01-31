'use client'

import { ConnectButton } from '@rainbow-me/rainbowkit'
import { useAccount, 
  // useConnect, 
  useDisconnect, useChains, useChainId, useSwitchChain } from 'wagmi'
// import { metaMask } from 'wagmi/connectors'

export function Profile() {
  const { address, isConnected } = useAccount()
  // const { connect } = useConnect()
  const { disconnect } = useDisconnect()
  const chains = useChains()
  const chainId = useChainId()
  const { switchChain } = useSwitchChain()

  // const handleConnect = async () => {
  //   connect({ connector: metaMask() })
  // }

  if (isConnected) {
    return (
      <div className="flex flex-col items-center gap-4">
        <p className="text-sm text-muted-foreground">
          Connected to {address?.slice(0, 6)}...{address?.slice(-4)}
        </p>
        <div className="flex flex-col gap-2">
          {chains.map((chain) => (
            <button
              key={chain.id}
              className="px-4 py-2 border rounded-lg hover:bg-gray-100 disabled:opacity-50"
              disabled={chain.id === chainId}
              onClick={() => switchChain({ chainId: chain.id })}
            >
              {chain.name} {chain.id === chainId && "(current)"}
            </button>
          ))}
        </div>
        <button 
          className="px-4 py-2 border rounded-lg hover:bg-gray-100"
          onClick={() => disconnect()}
        >
          Disconnect
        </button>
      </div>
    )
  }

  return (
    <div className="flex w-full justify-center items-center p-20">
      <ConnectButton chainStatus={"icon"} accountStatus={"avatar"} showBalance={false} />
    </div>
    // <button 
    //   className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
    //   onClick={handleConnect}
    // >
    //   Connect Wallet
    // </button>
  )
} 