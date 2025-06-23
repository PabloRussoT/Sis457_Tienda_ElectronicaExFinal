-- Script SQL para la gestión de una tienda de productos electrónicos.
-- Incluye la creación de la base de datos, usuarios, tablas,
-- procedimientos almacenados y datos de ejemplo.

CREATE DATABASE TiendaElectronicaFinal;
GO
USE [master]
GO
-- Crear un login de SQL Server para la aplicación
CREATE LOGIN [userelectronica] WITH PASSWORD = N'123456',
    DEFAULT_DATABASE = [TiendaElectronicaFinal],
    CHECK_EXPIRATION = OFF,
    CHECK_POLICY = ON
GO
USE [TiendaElectronicaFinal]
GO
-- Crear un usuario de base de datos asociado al login
CREATE USER [userelectronica] FOR LOGIN [userelectronica]
GO
-- Otorgar permisos de db_owner al usuario (para desarrollo, se recomienda menos permisos en producción)
ALTER ROLE [db_owner] ADD MEMBER [userelectronica]
GO

-- Eliminar tablas y procedimientos almacenados existentes si los hay,
-- en orden inverso de dependencia para evitar errores de clave foránea.
DROP TABLE IF EXISTS VentaDetalle;
DROP TABLE IF EXISTS Venta;
DROP TABLE IF EXISTS CompraDetalle;
DROP TABLE IF EXISTS Compra;
DROP TABLE IF EXISTS Usuario;
DROP TABLE IF EXISTS Empleado;
DROP TABLE IF EXISTS Proveedor;
DROP TABLE IF EXISTS Producto;
DROP TABLE IF EXISTS Categoria;
DROP TABLE IF EXISTS Marca;
-- La tabla UnidadMedida ha sido omitida
DROP PROC IF EXISTS paProductoListar;
DROP PROC IF EXISTS paEmpleadoListar;
DROP PROC IF EXISTS paCategoriaListar;
DROP PROC IF EXISTS paMarcaListar;
DROP PROC IF EXISTS paProveedorListar;
DROP PROC IF EXISTS paCompraListar;
DROP PROC IF EXISTS paCompraDetalleListar;
DROP PROC IF EXISTS paVentaListar;
DROP PROC IF EXISTS paVentaDetalleListar;
-- No eliminar la base de datos o el login del usuario aquí para mantener el contexto
-- Esto es un script de actualización/creación, no de limpieza total.

-- -----------------------------------------------------------
-- Creación de Tablas
-- -----------------------------------------------------------

-- La tabla UnidadMedida ha sido omitida según la solicitud

-- Nueva tabla para Categorías de productos
CREATE TABLE Categoria (
    id INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    descripcion VARCHAR(100) NOT NULL UNIQUE,
    usuarioRegistro VARCHAR(50) NOT NULL DEFAULT SUSER_SNAME(),
    fechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
    estado SMALLINT NOT NULL DEFAULT 1 -- -1:Eliminado, 0: Inactivo, 1: Activo
);

-- Nueva tabla para Marcas de productos
CREATE TABLE Marca (
    id INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    descripcion VARCHAR(100) NOT NULL UNIQUE,
    usuarioRegistro VARCHAR(50) NOT NULL DEFAULT SUSER_SNAME(),
    fechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
    estado SMALLINT NOT NULL DEFAULT 1 -- -1:Eliminado, 0: Inactivo, 1: Activo
);

-- Tabla para gestionar los productos (sin referencia a UnidadMedida)
CREATE TABLE Producto (
    id INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    -- IdUnidadMedida ha sido removido
    IdCategoria INT NOT NULL,
    IdMarca INT NOT NULL,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    descripcion VARCHAR(250) NOT NULL,
    saldo DECIMAL(10, 2) NOT NULL DEFAULT 0,
    precioVenta DECIMAL(10, 2) NOT NULL CHECK (precioVenta > 0),
    usuarioRegistro VARCHAR(50) NOT NULL DEFAULT SUSER_SNAME(),
    fechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
    estado SMALLINT NOT NULL DEFAULT 1, -- -1:Eliminado, 0: Inactivo, 1: Activo
    CONSTRAINT fk_Producto_Categoria FOREIGN KEY(IdCategoria) REFERENCES Categoria(id),
    CONSTRAINT fk_Producto_Marca FOREIGN KEY(IdMarca) REFERENCES Marca(id)
);

