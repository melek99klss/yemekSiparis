
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



