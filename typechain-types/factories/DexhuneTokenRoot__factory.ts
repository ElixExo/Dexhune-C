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
  "0x60806040526000600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506000600260006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506000600660006101000a8154816fffffffffffffffffffffffffffffffff0219169083600f0b6fffffffffffffffffffffffffffffffff1602179055506000600660106101000a81548161ffff021916908360010b61ffff1602179055506000600755600060085560006009553480156200010257600080fd5b50336000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506298968060030b600660006101000a8154816fffffffffffffffffffffffffffffffff0219169083600f0b6fffffffffffffffffffffffffffffffff160217905550620001c660008054906101000a900473ffffffffffffffffffffffffffffffffffffffff16600660009054906101000a9004600f0b620001cc60201b60201c565b6200045d565b600081600f0b12156200021a5781816040517f489b499a0000000000000000000000000000000000000000000000000000000081526004016200021192919062000430565b60405180910390fd5b600081600f0b036200024a577fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff90505b6000600560008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a9004600f0b9050600081600f0b148015620002d157507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff82600f0b145b15620002de5750620003c9565b600081600f0b036200034e576004839080600181540180825580915050600190039060005260206000200160009091909190916101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505b81600560008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a8154816fffffffffffffffffffffffffffffffff0219169083600f0b6fffffffffffffffffffffffffffffffff160217905550505b5050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000620003fa82620003cd565b9050919050565b6200040c81620003ed565b82525050565b600081600f0b9050919050565b6200042a8162000412565b82525050565b600060408201905062000447600083018562000401565b6200045660208301846200041f565b9392505050565b610f63806200046d6000396000f3fe608060405234801561001057600080fd5b50600436106100625760003560e01c80631249c58b146100675780633808721d146100715780636f01f40e1461007b578063893d20e8146100855780639a3cac6a146100a3578063d082ea8c146100bf575b600080fd5b61006f6100db565b005b610079610221565b005b6100836103ce565b005b61008d61057a565b60405161009a9190610c96565b60405180910390f35b6100bd60048036038101906100b89190610ce2565b6105a3565b005b6100d960048036038101906100d49190610ce2565b61064e565b005b610e4260010b600660109054906101000a900460010b60010b1261012b576040517f303b682f00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b60075442101561017f57600754426101439190610d48565b6040517ff461f5dd0000000000000000000000000000000000000000000000000000000081526004016101769190610d8b565b60405180910390fd5b6205460063ffffffff16426101949190610da6565b6007819055506000600660009054906101000a9004600f0b905060006101bb82600c6106f9565b90506101c681610723565b80600660008282829054906101000a9004600f0b6101e49190610de7565b92506101000a8154816fffffffffffffffffffffffffffffffff0219169083600f0b6fffffffffffffffffffffffffffffffff1602179055505050565b60085442101561027557600854426102399190610d48565b6040517ff461f5dd00000000000000000000000000000000000000000000000000000000815260040161026c9190610d8b565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff16600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16036102fd576040517f4cfe894800000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b6201518063ffffffff16426103129190610da6565b600881905550600060056000600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a9004600f0b905062155cc060030b8161039d9190610de7565b90506103cb600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1682610892565b50565b60095442101561042257600954426103e69190610d48565b6040517ff461f5dd0000000000000000000000000000000000000000000000000000000081526004016104199190610d8b565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff16600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16036104aa576040517f37a7527b00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b6201518063ffffffff16426104bf9190610da6565b600981905550600060056000600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a9004600f0b905061168060030b816105499190610de7565b9050610577600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1682610892565b50565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905090565b6105ab610a8b565b80600260006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550600073ffffffffffffffffffffffffffffffffffffffff16600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff161461064b5761064a610b1d565b5b50565b610656610a8b565b80600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550600073ffffffffffffffffffffffffffffffffffffffff16600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16146106f6576106f5610b1d565b5b50565b600080610709848460000b610b61565b905061071781612710610bcc565b90508091505092915050565b60008060008060005b60048054905081101561088a576004818154811061074d5761074c610e4f565b5b9060005260206000200160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff169450600560008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a9004600f0b93506107e284600660009054906101000a9004600f0b610bcc565b92506107ee8387610b61565b915081846107fc9190610de7565b935083600560008773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a8154816fffffffffffffffffffffffffffffffff0219169083600f0b6fffffffffffffffffffffffffffffffff160217905550808061088290610e7e565b91505061072c565b505050505050565b600081600f0b12156108dd5781816040517f489b499a0000000000000000000000000000000000000000000000000000000081526004016108d4929190610ed5565b60405180910390fd5b600081600f0b0361090c577fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff90505b6000600560008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a9004600f0b9050600081600f0b14801561099257507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff82600f0b145b1561099d5750610a87565b600081600f0b03610a0c576004839080600181540180825580915050600190039060005260206000200160009091909190916101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505b81600560008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a8154816fffffffffffffffffffffffffffffffff0219169083600f0b6fffffffffffffffffffffffffffffffff160217905550505b5050565b60008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610b1b57336040517f32b2baa3000000000000000000000000000000000000000000000000000000008152600401610b129190610c96565b60405180910390fd5b565b61dead6000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550565b600080604083600f0b85600f0b02901d90507fffffffffffffffffffffffffffffffff80000000000000000000000000000000600f0b8112158015610bb957506f7fffffffffffffffffffffffffffffff600f0b8113155b610bc257600080fd5b8091505092915050565b60008082600f0b03610bdd57600080fd5b600082600f0b604085600f0b901b81610bf957610bf8610efe565b5b0590507fffffffffffffffffffffffffffffffff80000000000000000000000000000000600f0b8112158015610c4257506f7fffffffffffffffffffffffffffffff600f0b8113155b610c4b57600080fd5b8091505092915050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000610c8082610c55565b9050919050565b610c9081610c75565b82525050565b6000602082019050610cab6000830184610c87565b92915050565b600080fd5b610cbf81610c75565b8114610cca57600080fd5b50565b600081359050610cdc81610cb6565b92915050565b600060208284031215610cf857610cf7610cb1565b5b6000610d0684828501610ccd565b91505092915050565b6000819050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b6000610d5382610d0f565b9150610d5e83610d0f565b9250828203905081811115610d7657610d75610d19565b5b92915050565b610d8581610d0f565b82525050565b6000602082019050610da06000830184610d7c565b92915050565b6000610db182610d0f565b9150610dbc83610d0f565b9250828201905080821115610dd457610dd3610d19565b5b92915050565b600081600f0b9050919050565b6000610df282610dda565b9150610dfd83610dda565b925082820190507fffffffffffffffffffffffffffffffff8000000000000000000000000000000081126f7fffffffffffffffffffffffffffffff82131715610e4957610e48610d19565b5b92915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b6000610e8982610d0f565b91507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8203610ebb57610eba610d19565b5b600182019050919050565b610ecf81610dda565b82525050565b6000604082019050610eea6000830185610c87565b610ef76020830184610ec6565b9392505050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601260045260246000fdfea26469706673582212203360243b8c39eafaaa7c0443c48146099b1bcb68deca863f697e8a03fd43338664736f6c63430008120033";

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
