/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumberish,
  BytesLike,
  FunctionFragment,
  Result,
  Interface,
  EventFragment,
  AddressLike,
  ContractRunner,
  ContractMethod,
  Listener,
} from "ethers";
import type {
  TypedContractEvent,
  TypedDeferredTopicFilter,
  TypedEventLog,
  TypedLogDescription,
  TypedListener,
  TypedContractMethod,
} from "./common";

export interface DexhunePriceDAOBaseInterface extends Interface {
  getFunction(
    nameOrSignature:
      | "assignNFTCollection"
      | "assignTokenAddress"
      | "nftAddress"
      | "owner"
      | "tokenAddress"
      | "transferOwnership"
  ): FunctionFragment;

  getEvent(
    nameOrSignatureOrTopic:
      | "AssignedNFTCollection"
      | "AssignedToken"
      | "ProposalCreated"
      | "ProposalDenied"
      | "ProposalPassed"
      | "RewardedProposer"
      | "TransferredOwnership"
      | "VotedDown"
      | "VotedUp"
  ): EventFragment;

  encodeFunctionData(
    functionFragment: "assignNFTCollection",
    values: [AddressLike]
  ): string;
  encodeFunctionData(
    functionFragment: "assignTokenAddress",
    values: [AddressLike]
  ): string;
  encodeFunctionData(
    functionFragment: "nftAddress",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "owner", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "tokenAddress",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "transferOwnership",
    values: [AddressLike]
  ): string;

  decodeFunctionResult(
    functionFragment: "assignNFTCollection",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "assignTokenAddress",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "nftAddress", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "owner", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "tokenAddress",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "transferOwnership",
    data: BytesLike
  ): Result;
}

