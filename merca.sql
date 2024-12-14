-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 14-12-2024 a las 03:10:24
-- Versión del servidor: 10.4.28-MariaDB
-- Versión de PHP: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `merca`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `registro_compra` (IN `p_id_cliente` INT, IN `p_id_producto` INT, IN `p_cantidad` INT)   BEGIN
    DECLARE stock_actual INT;

    -- Obtener el stock actual del producto específico
    SELECT stock INTO stock_actual
    FROM productos
    WHERE id_producto = p_id_producto
    LIMIT 1;

    -- Validar si hay stock suficiente
    IF stock_actual >= p_cantidad THEN
        -- Registrar la compra
        INSERT INTO compras (id_cliente, id_producto, cantidad, fecha)
        VALUES (p_id_cliente, p_id_producto, p_cantidad, NOW());

        -- Actualizar el stock solo del producto seleccionado
        UPDATE productos
        SET stock = stock_actual - p_cantidad
        WHERE id_producto = p_id_producto;
    ELSE
        -- Lanza un error si no hay stock suficiente
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Stock insuficiente';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `reporte_devoluciones` (IN `p_mes` INT, IN `p_anio` INT)   BEGIN  
    SELECT d.*, c.fecha, c.id_cliente  
    FROM Devoluciones d  
    JOIN Compras c ON d.id_compra = c.id_compra  
    WHERE MONTH(c.fecha) = p_mes AND YEAR(c.fecha) = p_anio;  
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clientes`
--

CREATE TABLE `clientes` (
  `id_cliente` int(11) NOT NULL,
  `nombre` varchar(100) DEFAULT NULL,
  `correo_electronico` varchar(250) NOT NULL,
  `direccion` varchar(255) DEFAULT NULL,
  `latitud` decimal(10,8) DEFAULT NULL,
  `longitud` decimal(11,8) DEFAULT NULL,
  `contraseña` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `clientes`
--

INSERT INTO `clientes` (`id_cliente`, `nombre`, `correo_electronico`, `direccion`, `latitud`, `longitud`, `contraseña`) VALUES
(1, 'Daniel', 'pepo@gmail.com', 'car 73', 4.62289357, -74.13530404, '123');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `compras`
--

CREATE TABLE `compras` (
  `id_compra` int(11) NOT NULL,
  `id_cliente` int(11) DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `fecha` datetime DEFAULT NULL,
  `cantidad` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `compras`
--

INSERT INTO `compras` (`id_compra`, `id_cliente`, `id_producto`, `fecha`, `cantidad`) VALUES
(2, 1, 38, '2024-12-12 19:05:57', 2),
(3, 1, 38, '2024-12-12 19:06:36', 1),
(4, 1, 38, '2024-12-12 19:06:43', 1),
(5, 1, 38, '2024-12-12 19:07:06', 1),
(6, 1, 37, '2024-12-12 19:07:29', 1),
(7, 1, 38, '2024-12-12 19:16:16', 1),
(8, 1, 37, '2024-12-12 19:19:10', 1),
(9, 1, 37, '2024-12-12 19:19:10', 1),
(10, 1, 34, '2024-12-12 19:36:54', 1),
(11, 1, 34, '2024-12-12 19:37:40', 1),
(12, 1, 38, '2024-12-12 19:49:47', 1),
(13, 1, 38, '2024-12-12 19:50:39', 1),
(14, 1, 38, '2024-12-12 19:54:51', 1),
(15, 1, 37, '2024-12-12 19:55:14', 8),
(16, 1, 18, '2024-12-13 18:58:16', 1),
(17, 1, 38, '2024-12-13 19:43:45', 1),
(18, 1, 38, '2024-12-13 19:53:33', 1),
(19, 1, 38, '2024-12-13 19:55:49', 1),
(20, 1, 38, '2024-12-13 19:56:35', 1);

--
-- Disparadores `compras`
--
DELIMITER $$
CREATE TRIGGER `after_insert_compras` AFTER INSERT ON `compras` FOR EACH ROW BEGIN  
    UPDATE Productos SET stock = stock - NEW.cantidad WHERE id_producto = NEW.id_producto;  
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `devoluciones`
--

CREATE TABLE `devoluciones` (
  `id_devolucion` int(11) NOT NULL,
  `id_compra` int(11) DEFAULT NULL,
  `fecha` datetime DEFAULT NULL,
  `motivo` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Disparadores `devoluciones`
--
DELIMITER $$
CREATE TRIGGER `after_insert_devoluciones` AFTER INSERT ON `devoluciones` FOR EACH ROW BEGIN  
    DECLARE v_cantidad INT;  
    SELECT cantidad INTO v_cantidad FROM Compras WHERE id_compra = NEW.id_compra;  
    UPDATE Productos SET stock = stock + v_cantidad WHERE id_producto = (SELECT id_producto FROM Compras WHERE id_compra = NEW.id_compra);  
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id_producto` int(11) NOT NULL,
  `nombre` varchar(100) DEFAULT NULL,
  `descripcion` text DEFAULT NULL,
  `precio` decimal(10,2) DEFAULT NULL,
  `stock` int(11) DEFAULT NULL,
  `imagen` varchar(250) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`id_producto`, `nombre`, `descripcion`, `precio`, `stock`, `imagen`) VALUES
