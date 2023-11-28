// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------
// CYRUS Contract
// Name          : CYRUS
// Symbol        : CRS
// Decimals      : 18
// InitialSupply : 3,000,000,000 CRS
// ----------------------------------------------------------------------------

pragma solidity 0.8.22;

abstract contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// @title Standard ERC20 Token Implementation
contract ERC20 is IERC20, Pausable {
    // @dev balance of each account
    mapping(address => uint256) internal _balances;
    // @dev allowances of each account
    mapping(address => mapping(address => uint256)) private _allowances;

    // @dev value of total supply
    uint256 private _totalSupply;
    // @dev value of name
    string private _name;
    // @dev value of symbol
    string private _symbol;
    // @dev value of decimals
    uint8 private _decimals;

    // @dev reentrancy guard variable
    bool private _inFunction;

    // @dev modifier to prevent reentrancy
    modifier nonReentrant() {
        require(!_inFunction, "ReentrancyGuard: reentrant call");
        _inFunction = true;
        _;
        _inFunction = false;
    }

    // @dev constructor of ERC20
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    // @dev return the name of the token
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    // @dev return the symbol of the token
    function name() public view virtual returns (string memory) {
        return _name;
    }

    // @dev return the number of decimals of the token
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    // @dev return the total supply of the token
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // @dev return the balance of the `_account`
    function balanceOf(address account) virtual public view returns (uint256) {
        return _balances[account];
    }

    // @dev transfer `_amount` tokens to `_recipient`
    function transfer(address recipient, uint256 amount) virtual public nonReentrant returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // @dev transfer `_amount` tokens from `_sender` to `_recipient`
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    // @dev approve `_spender` to spend `_amount` tokens
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    // @dev transfer `_amount` tokens from `_sender` to `_recipient` on the condition it is approved by `_sender`
    function transferFrom(address sender, address recipient, uint256 amount) virtual public nonReentrant returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    // @dev increase the allowance of `_spender` by `_addedValue`
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    // @dev decrease the allowance of `_spender` by `_subtractedValue`
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    // @dev transfer `_amount` tokens from `_sender` to `_recipient`
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    // @dev mint `_amount` tokens to `_account`
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    // @dev burn `_amount` tokens of `_owner`
    function _burn(address owner, uint256 value) internal {
        require(owner != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[owner];
        require(accountBalance >= value, "ERC20: burn amount exceeds balance");

        _balances[owner] = accountBalance - value;
        _totalSupply -= value;

        emit Transfer(owner, address(0), value);
    }

    // @dev approve `_spender` to spend `_value` tokens of `_owner`
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    // @dev burn `_amount` tokens of `_owner`
    function _burnFrom(address owner, uint256 amount) internal {
        _burn(owner, amount);
        uint256 currentAllowance = _allowances[owner][msg.sender];
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(owner, msg.sender, currentAllowance - amount);
    }
}

contract Cyrus is ERC20 {

    // @dev owner of the contract
    address public owner;

    // @dev event for ownership renouncement
    event OwnershipRenounced(
        address indexed previousOwner
    );
    // @dev event for ownership transfer
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // @dev event for lock and unlock
    event Burn(address indexed burner, uint256 value);
    // @dev event for lock
    event Lock(address indexed holder, uint256 value, uint256 releaseTime);
    // @dev event for unlock
    event Unlock(address indexed holder, uint256 value);

    // lock information of user
    struct LockInfo {
        uint256 releaseTime;
        uint256 balance;
    }

    // lock information of user
    mapping(address => LockInfo[]) internal lockInfo;
    // total locked amount of user
    mapping(address => uint256) internal totalLocked;

    // @dev constructor
    constructor() ERC20("CYRUS", "CRS", 18) {
        uint256 initialSupply = 3000000000 * (10 ** uint256(decimals()));

        // 발행자(msg.sender)에게 초기 공급량을 할당합니다.
        _mint(msg.sender, initialSupply);

        // 계약의 소유자를 설정합니다.
        owner = msg.sender;
    }

    // @dev pause the contract
    function pause() public onlyOwner {
        _pause();
    }

    // @dev unpause the contract
    function unpause() public onlyOwner {
        _unpause();
    }

    // @dev check owner of the contract
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // @dev ownership of the contract can be transferred by the current owner to a new address
    function transferOwnership(address _newOwner) public onlyOwner whenNotPaused {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        require(_newOwner != owner, "New owner cannot be the current owner");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    // @dev transfer `_value` tokens to `_to` from `msg.sender`
    function transfer(address _to, uint256 _value) public override whenNotPaused returns (bool) {
        // 잠금 해제 로직을 강화하고 가스 최적화
        releaseLock(msg.sender);

        // `_transfer` 함수를 직접 호출하여 중간 계층의 오버헤드를 줄임
        _transfer(msg.sender, _to, _value);
        return true;
    }

    // @dev transfer `_value` tokens to `_to` from `_from` on the condition it is approved by `_from`
    function transferFrom(address _from, address _to, uint256 _value) public override whenNotPaused returns (bool) {
        // 잠금 해제 로직을 강화하고 가스 최적화
        releaseLock(_from);

        // 승인된 토큰 양을 확인하고, 필요한 경우 감소시킵니다.
        uint256 currentAllowance = allowance(_from, msg.sender);
        require(currentAllowance >= _value, "ERC20: transfer amount exceeds allowance");
        _approve(_from, msg.sender, currentAllowance - _value);

        // `_transfer` 함수를 직접 호출하여 중간 계층의 오버헤드를 줄임
        _transfer(_from, _to, _value);
        return true;
    }

    // @dev burn `_value` tokens of the owner
    function burn(uint256 _value) public onlyOwner whenNotPaused {
        uint256 ownerBalance = balanceOf(owner);
        require(_value <= ownerBalance, "ERC20: burn amount exceeds balance");

        _burn(owner, _value);
    }

    // @dev return the total amount of locked and unlocked tokens of `_holder`
    function balanceOf(address _holder) public view override returns (uint256) {
        return super.balanceOf(_holder) + totalLocked[_holder];
    }

    // @dev release all expired locks of `_holder` (internal function)
    function releaseLock(address _holder) internal whenNotPaused {
        uint256 totalReleased = 0;
        LockInfo[] storage locks = lockInfo[_holder];

        for (uint256 i = 0; i < locks.length;) {
            if (locks[i].releaseTime <= block.timestamp) {
                totalReleased += locks[i].balance;

                locks[i] = locks[locks.length - 1];
                locks.pop();
            } else {
                i++;
            }
        }

        if (totalReleased > 0) {
            _balances[_holder] += totalReleased;
            totalLocked[_holder] -= totalReleased;
            emit Unlock(_holder, totalReleased);
        }
    }

    // @dev lock `_amount` tokens until `_releaseTime` of `_holder`
    function lock(address _holder, uint256 _amount, uint256 _releaseTime) public onlyOwner whenNotPaused {
        require(_balances[_holder] >= _amount, "Balance is too small.");
        require(block.timestamp <= _releaseTime, "TokenTimelock: release time is before current time");

        _balances[_holder] -= _amount;
        totalLocked[_holder] += _amount;  // 잠금된 토큰의 양 갱신
        lockInfo[_holder].push(LockInfo(_releaseTime, _amount));

        emit Transfer(_holder, address(0), _amount);  // 잠금을 반영하는 Transfer 이벤트 발생
        emit Lock(_holder, _amount, _releaseTime);
    }

    // @dev unlock the `_idx`-th lock of `_holder`
    function unlock(address _holder, uint256 i) public onlyOwner whenNotPaused {
        require(i < lockInfo[_holder].length, "No lock information.");
        uint256 unlockedAmount = lockInfo[_holder][i].balance;

        _balances[_holder] += unlockedAmount;  // 잠금 해제 시 발란스 증가
        totalLocked[_holder] -= unlockedAmount;
        emit Unlock(_holder, unlockedAmount);

        // 배열 재정렬: 마지막 요소를 삭제된 요소 위치로 이동
        if (i != lockInfo[_holder].length - 1) {
            lockInfo[_holder][i] = lockInfo[_holder][lockInfo[_holder].length - 1];
        }
        lockInfo[_holder].pop();
    }

    // @dev change release time of the `_idx`-th lock of `_holder`
    function lockTimeChange(address _holder, uint256 _idx, uint256 _releaseTime) public onlyOwner whenNotPaused {
        require(_idx < lockInfo[_holder].length, "No lock information.");
        require(block.timestamp < _releaseTime, "TokenTimelock: release time must be in the future");

        lockInfo[_holder][_idx].releaseTime = _releaseTime;
    }

    // @dev unlock all expired locks
    function releaseMyExpiredLocks() public whenNotPaused {
        uint256 totalReleased = 0;
        LockInfo[] storage locks = lockInfo[msg.sender];
        uint256 length = locks.length;

        for (uint256 i = 0; i < length;) {
            if (locks[i].releaseTime <= block.timestamp) {
                totalReleased += locks[i].balance;

                locks[i] = locks[length - 1];
                locks.pop();
                length--;
            } else {
                i++;
            }
        }

        if (totalReleased > 0) {
            _balances[msg.sender] += totalReleased;
            totalLocked[msg.sender] -= totalReleased;
            emit Unlock(msg.sender, totalReleased);
        }
    }

    // @dev return the number of locks of `_holder`
    function lockCount(address _holder) public view returns (uint256) {
        return lockInfo[_holder].length;
    }

    // @dev return the information of the `_idx`-th lock of `_holder`
    function lockState(address _holder, uint256 _idx) public view returns (uint256, uint256) {
        require(_idx < lockInfo[_holder].length, "Invalid index");  // 유효하지 않은 인덱스 확인

        return (lockInfo[_holder][_idx].releaseTime, lockInfo[_holder][_idx].balance);
    }

    // @dev return all lock information of `_holder`
    function getLocks(address _holder) public view returns (LockInfo[] memory) {
        return lockInfo[_holder];
    }

    // @dev return the amount of unlocked tokens of `_holder`
    function getUnlockedBalanceOf(address _holder) public view returns (uint256) {
        return _balances[_holder];
    }

    // @dev send token to `_to` with lock until `_releaseTime`
    function transferWithLock(address _to, uint256 _value, uint256 _releaseTime) public onlyOwner whenNotPaused returns (bool) {
        require(_to != address(0), "Wrong address");
        require(_value <= _balances[owner], "Not enough balance");
        require(block.timestamp <= _releaseTime, "TokenTimelock: release time is before current time");

        _balances[owner] -= _value;
        totalLocked[_to] += _value;  // 잠금된 토큰의 총량 갱신
        lockInfo[_to].push(LockInfo(_releaseTime, _value));

        // Transfer 이벤트 대신 Lock 이벤트만 발생
        emit Lock(_to, _value, _releaseTime);

        return true;
    }
}