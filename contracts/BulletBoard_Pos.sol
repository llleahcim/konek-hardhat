// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract POS {
    
    address public owner;
    
    // Store product information
    struct Product {
        uint256 id;
        string name;
        uint256 price; // Price in Wei (1 ETH = 10^18 Wei)
        uint256 stock; // Available stock
    }
    
    // Store customer loyalty points
    mapping(address => uint256) public loyaltyPoints;
    
    // Map product ID to product data
    mapping(uint256 => Product) public products;
    
    // Events for tracking purchases, stock changes, and loyalty points
    event ProductAdded(uint256 productId, string name, uint256 price, uint256 stock);
    event ProductRemoved(uint256 productId);
    event PurchaseMade(address customer, uint256 productId, uint256 quantity, uint256 totalPrice, uint256 discountApplied, uint256 loyaltyPointsEarned);
    event StockUpdated(uint256 productId, uint256 newStock);
    event LoyaltyPointsAwarded(address customer, uint256 points);
    event OwnershipTransferred(address oldOwner, address newOwner);
    
    constructor() {
        owner = msg.sender; // Owner is the account that deploys the contract
    }
    
    // Modifier to restrict actions to the owner (business)
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    // Function to add products to the POS system
    function addProduct(uint256 _id, string memory _name, uint256 _price, uint256 _stock) public onlyOwner {
        products[_id] = Product({
            id: _id,
            name: _name,
            price: _price,
            stock: _stock
        });
        
        emit ProductAdded(_id, _name, _price, _stock);
    }

    // Function to update product stock
    function updateStock(uint256 _id, uint256 _newStock) public onlyOwner {
        require(products[_id].id != 0, "Product does not exist");
        products[_id].stock = _newStock;
        
        emit StockUpdated(_id, _newStock);
    }
    
    // Function to remove a product from the store
    function removeProduct(uint256 _id) public onlyOwner {
        require(products[_id].id != 0, "Product does not exist");
        delete products[_id];
        
        emit ProductRemoved(_id);
    }

    // Function to make a purchase with optional discount
    function purchaseProduct(uint256 _productId, uint256 _quantity, uint256 _discountPercentage) public payable {
        require(products[_productId].id != 0, "Product does not exist");
        require(products[_productId].stock >= _quantity, "Not enough stock available");

        uint256 totalPrice = products[_productId].price * _quantity;
        uint256 discountAmount = (totalPrice * _discountPercentage) / 100;
        uint256 finalPrice = totalPrice - discountAmount;
        
        require(msg.value == finalPrice, "Incorrect payment amount");

        // Deduct stock
        products[_productId].stock -= _quantity;
        
        // Award loyalty points
        uint256 loyaltyPointsEarned = _quantity * 10; // 10 points per item purchased
        loyaltyPoints[msg.sender] += loyaltyPointsEarned;
        emit LoyaltyPointsAwarded(msg.sender, loyaltyPointsEarned);
        
        // Emit event for purchase
        emit PurchaseMade(msg.sender, _productId, _quantity, totalPrice, discountAmount, loyaltyPointsEarned);
        
        // Transfer payment to the store owner
        payable(owner).transfer(msg.value);
    }

    // Function to get product information
    function getProduct(uint256 _id) public view returns (string memory, uint256, uint256) {
        require(products[_id].id != 0, "Product does not exist");
        return (products[_id].name, products[_id].price, products[_id].stock);
    }
    
    // Function to get contract balance (store's earnings)
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    // Function to withdraw store earnings
    function withdrawBalance(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(amount);
    }
    
    // Function to transfer ownership of the store
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner address cannot be zero");
        address oldOwner = owner;
        owner = newOwner;
        
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // Function to check a customer's loyalty points
    function checkLoyaltyPoints(address _customer) public view returns (uint256) {
        return loyaltyPoints[_customer];
    }
}