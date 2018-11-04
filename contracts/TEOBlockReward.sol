// Copyright 2018 Parity Technologies (UK) Ltd.
// Copyright 2018 TAO.Foundation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

pragma solidity ^0.4.24;


interface BlockReward {
	// produce rewards for the given beneficiaries, with corresponding reward codes.
	// only callable by `SYSTEM_ADDRESS`
	function reward(address[] beneficiaries, uint16[] kind)
		external
		returns (address[], uint256[]);
}

// Implements the TEO block reward as defined in
// https://github.com/tao-foundation/tEIPS
contract TEOBlockReward is BlockReward {
	address constant SYSTEM_ADDRESS = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

	uint256 constant MINER_REWARD = 0x4563918244F40000; // 5 TEO
	uint256 constant SSZ_REWARD = 0x6f05b59d3b20000; // 0.5 TEO
	address constant SSZ_ACCOUNT = 0xe306fb9bce8365fb8b8245c732ede9165d66fcc5;

	modifier onlySystem {
		require(msg.sender == SYSTEM_ADDRESS);
		_;
	}

	// produce rewards for the given benefactors, with corresponding reward codes.
	// only callable by `SYSTEM_ADDRESS`
	function reward(address[] beneficiaries, uint16[] kind)
		external
		onlySystem
		returns (address[], uint256[])
	{
		require(beneficiaries.length == kind.length);

		address[] memory addresses = new address[](2);  // minimum 2 for author and ssz_account
		uint256[] memory rewards = new uint256[](2);

		addresses[1] = SSZ_ACCOUNT;
		rewards[1] = SSZ_REWARD;

		for (uint i = 0; i < beneficiaries.length; i++) {
			if (kind[i] == 0) { // author
				uint256 finalReward = MINER_REWARD + (MINER_REWARD >> 5) * (beneficiaries.length - 1);
				addresses[0] = beneficiaries[i];
				rewards[0] = finalReward;

			} else if (kind[i] >= 100) { // uncle
				uint16 depth = kind[i] - 100;
				uint256 uncleReward = (MINER_REWARD * (8 - depth)) >> 3;

				addresses = pushAddressArray(addresses, beneficiaries[i]);
				rewards = pushUint256Array(rewards, uncleReward);
			}
		}

		return (addresses, rewards);
	}

	function pushAddressArray(address[] arr, address addr)
		internal
		pure
		returns (address[])
	{
		address[] memory ret = new address[](arr.length + 1);
		for (uint i = 0; i < arr.length; i++) {
			ret[i] = arr[i];
		}
		ret[ret.length - 1] = addr;
		return ret;
	}

	function pushUint256Array(uint256[] arr, uint256 u)
		internal
		pure
		returns (uint256[])
	{
		uint256[] memory ret = new uint256[](arr.length + 1);
		for (uint i = 0; i < arr.length; i++) {
			ret[i] = arr[i];
		}
		ret[ret.length - 1] = u;
		return ret;
	}
}