(5, 'Samsung Galaxy S24 Ultra 5G', 'Rendimiento excepcional y batería de larga duración', 4800000.00, 148, './img/samsung_destacado.png'),
(6, 'Iphone 16 Pro Max', 'El smartphone más avanzado con cámara de 48MP', 5500000.00, 148, './img/iphone_destacado.png'),
(7, 'Xiaomi 14 Ultra 5G', 'Compacto y respetuoso con el medio ambiente', 6300000.00, 148, './img/xiami_destacado.jpg'),
(8, 'Samsung Galaxy S23', 'Smartphone de gama alta con pantalla Dynamic AMOLED 2X', 5000000.00, 148, './img/samsungs23.png'),
(9, 'iPhone 15', 'Smartphone premium con chip A17 y pantalla OLED', 3049900.00, 148, './img/iphone15.png'),
(10, 'Google Pixel 8', 'Smartphone con cámara avanzada y Android puro', 3740000.00, 148, './img/google_pixel8.jpg'),
(11, 'OnePlus 11', 'Smartphone con Snapdragon 8 Gen 2 y pantalla Fluid AMOLED', 5049000.00, 148, './img/oneplus11.png'),
(12, 'Xiaomi 13', 'Smartphone de alto rendimiento con cámara Leica', 629900.00, 148, './img/xiaomi13.jpg'),
(13, 'Huawei Mate 50', 'Smartphone con pantalla OLED y procesador Kirin 9000', 6299900.00, 148, './img/huawei_mate50.png'),
(14, 'Oppo Find X6', 'Smartphone con diseño premium y cámara de 50 MP', 4529900.00, 148, './img/oppo_findx6.png'),
(15, 'Realme GT 2 Pro', 'Smartphone con Snapdragon 8 Gen 1 y pantalla AMOLED', 4387688.00, 148, './img/realme_gt_2pro.png'),
(16, 'Sony Xperia 1 IV', 'Smartphone con pantalla 4K y cámara de 12 MP', 742000.00, 148, './img/sony_xperia_1iv.png'),
(17, 'Motorola Edge 40', 'Smartphone con pantalla curva y 5G', 1000000.00, 148, './img/Motorola_Edge40.png'),
(18, 'Asus ROG Phone 6', 'Smartphone gaming con pantalla de 165 Hz', 3052969.00, 147, './img/Asus_ROG_Phone6.png'),
(19, 'LG Velvet', 'Smartphone elegante con cámara triple y pantalla OLED', 1950000.00, 148, './img/LG_Velvet.png'),
(20, 'Nokia X30', 'Smartphone sostenible con pantalla AMOLED y 5G', 4000000.00, 148, './img/NokiaX30.jpg'),
(21, 'Vivo X90 Pro', 'Smartphone con cámara de 50 MP y pantalla AMOLED', 4400000.00, 148, './img/VivoX90Pro.png'),
(22, 'Infinix Zero Ultra', 'Smartphone con carga rápida de 180W y pantalla AMOLED', 3599000.00, 148, './img/Infinix_Zero_Ultra.png'),
(23, 'Tecno Phantom X2', 'Smartphone con diseño único y cámara de 50 MP', 3699900.00, 148, './img/Tecno_Phantom_X2.png'),
(24, 'Redmi Note 12 Pro', 'Smartphone de gama media con pantalla AMOLED y 5G', 1199900.00, 148, './img/Redmi_Note_12_Pro.png'),
(25, 'Samsung Galaxy A54', 'Smartphone de gama media con pantalla Super AMOLED', 1235990.00, 148, './img/SAMSUNG_A54_NEGRO.png'),
(27, 'Google Pixel 7a', 'Smartphone económico con cámara de 12 MP y 5G', 2999000.00, 148, './img/Google_Pixel_7a.png'),
(28, 'OnePlus Nord 3', 'Smartphone con Snapdragon 8 Gen 1 y pantalla Fluid AMOLED', 2174797.00, 148, './img/OnePlus_Nord_3.png'),
(29, 'Xiaomi Redmi 10', 'Smartphone de gama baja con pantalla Full HD+', 784452.00, 148, './img/Xiaomi_Redmi_10.png'),
(30, 'Motorola Moto G Power', 'Smartphone de gran batería y pantalla de 6.5\"', 1089534.00, 148, './img/Motorola_Moto_G_Power.png'),
(31, 'Oppo Reno 8 Pro', 'Smartphone con cámara de 50 MP y carga rápida', 2179111.00, 148, './img/Oppo_Reno_8 Pro.png'),
(32, 'Honor Magic 5 Pro', 'Smartphone de gama alta con cámara de 50 MP', 4576182.00, 148, './img/Honor_Magic_5_Pro.png'),
(33, 'Sony Xperia 10 IV', 'Smartphone compacto con pantalla OLED y 5G', 1956881.00, 148, './img/Sony_Xperia_10_IV.png'),
(34, 'Nokia G50', 'Smartphone de gama baja con batería de 5000 mAh', 871618.00, 148, './img/Nokia_G50.jpg'),
(35, 'Vivo Y73', 'Smartphone económico con cámara de 64 MP', 1215968.00, 148, './img/Vivo_Y73.png'),
(36, 'Infinix Note 12', 'Smartphone de gama media con carga rápida de 33W', 958784.00, 148, './img/Infinix_Note_12.jpg'),
(37, 'Asus Zenfone 9', 'Smartphone compacto con Snapdragon 8 Gen 1 y cámara de 50 MP', 3050773.00, 140, './img/Asus_Zenfone_9.png'),
(38, 'iPhone SE 3', 'Smartphone compacto con chip A15 Bionic y cámara de 12 MP', 1869715.00, 143, './img/iPhone_SE_3.jpg');

