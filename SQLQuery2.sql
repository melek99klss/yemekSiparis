
USE YemekSiparis;

CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Phone NVARCHAR(20) NOT NULL UNIQUE,
    Password NVARCHAR(100) NOT NULL,
    IsActive BIT DEFAULT 1
);
CREATE TABLE Restaurant (
    RestaurantID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Address NVARCHAR(200),
    Phone NVARCHAR(20),
    Rating DECIMAL(2,1) CHECK (Rating BETWEEN 1 AND 5),
    IsActive BIT DEFAULT 1
);
CREATE TABLE Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    RestaurantID INT FOREIGN KEY REFERENCES Restaurant(RestaurantID),
    Name NVARCHAR(100) NOT NULL,
    Price DECIMAL(10,2) CHECK (Price > 0),
    IsActive BIT DEFAULT 1
);
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customer(CustomerID),
    RestaurantID INT FOREIGN KEY REFERENCES Restaurant(RestaurantID),
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2) CHECK (TotalAmount >= 0),
    Status NVARCHAR(50)
);
SELECT 
    o.OrderID,
    c.FullName AS CustomerName,
    r.Name AS RestaurantName,
    p.Name AS ProductName,
    od.Quantity,
    od.UnitPrice,
    (od.Quantity * od.UnitPrice) AS TotalPrice,
    o.OrderDate,
    o.Status
FROM Orders o
INNER JOIN Customer c ON o.CustomerID = c.CustomerID
INNER JOIN Restaurant r ON o.RestaurantID = r.RestaurantID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Product p ON od.ProductID = p.ProductID;
-- GROUP BY ANALÝZ SORGUSU

SELECT 
    r.Name AS RestaurantName,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(o.TotalAmount) AS TotalRevenue,
    AVG(o.TotalAmount) AS AvgOrderValue
FROM Restaurant r
INNER JOIN Orders o ON r.RestaurantID = o.RestaurantID
GROUP BY r.Name;



-- SUBQUERY SORGUSU

SELECT 
    c.CustomerID,
    c.FullName,
    c.Email
FROM Customer c
WHERE c.CustomerID NOT IN (
    SELECT d.CustomerID
    FROM Donation d
);
CREATE VIEW vw_AktifRestoranMenuleri AS
SELECT 
    r.RestaurantID,
    r.Name AS RestaurantName,
    p.ProductID,
    p.Name AS ProductName,
    p.Price
FROM Restaurant r
INNER JOIN Product p ON r.RestaurantID = p.RestaurantID
WHERE r.IsActive = 1 AND p.IsActive = 1;
CREATE VIEW vw_AskidaYemekHavuzu AS
SELECT 
    c.CustomerID,
    c.FullName,
    d.DonationID,
    d.Amount,
    d.IsAnonymous,
    d.DonationDate
FROM Donation d
LEFT JOIN Customer c ON d.CustomerID = c.CustomerID;
CREATE TRIGGER trg_OrderDelivered
ON Orders
AFTER UPDATE
AS
BEGIN
    IF UPDATE(Status)
    BEGIN
        UPDATE r
        SET r.IsActive = r.IsActive
        FROM Restaurant r
        INNER JOIN inserted i ON r.RestaurantID = i.RestaurantID
        WHERE i.Status = 'Teslim Edildi';
    END
END;
CREATE TRIGGER trg_DonationInsert
ON Donation
AFTER INSERT
AS
BEGIN
    UPDATE CharityPool
    SET TotalAmount = TotalAmount + (
        SELECT SUM(Amount)
        FROM inserted
    );
END;
CREATE INDEX IX_Customer_Email
ON Customer(Email);
CREATE INDEX IX_Orders_OrderDate
ON Orders(OrderDate);