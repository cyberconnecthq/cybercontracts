pragma solidity 0.8.14;

library DataTypes {
    struct ProfileStruct {
        address subscribeNFT;
        string handle;
        string imageURI;
    }

    struct CreateProfileData {
        address to;
        address subscribeNFT;
        string handle;
        string imageURI;
    }
}