export namespace AssignedNFTCollectionEvent {
  export type InputTuple = [addr: AddressLike];
  export type OutputTuple = [addr: string];
  export interface OutputObject {
    addr: string;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace AssignedTokenEvent {
  export type InputTuple = [addr: AddressLike];
  export type OutputTuple = [addr: string];
  export interface OutputObject {
    addr: string;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace ProposalCreatedEvent {
  export type InputTuple = [
    price: string,
    description: string,
    proposer: AddressLike
  ];
  export type OutputTuple = [
    price: string,
    description: string,
    proposer: string
  ];
  export interface OutputObject {
    price: string;
    description: string;
    proposer: string;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace ProposalDeniedEvent {
  export type InputTuple = [_for: BigNumberish, _against: BigNumberish];
  export type OutputTuple = [_for: bigint, _against: bigint];
  export interface OutputObject {
    _for: bigint;
    _against: bigint;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace ProposalPassedEvent {
  export type InputTuple = [
    _for: BigNumberish,
    _against: BigNumberish,
    newPrice: string
  ];
  export type OutputTuple = [_for: bigint, _against: bigint, newPrice: string];
  export interface OutputObject {
    _for: bigint;
    _against: bigint;
    newPrice: string;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace RewardedProposerEvent {
  export type InputTuple = [addr: AddressLike, amount: BigNumberish];
  export type OutputTuple = [addr: string, amount: bigint];
  export interface OutputObject {
    addr: string;
    amount: bigint;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace TransferredOwnershipEvent {
  export type InputTuple = [oldOwner: AddressLike, newOwner: AddressLike];
  export type OutputTuple = [oldOwner: string, newOwner: string];
  export interface OutputObject {
    oldOwner: string;
    newOwner: string;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace VotedDownEvent {
  export type InputTuple = [voter: AddressLike, votes: BigNumberish];
  export type OutputTuple = [voter: string, votes: bigint];
  export interface OutputObject {
    voter: string;
    votes: bigint;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace VotedUpEvent {
  export type InputTuple = [voter: AddressLike, votes: BigNumberish];
  export type OutputTuple = [voter: string, votes: bigint];
  export interface OutputObject {
    voter: string;
    votes: bigint;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export interface DexhunePriceDAOBase extends BaseContract {
  connect(runner?: ContractRunner | null): DexhunePriceDAOBase;
  waitForDeployment(): Promise<this>;

  interface: DexhunePriceDAOBaseInterface;

  queryFilter<TCEvent extends TypedContractEvent>(
    event: TCEvent,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TypedEventLog<TCEvent>>>;
  queryFilter<TCEvent extends TypedContractEvent>(
    filter: TypedDeferredTopicFilter<TCEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TypedEventLog<TCEvent>>>;

  on<TCEvent extends TypedContractEvent>(
    event: TCEvent,
    listener: TypedListener<TCEvent>
  ): Promise<this>;
  on<TCEvent extends TypedContractEvent>(
    filter: TypedDeferredTopicFilter<TCEvent>,
    listener: TypedListener<TCEvent>
  ): Promise<this>;

  once<TCEvent extends TypedContractEvent>(
    event: TCEvent,
    listener: TypedListener<TCEvent>
  ): Promise<this>;
  once<TCEvent extends TypedContractEvent>(
    filter: TypedDeferredTopicFilter<TCEvent>,
    listener: TypedListener<TCEvent>
  ): Promise<this>;

  listeners<TCEvent extends TypedContractEvent>(
    event: TCEvent
  ): Promise<Array<TypedListener<TCEvent>>>;
  listeners(eventName?: string): Promise<Array<Listener>>;
  removeAllListeners<TCEvent extends TypedContractEvent>(
    event?: TCEvent
  ): Promise<this>;

  assignNFTCollection: TypedContractMethod<
    [addr: AddressLike],
    [void],
    "nonpayable"
  >;

  assignTokenAddress: TypedContractMethod<
    [addr: AddressLike],
    [void],
    "nonpayable"
  >;

  nftAddress: TypedContractMethod<[], [string], "view">;

  owner: TypedContractMethod<[], [string], "view">;

  tokenAddress: TypedContractMethod<[], [string], "view">;

  transferOwnership: TypedContractMethod<
    [_address: AddressLike],
    [void],
    "nonpayable"
  >;

  getFunction<T extends ContractMethod = ContractMethod>(
    key: string | FunctionFragment
  ): T;

  getFunction(
    nameOrSignature: "assignNFTCollection"
  ): TypedContractMethod<[addr: AddressLike], [void], "nonpayable">;
  getFunction(
    nameOrSignature: "assignTokenAddress"
  ): TypedContractMethod<[addr: AddressLike], [void], "nonpayable">;
  getFunction(
    nameOrSignature: "nftAddress"
  ): TypedContractMethod<[], [string], "view">;
  getFunction(
    nameOrSignature: "owner"
  ): TypedContractMethod<[], [string], "view">;
  getFunction(
    nameOrSignature: "tokenAddress"
  ): TypedContractMethod<[], [string], "view">;
  getFunction(
    nameOrSignature: "transferOwnership"
  ): TypedContractMethod<[_address: AddressLike], [void], "nonpayable">;

  getEvent(
    key: "AssignedNFTCollection"
  ): TypedContractEvent<
    AssignedNFTCollectionEvent.InputTuple,
    AssignedNFTCollectionEvent.OutputTuple,
    AssignedNFTCollectionEvent.OutputObject
  >;
  getEvent(
    key: "AssignedToken"
  ): TypedContractEvent<
    AssignedTokenEvent.InputTuple,
    AssignedTokenEvent.OutputTuple,
    AssignedTokenEvent.OutputObject
  >;
  getEvent(
    key: "ProposalCreated"
  ): TypedContractEvent<
    ProposalCreatedEvent.InputTuple,
    ProposalCreatedEvent.OutputTuple,
    ProposalCreatedEvent.OutputObject
  >;
  getEvent(
    key: "ProposalDenied"
  ): TypedContractEvent<
    ProposalDeniedEvent.InputTuple,
    ProposalDeniedEvent.OutputTuple,
    ProposalDeniedEvent.OutputObject
  >;
  getEvent(
    key: "ProposalPassed"
  ): TypedContractEvent<
    ProposalPassedEvent.InputTuple,
    ProposalPassedEvent.OutputTuple,
    ProposalPassedEvent.OutputObject
  >;
  getEvent(
    key: "RewardedProposer"
  ): TypedContractEvent<
    RewardedProposerEvent.InputTuple,
    RewardedProposerEvent.OutputTuple,
    RewardedProposerEvent.OutputObject
  >;
  getEvent(
    key: "TransferredOwnership"
  ): TypedContractEvent<
    TransferredOwnershipEvent.InputTuple,
    TransferredOwnershipEvent.OutputTuple,
    TransferredOwnershipEvent.OutputObject
  >;
  getEvent(
    key: "VotedDown"
  ): TypedContractEvent<
    VotedDownEvent.InputTuple,
    VotedDownEvent.OutputTuple,
    VotedDownEvent.OutputObject
  >;
  getEvent(
    key: "VotedUp"
  ): TypedContractEvent<
    VotedUpEvent.InputTuple,
    VotedUpEvent.OutputTuple,
    VotedUpEvent.OutputObject
  >;

  filters: {
    "AssignedNFTCollection(address)": TypedContractEvent<
      AssignedNFTCollectionEvent.InputTuple,
      AssignedNFTCollectionEvent.OutputTuple,
      AssignedNFTCollectionEvent.OutputObject
    >;
    AssignedNFTCollection: TypedContractEvent<
      AssignedNFTCollectionEvent.InputTuple,
      AssignedNFTCollectionEvent.OutputTuple,
      AssignedNFTCollectionEvent.OutputObject
    >;

    "AssignedToken(address)": TypedContractEvent<
      AssignedTokenEvent.InputTuple,
      AssignedTokenEvent.OutputTuple,
      AssignedTokenEvent.OutputObject
    >;
    AssignedToken: TypedContractEvent<
      AssignedTokenEvent.InputTuple,
      AssignedTokenEvent.OutputTuple,
      AssignedTokenEvent.OutputObject
    >;

    "ProposalCreated(string,string,address)": TypedContractEvent<
      ProposalCreatedEvent.InputTuple,
      ProposalCreatedEvent.OutputTuple,
      ProposalCreatedEvent.OutputObject
    >;
    ProposalCreated: TypedContractEvent<
      ProposalCreatedEvent.InputTuple,
      ProposalCreatedEvent.OutputTuple,
      ProposalCreatedEvent.OutputObject
    >;

    "ProposalDenied(uint16,uint16)": TypedContractEvent<
      ProposalDeniedEvent.InputTuple,
      ProposalDeniedEvent.OutputTuple,
      ProposalDeniedEvent.OutputObject
    >;
    ProposalDenied: TypedContractEvent<
      ProposalDeniedEvent.InputTuple,
      ProposalDeniedEvent.OutputTuple,
      ProposalDeniedEvent.OutputObject
    >;

    "ProposalPassed(uint16,uint16,string)": TypedContractEvent<
      ProposalPassedEvent.InputTuple,
      ProposalPassedEvent.OutputTuple,
      ProposalPassedEvent.OutputObject
    >;
    ProposalPassed: TypedContractEvent<
      ProposalPassedEvent.InputTuple,
      ProposalPassedEvent.OutputTuple,
      ProposalPassedEvent.OutputObject
    >;

    "RewardedProposer(address,uint256)": TypedContractEvent<
      RewardedProposerEvent.InputTuple,
      RewardedProposerEvent.OutputTuple,
      RewardedProposerEvent.OutputObject
    >;
    RewardedProposer: TypedContractEvent<
      RewardedProposerEvent.InputTuple,
      RewardedProposerEvent.OutputTuple,
      RewardedProposerEvent.OutputObject
    >;

    "TransferredOwnership(address,address)": TypedContractEvent<
      TransferredOwnershipEvent.InputTuple,
      TransferredOwnershipEvent.OutputTuple,
      TransferredOwnershipEvent.OutputObject
    >;
    TransferredOwnership: TypedContractEvent<
      TransferredOwnershipEvent.InputTuple,
      TransferredOwnershipEvent.OutputTuple,
      TransferredOwnershipEvent.OutputObject
    >;

    "VotedDown(address,uint16)": TypedContractEvent<
      VotedDownEvent.InputTuple,
      VotedDownEvent.OutputTuple,
      VotedDownEvent.OutputObject
    >;
    VotedDown: TypedContractEvent<
      VotedDownEvent.InputTuple,
      VotedDownEvent.OutputTuple,
      VotedDownEvent.OutputObject
    >;

    "VotedUp(address,uint16)": TypedContractEvent<
      VotedUpEvent.InputTuple,
      VotedUpEvent.OutputTuple,
      VotedUpEvent.OutputObject
    >;
    VotedUp: TypedContractEvent<
      VotedUpEvent.InputTuple,
      VotedUpEvent.OutputTuple,
      VotedUpEvent.OutputObject
    >;
  };
}