-- Tabla para gestionar los proveedores
CREATE TABLE Proveedor (
    id INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    nit BIGINT NOT NULL UNIQUE,
    razonSocial VARCHAR(100) NOT NULL,
    direccion VARCHAR(250) NULL,
    telefono VARCHAR(30) NOT NULL,
    representante VARCHAR(100) NOT NULL,
    usuarioRegistro VARCHAR(50) NOT NULL DEFAULT SUSER_SNAME(),
    fechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
    estado SMALLINT NOT NULL DEFAULT 1 -- -1:Eliminado, 0: Inactivo, 1: Activo
);

-- Tabla para gestionar los empleados
CREATE TABLE Empleado (
    id INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    cedulaIdentidad VARCHAR(12) NOT NULL UNIQUE,
    nombres VARCHAR(30) NOT NULL,
    primerApellido VARCHAR(30) NULL,
    segundoApellido VARCHAR(30) NULL,
    direccion VARCHAR(250) NOT NULL,
    celular BIGINT NOT NULL,
    cargo VARCHAR(50) NOT NULL,
    usuarioRegistro VARCHAR(50) NOT NULL DEFAULT SUSER_SNAME(),
    fechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
    estado SMALLINT NOT NULL DEFAULT 1 -- -1:Eliminado, 0: Inactivo, 1: Activo
);

-- Tabla para gestionar los usuarios del sistema (relacionado con empleados)
CREATE TABLE Usuario (
    id INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    idEmpleado INT NOT NULL UNIQUE,
    usuario VARCHAR(20) NOT NULL UNIQUE,
    clave VARCHAR(250) NOT NULL,
    usuarioRegistro VARCHAR(50) NOT NULL DEFAULT SUSER_SNAME(),
    fechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
    estado SMALLINT NOT NULL DEFAULT 1, -- -1:Eliminado, 0: Inactivo, 1: Activo
    CONSTRAINT fk_Usuario_Empleado FOREIGN KEY(idEmpleado) REFERENCES Empleado(id)
);

-- Tabla para gestionar las compras a proveedores
CREATE TABLE Compra (
    id INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    idProveedor INT NOT NULL,
    transaccion VARCHAR(50) NOT NULL UNIQUE,
    fecha DATE NOT NULL DEFAULT GETDATE(),
    total DECIMAL(10, 2) NOT NULL DEFAULT 0,
    usuarioRegistro VARCHAR(50) NOT NULL DEFAULT SUSER_SNAME(),
    fechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
    estado SMALLINT NOT NULL DEFAULT 1, -- -1:Eliminado, 0: Inactivo, 1: Activo
    CONSTRAINT fk_Compra_Proveedor FOREIGN KEY(idProveedor) REFERENCES Proveedor(id)
);

-- Tabla para los detalles de cada compra (productos en una compra)
CREATE TABLE CompraDetalle (
    id INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    idCompra INT NOT NULL,
    idProducto INT NOT NULL,
    cantidad DECIMAL(10, 2) NOT NULL CHECK (cantidad > 0),
    precioUnitario DECIMAL(10, 2) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    usuarioRegistro VARCHAR(50) NOT NULL DEFAULT SUSER_SNAME(),
    fechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
    estado SMALLINT NOT NULL DEFAULT 1, -- -1:Eliminado, 0: Inactivo, 1: Activo
    CONSTRAINT fk_CompraDetalle_Compra FOREIGN KEY(idCompra) REFERENCES Compra(id) ON DELETE CASCADE,
    CONSTRAINT fk_CompraDetalle_Producto FOREIGN KEY(idProducto) REFERENCES Producto(id)
);

