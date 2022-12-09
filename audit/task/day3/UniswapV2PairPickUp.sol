
/**
 * UniswapV2Pairコントラクト
 * IUniswapV2Pair, UniswapV2ERC20を継承している。
 */
contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {

    // uint型にSafeMathライブラリを適用させる。
    using SafeMath  for uint;
    // unit224型にUQ112x112ライブラリを適用させる。
    using UQ112x112 for uint224;

    /**
     * リエントランシーを防ぐためのlock修飾子
     */
    modifier lock() {
        // unlockedの値が1がどうかをチェックする。
        require(unlocked == 1, 'UniswapV2: LOCKED');
        // 0にする。(lock状態)
        unlocked = 0;
        _;
        // 1にする。(lock解除)
        unlocked = 1;
    }

    /**
     * getReservesメソッド    
     */
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        // 引数 _reserve0を代入する
        _reserve0 = reserve0;
        // 引数 _reserve1を代入する
        _reserve1 = reserve1;
        // 引数 _blockTimestampLastを代入する
        _blockTimestampLast = blockTimestampLast;
    }

    /**
     * update メソッド
     * update reserves and, on the first call per block, price accumulators
     */
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        // 引数として渡されたbalance0とbalance1の値がoverflowしないかチェックする。
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
        // ブロックタイムスタンプを2で割り、その値を32回掛け算した値を代入する。
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        // どのくらい時間が経過したのか算出する。(overflowを防ぐ)
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        // 前回更新されてから未来であること、およびリザーブの値が0ではない場合に中身の処理を実行する。
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            // 不明・・。
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        // 引数balance0をuint112にリキャストしてreserve0にセットする。
        reserve0 = uint112(balance0);
        // 引数balance1をuint112にリキャストしてreserve1にセットする。
        reserve1 = uint112(balance1);
        // blockTimestampLastの値を更新する。
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    /**
     * mint関数
     * @param to mint先アドレス
     * @return liquidity 流動性トークン発行量
     */
    function mint(address to) external lock returns (uint liquidity) {
        // 現在保有しているリザーブの値を取得する。
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); 
        // このコントラクトが保有しているtoken0の残高を取得する。
        uint balance0 = IERC20(token0).balanceOf(address(this));
        // このコントラクトが保有しているtoken1の残高を取得する。
        uint balance1 = IERC20(token1).balanceOf(address(this));
        // それぞれの残高の値からリザーブの値を減算する。
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);
        // リザーブの値からmint手数料が発生するかチェックする。
        bool feeOn = _mintFee(_reserve0, _reserve1);
        // gas savings, must be defined here since totalSupply can update in _mintFee
        // 総供給量を取得する。
        uint _totalSupply = totalSupply;

        // 供給量が0の場合 
        if (_totalSupply == 0) {
            // リクイディティを算出する。
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            // permanently lock the first MINIMUM_LIQUIDITY tokens
            // 流動性トークンを発行する。(発行量は定数により定義された分)
           _mint(address(0), MINIMUM_LIQUIDITY); 
        } else { // 0以外である場合
            // リクイディティを算出する。
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        // リクイディテイが0以上であることをチェックする。
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        // 流動性トークンをliquidity分だけtoアドレスに発行する。
        _mint(to, liquidity);
        // _update関数を呼び出してリザーブなどの情報を更新する。
        _update(balance0, balance1, _reserve0, _reserve1);
        // もし feeOnがtrueであれば、kLastの値を更新する。
        if (feeOn) kLast = uint(reserve0).mul(reserve1); 
        // イベント発行
        emit Mint(msg.sender, amount0, amount1);
    }

    /**
     * burn関数
     * @param to トークンを償却するアドレス
     * @return amount0 
     * @return amount1 
     */
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        // 現在保有しているリザーブの値を取得する。
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); 
        // トークン0の値を取得する。(ガス最適化)
        address _token0 = token0;  
        // トークン1の値を取得する。(ガス最適化)                             
        address _token1 = token1;                      
        // このコントラクトが保有しているtoken0の残高を取得する。          
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        // このコントラクトが保有しているtoken1の残高を取得する。
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        // このコントラクトの流動性トークンの残高を取得する。
        uint liquidity = balanceOf[address(this)];
        // 手数料が発生するかチェックする。
        bool feeOn = _mintFee(_reserve0, _reserve1);
        // 総供給量の値をセットする。
        uint _totalSupply = totalSupply; 

        // liquidityと残高の値をかけて、総供給量の値で割ることで、償却先に移転させるトークン量を算出する
        amount0 = liquidity.mul(balance0) / _totalSupply; 
        // liquidityと残高の値をかけて、総供給量の値で割ることで、償却先に移転させるトークン量を算出する
        amount1 = liquidity.mul(balance1) / _totalSupply; 

        // 移転させるトークン0とトークン１の量が0以上であることをチェックする。
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        // liquidity分だけ流動性トークンを償却する。
        _burn(address(this), liquidity);
        // 償却先に移転する。
        _safeTransfer(_token0, to, amount0);
        // 償却先に移転する。
        _safeTransfer(_token1, to, amount1);
        // このコントラクトが保有しているtoken0の残高を取得する。          
        balance0 = IERC20(_token0).balanceOf(address(this));
        // このコントラクトが保有しているtoken1の残高を取得する。          
        balance1 = IERC20(_token1).balanceOf(address(this));
        // リザーブなどの情報を更新する。
        _update(balance0, balance1, _reserve0, _reserve1);
        // もし feeOnがtrueであれば、kLastの値を更新する。
        if (feeOn) kLast = uint(reserve0).mul(reserve1); 
        // イベント発行
        emit Burn(msg.sender, amount0, amount1, to);
    }

    /**
     * swap 関数
     * @param amount0Out スワップするトークン0の量
     * @param amount1Out スワップするトークン1の量
     * @param to スワップするトークンを移転する先のアドレス
     * @param data コールデータ
     */
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        // スワップするトークンの量が両方とも0より大きいことを確認する。
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        // リザーブの情報を取得する。(ガス最適化)
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        // スワップするトークンの量が両方ともリザーブしている以上の値でないことをチェックする。
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        // トークン0とトークン1の残高を格納するための変数
        uint balance0;
        uint balance1;

        { // scope for _token{0,1}, avoids stack too deep errors
            // トークン0とトークン１のアドレスを取得する。
            address _token0 = token0;
            address _token1 = token1;
            // toアドレスがトークン0とトークン1のアドレスのどちらでもないことをチェックする。
            require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
            // スワップするトークンの量が0より大きければ amount0Out分だけtoアドレスに移転する。
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            // スワップするトークンの量が0より大きければ amount1Out分だけtoアドレスに移転する。
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            // もしコールデータが存在するすればuniswapV2Call関数を利用してコールデータにセットされている内容を実行する。
            if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
            // このコントラクトが保有しているtoken0の残高を取得する。
            balance0 = IERC20(_token0).balanceOf(address(this));
            // このコントラクトが保有しているtoken1の残高を取得する。
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        // 現在の残高がトークン移転後のリザーブの値よりも大きい場合は、残高から移転後のリザーブの値を引いた値をセットする。そうでなければ0をセットする。
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        // amount0Inとamount1Inの両方が0よりも大きいことを確認する。
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');

        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            // 残高調整量を算出する(不明)
            uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            // 想定の範囲内かをチェックする(不明)
            require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        }

        // リザーブなどの情報を更新する。
        _update(balance0, balance1, _reserve0, _reserve1);
        // イベントの発行
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }
}