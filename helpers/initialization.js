require("dotenv").config();
const config = require('../config.json')

const Web3 = require('web3')
let web3

if (!config.PROJECT_SETTINGS.isLocal) {
web3 = new Web3(`wss://polygon-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`)
} else {
    web3 = new Web3('ws://127.0.0.1:7545')
}

const IUniswapV2Router02 = require('@uniswap/v2-periphery/build/IUniswapV2Router02.json')
const IUniswapV2Factory = require("@uniswap/v2-core/build/IUniswapV2Factory.json")

const uFactory = new web3.eth.Contract(IUniswapV2Factory.abi, config.QUICKSWAP.FACTORY_ADDRESS) // QUICKSWAP FACTORY CONTRACT
const uRouter = new web3.eth.Contract(IUniswapV2Router02.abi, config.QUICKSWAP.V2_ROUTER_02_ADDRESS) // QUICKSWAP ROUTER CONTRACT
const sFactory = new web3.eth.Contract(IUniswapV2Factory.abi, config.SUSHISWAP.FACTORY_ADDRESS) // SUSHISWAP FACTORY CONTRACT
const sRouter = new web3.eth.Contract(IUniswapV2Router02.abi, config.SUSHISWAP.V2_ROUTER_02_ADDRESS) // SUSHISWAP ROUTER CONTRACT

const IArbitrage = require('../build/contracts/Arbitrage.json')
const arbitrage = new web3.eth.Contract(IArbitrage.abi, IArbitrage.networks[137].address);

module.exports = {
    uFactory,
    uRouter,
    sFactory,
    sRouter,
    web3,
    arbitrage
}