-- Tabla para gestionar las ventas a clientes
CREATE TABLE Venta (
    id INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    idCliente INT NOT NULL,
    idEmpleado INT NOT NULL,
    transaccion VARCHAR(50) NOT NULL UNIQUE,
    fecha DATE NOT NULL DEFAULT GETDATE(),
    total DECIMAL(10, 2) NOT NULL CHECK (total >= 0),
    usuarioRegistro VARCHAR(50) NOT NULL DEFAULT SUSER_SNAME(),
    fechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
    estado SMALLINT NOT NULL DEFAULT 1, -- -1:Eliminado, 0: Inactivo, 1: Activo
    CONSTRAINT fk_Venta_Empleado FOREIGN KEY(idEmpleado) REFERENCES Empleado(id)
);

-- Tabla para los detalles de cada venta (productos en una venta)
CREATE TABLE VentaDetalle (
    id INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    idVenta INT NOT NULL,
    idProducto INT NOT NULL,
    cantidad DECIMAL(10, 2) NOT NULL CHECK (cantidad > 0),
    precioUnitario DECIMAL(10, 2) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    usuarioRegistro VARCHAR(50) NOT NULL DEFAULT SUSER_SNAME(),
    fechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
    estado SMALLINT NOT NULL DEFAULT 1, -- -1:Eliminado, 0: Inactivo, 1: Activo
    CONSTRAINT fk_VentaDetalle_Venta FOREIGN KEY(idVenta) REFERENCES Venta(id) ON DELETE CASCADE,
    CONSTRAINT fk_VentaDetalle_Producto FOREIGN KEY(idProducto) REFERENCES Producto(id)
);

-- Agregando la tabla Cliente
CREATE TABLE Cliente (
    id INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    nombreCompleto VARCHAR(100) NOT NULL,
    nit VARCHAR(20) NULL UNIQUE,
    direccion VARCHAR(250) NULL,
    telefono VARCHAR(30) NULL,
    email VARCHAR(100) NULL,
    usuarioRegistro VARCHAR(50) NOT NULL DEFAULT SUSER_SNAME(),
    fechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
    estado SMALLINT NOT NULL DEFAULT 1 -- -1:Eliminado, 0: Inactivo, 1: Activo
);

-- Añadir la clave foránea a la tabla Venta una vez que Cliente existe
ALTER TABLE Venta
ADD CONSTRAINT fk_Venta_Cliente FOREIGN KEY(idCliente) REFERENCES Cliente(id);


GO


-- -----------------------------------------------------------
-- Procedimientos Almacenados
-- -----------------------------------------------------------

-- Procedimiento para listar productos con información de categoría y marca (sin unidad de medida)
CREATE OR ALTER PROC paProductoListar @parametro VARCHAR(100)
AS
    SELECT
        p.id,
        p.codigo,
        p.descripcion,
        c.descripcion AS categoria,
        m.descripcion AS marca,
        p.saldo,
        p.precioVenta,
        p.usuarioRegistro,
        p.fechaRegistro,
        p.estado,
        p.IdCategoria,
        p.IdMarca
    FROM Producto p
    INNER JOIN Categoria c ON p.IdCategoria = c.id
    INNER JOIN Marca m ON p.IdMarca = m.id
    WHERE p.estado <> -1
      AND (
            p.codigo LIKE '%' + REPLACE(@parametro, ' ', '%') + '%' OR
            p.descripcion LIKE '%' + REPLACE(@parametro, ' ', '%') + '%' OR
            c.descripcion LIKE '%' + REPLACE(@parametro, ' ', '%') + '%' OR
            m.descripcion LIKE '%' + REPLACE(@parametro, ' ', '%') + '%'
          )
    ORDER BY p.estado DESC, p.descripcion ASC;
GO

-- Procedimiento para listar empleados
CREATE OR ALTER PROC paEmpleadoListar @parametro VARCHAR(100)
AS
    SELECT ISNULL(u.usuario,'--') AS usuario,e.*
    FROM Empleado e
    LEFT JOIN Usuario u ON e.id = u.idEmpleado
    WHERE e.estado<>-1
        AND e.cedulaIdentidad+e.nombres+ISNULL(e.primerApellido,'')+ISNULL(e.segundoApellido,'') LIKE '%'+REPLACE(@parametro,' ','%')+'%'
    ORDER BY e.estado DESC, e.nombres ASC, e.primerApellido ASC;
GO

