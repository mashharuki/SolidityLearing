pragma solidity =0.5.16;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
// 2進固定小数点数を扱うためのライブラリ

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

/**
 * UQ112x112 ライブラリ
 */
library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    // UQ112x112 を uint112 で割って UQ112x112 を返す。
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}