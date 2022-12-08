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

1. ERC20とERC721のtransferの違いはなんでしょうか？

ERC20のtransferでは、トークンの残高のみの増減を操作するのに対して、ERC721ではowner addressとトークンIDの紐付けを操作する。

1. なぜその違いが起こるのでしょうか？

1. OpenZeppelin#ERC721の `_checkOnERC721Received` はどこで使われているでしょうか？
    - Source  
        [openzeppelin-contracts/ERC721.sol at master · OpenZeppelin/openzeppelin-contracts](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol)
        
    - _safeTransfer
    - _safeMint

1. なぜNFTを送信する`superSafeTransferFrom` は失敗したのでしょうか？


1. `_checkOnERC721Receive` を使用する目的はなんでしょうか？
誤ってEOA以外のアドレスに(コントラクトのアドレス)に送信してしまわないようにうするため。