-- Procedimiento para listar categorías
CREATE OR ALTER PROC paCategoriaListar @parametro VARCHAR(100)
AS
BEGIN
    SELECT * FROM Categoria
    WHERE estado <> -1 AND (descripcion LIKE '%' + REPLACE(@parametro, ' ', '%') + '%')
    ORDER BY estado DESC, descripcion ASC;
END;
GO

-- Procedimiento para listar marcas
CREATE OR ALTER PROC paMarcaListar @parametro VARCHAR(100)
AS
BEGIN
    SELECT * FROM Marca
    WHERE estado <> -1 AND (descripcion LIKE '%' + REPLACE(@parametro, ' ', '%') + '%')
    ORDER BY estado DESC, descripcion ASC;
END;
GO

-- Procedimiento para listar proveedores
CREATE OR ALTER PROC paProveedorListar @parametro VARCHAR(100)
AS
BEGIN
    SELECT * FROM Proveedor
    WHERE estado <> -1 AND (CAST(nit AS VARCHAR) + razonSocial + ISNULL(direccion, '') + telefono + representante LIKE '%' + REPLACE(@parametro, ' ', '%') + '%')
    ORDER BY estado DESC, razonSocial ASC;
END;
GO

-- Procedimiento para listar compras
CREATE OR ALTER PROC paCompraListar @parametro VARCHAR(100)
AS
BEGIN
    SELECT c.*, p.razonSocial AS proveedor
    FROM Compra c
    INNER JOIN Proveedor p ON c.idProveedor = p.id
    WHERE c.estado <> -1 AND (CAST(c.transaccion AS VARCHAR) + p.razonSocial LIKE '%' + REPLACE(@parametro, ' ', '%') + '%')
    ORDER BY c.estado DESC, c.fecha DESC;
END;
GO

-- Procedimiento para listar detalles de compra
CREATE OR ALTER PROC paCompraDetalleListar @parametro VARCHAR(100)
AS
BEGIN
    SELECT cd.*, pr.descripcion AS producto
    FROM CompraDetalle cd
    INNER JOIN Producto pr ON cd.idProducto = pr.id
    WHERE cd.estado <> -1 AND (pr.codigo + pr.descripcion LIKE '%' + REPLACE(@parametro, ' ', '%') + '%')
    ORDER BY cd.estado DESC, pr.descripcion ASC;
END;
GO

-- Procedimiento para listar ventas
CREATE OR ALTER PROC paVentaListar
    @parametro VARCHAR(100)
AS
BEGIN
    SELECT
        v.id AS idVenta,
        v.fecha AS fechaVenta,
        v.total AS totalVenta,
        v.estado AS estadoVenta,
        v.usuarioRegistro AS usuarioVenta,
        v.fechaRegistro AS fechaRegistroVenta,
        -- Concatenación del nombre completo del empleado
        e.nombres + ' ' + ISNULL(e.primerApellido, '') + ' ' + ISNULL(e.segundoApellido, '') AS empleado,
        -- Nombre completo del cliente
        c.nombreCompleto AS cliente
    FROM Venta v
    INNER JOIN Empleado e ON v.idEmpleado = e.id
    LEFT JOIN Cliente c ON v.idCliente = c.id
    WHERE v.estado <> -1
      AND (
            CAST(v.id AS VARCHAR) +
            e.nombres +
            ISNULL(e.primerApellido, '') +
            ISNULL(e.segundoApellido, '') +
            ISNULL(c.nombreCompleto, '') LIKE '%' + REPLACE(@parametro, ' ', '%') + '%'
        )
    ORDER BY v.estado DESC, v.fecha DESC;
END;
GO

-- Procedimiento para listar detalles de venta
CREATE OR ALTER PROC paVentaDetalleListar @parametro VARCHAR(100)
AS
BEGIN
    SELECT vd.*, p.descripcion AS producto
    FROM VentaDetalle vd
    INNER JOIN Producto p ON vd.idProducto = p.id
    WHERE vd.estado <> -1 AND (p.codigo + p.descripcion LIKE '%' + REPLACE(@parametro, ' ', '%') + '%')
    ORDER BY vd.estado DESC, p.descripcion ASC;
END;
GO

-- -----------------------------------------------------------
-- Datos de Ejemplo (DML - Data Manipulation Language)
-- -----------------------------------------------------------

