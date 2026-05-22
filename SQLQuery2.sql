CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Phone NVARCHAR(20) NOT NULL UNIQUE,
    Password NVARCHAR(100) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1
);

CREATE TABLE Restaurant (
    RestaurantID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Address NVARCHAR(200),
    Phone NVARCHAR(20),
    Rating DECIMAL(2,1) CHECK (Rating BETWEEN 1 AND 5),
    IsActive BIT NOT NULL DEFAULT 1
);

CREATE TABLE Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    RestaurantID INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Price DECIMAL(10,2) CHECK (Price > 0),
    IsActive BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (RestaurantID) REFERENCES Restaurant(RestaurantID)
);

CREATE TABLE Courier (
    CourierID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL
);

CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    RestaurantID INT NOT NULL,
    CourierID INT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2) CHECK (TotalAmount >= 0),
    Status NVARCHAR(50),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    FOREIGN KEY (RestaurantID) REFERENCES Restaurant(RestaurantID),
    FOREIGN KEY (CourierID) REFERENCES Courier(CourierID)
);

CREATE TABLE OrderDetails (
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT CHECK (Quantity > 0),
    UnitPrice DECIMAL(10,2),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);

CREATE TABLE Donation (
    DonationID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    Amount DECIMAL(10,2) CHECK (Amount > 0),
    DonationDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);


-- RESTAURANTS (5 adet)
INSERT INTO Restaurant (Name, Address, Phone, Rating)
VALUES
('Burger House', 'Konya', '05001111111', 4.5),
('Pizza World', 'Ankara', '05002222222', 4.2),
('Kebap Sarayi', 'Istanbul', '05003333333', 4.8),
('Tavuk Dunyasi', 'Izmir', '05004444444', 4.1),
('Cafe Lezzet', 'Bursa', '05005555555', 4.6);

-- CUSTOMERS (20'e tamamlayacaðýz þimdilik 10)
INSERT INTO Customer (FullName, Email, Phone, Password)
VALUES
('Ali Yilmaz', 'ali1@gmail.com', '05551000001', '123'),
('Ayse Demir', 'ayse2@gmail.com', '05551000002', '123'),
('Mehmet Kaya', 'mehmet3@gmail.com', '05551000003', '123'),
('Zeynep Arslan', 'zeynep4@gmail.com', '05551000004', '123'),
('Can Aydin', 'can5@gmail.com', '05551000005', '123'),
('Elif Demir', 'elif@gmail.com', '05551000006', '123'),
('Burak Yildiz', 'burak@gmail.com', '05551000007', '123'),
('Ece Kaya', 'ece@gmail.com', '05551000008', '123'),
('Mert Can', 'mert@gmail.com', '05551000009', '123'),
('Seda Polat', 'seda@gmail.com', '05551000010', '123');

-- COURIERS
INSERT INTO Courier (FullName)
VALUES
('Ahmet Kurye'),
('Mehmet Kurye'),
('Hasan Kurye');

-- CHARITY POOL
INSERT INTO CharityPool (TotalAmount)
VALUES (0);
SELECT * FROM Restaurant;
DELETE FROM OrderDetails;
DELETE FROM Orders;
DECLARE @i INT = 1;

WHILE @i <= 100
BEGIN
    INSERT INTO Orders (CustomerID, RestaurantID, TotalAmount, Status)
    VALUES (
        (SELECT TOP 1 CustomerID FROM Customer ORDER BY NEWID()),
        (SELECT TOP 1 RestaurantID FROM Restaurant ORDER BY NEWID()),
        0,
        'Hazýrlanýyor'
    );

    SET @i = @i + 1;
END;
DECLARE @i INT = 1;

WHILE @i <= 100
BEGIN
    DECLARE @pid INT;

    SET @pid = (SELECT TOP 1 ProductID FROM Product ORDER BY NEWID());

    INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice)
    SELECT 
        @i,
        @pid,
        ABS(CHECKSUM(NEWID()) % 3) + 1,
        Price
    FROM Product
    WHERE ProductID = @pid;

    SET @i = @i + 1;
END;
SELECT 
    r.Name AS RestaurantName,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(o.TotalAmount) AS TotalRevenue,
    AVG(o.TotalAmount) AS AvgOrderValue
FROM Restaurant r
INNER JOIN Orders o ON r.RestaurantID = o.RestaurantID
GROUP BY r.Name
HAVING COUNT(o.OrderID) > 5;
SELECT 
    o.OrderID,
    c.FullName AS CustomerName,
    r.Name AS RestaurantName,
    p.Name AS ProductName,
    od.Quantity,
    od.UnitPrice,
    (od.Quantity * od.UnitPrice) AS LineTotal
FROM Orders o
INNER JOIN Customer c ON o.CustomerID = c.CustomerID
INNER JOIN Restaurant r ON o.RestaurantID = r.RestaurantID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Product p ON od.ProductID = p.ProductID;
CREATE OR ALTER VIEW vw_AktifRestoranMenuleri AS
SELECT 
    r.RestaurantID,
    r.Name AS RestaurantName,
    p.ProductID,
    p.Name AS ProductName,
    p.Price
FROM Restaurant r
INNER JOIN Product p ON r.RestaurantID = p.RestaurantID
WHERE r.IsActive = 1 AND p.IsActive = 1;
CREATE OR ALTER TRIGGER trg_DonationInsert
ON Donation
AFTER INSERT
AS
BEGIN
    UPDATE CharityPool
    SET TotalAmount = TotalAmount + (
        SELECT SUM(Amount) FROM inserted
    );
END;
CREATE INDEX IX_Customer_Email ON Customer(Email);
CREATE INDEX IX_Orders_OrderDate ON Orders(OrderDate);
SELECT 
    c.CustomerID,
    c.FullName
FROM Customer c
WHERE NOT EXISTS (
    SELECT 1 
    FROM Donation d
    WHERE d.CustomerID = c.CustomerID
);