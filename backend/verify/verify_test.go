// day 9
// go test .
package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

const address = "0x32e0556aeC41a34C3002a264f4694193EBCf44F7"
const msg = "Welcome to myawesomedapp.com. Please login to continue. Challenge: 0x32e0556aec41a34c3002a264f4694193ebcf44f7:1693724609"
const msgSignature = "0x53dd5375da3fb1cadb5b5bd27c6ee7a23c715ff6be1c8001a52b4d1e2bb206e078f337645e223899b38a908a68d19c71850e4a48dc8753de1c3c8cd401c72bbf1b"

const siweMessage = `localhost:3000 wants you to sign in with your Ethereum account:
0x32e0556aeC41a34C3002a264f4694193EBCf44F7

Welcome to myawesomedapp. Please login to continue.

URI: http://localhost:3000/signin
Version: 1
Chain ID: 1
Nonce: 07EwlNV39F7FRRqpu
Issued At: 2023-09-03T06:41:21.941Z`

const siweSignature = "0xf90048971fd8e50e1768386ea28139d9cc708d60b2b475407f6c1fb9bcad34df48f0d310d5eaf7a99b30f518ade8d712637f73681a372b461519c38ef3ab9f8e1b"

func TestVerifySignature(t *testing.T) {
	err := VerifySignature(address, msgSignature, msg)
	assert.Nil(t, err)

	err = VerifySignature(address, siweSignature, siweMessage)
	assert.Nil(t, err)
}

func TestVerifySiweSignature(t *testing.T) {
	nonce, err := VerifySiweSignature(address, siweSignature, siweMessage, "localhost:3000")
	assert.Nil(t, err)
	assert.Equal(t, "07EwlNV39F7FRRqpu", nonce)

	_, err = VerifySiweSignature(address, siweSignature, siweMessage, "localhost:3001")
	assert.NotNil(t, err)
	assert.Contains(t, err.Error(), "Message domain doesn't match")
}