-- Inserción de categorías
INSERT INTO Categoria(descripcion) VALUES ('Celulares'),('Laptops'),('Accesorios'),('Electrodomésticos'),('Componentes PC');

-- Inserción de marcas
INSERT INTO Marca(descripcion) VALUES ('Samsung'),('Apple'),('HP'),('Dell'),('Logitech'),('LG'),('Sony');

-- Inserción de productos (ejemplos de electrónica) - sin referencia a UnidadMedida
INSERT INTO Producto(codigo, descripcion, IdCategoria, IdMarca, saldo, precioVenta)
VALUES ('SMG-S24', 'Smartphone Samsung Galaxy S24 Ultra', (SELECT id FROM Categoria WHERE descripcion = 'Celulares'), (SELECT id FROM Marca WHERE descripcion = 'Samsung'), 10, 1200.00);

INSERT INTO Producto(codigo, descripcion, IdCategoria, IdMarca, saldo, precioVenta)
VALUES ('APL-MBP16', 'Laptop Apple MacBook Pro 16"', (SELECT id FROM Categoria WHERE descripcion = 'Laptops'), (SELECT id FROM Marca WHERE descripcion = 'Apple'), 5, 2500.00);

INSERT INTO Producto(codigo, descripcion, IdCategoria, IdMarca, saldo, precioVenta)
VALUES ('HP-ENVY15', 'Laptop HP Envy 15', (SELECT id FROM Categoria WHERE descripcion = 'Laptops'), (SELECT id FROM Marca WHERE descripcion = 'HP'), 8, 1100.00);

INSERT INTO Producto(codigo, descripcion, IdCategoria, IdMarca, saldo, precioVenta)
VALUES ('LOG-MXM', 'Mouse Inalámbrico Logitech MX Master 3S', (SELECT id FROM Categoria WHERE descripcion = 'Accesorios'), (SELECT id FROM Marca WHERE descripcion = 'Logitech'), 50, 99.99);

INSERT INTO Producto(codigo, descripcion, IdCategoria, IdMarca, saldo, precioVenta)
VALUES ('LG-OLED65', 'Televisor LG OLED 65 Pulgadas', (SELECT id FROM Categoria WHERE descripcion = 'Electrodomésticos'), (SELECT id FROM Marca WHERE descripcion = 'LG'), 3, 1800.00);

-- Inserción de un empleado
INSERT INTO Empleado(cedulaIdentidad, nombres, primerApellido, segundoApellido, direccion, celular, cargo)
VALUES ('1234567', 'Juan', 'Pérez', 'López', 'Calle Loa N° 50', 71717171, 'Cajero');

-- Inserción de un usuario (asociado al empleado anterior)
INSERT INTO Usuario(idEmpleado, usuario, clave)
VALUES ((SELECT id FROM Empleado WHERE cedulaIdentidad = '1234567'), 'jperez', 'clave_segura_a_hashear');

-- Actualización de la clave (ejemplo, en una aplicación real, se hashearía)
UPDATE Usuario SET clave='i0hcoO/nssY6WOs9pOp5Xw==' WHERE usuario='jperez';

-- Inserción de un cliente
INSERT INTO Cliente(nombreCompleto, nit, direccion, telefono, email)
VALUES ('María García', '1234567890123', 'Av. Siempre Viva 742', '555123456', 'maria.garcia@example.com');

INSERT INTO Cliente(nombreCompleto, nit, direccion, telefono, email)
VALUES ('Consumidor Final', NULL, 'N/A', 'N/A', 'N/A');

-- Inserción de un proveedor
INSERT INTO Proveedor(nit, razonSocial, direccion, telefono, representante)
VALUES (1020304050607, 'ElectroMayorista S.A.', 'Zona Industrial, Calle Principal #100', '222-3333', 'Roberto Díaz');

-- Ejemplo de inserción de una compra
INSERT INTO Compra(idProveedor, transaccion, fecha, total)
VALUES ((SELECT id FROM Proveedor WHERE razonSocial = 'ElectroMayorista S.A.'), 'COMPRA-001', GETDATE(), 0);

