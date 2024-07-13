// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract USDT_Escrow is Ownable {
    IERC20 public usdt;
    address public notary;
    uint256 public escrowCounter;

    struct Escrow {
        address sender;
        address receiver;
        uint256 amount;
        uint256 deadline;
        bytes32 escrowId;
        EscrowState state;
    }

    enum EscrowState {
        IDLE,
        RELEASED,
        REFUNDED
    }

    mapping(bytes32 => Escrow) public escrows;

    event EscrowCreated(bytes32 indexed escrowId, address indexed sender, address indexed receiver, uint256 amount, uint256 deadline);
    event EscrowReleased(bytes32 indexed escrowId);
    event EscrowRefunded(bytes32 indexed escrowId);

    modifier onlyNotary() {
        require(msg.sender == notary, "Only notary can perform this action");
        _;
    }

    constructor(address _usdt, address _notary) Ownable(msg.sender) {
        usdt = IERC20(_usdt);
        notary = _notary;
    }

    function createEscrow(address _receiver, uint256 _amount, uint256 _duration) external returns (bytes32) {
        require(usdt.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        bytes32 escrowId = keccak256(abi.encodePacked(msg.sender, _receiver, _amount, block.timestamp, escrowCounter));
        escrowCounter++;

        escrows[escrowId] = Escrow({
            sender: msg.sender,
            receiver: _receiver,
            amount: _amount,
            deadline: block.timestamp + _duration,
            escrowId: escrowId,
            state: EscrowState.IDLE
        });

        emit EscrowCreated(escrowId, msg.sender, _receiver, _amount, block.timestamp + _duration);

        return escrowId;
    }

    function releaseEscrow(bytes32 _escrowId) external onlyNotary {
        Escrow storage escrow = escrows[_escrowId];
        require(escrow.state == EscrowState.RELEASED, "Funds already released");
        require(escrow.state == EscrowState.REFUNDED, "Funds already refunded");

        escrow.state = EscrowState.RELEASED;
        require(usdt.transfer(escrow.receiver, escrow.amount), "Transfer failed");

        emit EscrowReleased(_escrowId);
    }

    function refundEscrow(bytes32 _escrowId) external {
        Escrow storage escrow = escrows[_escrowId];
        require(block.timestamp > escrow.deadline, "Escrow period not ended");
        require(escrow.state == EscrowState.RELEASED, "Funds already released");
        require(escrow.state == EscrowState.REFUNDED, "Funds already refunded");

        escrow.state = EscrowState.REFUNDED;
        require(usdt.transfer(escrow.sender, escrow.amount), "Transfer failed");

        emit EscrowRefunded(_escrowId);
    }

    function getEscrowInfo(bytes32 _escrowId) external view returns (Escrow memory escrow) {
        escrow = escrows[_escrowId];
        return escrow;
    }
}