--
-- Disparadores `productos`
--
DELIMITER $$
CREATE TRIGGER `NotificacionStockBajo` AFTER UPDATE ON `productos` FOR EACH ROW BEGIN
    -- Declarar variable fuera de la condición
    DECLARE mensaje VARCHAR(255);
    
    -- Verificar si el stock es menor a 5
    IF NEW.stock < 5 THEN
        -- Construir el mensaje solo si el stock es bajo
        SET mensaje = CONCAT(
            'AVISO: El producto "', NEW.nombre, 
            '" tiene un stock bajo: ', NEW.stock, ' unidades.'
        );
        -- Enviar la advertencia personalizada
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = mensaje;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sucursales`
--

CREATE TABLE `sucursales` (
  `id_sucursal` int(11) NOT NULL,
  `nombre` varchar(100) DEFAULT NULL,
  `latitud` decimal(10,8) DEFAULT NULL,
  `longitud` decimal(11,8) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `sucursales`
--

INSERT INTO `sucursales` (`id_sucursal`, `nombre`, `latitud`, `longitud`) VALUES
(1, 'Sucursal sur', 4.58541472, -74.14449299),
(2, 'Sucursal Norte', 4.75209567, -74.02989361);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`id_cliente`);

--
-- Indices de la tabla `compras`
--
ALTER TABLE `compras`
  ADD PRIMARY KEY (`id_compra`),
  ADD KEY `id_cliente` (`id_cliente`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `devoluciones`
--
ALTER TABLE `devoluciones`
  ADD PRIMARY KEY (`id_devolucion`),
  ADD KEY `id_compra` (`id_compra`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id_producto`);

--
-- Indices de la tabla `sucursales`
--
ALTER TABLE `sucursales`
  ADD PRIMARY KEY (`id_sucursal`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `clientes`
--
ALTER TABLE `clientes`
  MODIFY `id_cliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `compras`
--
ALTER TABLE `compras`
  MODIFY `id_compra` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT de la tabla `devoluciones`
--
ALTER TABLE `devoluciones`
  MODIFY `id_devolucion` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `id_producto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=39;

--
-- AUTO_INCREMENT de la tabla `sucursales`
--
ALTER TABLE `sucursales`
  MODIFY `id_sucursal` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `compras`
--
ALTER TABLE `compras`
  ADD CONSTRAINT `compras_ibfk_1` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`),
  ADD CONSTRAINT `compras_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`);

--
-- Filtros para la tabla `devoluciones`
--
ALTER TABLE `devoluciones`
  ADD CONSTRAINT `devoluciones_ibfk_1` FOREIGN KEY (`id_compra`) REFERENCES `compras` (`id_compra`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