-- Ejemplo de inserción de detalles de compra
INSERT INTO CompraDetalle(idCompra, idProducto, cantidad, precioUnitario, total)
VALUES (
    (SELECT id FROM Compra WHERE transaccion = 'COMPRA-001'),
    (SELECT id FROM Producto WHERE codigo = 'SMG-S24'),
    5,
    1000.00,
    5 * 1000.00
);

INSERT INTO CompraDetalle(idCompra, idProducto, cantidad, precioUnitario, total)
VALUES (
    (SELECT id FROM Compra WHERE transaccion = 'COMPRA-001'),
    (SELECT id FROM Producto WHERE codigo = 'LOG-MXM'),
    20,
    80.00,
    20 * 80.00
);

-- Actualizar el saldo de productos después de la compra (ejemplo de lógica de negocio)
UPDATE Producto SET saldo = saldo + 5 WHERE codigo = 'SMG-S24';
UPDATE Producto SET saldo = saldo + 20 WHERE codigo = 'LOG-MXM';

-- Actualizar el total de la compra (debería hacerse con un trigger o lógica de aplicación)
UPDATE Compra
SET total = (SELECT SUM(total) FROM CompraDetalle WHERE idCompra = (SELECT id FROM Compra WHERE transaccion = 'COMPRA-001'))
WHERE transaccion = 'COMPRA-001';

-- Ejemplo de inserción de una venta
INSERT INTO Venta(idCliente, idEmpleado, transaccion, fecha, total)
VALUES (
    (SELECT id FROM Cliente WHERE nombreCompleto = 'María García'),
    (SELECT id FROM Empleado WHERE cedulaIdentidad = '1234567'),
    'VENTA-001',
    GETDATE(),
    0
);

-- Ejemplo de inserción de detalles de venta
INSERT INTO VentaDetalle(idVenta, idProducto, cantidad, precioUnitario, total)
VALUES (
    (SELECT id FROM Venta WHERE transaccion = 'VENTA-001'),
    (SELECT id FROM Producto WHERE codigo = 'SMG-S24'),
    1,
    1200.00,
    1 * 1200.00
);

INSERT INTO VentaDetalle(idVenta, idProducto, cantidad, precioUnitario, total)
VALUES (
    (SELECT id FROM Venta WHERE transaccion = 'VENTA-001'),
    (SELECT id FROM Producto WHERE codigo = 'LOG-MXM'),
    2,
    99.99,
    2 * 99.99
);

-- Actualizar el saldo de productos después de la venta (ejemplo de lógica de negocio)
UPDATE Producto SET saldo = saldo - 1 WHERE codigo = 'SMG-S24';
UPDATE Producto SET saldo = saldo - 2 WHERE codigo = 'LOG-MXM';

-- Actualizar el total de la venta (debería hacerse con un trigger o lógica de aplicación)
UPDATE Venta
SET total = (SELECT SUM(total) FROM VentaDetalle WHERE idVenta = (SELECT id FROM Venta WHERE transaccion = 'VENTA-001'))
WHERE transaccion = 'VENTA-001';


-- Consultas de prueba para listar todas las tablas
SELECT * FROM Categoria;
SELECT * FROM Marca;
SELECT * FROM Producto;
SELECT * FROM Proveedor;
SELECT * FROM Empleado;
SELECT * FROM Usuario;
SELECT * FROM Cliente;
SELECT * FROM Compra;
SELECT * FROM CompraDetalle;
SELECT * FROM Venta;
SELECT * FROM VentaDetalle;

-- Ejecuciones de prueba de los procedimientos almacenados de listado
EXEC paProductoListar '';
EXEC paProductoListar 'Samsung';
EXEC paProductoListar 'Mouse';
EXEC paEmpleadoListar '';
EXEC paCategoriaListar ''; 
EXEC paMarcaListar '';
EXEC paProveedorListar '';
EXEC paCompraListar '';
EXEC paCompraDetalleListar '';
EXEC paVentaListar '';
EXEC paVentaDetalleListar '';


