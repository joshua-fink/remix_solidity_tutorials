// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

contract Hostel{
    // payable - address where you can send Ether to
    address payable tenant;
    address payable landlord;

    // here is where smart contract will store integer values
    uint public room_idx = 0;
    uint public agreement_idx = 0;
    uint public rent_idx = 0;

    struct Room{
        uint room_id;
        uint agreement_id;
        string room_name;
        string room_address;
        uint rent_per_month;
        uint security_deposit;
        uint timestamp;
        bool vacant;
        address payable tenant_address;
        address payable landlord_address;
    }

    mapping(uint => Room) public RoomMap;

    struct RoomAgreement {
        uint room_id;
        uint agreement_id;
        string room_name;
        string room_address;
        uint rent_per_month;
        uint security_deposit;
        uint lock_in_period;
        uint timestamp;
        address payable tenant_address;
        address payable landlord_address;
    }

    mapping(uint => RoomAgreement) public RoomAgreementMap;

    struct Rent{
        uint rent_no;
        uint room_id;
        uint agreement_id;
        string room_name;
        string room_address;
        uint rent_per_month;
        uint timestamp;
        address payable tenant_address;
        address payable landlord_address;
    }

    mapping(uint => Rent) public RentMap;

    // modifiers -> effectively like 'assert' functions
    modifier onlyLandlord(uint _index) {
        require(
            msg.sender == RoomMap[_index].landlord_address, 
            "Only landlord can access this"
        );
        _;
    }

    modifier notLandlord(uint _index) {
        require(msg.sender != RoomMap[_index].landlord_address, "Only tenant can access this");
        _;
    }

    modifier onlyWhileVacant(uint _index){
        require(RoomMap[_index].vacant == true, "Room is currently occupied");
        _;
    }

    modifier enoughRent(uint _index) {
        require(msg.value >= uint(RoomMap[_index].rent_per_month), "Not enough Ether in your wallet");
        _;
    }

    modifier enoughAgreementFee(uint _index) {
        require(msg.value >= uint(uint(RoomMap[_index].rent_per_month) + uint(RoomMap[_index].security_deposit)), "Not enough Ether in your wallet");
        _;
    }

    modifier sameTenant(uint _index) {
        require(msg.sender == RoomMap[_index].tenant_address, "No previous agreement found with you & landlord");
        _;
    }

    modifier agreementTimesUp(uint _index) {
        uint _agreement_number = RoomMap[_index].agreement_id;
        uint time = RoomAgreementMap[_agreement_number].timestamp + RoomAgreementMap[_agreement_number].lock_in_period;
        require(block.timestamp < time, "Agreement already ended");
        _;
    }

    modifier rentTimesUp(uint _index) {
        uint time = RoomMap[_index].timestamp + 1 minutes;
        require(block.timestamp >= time, "Time left to pay rent");
        _;
    }

    function addRoom(string memory _room_name, string memory _room_address, uint _rent_cost, uint _security_deposit) public {
        require(msg.sender != address(0));
        room_idx ++;
        bool _vacancy = true;
        address payable _tenant = payable(msg.sender);
        address payable _landlord = payable(address(0));

        RoomMap[room_idx] = Room(room_idx, 0, _room_name, _room_address, _rent_cost, _security_deposit, 0, _vacancy, _tenant, _landlord);
    }

    function signAgreement(uint _index) public payable notLandlord(_index) enoughAgreementFee(_index) onlyWhileVacant(_index) {
        require(msg.sender != address(0));
        address payable _landlord = RoomMap[_index].landlord_address;
        uint _total_fee = RoomMap[_index].rent_per_month + RoomMap[_index].security_deposit;
        _landlord.transfer(_total_fee);
        agreement_idx++;
        RoomMap[_index].tenant_address = payable(msg.sender);
        RoomMap[_index].vacant = false;
        RoomMap[_index].timestamp = block.timestamp;
        RoomMap[_index].agreement_id = agreement_idx;
        RoomAgreementMap[agreement_idx] = RoomAgreement(_index, agreement_idx, RoomMap[_index].room_name, RoomMap[_index].room_address, RoomMap[_index].rent_per_month, RoomMap[_index].security_deposit, 365 days, block.timestamp, payable(msg.sender), _landlord);
        rent_idx++;
        RentMap[rent_idx] = Rent(rent_idx, _index, agreement_idx, RoomMap[_index].room_name, RoomMap[_index].room_address, RoomMap[_index].rent_per_month, block.timestamp, payable(msg.sender), _landlord);
    }

    function payRent(uint _index) public payable sameTenant(_index) rentTimesUp(_index) enoughRent(_index){
        require(msg.sender != address(0));
        address payable _landlord = RoomMap[_index].landlord_address;
        uint _rent = RoomMap[_index].rent_per_month;
        _landlord.transfer(_rent);
        RoomMap[_index].tenant_address = payable(msg.sender);
        RoomMap[_index].vacant = false;
        rent_idx++;
        RentMap[rent_idx] = Rent(rent_idx, _index, RoomMap[_index].agreement_id, RoomMap[_index].room_name, RoomMap[_index].room_address, _rent, block.timestamp, payable(msg.sender), RoomMap[_index].landlord_address);
    }

    function agreementCompleted(uint _index) public payable onlyLandlord(_index) agreementTimesUp(_index){
        require(msg.sender != address(0));
        require(RoomMap[_index].vacant == false, "Room is currently occupied");
        RoomMap[_index].vacant = true;
        address payable _tenant = RoomMap[_index].tenant_address;
        uint _security_deposit = RoomMap[_index].security_deposit;
        _tenant.transfer(_security_deposit);
    }

    function agreementTerminated(uint _index) public onlyLandlord(_index) agreementTimesUp(_index){
        require(msg.sender == address(0));
        RoomMap[_index].vacant = true;
    }
}

// https://www.loginradius.com/blog/engineering/guest-post/ethereum-smart-contract-tutorial/