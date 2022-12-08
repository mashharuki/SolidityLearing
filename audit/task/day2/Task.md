1. ERC20にはなかったERC721の関数は？
   - ownerOf
   - setApprovalForAll
   - supportsInterface
   - tokenURI
   - _baseURI
   - setApprovalForAll
   - isApprovalForAll
   - _ownerOf
   - _safeTransfer
   - _exists
   - _isApprovedOrOwner
   - _safemint
   - _checkOnERC721Received

2. ERC20とERC721のtransferの違いはなんでしょうか？

ERC20のtransferでは、トークンの残高のみの増減を操作するのに対して、ERC721ではowner addressとトークンIDの紐付けを操作する。

3. なぜその違いが起こるのでしょうか？

NFTの場合は、どのアドレスがどのIDのトークンを所有しているかという情報を管理することが重要だから

4. OpenZeppelin#ERC721の `_checkOnERC721Received` はどこで使われているでしょうか？
    - Source  
        [openzeppelin-contracts/ERC721.sol at master · OpenZeppelin/openzeppelin-contracts](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol)
        
    - _safeTransfer
    - _safeMint

5. なぜNFTを送信する`superSafeTransferFrom` は失敗したのでしょうか？

- If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
- GiveMeNFTは何も継承していないから

6. `_checkOnERC721Receive` を使用する目的はなんでしょうか？
誤ってEOA以外のアドレスに(コントラクトのアドレス)に送信してしまわないようにうするため。