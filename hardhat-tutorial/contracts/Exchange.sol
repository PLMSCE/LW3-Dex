//SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20{

    address public cryptoDevTokenAddress;

    constructor(address _cryptoDevToken) ERC20 ("Crypto Dev Token", "CD") {
        require(_cryptoDevToken != address(0), "Address passed is a null address");
        cryptoDevTokenAddress = _cryptoDevToken;
    }
    function getReserve() public view returns(uint){
        return ERC20(cryptoDevTokenAddress).balanceOf(address(this));
    }

    // this is the x*y=k formula that was taught in the previous lesson in effect.
    // (LP tokens to be sent to the user (liquidity) / totalSupply of LP tokens in contract) = (Eth sent by the user) / (Eth reserve in the contract).

    function addLiquidity(uint _amount) public payable returns(uint){
        uint liquidity;
        uint ethBalance = address(this).balance;
        uint cryptoDevTokenReserve = getReserve();
        ERC20 cryptoDevToken = ERC20(cryptoDevTokenAddress);

        if (cryptoDevTokenReserve == 0) {
            cryptoDevToken.transferFrom(msg.sender, address(this), _amount);
            liquidity = ethBalance - msg.value;
            _mint(msg.sender, liquidity);
        } else {
            uint ethReserve = ethBalance - msg.value;
            uint cryptoDevTokenAmount = (msg.value * cryptoDevTokenReserve)/(ethReserve);
            require(_amount >= cryptoDevTokenAmount, "Amount of provided tokens is less than required amount");
            cryptoDevToken.transferFrom(msg.sender, address(this), cryptoDevTokenAmount);
            liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint (msg.sender, liquidity);
        }
        return liquidity;
    }
    //removing liquidity from the contract.abi
    //(Crypto Dev sent back to the user) / (current Crypto Dev token reserve) = (amount of LP tokens that user wants to withdraw) / (total supply of LP tokens).

    function removelLiquidity(uint _amount) public returns(uint, uint){
        require(_amount > 0, "No Liquidity to withdrawl.");
        uint ethReserve = address(this).balance;
        uint _totalSupply = totalSupply();

        uint ethAmount = (ethReserve * _amount) / _totalSupply;
        uint cryptoDevTokenAmount = (getReserve() * _amount)/ _totalSupply;
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        ERC20 (cryptoDevTokenAddress).transfer(msg.sender, cryptoDevTokenAmount);
        return(ethAmount, cryptoDevTokenAmount);
    }
    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve)
        public pure returns(uint256){
        require(inputReserve > 0 && outputReserve >0, "invalid reserves");
        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
        return numerator / denominator;
        }

    function ethToCryptoDevToken(uint _minTokens) public payable {
        uint tokenReserve = getReserve();
        uint256 tokensBought = getAmountOfTokens(
            msg.value, address(this).balance - msg.value, tokenReserve
        );
        require(tokensBought >= _minTokens, "insufficent output amount");
        ERC20(cryptoDevTokenAddress).transfer(msg.sender, tokensBought);
    }
    function cryptoDevTokenToEth(uint _tokenSold, uint _minEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmountOfTokens(
            _tokenSold,
            tokenReserve,
            address(this).balance
        );
        require(ethBought >= _minEth, "insufficent output amount");
        ERC20(cryptoDevTokenAddress).transferFrom
            (msg.sender,
            address(this),
            _tokenSold
        );
        payable(msg.sender).transfer(ethBought);
    }



}