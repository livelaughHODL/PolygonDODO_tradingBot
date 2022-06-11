//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IDODO {
    function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes calldata data
    ) external;

    function _BASE_TOKEN_() external view returns (address);
}

contract Arbitrage {
    IUniswapV2Router02 public immutable sRouter;
    IUniswapV2Router02 public immutable uRouter;

    address public owner;

    address public immutable flashLoanPool = 0x5333Eb1E32522F1893B7C9feA3c263807A02d561; //You will make a flashloan from this DODOV2 pool

    constructor(address _sRouter, address _uRouter) {
        sRouter = IUniswapV2Router02(_sRouter); // Sushiswap
        uRouter = IUniswapV2Router02(_uRouter); // Quickswap
        owner = msg.sender;
    }

     function executeTrade(
        bool _startOnQuickswap,
        address _token0,
        address _token1,
        uint256 _flashAmount
    ) external {
        uint256 balanceBefore = IERC20(_token0).balanceOf(address(this));

        bytes memory data = abi.encode(
            _startOnQuickswap,
            _token0,
            _token1,
            _flashAmount,
            balanceBefore
        );

        address flashLoanBase = IDODO(flashLoanPool)._BASE_TOKEN_();

        if (flashLoanBase == _token0) {
            IDODO(flashLoanPool).flashLoan(_flashAmount, 0, address(this), data);
        } else {
            IDODO(flashLoanPool).flashLoan(0, _flashAmount, address(this), data);
        }
    }

    // Note: CallBack function executed by DODOV2(DVM) flashLoan pool
    // Dodo Vending Machine Factory --> 0x79887f65f83bdf15Bcc8736b5e5BcDB48fb8fE13
    function DVMFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    // Note: CallBack function executed by DODOV2(DPP) flashLoan pool
    // Dodo Private Pool Factory --> 0xd24153244066F0afA9415563bFC7Ba248bfB7a51
    function DPPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    function _flashLoanCallBack(
        address sender,
        uint256,
        uint256,
        bytes calldata data
    ) internal {
        (
            bool startOnQuickswap, 
            address token0, 
            address token1,
            uint256 flashAmount
            
        ) = abi.decode(data, (bool, address, address, uint256));        

        require(
            sender == address(this) && msg.sender == flashLoanPool,
            "HANDLE_FLASH_NENIED"
        );

        // Note: Realize your own logic using the token from flashLoan pool.
        // Use the money here!
        address[] memory path = new address[](2);

        path[0] = token0;
        path[1] = token1;

        if (startOnQuickswap) {
            _swapOnQuickswap(path, flashAmount, 0);

            path[0] = token1;
            path[1] = token0;

            _swapOnSushiswap(
                path,
                IERC20(token1).balanceOf(address(this)),
                (flashAmount + 1)
            );
        } else {
            _swapOnSushiswap(path, flashAmount, 0);

            path[0] = token1;
            path[1] = token0;

            _swapOnQuickswap(
                path,
                IERC20(token1).balanceOf(address(this)),
                (flashAmount + 1)
            );
        }

        // Return funds
        IERC20(token0).transfer(flashLoanPool, flashAmount);

        IERC20(token0).transfer(
            owner,
            IERC20(token0).balanceOf(address(this))
        );
    }        

    // -- INTERNAL FUNCTIONS -- //

    function _swapOnQuickswap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _amountOut
    ) internal {
        require(
            IERC20(_path[0]).approve(address(uRouter), _amountIn),
            "Quickswap approval failed."
        );

        uRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOut,
            _path,
            address(this),
            (block.timestamp + 1200)
        );
    }

    function _swapOnSushiswap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _amountOut
    ) internal {
        require(
            IERC20(_path[0]).approve(address(sRouter), _amountIn),
            "Sushiswap approval failed."
        );

        sRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOut,
            _path,
            address(this),
            (block.timestamp + 1200)
        );
    }
}