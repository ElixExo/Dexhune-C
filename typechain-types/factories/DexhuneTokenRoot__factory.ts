/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import {
  Contract,
  ContractFactory,
  ContractTransactionResponse,
  Interface,
} from "ethers";
import type { Signer, ContractDeployTransaction, ContractRunner } from "ethers";
import type { NonPayableOverrides } from "../common";
import type {
  DexhuneTokenRoot,
  DexhuneTokenRootInterface,
} from "../DexhuneTokenRoot";

const _abi = [
  {
    inputs: [],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [],
    name: "ExchangeAddressNotSet",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "addr",
        type: "address",
      },
      {
        internalType: "int128",
        name: "balance",
        type: "int128",
      },
    ],
    name: "InvalidBalance",
    type: "error",
  },
  {
    inputs: [],
    name: "MintLimitReached",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "timeRemaining",
        type: "uint256",
      },
    ],
    name: "MintedTooEarly",
    type: "error",
  },
  {
    inputs: [],
    name: "PriceDaoAddressNotSet",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "UnauthorizedAccount",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "addr",
        type: "address",
      },
      {
        indexed: false,
        internalType: "int128",
        name: "funds",
        type: "int128",
      },
    ],
    name: "Alloc",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    name: "_holders",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "daoMintingStartsAfter",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "exchangeMintingStartsAfter",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getOwner",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "mint",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "mintToDao",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "mintToExchange",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "mintingStartsAfter",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "addr",
        type: "address",
      },
    ],
    name: "setDaoAddress",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "addr",
        type: "address",
      },
    ],
    name: "setExchangeAddress",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x60806040526000600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506000600260006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506000600660006101000a8154816fffffffffffffffffffffffffffffffff0219169083600f0b6fffffffffffffffffffffffffffffffff1602179055506000600660106101000a81548161ffff021916908360010b61ffff1602179055506000600755600060085560006009553480156200010257600080fd5b50336000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506298968060030b600660006101000a8154816fffffffffffffffffffffffffffffffff0219169083600f0b6fffffffffffffffffffffffffffffffff160217905550620001c660008054906101000a900473ffffffffffffffffffffffffffffffffffffffff16600660009054906101000a9004600f0b620001cc60201b60201c565b6200045d565b600081600f0b12156200021a5781816040517f489b499a0000000000000000000000000000000000000000000000000000000081526004016200021192919062000430565b60405180910390fd5b600081600f0b036200024a577fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff90505b6000600560008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a9004600f0b9050600081600f0b148015620002d157507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff82600f0b145b15620002de5750620003c9565b600081600f0b036200034e576004839080600181540180825580915050600190039060005260206000200160009091909190916101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505b81600560008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a8154816fffffffffffffffffffffffffffffffff0219169083600f0b6fffffffffffffffffffffffffffffffff160217905550505b5050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000620003fa82620003cd565b9050919050565b6200040c81620003ed565b82525050565b600081600f0b9050919050565b6200042a8162000412565b82525050565b600060408201905062000447600083018562000401565b6200045660208301846200041f565b9392505050565b6111c3806200046d6000396000f3fe608060405234801561001057600080fd5b506004361061009e5760003560e01c80639a3cac6a116100665780639a3cac6a146100fd578063d082ea8c14610119578063d20a02cf14610135578063dd2cec7f14610153578063f8f4c343146101835761009e565b80631249c58b146100a35780631275d2a9146100ad5780633808721d146100cb5780636f01f40e146100d5578063893d20e8146100df575b600080fd5b6100ab6101a1565b005b6100b5610493565b6040516100c29190610d2f565b60405180910390f35b6100d36104c2565b005b6100dd6105ed565b005b6100e7610717565b6040516100f49190610d8b565b60405180910390f35b61011760048036038101906101129190610dd7565b610740565b005b610133600480360381019061012e9190610dd7565b6107eb565b005b61013d610896565b60405161014a9190610d2f565b60405180910390f35b61016d60048036038101906101689190610e30565b6108c5565b60405161017a9190610d8b565b60405180910390f35b61018b610904565b6040516101989190610d2f565b60405180910390f35b610e4260010b600660109054906101000a900460010b60010b126101f1576040517f303b682f00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b60075442101561024557600754426102099190610e8c565b6040517ff461f5dd00000000000000000000000000000000000000000000000000000000815260040161023c9190610d2f565b60405180910390fd5b6006601081819054906101000a900460010b8092919061026490610ecd565b91906101000a81548161ffff021916908360010b61ffff160217905550506205460063ffffffff16426102979190610ef7565b6007819055506000600660009054906101000a9004600f0b90506000612710600c60000b836102c69190610f38565b6102d09190610fa4565b905060006102dd82610933565b9050600081836102ed919061100e565b9050600081600f0b131561043657600073ffffffffffffffffffffffffffffffffffffffff16600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16146103825761037d600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1682610af4565b610435565b600073ffffffffffffffffffffffffffffffffffffffff16600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff161461040957610404600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1682610af4565b610434565b61043360008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1682610af4565b5b5b5b82600660008282829054906101000a9004600f0b6104549190611076565b92506101000a8154816fffffffffffffffffffffffffffffffff0219169083600f0b6fffffffffffffffffffffffffffffffff16021790555050505050565b6000804290508060095410156104ad5760009150506104bf565b806009546104bb9190610e8c565b9150505b90565b42600854111561051657426008546104da9190610e8c565b6040517ff461f5dd00000000000000000000000000000000000000000000000000000000815260040161050d9190610d2f565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff16600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff160361059e576040517f4cfe894800000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b6201518063ffffffff16426105b39190610ef7565b6008819055506105eb600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16620493e060030b610af4565b565b60095442101561064157600954426106059190610e8c565b6040517ff461f5dd0000000000000000000000000000000000000000000000000000000081526004016106389190610d2f565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff16600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16036106c9576040517f37a7527b00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b6201518063ffffffff16426106de9190610ef7565b600981905550610715600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1661168060030b610af4565b565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905090565b610748610c40565b80600260006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550600073ffffffffffffffffffffffffffffffffffffffff16600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16146107e8576107e7610cd2565b5b50565b6107f3610c40565b80600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550600073ffffffffffffffffffffffffffffffffffffffff16600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff161461089357610892610cd2565b5b50565b6000804290508060085410156108b05760009150506108c2565b806008546108be9190610e8c565b9150505b90565b600481815481106108d557600080fd5b906000526020600020016000915054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60008042905080600754101561091e576000915050610930565b8060075461092c9190610e8c565b9150505b90565b600080600080600080600090505b600480549050811015610ae75760048181548110610962576109616110de565b5b9060005260206000200160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff169450600560008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a9004600f0b9350600660009054906101000a9004600f0b87856109fa9190610f38565b610a049190610fa4565b92508284610a129190611076565b93508282610a209190611076565b915083600560008773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a8154816fffffffffffffffffffffffffffffffff0219169083600f0b6fffffffffffffffffffffffffffffffff1602179055507fb71bcb8fffeb745df80831753390e133c8b6549b8be2c5ae6a203b0ec87d4cf28585604051610acc92919061111c565b60405180910390a18080610adf90611145565b915050610941565b5080945050505050919050565b6000600560008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a9004600f0b9050600081600f0b03610bb4576004839080600181540180825580915050600190039060005260206000200160009091909190916101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505b8181610bc09190611076565b905080600560008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a8154816fffffffffffffffffffffffffffffffff0219169083600f0b6fffffffffffffffffffffffffffffffff160217905550505050565b60008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610cd057336040517f32b2baa3000000000000000000000000000000000000000000000000000000008152600401610cc79190610d8b565b60405180910390fd5b565b61dead6000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550565b6000819050919050565b610d2981610d16565b82525050565b6000602082019050610d446000830184610d20565b92915050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000610d7582610d4a565b9050919050565b610d8581610d6a565b82525050565b6000602082019050610da06000830184610d7c565b92915050565b600080fd5b610db481610d6a565b8114610dbf57600080fd5b50565b600081359050610dd181610dab565b92915050565b600060208284031215610ded57610dec610da6565b5b6000610dfb84828501610dc2565b91505092915050565b610e0d81610d16565b8114610e1857600080fd5b50565b600081359050610e2a81610e04565b92915050565b600060208284031215610e4657610e45610da6565b5b6000610e5484828501610e1b565b91505092915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b6000610e9782610d16565b9150610ea283610d16565b9250828203905081811115610eba57610eb9610e5d565b5b92915050565b60008160010b9050919050565b6000610ed882610ec0565b9150617fff8203610eec57610eeb610e5d565b5b600182019050919050565b6000610f0282610d16565b9150610f0d83610d16565b9250828201905080821115610f2557610f24610e5d565b5b92915050565b600081600f0b9050919050565b6000610f4382610f2b565b9150610f4e83610f2b565b9250828202610f5c81610f2b565b9150808214610f6e57610f6d610e5d565b5b5092915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601260045260246000fd5b6000610faf82610f2b565b9150610fba83610f2b565b925082610fca57610fc9610f75565b5b600160000383147fffffffffffffffffffffffffffffffff800000000000000000000000000000008314161561100357611002610e5d565b5b828205905092915050565b600061101982610f2b565b915061102483610f2b565b925082820390506f7fffffffffffffffffffffffffffffff81137fffffffffffffffffffffffffffffffff80000000000000000000000000000000821217156110705761106f610e5d565b5b92915050565b600061108182610f2b565b915061108c83610f2b565b925082820190507fffffffffffffffffffffffffffffffff8000000000000000000000000000000081126f7fffffffffffffffffffffffffffffff821317156110d8576110d7610e5d565b5b92915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b61111681610f2b565b82525050565b60006040820190506111316000830185610d7c565b61113e602083018461110d565b9392505050565b600061115082610d16565b91507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff820361118257611181610e5d565b5b60018201905091905056fea264697066735822122097c34bf39d3e0b8d2e5090a6302b958e8ae4c2f5cb08031c82c7dfc5149c3dec64736f6c63430008120033";

type DexhuneTokenRootConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: DexhuneTokenRootConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class DexhuneTokenRoot__factory extends ContractFactory {
  constructor(...args: DexhuneTokenRootConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override getDeployTransaction(
    overrides?: NonPayableOverrides & { from?: string }
  ): Promise<ContractDeployTransaction> {
    return super.getDeployTransaction(overrides || {});
  }
  override deploy(overrides?: NonPayableOverrides & { from?: string }) {
    return super.deploy(overrides || {}) as Promise<
      DexhuneTokenRoot & {
        deploymentTransaction(): ContractTransactionResponse;
      }
    >;
  }
  override connect(runner: ContractRunner | null): DexhuneTokenRoot__factory {
    return super.connect(runner) as DexhuneTokenRoot__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): DexhuneTokenRootInterface {
    return new Interface(_abi) as DexhuneTokenRootInterface;
  }
  static connect(
    address: string,
    runner?: ContractRunner | null
  ): DexhuneTokenRoot {
    return new Contract(address, _abi, runner) as unknown as DexhuneTokenRoot;
  }
}