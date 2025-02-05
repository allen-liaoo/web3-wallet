'use client'

import { ConnectButton } from '@rainbow-me/rainbowkit'
import { 
  useAccount, 
  useDisconnect, 
  useChains, 
  useChainId, 
  useSwitchChain,
  useSignMessage
} from 'wagmi'
import * as siwe from "siwe";
import { useEffect, useState } from 'react';

function createSiweMessage(address: string): string {
  const siweMessage = new siwe.SiweMessage({
    domain: "localhost:3000",
    address,
    statement: "Welcome to myawesomedapp. Please login to continue.",
    uri: "http://localhost:3000/signin",
    version: "1",
    chainId: 1,
    nonce: "07EwlNV39F7FRRqpu",
  });
  return siweMessage.prepareMessage();
}

export function Profile() {
  const { address, isConnected } = useAccount()
  // const { connect } = useConnect()
  const { disconnect } = useDisconnect()
  const chains = useChains()
  const chainId = useChainId()
  const { switchChain } = useSwitchChain()

  // SIWE state
  const [siweMessage, setSiweMessage] = useState("");
  
  useEffect(() => {
    if (address) {
      setSiweMessage(createSiweMessage(address));
    }
  }, [address]);

  // Regular message signing
  const { data: signature, error: signError, isPending: isSignPending, signMessage } = useSignMessage()

  // SIWE message signing
  const { 
    data: siweSignature, 
    error: siweError,
    isPending: isSiwePending,
    signMessage: signSiweMessage 
  } = useSignMessage()

  const handleSignMessage = () => {
    signMessage({ message: 'hello world!' })
  }

  const handleSignSiweMessage = () => {
    signSiweMessage({ message: siweMessage })
  }

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

        <div className="mt-10 flex flex-col gap-4 items-center">
        <button 
          onClick={handleSignMessage}
          disabled={isSignPending}
          className="px-4 py-2 border rounded-lg hover:bg-gray-100"
        >
          Sign Message
        </button>
        <button 
          onClick={handleSignSiweMessage}
          disabled={isSiwePending}
          className="px-4 py-2 border rounded-lg hover:bg-gray-100"
        >
          Sign SIWE Message
        </button>

        {/* {messageToSign && <div>Message: {messageToSign}</div>} */}
        {signature && <div>Signature: {signature}</div>}
        {signError && <div>Error: {signError.message}</div>}
        
        {/* {siweMessage && <div>SIWE Message: {siweMessage}</div>} */}
        {siweSignature && <div>SIWE Signature: {siweSignature}</div>}
        {siweError && <div>SIWE Error: {siweError.message}</div>}
      </div>
      </div>
    )
  }

  return (
    <div className="flex flex-col items-center gap-4">
      <div className="flex w-full justify-center items-center p-20">
        <ConnectButton chainStatus="icon" accountStatus="avatar" showBalance={false} />
      </div>
    </div>
  )
} 