-- Tuplas para la tabla [dbo].[Cliente]
INSERT INTO [dbo].[Cliente] (nombreCompleto, nit, direccion, telefono, email, usuarioRegistro, fechaRegistro, estado) VALUES
('Juan Perez Lopez', '12345678', 'Av. Principal #123, Ciudad', '77712345', 'juan.perez@example.com', 'System', GETDATE(), 1),
('Maria Garcia Martinez', '87654321', 'Calle Falsa #456, Pueblo', '65432109', 'maria.g@example.com', 'System', GETDATE(), 1),
('Carlos Ramirez Sanchez', '11223344', 'Zona Central, Edif. Alfa', '70011223', 'carlos.r@example.com', 'System', GETDATE(), 1),
('Ana Torres Vega', '55667788', 'Barrio Sur, Casa #789', '79944556', 'ana.t@example.com', 'System', GETDATE(), 1),
('Luis Fernandez Gomez', '99887766', 'Av. Las Flores #10, Capital', '71188990', 'luis.f@example.com', 'System', GETDATE(), 1);

-- Tuplas para la tabla [dbo].[Producto]
-- Note: IdCategoria and IdMarca values must correspond to existing IDs in Categoria and Marca tables.
-- The IDs used here (1,2,3,4 for Categoria and 1,2,3,4,5,6 for Marca) are based on the sample INSERTs above.
INSERT INTO [dbo].[Producto] (IdCategoria, IdMarca, codigo, descripcion, saldo, precioVenta, usuarioRegistro, fechaRegistro, estado) VALUES
(1, 1, 'P-CEL001', 'Samsung Galaxy S23 Ultra', 50.00, 999.99, 'System', GETDATE(), 1),
(1, 2, 'P-CEL002', 'iPhone 15 Pro Max', 30.00, 1299.00, 'System', GETDATE(), 1),
(1, 3, 'P-CEL003', 'Xiaomi Redmi Note 12', 120.00, 249.50, 'System', GETDATE(), 1),
(2, 4, 'P-LAP001', 'Dell XPS 15 Laptop', 25.00, 1500.00, 'System', GETDATE(), 1),
(2, 5, 'P-LAP002', 'HP Spectre x360', 15.00, 1350.75, 'System', GETDATE(), 1),
(3, 6, 'P-TV001', 'Sony Bravia 65 Pulgadas 4K', 10.00, 899.99, 'System', GETDATE(), 1),
(4, 1, 'P-ACC001', 'Audífonos Samsung Galaxy Buds 2', 200.00, 120.00, 'System', GETDATE(), 1),
(4, 2, 'P-ACC002', 'Apple Watch Series 9', 70.00, 399.00, 'System', GETDATE(), 1);



-- Tuplas para la tabla [dbo].[Venta]
-- Make sure the IDs (idCliente, idEmpleado, IdProducto) exist in their respective tables.
-- The Fecha and FechaRegistro columns will use GETDATE() by default unless specified.
-- Estado defaults to 1. Total must be >= 0.

INSERT INTO [dbo].[Venta] (idCliente, idEmpleado, transaccion, fecha, total, usuarioRegistro, fechaRegistro, estado, IdProducto) VALUES
(1, 1, 'VENTA-001-20250623', '2025-06-23', 1249.50, 'usuario_venta', GETDATE(), 1, 3), -- Cliente 1, Empleado 1, Producto 3 (Xiaomi Redmi Note 12)
(3, 1, 'VENTA-002-20250623', '2025-06-23', 999.99, 'usuario_venta', GETDATE(), 1, 1), -- Cliente 2, Empleado 2, Producto 1 (Samsung Galaxy S23 Ultra)
(3, 1, 'VENTA-003-20250624', '2025-06-24', 1299.00, 'usuario_venta', GETDATE(), 1, 2), -- Cliente 3, Empleado 1, Producto 2 (iPhone 15 Pro Max)
(4, 1, 'VENTA-004-20250624', '2025-06-24', 1500.00, 'usuario_venta', GETDATE(), 1, 4), -- Cliente 4, Empleado 3, Producto 4 (Dell XPS 15)
(1, 1, 'VENTA-005-20250625', '2025-06-25', 399.00, 'usuario_venta', GETDATE(), 1, 8), -- Cliente 1, Empleado 2, Producto 8 (Apple Watch Series 9)
(5, 1, 'VENTA-006-20250625', '2025-06-25', 899.99, 'usuario_venta', GETDATE(), 1, 6); -- Cliente 5, Empleado 3, Producto 6 (Sony Bravia TV)