pragma solidity 0.8.14;

import "solmate/auth/authorities/RolesAuthority.sol";
import {Authority} from "solmate/auth/Auth.sol";

contract CyberEngine is Auth {

  address public profileAddress;
  address public boxAddress;
  address public signer;

  constructor(
      address _owner,
      address _profileAddress,
      address _boxAddress,
      RolesAuthority _rolesAuthority
  ) Auth(_owner, _rolesAuthority) {
      signer = _owner;
      profileAddress = _profileAddress;
      boxAddress = _boxAddress;
  }

  function setSigner(address _signer) 
      external
      requiresAuth
  {
      signer = _signer;
  }

  function setProfileAddress(address _profileAddress) 
      external
      requiresAuth
  {
      profileAddress = _profileAddress;
  }

  function setBoxAddress(address _boxAddress) 
      external
      requiresAuth
  {
      boxAddress = _boxAddress;
  }
}

