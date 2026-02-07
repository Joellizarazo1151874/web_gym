-- MySQL dump 10.13  Distrib 8.0.45, for Linux (x86_64)
--
-- Host: localhost    Database: ft_gym
-- ------------------------------------------------------
-- Server version	8.0.45-0ubuntu0.22.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `asistencias`
--

DROP TABLE IF EXISTS `asistencias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `asistencias` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` int unsigned NOT NULL COMMENT 'ID del usuario que asistió',
  `membresia_id` int unsigned DEFAULT NULL COMMENT 'ID de la membresía activa al momento de la asistencia',
  `fecha_entrada` datetime NOT NULL COMMENT 'Fecha y hora de entrada',
  `fecha_salida` datetime DEFAULT NULL COMMENT 'Fecha y hora de salida',
  `codigo_qr` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Código QR escaneado',
  `tipo_acceso` enum('entrada','salida') COLLATE utf8mb4_unicode_ci DEFAULT 'entrada' COMMENT 'Tipo de acceso',
  `dispositivo` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Dispositivo o ubicación del escáner',
  `observaciones` text COLLATE utf8mb4_unicode_ci COMMENT 'Observaciones adicionales',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_asistencias_usuario` (`usuario_id`),
  KEY `idx_asistencias_membresia` (`membresia_id`),
  KEY `idx_asistencias_fecha` (`fecha_entrada`),
  KEY `idx_asistencias_qr` (`codigo_qr`),
  CONSTRAINT `fk_asistencias_membresia` FOREIGN KEY (`membresia_id`) REFERENCES `membresias` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_asistencias_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Registro de asistencias al gimnasio';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `asistencias`
--

LOCK TABLES `asistencias` WRITE;
/*!40000 ALTER TABLE `asistencias` DISABLE KEYS */;
INSERT INTO `asistencias` VALUES (17,10,4,'2026-01-08 17:03:17',NULL,'1004914530','entrada','form',NULL,'2026-01-08 17:03:17'),(18,10,4,'2026-01-08 17:03:46',NULL,'1004914530','entrada','form',NULL,'2026-01-08 17:03:46'),(19,10,4,'2026-01-08 17:03:53',NULL,'1004914530','entrada','form',NULL,'2026-01-08 17:03:53'),(20,10,4,'2026-01-08 17:04:58',NULL,'1004914530','entrada','form',NULL,'2026-01-08 17:04:58'),(21,10,4,'2026-01-08 17:13:03',NULL,'1004914530','entrada','form',NULL,'2026-01-08 17:13:03'),(22,10,4,'2026-01-08 17:13:16',NULL,'1004914530','entrada','form',NULL,'2026-01-08 17:13:16'),(23,10,4,'2026-01-08 17:13:31',NULL,'1004914530','entrada','form',NULL,'2026-01-08 17:13:31'),(24,10,4,'2026-01-08 17:13:31',NULL,'1004914530','entrada','qr',NULL,'2026-01-08 17:13:31'),(25,10,4,'2026-01-08 17:13:40',NULL,'1004914530','entrada','numpad',NULL,'2026-01-08 17:13:40'),(26,10,4,'2026-01-08 17:13:53',NULL,'1004914530','entrada','numpad',NULL,'2026-01-08 17:13:53'),(27,10,4,'2026-01-08 17:14:06',NULL,'1004914530','entrada','qr',NULL,'2026-01-08 17:14:06'),(28,10,4,'2026-01-09 07:30:33',NULL,'1004914530','entrada','mobile-app',NULL,'2026-01-09 07:30:33'),(29,10,4,'2026-01-09 07:31:11',NULL,'1004914530','entrada','mobile-app',NULL,'2026-01-09 07:31:11'),(30,10,4,'2026-01-09 07:31:52',NULL,'1004914530','entrada','mobile-app',NULL,'2026-01-09 07:31:52'),(31,11,6,'2026-01-10 22:43:34',NULL,'1127053018','entrada','form',NULL,'2026-01-11 03:43:34'),(32,10,10,'2026-02-04 15:23:23',NULL,'1004914530','entrada','form',NULL,'2026-02-04 20:23:23'),(33,10,10,'2026-02-04 15:42:23',NULL,'1004914530','entrada','form',NULL,'2026-02-04 20:42:23'),(34,10,10,'2026-02-04 15:42:48',NULL,'1004914530','entrada','numpad',NULL,'2026-02-04 20:42:48');
/*!40000 ALTER TABLE `asistencias` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `chat_mensajes`
--

DROP TABLE IF EXISTS `chat_mensajes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chat_mensajes` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `chat_id` int unsigned NOT NULL,
  `remitente_id` int unsigned NOT NULL,
  `mensaje` text NOT NULL,
  `imagen_url` varchar(500) DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `leido` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_mensajes_usuario` (`remitente_id`),
  KEY `idx_chat_creado_en` (`chat_id`,`creado_en`),
  CONSTRAINT `fk_mensajes_chat` FOREIGN KEY (`chat_id`) REFERENCES `chats` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_mensajes_usuario` FOREIGN KEY (`remitente_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=104 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `chat_mensajes`
--

LOCK TABLES `chat_mensajes` WRITE;
/*!40000 ALTER TABLE `chat_mensajes` DISABLE KEYS */;
INSERT INTO `chat_mensajes` VALUES (45,15,11,'Hola Bro',NULL,'2026-01-12 12:18:16',1),(46,15,11,'Bro',NULL,'2026-01-13 08:16:51',1),(47,15,10,'Que paso??',NULL,'2026-01-13 08:17:14',1),(48,15,11,'Nada bro',NULL,'2026-01-13 08:17:47',1),(49,15,10,'Bien',NULL,'2026-01-13 08:17:56',1),(50,15,10,'Que hace?',NULL,'2026-01-13 08:18:25',1),(51,15,10,'Hola Bro',NULL,'2026-01-13 09:03:15',1),(52,15,10,'Bien o que',NULL,'2026-01-13 09:03:26',1),(53,15,10,'Men',NULL,'2026-01-13 09:14:58',1),(54,15,11,'Que paso canson',NULL,'2026-01-13 09:15:26',1),(55,15,11,'Voy a pagar la membresia',NULL,'2026-01-13 09:18:59',1),(56,15,11,'Hola',NULL,'2026-01-13 09:31:08',1),(57,15,11,'Men',NULL,'2026-01-13 09:33:50',1),(58,15,10,'Men',NULL,'2026-01-13 09:50:14',1),(59,15,11,'Que',NULL,'2026-01-13 09:50:27',1),(60,15,10,'Men',NULL,'2026-01-13 10:08:21',1),(61,15,11,'Que',NULL,'2026-01-13 10:08:29',1),(62,15,11,'Todo bien',NULL,'2026-01-13 10:08:37',1),(63,15,11,'📷 Foto','https://functionaltraining.site/uploads/chats/chat_69666003d22ba1.77551508.jpg','2026-01-13 10:08:52',1),(64,15,11,'📷 Foto','https://functionaltraining.site/uploads/chats/chat_6966601312dee1.63233178.jpg','2026-01-13 10:09:07',1),(66,15,11,'Jajaja',NULL,'2026-01-13 10:11:07',1),(67,15,10,'Bien',NULL,'2026-01-13 10:11:11',1),(68,15,10,'Que',NULL,'2026-01-13 10:11:16',1),(69,15,10,'Que',NULL,'2026-01-13 10:11:20',1),(70,15,10,'No',NULL,'2026-01-13 10:11:29',1),(71,15,10,'No',NULL,'2026-01-13 10:11:34',1),(72,15,10,'Nose',NULL,'2026-01-13 10:11:39',1),(73,15,10,'No',NULL,'2026-01-13 10:11:44',1),(74,15,10,'Se',NULL,'2026-01-13 10:11:46',1),(75,15,10,'Que',NULL,'2026-01-13 10:11:48',1),(76,15,10,'Pa',NULL,'2026-01-13 10:11:50',1),(77,15,10,'Sa',NULL,'2026-01-13 10:11:52',1),(79,15,10,'Jajaja perro',NULL,'2026-01-13 10:12:10',1),(80,15,11,'Men',NULL,'2026-01-13 10:23:02',1),(81,15,11,'Que hace',NULL,'2026-01-13 10:23:08',1),(82,15,11,'Ya no mire',NULL,'2026-01-13 10:23:12',1),(84,15,10,'Hola mariko',NULL,'2026-01-13 11:10:20',1),(85,15,10,'Breinder',NULL,'2026-01-13 11:10:34',1),(86,15,10,'Hable conmigo mariko',NULL,'2026-01-13 11:11:06',1),(87,15,11,'😄',NULL,'2026-01-13 11:11:13',1),(88,15,10,'Quiuvo chamo no va a hacer el desayuno',NULL,'2026-01-13 11:11:17',1),(89,15,11,':v',NULL,'2026-01-13 11:11:21',1),(90,15,11,'Fua',NULL,'2026-01-13 11:11:23',1),(91,15,11,'🍑',NULL,'2026-01-13 11:11:34',1),(92,15,10,'Ja webon ta potente la paja',NULL,'2026-01-13 11:11:41',1),(93,15,10,'Pille la de Brenda','https://functionaltraining.site/uploads/chats/chat_69666ec91b0ab6.96477960.jpg','2026-01-13 11:11:53',1),(94,15,10,'Que le parece',NULL,'2026-01-13 11:11:56',1),(97,15,10,'Hola bro',NULL,'2026-01-18 22:54:12',1),(98,15,10,'Se le daño el celular',NULL,'2026-01-18 22:54:17',1),(99,15,10,'Men',NULL,'2026-01-19 00:31:33',1),(100,18,10,'Hola',NULL,'2026-02-03 11:27:47',1),(101,18,13,'Listo',NULL,'2026-02-03 11:28:34',1),(102,18,13,'😁',NULL,'2026-02-03 11:28:41',1),(103,18,10,'🤣',NULL,'2026-02-03 11:28:55',1);
/*!40000 ALTER TABLE `chat_mensajes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `chat_participantes`
--

DROP TABLE IF EXISTS `chat_participantes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chat_participantes` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `chat_id` int unsigned NOT NULL,
  `usuario_id` int unsigned NOT NULL,
  `agregado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_chat_usuario` (`chat_id`,`usuario_id`),
  KEY `fk_participantes_usuario` (`usuario_id`),
  CONSTRAINT `fk_participantes_chat` FOREIGN KEY (`chat_id`) REFERENCES `chats` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_participantes_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `chat_participantes`
--

LOCK TABLES `chat_participantes` WRITE;
/*!40000 ALTER TABLE `chat_participantes` DISABLE KEYS */;
INSERT INTO `chat_participantes` VALUES (23,15,11,'2026-01-12 12:18:10'),(24,15,10,'2026-01-12 12:18:10'),(29,18,13,'2026-02-03 11:27:29'),(30,18,10,'2026-02-03 11:27:29'),(31,19,10,'2026-02-03 11:27:58'),(32,19,1,'2026-02-03 11:27:58');
/*!40000 ALTER TABLE `chat_participantes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `chats`
--

DROP TABLE IF EXISTS `chats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chats` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(150) DEFAULT NULL,
  `es_grupal` tinyint(1) NOT NULL DEFAULT '0',
  `creado_por` int unsigned NOT NULL,
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_chats_usuario` (`creado_por`),
  CONSTRAINT `fk_chats_usuario` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `chats`
--

LOCK TABLES `chats` WRITE;
/*!40000 ALTER TABLE `chats` DISABLE KEYS */;
INSERT INTO `chats` VALUES (7,'Chat de Bienvenida 🏋️',1,10,'2026-01-10 08:19:59'),(15,'Joel Lizarazo',0,11,'2026-01-12 12:18:10'),(18,'Joel Lizarazo',0,13,'2026-02-03 11:27:29'),(19,'Admin Sistema',0,10,'2026-02-03 11:27:58');
/*!40000 ALTER TABLE `chats` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `checkin_live_buffer`
--

DROP TABLE IF EXISTS `checkin_live_buffer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `checkin_live_buffer` (
  `id` tinyint NOT NULL DEFAULT '1',
  `code` varchar(32) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `checkin_live_buffer`
--

LOCK TABLES `checkin_live_buffer` WRITE;
/*!40000 ALTER TABLE `checkin_live_buffer` DISABLE KEYS */;
/*!40000 ALTER TABLE `checkin_live_buffer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `clase_horarios`
--

DROP TABLE IF EXISTS `clase_horarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `clase_horarios` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `clase_id` int unsigned NOT NULL COMMENT 'ID de la clase',
  `dia_semana` int NOT NULL COMMENT 'Día de la semana (1=lunes, 7=domingo)',
  `hora_inicio` time NOT NULL COMMENT 'Hora de inicio',
  `hora_fin` time NOT NULL COMMENT 'Hora de finalización',
  `activo` tinyint(1) DEFAULT '1' COMMENT '1=activo, 0=inactivo',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_clase_horarios_clase` (`clase_id`),
  CONSTRAINT `fk_clase_horarios_clase` FOREIGN KEY (`clase_id`) REFERENCES `clases` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Horarios de clases';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clase_horarios`
--

LOCK TABLES `clase_horarios` WRITE;
/*!40000 ALTER TABLE `clase_horarios` DISABLE KEYS */;
INSERT INTO `clase_horarios` VALUES (3,3,5,'14:30:00','15:30:00',1,'2026-01-08 19:02:01'),(4,4,2,'09:00:00','10:00:00',1,'2026-01-09 05:36:38'),(5,4,7,'08:00:00','09:00:00',1,'2026-01-09 06:01:21'),(8,5,6,'08:00:00','11:30:00',1,'2026-01-14 02:11:54'),(10,5,2,'08:00:00','09:00:00',1,'2026-01-14 04:23:40');
/*!40000 ALTER TABLE `clase_horarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `clase_reservas`
--

DROP TABLE IF EXISTS `clase_reservas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `clase_reservas` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` int unsigned NOT NULL COMMENT 'ID del usuario',
  `clase_horario_id` int unsigned NOT NULL COMMENT 'ID del horario de la clase',
  `fecha_clase` date NOT NULL COMMENT 'Fecha de la clase',
  `estado` enum('reservada','confirmada','cancelada','asistio','no_asistio') COLLATE utf8mb4_unicode_ci DEFAULT 'reservada' COMMENT 'Estado de la reserva',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_clase_reservas_usuario` (`usuario_id`),
  KEY `idx_clase_reservas_horario` (`clase_horario_id`),
  KEY `idx_clase_reservas_fecha` (`fecha_clase`),
  CONSTRAINT `fk_clase_reservas_horario` FOREIGN KEY (`clase_horario_id`) REFERENCES `clase_horarios` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_clase_reservas_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Reservas de clases';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clase_reservas`
--

LOCK TABLES `clase_reservas` WRITE;
/*!40000 ALTER TABLE `clase_reservas` DISABLE KEYS */;
/*!40000 ALTER TABLE `clase_reservas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `clases`
--

DROP TABLE IF EXISTS `clases`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `clases` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nombre de la clase',
  `descripcion` text COLLATE utf8mb4_unicode_ci COMMENT 'Descripción de la clase',
  `instructor_id` int unsigned DEFAULT NULL COMMENT 'ID del instructor',
  `capacidad_maxima` int DEFAULT NULL COMMENT 'Capacidad máxima de participantes',
  `duracion_minutos` int DEFAULT NULL COMMENT 'Duración en minutos',
  `activo` tinyint(1) DEFAULT '1' COMMENT '1=activo, 0=inactivo',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_clases_instructor` (`instructor_id`),
  KEY `idx_clases_activo` (`activo`),
  CONSTRAINT `fk_clases_instructor` FOREIGN KEY (`instructor_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Clases grupales';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clases`
--

LOCK TABLES `clases` WRITE;
/*!40000 ALTER TABLE `clases` DISABLE KEYS */;
INSERT INTO `clases` VALUES (3,'Funcional','funcional mañanero',NULL,50,50,1,'2026-01-08 19:01:05','2026-01-14 05:07:18'),(4,'Yoga','Yoga matutina',NULL,20,45,1,'2026-01-09 05:35:20','2026-01-09 05:35:20'),(5,'Pierna explosiva 2','para mataste',10,20,60,1,'2026-01-14 01:35:00','2026-01-14 02:29:24');
/*!40000 ALTER TABLE `clases` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `configuracion`
--

DROP TABLE IF EXISTS `configuracion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `configuracion` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `clave` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Clave única de la configuración',
  `valor` text COLLATE utf8mb4_unicode_ci COMMENT 'Valor de la configuración (puede ser JSON para arrays)',
  `tipo` enum('string','number','boolean','json','time') COLLATE utf8mb4_unicode_ci DEFAULT 'string' COMMENT 'Tipo de dato',
  `categoria` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT 'general' COMMENT 'Categoría de la configuración',
  `descripcion` text COLLATE utf8mb4_unicode_ci COMMENT 'Descripción de la configuración',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_configuracion_clave` (`clave`),
  KEY `idx_configuracion_categoria` (`categoria`)
) ENGINE=InnoDB AUTO_INCREMENT=17610 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Configuración del sistema';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `configuracion`
--

LOCK TABLES `configuracion` WRITE;
/*!40000 ALTER TABLE `configuracion` DISABLE KEYS */;
INSERT INTO `configuracion` VALUES (1,'gimnasio_nombre','Functional Training','string','general','Nombre del gimnasio','2025-11-19 23:45:57','2026-02-04 20:40:50'),(2,'gimnasio_direccion','Calle Principal 666','string','general','Dirección del gimnasio','2025-11-19 23:45:57','2026-02-04 20:40:50'),(3,'gimnasio_ciudad','Cúcuta','string','general','Ciudad del gimnasio','2025-11-19 23:45:57','2026-02-04 20:40:50'),(4,'gimnasio_telefono','+57 1 234 5678','string','general','Teléfono de contacto','2025-11-19 23:45:57','2026-02-04 20:40:50'),(5,'gimnasio_email','info@ftgym.com','string','general','Email de contacto','2025-11-19 23:45:57','2026-02-04 20:40:50'),(6,'gimnasio_web','www.functionaltraining.site','string','general','Sitio web','2025-11-19 23:45:57','2026-02-04 20:40:50'),(7,'horario_apertura','06:00','time','horarios','Hora de apertura','2025-11-19 23:45:57','2026-02-04 20:40:50'),(8,'horario_cierre','20:30','time','horarios','Hora de cierre','2025-11-19 23:45:57','2026-02-04 20:40:50'),(9,'dias_semana','[\"Lunes\",\"Martes\",\"Mi\\u00e9rcoles\",\"Jueves\",\"Viernes\",\"S\\u00e1bado\"]','json','horarios','Días de la semana que está abierto','2025-11-19 23:45:57','2026-02-04 20:40:50'),(10,'notificaciones_email','1','boolean','notificaciones','Habilitar notificaciones por email','2025-11-19 23:45:57','2026-02-04 20:40:50'),(11,'notificaciones_sms','0','boolean','notificaciones','Habilitar notificaciones por SMS','2025-11-19 23:45:57','2026-02-04 20:40:50'),(12,'notificaciones_push','1','boolean','notificaciones','Habilitar notificaciones push','2025-11-19 23:45:57','2026-02-04 20:40:50'),(13,'sesion_timeout','0','number','seguridad','Timeout de sesión en minutos','2025-11-19 23:45:57','2026-02-04 20:40:50'),(14,'requiere_verificacion_email','0','boolean','seguridad','Requerir verificación de email','2025-11-19 23:45:57','2026-02-04 20:40:50'),(15,'metodos_pago','[\"efectivo\",\"tarjeta\",\"transferencia\",\"app\"]','json','pagos','Métodos de pago habilitados','2025-11-19 23:45:57','2026-02-04 20:40:50'),(16,'moneda','COP','string','pagos','Moneda del sistema','2025-11-19 23:45:57','2026-02-04 20:40:50'),(17,'iva','19','number','pagos','Porcentaje de IVA','2025-11-19 23:45:57','2026-02-04 20:40:50'),(18,'backup_automatico','1','boolean','sistema','Habilitar backup automático','2025-11-19 23:45:57','2026-02-04 20:40:50'),(19,'frecuencia_backup','diario','string','sistema','Frecuencia de backup','2025-11-19 23:45:57','2026-02-04 20:40:50'),(20,'mantener_logs','1','boolean','sistema','Mantener logs del sistema','2025-11-19 23:45:57','2026-02-04 20:40:50'),(21,'dias_logs','30','number','sistema','Días de retención de logs','2025-11-19 23:45:57','2026-02-04 20:40:50'),(144,'app_descuento','10','number','general',NULL,'2025-11-28 21:01:17','2026-02-04 20:40:50'),(241,'gimnasio_telefono_2','3209939817','string','general',NULL,'2025-12-06 06:26:16','2026-02-04 20:40:50'),(243,'gimnasio_email_2','','string','general',NULL,'2025-12-06 06:26:16','2026-02-04 20:40:50'),(344,'horario_sabado_apertura','07:00','time','general',NULL,'2025-12-06 06:44:55','2026-02-04 20:40:50'),(345,'horario_sabado_cierre','12:00','time','general',NULL,'2025-12-06 06:44:55','2026-02-04 20:40:50'),(346,'horario_domingo_apertura','08:00','time','general',NULL,'2025-12-06 06:44:55','2026-02-04 20:40:50'),(347,'horario_domingo_cierre','12:00','time','general',NULL,'2025-12-06 06:44:55','2026-02-04 20:40:50'),(488,'red_social_facebook_url','https://www.facebook.com/','string','general',NULL,'2025-12-06 06:52:44','2026-02-04 20:40:50'),(489,'red_social_facebook_activa','1','boolean','general',NULL,'2025-12-06 06:52:44','2026-02-04 20:40:50'),(490,'red_social_instagram_url','https://www.instagram.com/','string','general',NULL,'2025-12-06 06:52:44','2026-02-04 20:40:50'),(491,'red_social_instagram_activa','1','boolean','general',NULL,'2025-12-06 06:52:44','2026-02-04 20:40:50'),(492,'red_social_tiktok_url','https://www.tiktok.com/','string','general',NULL,'2025-12-06 06:52:44','2026-02-04 20:40:50'),(493,'red_social_tiktok_activa','1','boolean','general',NULL,'2025-12-06 06:52:44','2026-02-04 20:40:50'),(494,'red_social_x_url','https://www.x.com/','string','general',NULL,'2025-12-06 06:52:44','2026-02-04 20:40:50'),(495,'red_social_x_activa','1','boolean','general',NULL,'2025-12-06 06:52:44','2026-02-04 20:40:50'),(977,'sesion_never_expire','1','boolean','seguridad','Nunca cerrar sesión automáticamente (solo cierre manual)','2025-12-06 09:56:46','2026-02-04 20:40:50'),(1089,'checkin_qr_auto_enabled','0','string','general',NULL,'2025-12-11 05:19:31','2026-02-04 20:46:04'),(1090,'checkin_manual_enabled','1','string','general',NULL,'2025-12-11 05:19:31','2025-12-11 16:26:14'),(1091,'checkin_sound_enabled','1','string','general',NULL,'2025-12-11 05:19:31','2025-12-11 05:19:31'),(1092,'checkin_vibration_enabled','1','string','general',NULL,'2025-12-11 05:19:31','2025-12-11 05:19:31'),(1093,'checkin_auto_reset_seconds','5','string','general',NULL,'2025-12-11 05:19:31','2025-12-11 05:19:31'),(1109,'checkin_qr_position','left','string','general',NULL,'2025-12-11 05:29:40','2026-02-04 20:44:12'),(1162,'checkin_input_clear_seconds','3','string','general',NULL,'2025-12-11 06:32:32','2025-12-11 06:32:32'),(1176,'checkin_camera_device_id','','string','general',NULL,'2025-12-11 06:39:05','2026-01-08 00:05:20'),(1228,'logo_empresa','uploads/logo/logo_empresa.svg','string','general',NULL,'2025-12-11 07:15:40','2026-01-08 04:50:31'),(1485,'checkin_live_input','{\"code\":\"\",\"ts\":1770239916}','json','general',NULL,'2025-12-11 08:24:16','2026-02-04 21:18:36'),(15606,'fcm_server_key','','string','general','Clave del servidor de Firebase Cloud Messaging (FCM) para enviar notificaciones push','2026-01-12 21:13:37','2026-01-12 21:13:37'),(15607,'fcm_credentials_path','/var/www/html/config/ft-gym-bf8ce0fad533.json','string','general','Ruta al archivo JSON de credenciales de Firebase para FCM API V1','2026-01-13 02:31:41','2026-01-13 02:38:19');
/*!40000 ALTER TABLE `configuracion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ejercicios`
--

DROP TABLE IF EXISTS `ejercicios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ejercicios` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nombre del ejercicio',
  `descripcion` text COLLATE utf8mb4_unicode_ci COMMENT 'Descripción del ejercicio',
  `categoria` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Categoría (fuerza, cardio, flexibilidad, etc.)',
  `grupo_muscular` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Grupo muscular principal',
  `imagen` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Ruta de la imagen del ejercicio',
  `video_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'URL del video tutorial',
  `nivel` enum('principiante','intermedio','avanzado') COLLATE utf8mb4_unicode_ci DEFAULT 'principiante' COMMENT 'Nivel de dificultad',
  `activo` tinyint(1) DEFAULT '1' COMMENT '1=activo, 0=inactivo',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ejercicios_categoria` (`categoria`),
  KEY `idx_ejercicios_activo` (`activo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo de ejercicios';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ejercicios`
--

LOCK TABLES `ejercicios` WRITE;
/*!40000 ALTER TABLE `ejercicios` DISABLE KEYS */;
/*!40000 ALTER TABLE `ejercicios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fcm_tokens`
--

DROP TABLE IF EXISTS `fcm_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fcm_tokens` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` int unsigned NOT NULL COMMENT 'ID del usuario propietario del dispositivo',
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Token FCM del dispositivo',
  `plataforma` enum('android','ios') COLLATE utf8mb4_unicode_ci DEFAULT 'android' COMMENT 'Plataforma del dispositivo',
  `activo` tinyint(1) DEFAULT '1' COMMENT '1=activo, 0=inactivo',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_token` (`token`),
  KEY `idx_usuario_id` (`usuario_id`),
  KEY `idx_activo` (`activo`),
  CONSTRAINT `fk_fcm_tokens_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tokens FCM para notificaciones push';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fcm_tokens`
--

LOCK TABLES `fcm_tokens` WRITE;
/*!40000 ALTER TABLE `fcm_tokens` DISABLE KEYS */;
INSERT INTO `fcm_tokens` VALUES (1,10,'ctecsABwQIK_BNLze6r86Q:APA91bEIyRzrr4XTl3Bz_i-WjLlpjjq45mAXiE5ZrXU7pPVSGgwYIirFBhmHZ_ZWzAGJEX7utzwaGWFjZxZ2ywlc1GRZTdly9jrHmljDf7tI5MF_3W7eA-c','android',1,'2026-01-13 13:13:46','2026-01-13 13:17:01'),(2,11,'fRgU_r8wRNWFAVtA8zO5zI:APA91bHksQhMKrvdw8hpCwIeer50JVcsIrFNhTiA5Mn1x4fbi7F7pm0X7VSe_ceZusyuEjR17lnVl8PX6wlOx9ayeQLz2YLhuZHyPXDbUe9oMbyXBBf_vq8','android',1,'2026-01-13 13:16:00','2026-01-13 13:16:00'),(3,10,'fOmjqgtjRjOwTuJpPFP4Ge:APA91bGeOPLOHEbydcs5Tgp25V6ZtaIKEz3BiEK5TQ-tW2P1vx8igXpJpylXKfS7p8zNwJ5KPqGTUNDtAR2V6q5yWjFnSGaJ7nHwtBKfYJJPEGnDo2bKmU8','android',1,'2026-01-13 14:02:03','2026-01-13 14:18:02'),(4,11,'cg8RvK9GR6KPZeHVRo3Uj_:APA91bHYMSGK5iNRDlA7ny-KsZ7IN5TtSAlG0YQUerT8_iNpkPK-qkK6fih9LkVTPe04xeWYsd2eTvIWN6m-Mt7sVXmywqw5aqjaQdljKVs7YeN2xJhophE','android',1,'2026-01-13 14:02:59','2026-01-13 14:18:33'),(5,11,'fEJqIOxqQpmBBMbVsAQ5K0:APA91bGOyCcT77pyDCknzLxSOW3dyxovk7D4ZjPcSk_OhyFRxmygKjlCE6CqfECyi5z2M5gPuflm2sU_IFxCGeOX3dLh7w-Fjzoh0uGELfZEeDUoAm6v0Us','android',1,'2026-01-13 14:28:33','2026-01-13 14:28:33'),(6,10,'edDPgB5UQySru8zZTe0aFO:APA91bH2zESBbb1Pd-zhIqzNhMT4COr2v5uwZRgZgFr0R5d_2oMWioNx_Wq02pWpMWGJcYJj6p5uewp68U4r-Y0Va2O5RoiFB3sbEAwSD2AjaupN3OyF8TY','android',1,'2026-01-13 14:28:46','2026-01-13 14:28:46'),(7,11,'fm2JreteSeG90hDFmcCjGP:APA91bE6mUNB_iy5Z_QSRBRDCS6Bes1ZarksLxJDNOesi-xm3bdiqCl4XKSr0Or3VrRQ2VyBYQGaLKtksrA3l92MY1bNhQjsGxQqNsTf9UkcfilevOu_ozI','android',1,'2026-01-13 14:49:45','2026-01-13 14:49:45'),(8,10,'f34wFUo5RCmqWo8imFHkAL:APA91bEHhjimcfu6rDoe9RxyZG3K4zaUvKu_IWNkCKyux8tfUQxbAN9mjDk3rmPAYjCJszPGaQqGdPdXs3D2Uc0Kb430SP-4picxe1XZX3iFfFITa5knbfY','android',1,'2026-01-13 14:50:02','2026-01-13 14:50:02'),(9,12,'cHM8jW00Tma8v4GXjDWCEB:APA91bGWoqGsM-7duQzRP4c8A2l1lsUxmFhIXH7ivSL94EmEYDUkkvzbBKb80qPdBLfVe6YazdY9ldSkZUevJ6W_v8sKFBE0HAd08aU6ZOd-M0LCHvsVT4Q','android',1,'2026-01-13 15:07:40','2026-01-13 15:56:27'),(10,11,'c6a2M6-CTqSUV0eLdag06L:APA91bGx7XWvbj9kaC5WpmKnRnSos0QPK9wIW7Sw4Z2bScqJ2RRJaBXuWk5yjB6eHxX_5BlFeMf-hIaToaMyHtsOTwbrHCTEP0ywC8uCkqfui2CdhqYlboo','android',1,'2026-01-13 15:08:07','2026-01-13 16:13:33'),(11,10,'eT2WZmzNSPCx8-Y_Hc2xXs:APA91bHQ8bXykRJEgQd5-55zHlFrkCm5TLTLOihhBi5NerMgVHcGue2dX6DILR7atfMeV6WuLWTX45JlaP3NrVnMb1vmjOPtG6d_LshGJ6N3y9B4qXvLpeU','android',1,'2026-01-13 16:10:10','2026-02-03 01:11:01'),(12,10,'fM8Euua8TOyxJ6pELFC675:APA91bGpPFfmGPu4kqnHQZL-tBSVYPMCRZu0nyQwb72jv8omKDoz0hJnWABk0Nqa3Z_7y668La4_3KXU7p9T5HhK_Jb4NNXLEeoK0e7fmwqG7DFIyGClBQY','android',1,'2026-02-03 16:14:06','2026-02-05 03:17:58'),(13,13,'ewc3Bm1vQoS83PY_VGl2uS:APA91bGElcLhItVe7TG-91iRVOFLI8tm-hueBYYGJfSVwd4dMhTiUXZmuJFCiJDtQKJ0JskDX-z4MTYgyUH3WSE2it_B0TVHVKZ7ZIDZUJV0hEhGOlXG_Rg','android',1,'2026-02-03 16:14:39','2026-02-04 21:19:21');
/*!40000 ALTER TABLE `fcm_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `friend_requests`
--

DROP TABLE IF EXISTS `friend_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `friend_requests` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `de_usuario_id` int unsigned NOT NULL,
  `para_usuario_id` int unsigned NOT NULL,
  `estado` enum('pendiente','aceptada','rechazada') NOT NULL DEFAULT 'pendiente',
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `respondido_en` datetime DEFAULT NULL,
  `apodo` varchar(100) DEFAULT NULL,
  `apodo_inverso` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_request` (`de_usuario_id`,`para_usuario_id`),
  KEY `fk_req_para` (`para_usuario_id`),
  CONSTRAINT `fk_req_de` FOREIGN KEY (`de_usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_req_para` FOREIGN KEY (`para_usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `friend_requests`
--

LOCK TABLES `friend_requests` WRITE;
/*!40000 ALTER TABLE `friend_requests` DISABLE KEYS */;
INSERT INTO `friend_requests` VALUES (5,10,1,'aceptada','2026-01-12 07:55:19','2026-01-13 20:36:36',NULL,NULL),(6,1,12,'rechazada','2026-01-12 10:59:09','2026-01-12 11:22:31',NULL,NULL),(7,10,11,'aceptada','2026-01-12 12:17:36','2026-01-12 12:18:10',NULL,NULL),(8,11,12,'pendiente','2026-01-13 10:51:57',NULL,NULL,NULL),(9,11,10,'aceptada','2026-01-19 00:45:17','2026-01-19 00:46:48',NULL,NULL),(10,10,13,'aceptada','2026-02-03 11:27:22','2026-02-03 11:27:29',NULL,NULL),(11,14,13,'pendiente','2026-02-04 16:13:31',NULL,NULL,NULL);
/*!40000 ALTER TABLE `friend_requests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `landing_content`
--

DROP TABLE IF EXISTS `landing_content`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `landing_content` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `section` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Sección del landing (hero, about, classes, etc)',
  `element_id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'ID único del elemento editable',
  `content_type` enum('text','image','html') COLLATE utf8mb4_unicode_ci DEFAULT 'text' COMMENT 'Tipo de contenido',
  `content` text COLLATE utf8mb4_unicode_ci COMMENT 'Contenido del elemento (texto o HTML)',
  `image_path` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Ruta de la imagen si es tipo image',
  `alt_text` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Texto alternativo para imágenes',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_by` int unsigned DEFAULT NULL COMMENT 'ID del usuario que hizo la última actualización',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_landing_element` (`section`,`element_id`),
  KEY `idx_section` (`section`),
  KEY `updated_by` (`updated_by`),
  CONSTRAINT `landing_content_ibfk_1` FOREIGN KEY (`updated_by`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Contenidos editables del landing page';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `landing_content`
--

LOCK TABLES `landing_content` WRITE;
/*!40000 ALTER TABLE `landing_content` DISABLE KEYS */;
INSERT INTO `landing_content` VALUES (1,'header','logo-text','text','Functional Training',NULL,'','2025-12-06 06:18:12','2025-12-06 06:33:15',1),(2,'class','class-1-image','image',NULL,'uploads/landing/class_class-1-image_1765002062_6933cb4e26dd6.jpg','','2025-12-06 06:20:52','2025-12-06 06:21:02',1),(3,'footer','schedule-title-2','text','Sábado',NULL,'','2025-12-06 06:29:44','2025-12-06 06:29:44',1),(4,'footer','schedule-time-1','text','5:00am - 9:30pm',NULL,'','2025-12-06 06:30:27','2025-12-06 06:30:27',1),(5,'app','title','text','Tu gimnasio en el bolsillo',NULL,'','2025-12-06 06:30:58','2025-12-11 06:49:07',1),(6,'app','subtitle','text','Aplicación Móvil',NULL,'','2025-12-06 06:34:14','2025-12-06 08:04:21',1),(7,'blog','title','text','Últimas Publicaciones del Blog',NULL,'','2025-12-06 06:36:42','2025-12-06 06:52:05',1),(8,'class','class-2-title','text','Cardio y Fuerza',NULL,'','2025-12-06 07:10:03','2025-12-06 07:14:42',1),(9,'class','class-2-text','text','Circuitos funcionales y HIIT para aumentar resistencia, quemar grasa y mejorar tu condición física general en poco tiempo.',NULL,'','2025-12-06 07:10:32','2025-12-06 07:14:52',1),(10,'class','subtitle','text','Nuestras Clases',NULL,'','2025-12-06 07:11:19','2025-12-06 07:11:38',1),(11,'class','class-1-title','text','Levantamiento de Pesas',NULL,'','2025-12-06 07:13:04','2025-12-06 07:14:37',1),(12,'video','title','text','Explora la Vida Fitness',NULL,'','2025-12-06 07:15:02','2025-12-06 07:15:10',1),(13,'about','cta-button','text','Explorar más',NULL,'','2025-12-06 07:15:16','2025-12-06 07:15:26',1),(14,'blog','blog-1-text','text','Ampliamos la zona de peso libre y sumamos máquinas de última generación para que entrenes con más comodidad y seguridad en tus rutinas de fuerza e hipertrofia. ',NULL,'','2025-12-06 07:20:26','2025-12-06 07:20:47',1),(15,'blog','blog-1-date','text','15 Sep 2025',NULL,'','2025-12-06 07:20:31','2025-12-06 07:20:41',1),(16,'footer','brand-text','text','Entrena con nosotros y alcanza tus objetivos fitness. Instalaciones modernas, entrenadores profesionales y una comunidad activa.',NULL,'','2025-12-06 08:04:28','2025-12-06 08:04:28',1),(17,'footer','logo-text','text','Functional Training',NULL,'','2025-12-06 08:04:37','2025-12-06 08:04:47',1),(18,'about','coach-name','text','Eduard Puerto',NULL,'','2025-12-06 08:05:00','2026-02-04 20:47:08',1),(19,'footer','copyright','text','© 2025 Functional Training. Todos los derechos reservados por Joel Lizarazo',NULL,'','2025-12-11 07:11:47','2025-12-11 07:11:47',1),(20,'blog','subtitle','text','Nuestras Noticias',NULL,'','2025-12-11 16:30:09','2025-12-11 16:30:30',1),(21,'header','cta-button','text','Únete ahora',NULL,'','2025-12-11 16:33:05','2025-12-11 16:33:16',1);
/*!40000 ALTER TABLE `landing_content` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `membresias`
--

DROP TABLE IF EXISTS `membresias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `membresias` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` int unsigned NOT NULL COMMENT 'ID del usuario',
  `plan_id` int unsigned NOT NULL COMMENT 'ID del plan contratado',
  `fecha_inicio` date NOT NULL COMMENT 'Fecha de inicio de la membresía',
  `fecha_fin` date NOT NULL COMMENT 'Fecha de vencimiento de la membresía',
  `precio_pagado` decimal(10,2) NOT NULL COMMENT 'Precio que se pagó por esta membresía',
  `descuento_app` tinyint(1) DEFAULT '0' COMMENT '1=se aplicó descuento de app, 0=sin descuento',
  `estado` enum('activa','vencida','cancelada','suspendida') COLLATE utf8mb4_unicode_ci DEFAULT 'activa' COMMENT 'Estado de la membresía',
  `observaciones` text COLLATE utf8mb4_unicode_ci COMMENT 'Observaciones adicionales',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `recordatorio_3dias_enviado` datetime DEFAULT NULL COMMENT 'Fecha y hora en que se envió el recordatorio de 3 días',
  `recordatorio_1dia_enviado` datetime DEFAULT NULL COMMENT 'Fecha y hora en que se envió el recordatorio de 1 día',
  PRIMARY KEY (`id`),
  KEY `idx_membresias_usuario` (`usuario_id`),
  KEY `idx_membresias_plan` (`plan_id`),
  KEY `idx_membresias_estado` (`estado`),
  KEY `idx_membresias_fechas` (`fecha_inicio`,`fecha_fin`),
  CONSTRAINT `fk_membresias_plan` FOREIGN KEY (`plan_id`) REFERENCES `planes` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_membresias_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Membresías de usuarios';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `membresias`
--

LOCK TABLES `membresias` WRITE;
/*!40000 ALTER TABLE `membresias` DISABLE KEYS */;
INSERT INTO `membresias` VALUES (4,10,2,'2026-01-08','2026-01-15',25000.00,0,'vencida',NULL,'2026-01-08 17:02:51','2026-02-01 23:57:35',NULL,NULL),(5,11,1,'2026-01-09','2026-01-10',7000.00,0,'vencida',NULL,'2026-01-09 17:45:31','2026-01-11 05:48:10',NULL,NULL),(6,11,1,'2026-01-10','2026-01-11',7000.00,0,'vencida',NULL,'2026-01-10 11:59:19','2026-01-12 11:51:39',NULL,'2026-01-10 22:43:20'),(7,12,1,'2026-01-10','2026-01-11',7000.00,0,'vencida',NULL,'2026-01-11 03:47:45','2026-01-12 11:51:39',NULL,NULL),(8,12,1,'2026-01-11','2026-01-12',7000.00,0,'vencida',NULL,'2026-01-11 05:49:27','2026-01-13 15:55:35',NULL,NULL),(9,12,1,'2026-01-12','2026-01-13',7000.00,0,'vencida',NULL,'2026-01-12 11:52:10','2026-01-14 11:10:25',NULL,NULL),(10,10,2,'2026-02-02','2026-02-09',25000.00,0,'activa',NULL,'2026-02-02 22:36:22','2026-02-02 22:36:22',NULL,NULL),(11,13,3,'2026-02-03','2026-03-03',70000.00,0,'activa',NULL,'2026-02-03 16:05:57','2026-02-03 16:05:57',NULL,NULL),(12,13,1,'2026-02-04','2026-02-05',7000.00,0,'activa',NULL,'2026-02-04 21:17:37','2026-02-04 21:17:37',NULL,NULL),(13,14,1,'2026-02-04','2026-02-05',7000.00,0,'activa',NULL,'2026-02-04 21:18:55','2026-02-04 21:18:55',NULL,NULL);
/*!40000 ALTER TABLE `membresias` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notificaciones`
--

DROP TABLE IF EXISTS `notificaciones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notificaciones` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` int unsigned DEFAULT NULL COMMENT 'ID del usuario (NULL = notificación global)',
  `titulo` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Título de la notificación',
  `mensaje` text COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Mensaje de la notificación',
  `tipo` enum('info','success','warning','error','promocion') COLLATE utf8mb4_unicode_ci DEFAULT 'info' COMMENT 'Tipo de notificación',
  `leida` tinyint(1) DEFAULT '0' COMMENT '1=leída, 0=no leída',
  `fecha_leida` datetime DEFAULT NULL COMMENT 'Fecha en que se marcó como leída',
  `fecha` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de la notificación',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_notificaciones_usuario` (`usuario_id`),
  KEY `idx_notificaciones_leida` (`leida`),
  CONSTRAINT `fk_notificaciones_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Notificaciones del sistema';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notificaciones`
--

LOCK TABLES `notificaciones` WRITE;
/*!40000 ALTER TABLE `notificaciones` DISABLE KEYS */;
INSERT INTO `notificaciones` VALUES (7,12,'Breinder wladimir','Te envió una solicitud de amistad','info',0,NULL,'2026-01-13 10:51:57','2026-01-13 15:51:57'),(8,NULL,'Bienvenidos a FTGYM','compas sean bienvenidos a este increible gym','info',1,'2026-01-13 11:00:25','2026-01-13 10:56:15','2026-01-13 15:56:15'),(9,NULL,'Notificacion 2 de prueba','prueba de notificacion push','success',1,'2026-01-13 11:13:13','2026-01-13 11:12:43','2026-01-13 16:12:43'),(10,12,'Te extrañamos en el gimnasio 💪','Hola Carlos Mendoza, hace 7 día(s) que no te vemos en el gimnasio. ¡Vuelve y continúa con tu rutina! Te esperamos.','info',0,NULL,'2026-01-13 11:19:24','2026-01-13 16:19:24'),(16,10,'¡Feliz Cumpleaños! 🎉','¡Feliz cumpleaños Joel Lizarazo! Esperamos verte hoy en el gimnasio. Te deseamos un día lleno de energía y éxito. ¡Vamos a entrenar! 💪','promocion',1,'2026-01-13 19:38:15','2026-01-13 11:54:53','2026-01-13 16:54:53'),(17,NULL,'notificacion de prueba 2','pruebna notificacion push','promocion',1,'2026-01-13 13:13:04','2026-01-13 12:01:45','2026-01-13 17:01:45'),(18,NULL,'prueba notificacion interna','esto es una prueba','error',1,'2026-01-13 13:12:58','2026-01-13 12:29:20','2026-01-13 17:29:20'),(19,10,'Breinder wladimir','Te envió una solicitud de amistad','info',1,'2026-01-19 00:46:30','2026-01-19 00:45:17','2026-01-19 05:45:17'),(20,10,'Te extrañamos en el gimnasio 💪','Hola Joel Lizarazo, hace 25 día(s) que no te vemos en el gimnasio. ¡Vuelve y continúa con tu rutina! Te esperamos.','info',1,'2026-02-03 11:24:19','2026-02-03 11:22:00','2026-02-03 16:22:00'),(21,13,'Te extrañamos en el gimnasio 💪','Hola edison puerto, hace 7 día(s) que no te vemos en el gimnasio. ¡Vuelve y continúa con tu rutina! Te esperamos.','info',0,NULL,'2026-02-03 11:22:00','2026-02-03 16:22:00'),(22,NULL,'calse gluteos hoy','listo','info',0,NULL,'2026-02-03 11:23:39','2026-02-03 16:23:39'),(23,13,'Joel Lizarazo','Te envió una solicitud de amistad','info',1,'2026-02-03 11:28:07','2026-02-03 11:27:22','2026-02-03 16:27:22'),(24,13,'Te extrañamos en el gimnasio 💪','Hola edison puerto, hace 7 día(s) que no te vemos en el gimnasio. ¡Vuelve y continúa con tu rutina! Te esperamos.','info',0,NULL,'2026-02-04 15:35:02','2026-02-04 20:35:02'),(25,13,'eduard puerto','Te envió una solicitud de amistad','info',1,'2026-02-04 16:17:47','2026-02-04 16:13:31','2026-02-04 21:13:31');
/*!40000 ALTER TABLE `notificaciones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notificaciones_leidas`
--

DROP TABLE IF EXISTS `notificaciones_leidas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notificaciones_leidas` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `notificacion_id` int unsigned NOT NULL,
  `usuario_id` int unsigned NOT NULL,
  `fecha_leida` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_notificacion_usuario` (`notificacion_id`,`usuario_id`),
  KEY `idx_usuario_id` (`usuario_id`),
  KEY `idx_notificacion_id` (`notificacion_id`),
  CONSTRAINT `notificaciones_leidas_ibfk_1` FOREIGN KEY (`notificacion_id`) REFERENCES `notificaciones` (`id`) ON DELETE CASCADE,
  CONSTRAINT `notificaciones_leidas_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notificaciones_leidas`
--

LOCK TABLES `notificaciones_leidas` WRITE;
/*!40000 ALTER TABLE `notificaciones_leidas` DISABLE KEYS */;
INSERT INTO `notificaciones_leidas` VALUES (1,18,10,'2026-01-14 00:38:14'),(2,17,10,'2026-01-14 00:38:15'),(3,16,10,'2026-01-14 00:38:15'),(4,9,10,'2026-01-14 00:37:53'),(5,8,10,'2026-01-14 00:37:55'),(9,18,1,'2026-01-14 01:04:22'),(10,9,1,'2026-01-14 01:04:23'),(11,17,1,'2026-01-14 01:04:24'),(12,8,1,'2026-01-14 01:04:27'),(13,18,11,'2026-01-19 05:19:33'),(14,17,11,'2026-01-19 05:19:34'),(15,9,11,'2026-01-19 05:19:44'),(16,8,11,'2026-01-19 05:19:39'),(18,19,10,'2026-01-19 05:46:30'),(19,22,10,'2026-02-03 16:24:18'),(20,20,10,'2026-02-03 16:24:19'),(21,23,13,'2026-02-03 16:28:07'),(22,22,1,'2026-02-04 20:34:30'),(23,25,13,'2026-02-04 21:17:47');
/*!40000 ALTER TABLE `notificaciones_leidas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pagos`
--

DROP TABLE IF EXISTS `pagos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pagos` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `membresia_id` int unsigned DEFAULT NULL COMMENT 'ID de la membresía pagada (si aplica)',
  `usuario_id` int unsigned NOT NULL COMMENT 'ID del usuario que realizó el pago',
  `tipo` enum('membresia','producto','clase_especial','otro') COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Tipo de pago',
  `monto` decimal(10,2) NOT NULL COMMENT 'Monto del pago',
  `metodo_pago` enum('efectivo','tarjeta','transferencia','app','otro') COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Método de pago',
  `referencia` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Número de referencia o transacción',
  `estado` enum('pendiente','completado','cancelado','reembolsado') COLLATE utf8mb4_unicode_ci DEFAULT 'pendiente' COMMENT 'Estado del pago',
  `fecha_pago` datetime DEFAULT NULL COMMENT 'Fecha y hora del pago',
  `observaciones` text COLLATE utf8mb4_unicode_ci COMMENT 'Observaciones del pago',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_pagos_membresia` (`membresia_id`),
  KEY `idx_pagos_usuario` (`usuario_id`),
  KEY `idx_pagos_estado` (`estado`),
  KEY `idx_pagos_fecha` (`fecha_pago`),
  CONSTRAINT `fk_pagos_membresia` FOREIGN KEY (`membresia_id`) REFERENCES `membresias` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_pagos_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Historial de pagos';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pagos`
--

LOCK TABLES `pagos` WRITE;
/*!40000 ALTER TABLE `pagos` DISABLE KEYS */;
/*!40000 ALTER TABLE `pagos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pedido_items`
--

DROP TABLE IF EXISTS `pedido_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pedido_items` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `pedido_id` int unsigned NOT NULL COMMENT 'ID del pedido',
  `producto_id` int unsigned NOT NULL COMMENT 'ID del producto',
  `cantidad` int NOT NULL COMMENT 'Cantidad del producto',
  `precio_unitario` decimal(10,2) NOT NULL COMMENT 'Precio unitario al momento del pedido',
  `subtotal` decimal(10,2) NOT NULL COMMENT 'Subtotal (cantidad * precio_unitario)',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_pedido_items_pedido` (`pedido_id`),
  KEY `idx_pedido_items_producto` (`producto_id`),
  CONSTRAINT `fk_pedido_items_pedido` FOREIGN KEY (`pedido_id`) REFERENCES `pedidos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pedido_items_producto` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Items de pedidos';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pedido_items`
--

LOCK TABLES `pedido_items` WRITE;
/*!40000 ALTER TABLE `pedido_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `pedido_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pedidos`
--

DROP TABLE IF EXISTS `pedidos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pedidos` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` int unsigned NOT NULL COMMENT 'ID del usuario que realizó el pedido',
  `numero_pedido` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Número único del pedido',
  `total` decimal(10,2) NOT NULL COMMENT 'Total del pedido',
  `metodo_pago` enum('efectivo','tarjeta','transferencia','app') COLLATE utf8mb4_unicode_ci DEFAULT 'efectivo' COMMENT 'Método de pago',
  `estado` enum('pendiente','confirmado','en_preparacion','listo','entregado','cancelado') COLLATE utf8mb4_unicode_ci DEFAULT 'pendiente' COMMENT 'Estado del pedido',
  `fecha_pedido` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha y hora del pedido',
  `fecha_entrega` datetime DEFAULT NULL COMMENT 'Fecha y hora de entrega',
  `observaciones` text COLLATE utf8mb4_unicode_ci COMMENT 'Observaciones del pedido',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pedidos_numero` (`numero_pedido`),
  KEY `idx_pedidos_usuario` (`usuario_id`),
  KEY `idx_pedidos_estado` (`estado`),
  CONSTRAINT `fk_pedidos_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Pedidos de productos';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pedidos`
--

LOCK TABLES `pedidos` WRITE;
/*!40000 ALTER TABLE `pedidos` DISABLE KEYS */;
/*!40000 ALTER TABLE `pedidos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `plan_entrenamiento`
--

DROP TABLE IF EXISTS `plan_entrenamiento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `plan_entrenamiento` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `titulo` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `descripcion_ia` text COLLATE utf8mb4_unicode_ci,
  `ejercicios_json` text COLLATE utf8mb4_unicode_ci,
  `fecha` date NOT NULL,
  `completado` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `usuario_id` (`usuario_id`,`fecha`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `plan_entrenamiento`
--

LOCK TABLES `plan_entrenamiento` WRITE;
/*!40000 ALTER TABLE `plan_entrenamiento` DISABLE KEYS */;
INSERT INTO `plan_entrenamiento` VALUES (15,10,'Pierna Explosiva - Fuerza + Volumen',NULL,'[{\"n\":\"Sentadilla libre\",\"d\":\"4 series x 5 reps (RPE 9, descanso 3 min)\",\"v\":\"\"},{\"n\":\"Prensa inclinada\",\"d\":\"3 series x 8-10 reps (RPE 8, descanso 2 min)\",\"v\":\"\"},{\"n\":\"Peso muerto rumano\",\"d\":\"3 series x 8 reps (RPE 7, descanso 90 seg)\",\"v\":\"\"},{\"n\":\"Extensiones de cuadriceps\",\"d\":\"3 series x 12-15 reps (RPE 6, descanso 60 seg)\",\"v\":\"\"},{\"n\":\"Curl femoral acostado\",\"d\":\"3 series x 12 reps (RPE 7, descanso 60 seg)\",\"v\":\"\"},{\"n\":\"Elevación de talones\",\"d\":\"4 series x 15 reps (descanso 45 seg)\",\"v\":\"\"}]','2026-02-02',0,'2026-02-03 01:11:37'),(16,13,'Rutina Fuerza-Resistencia 03/02',NULL,'[{\"nombre\":\"Sentadillas con salto\",\"d\":\"4 series x 12 reps. Intensidad: RPE 7. Descanso 60 segundos\",\"v\":\"\"},{\"nombre\":\"Dominadas pronas\",\"d\":\"3 series x 8 reps. Intensidad: RPE 8. Descanso 90 segundos\",\"v\":\"\"},{\"nombre\":\"Press militar con mancuernas\",\"d\":\"4 series x 10 reps. Intensidad: RPE 7. Descanso 75 segundos\",\"v\":\"\"},{\"nombre\":\"Plancha con desplazamiento lateral\",\"d\":\"3 series x 20 segundos. Intensidad: RPE 6. Descanso 45 segundos\",\"v\":\"\"},{\"nombre\":\"Peso muerto rumano\",\"d\":\"4 series x 8 reps. Intensidad: RPE 8. Descanso 90 segundos\",\"v\":\"\"}]','2026-02-03',0,'2026-02-03 16:17:06'),(17,14,'Pierna seguro para isquio',NULL,'[{\"n\":\"Sentadilla Goblet\",\"d\":\"3x12 reps, RPE 5, descanso 60s\",\"v\":\"\"},{\"n\":\"Extensiones pierna\",\"d\":\"3x15 reps, RPE 4, descanso 45s\",\"v\":\"\"},{\"n\":\"Prensa inclinada\",\"d\":\"3x10 reps, RPE 5, descanso 75s\",\"v\":\"\"},{\"n\":\"Elevación talones\",\"d\":\"3x20 reps, descanso 30s\",\"v\":\"\"},{\"n\":\"Puente glúteos\",\"d\":\"3x12 reps, contracción 2s, descanso 45s\",\"v\":\"\"}]','2026-02-04',0,'2026-02-04 21:21:12');
/*!40000 ALTER TABLE `plan_entrenamiento` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `planes`
--

DROP TABLE IF EXISTS `planes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `planes` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nombre del plan (Día, Semana, Mes)',
  `descripcion` text COLLATE utf8mb4_unicode_ci COMMENT 'Descripción del plan',
  `duracion_dias` int NOT NULL COMMENT 'Duración del plan en días',
  `precio` decimal(10,2) NOT NULL COMMENT 'Precio del plan',
  `precio_app` decimal(10,2) DEFAULT NULL COMMENT 'Precio con descuento desde la app (10% descuento)',
  `tipo` enum('día','semana','mes','anual') COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Tipo de plan',
  `activo` tinyint(1) DEFAULT '1' COMMENT '1=activo, 0=inactivo',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_planes_activo` (`activo`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Planes de membresía';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `planes`
--

LOCK TABLES `planes` WRITE;
/*!40000 ALTER TABLE `planes` DISABLE KEYS */;
INSERT INTO `planes` VALUES (1,'Día','Acceso por un día',1,7000.00,6300.00,'día',1,'2025-11-04 19:34:42','2025-12-11 16:12:46'),(2,'Semana','Acceso por una semana',7,25000.00,22500.00,'semana',1,'2025-11-04 19:34:42','2025-12-11 16:12:46'),(3,'Mes','Acceso por un mes',30,70000.00,63000.00,'mes',1,'2025-11-04 19:34:42','2025-12-11 16:12:46'),(4,'Anual','Pla del año',365,1000000.00,900000.00,'anual',0,'2025-11-28 21:00:10','2026-02-04 20:20:20');
/*!40000 ALTER TABLE `planes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `post_likes`
--

DROP TABLE IF EXISTS `post_likes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `post_likes` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `post_id` int unsigned NOT NULL,
  `usuario_id` int unsigned NOT NULL,
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_post_like` (`post_id`,`usuario_id`),
  KEY `fk_post_likes_usuario` (`usuario_id`),
  CONSTRAINT `fk_post_likes_post` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_post_likes_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `post_likes`
--

LOCK TABLES `post_likes` WRITE;
/*!40000 ALTER TABLE `post_likes` DISABLE KEYS */;
INSERT INTO `post_likes` VALUES (3,1,10,'2026-01-09 08:18:06'),(5,2,10,'2026-01-10 05:56:11'),(6,3,10,'2026-01-10 05:56:50'),(7,20,10,'2026-01-10 11:23:04'),(8,38,12,'2026-01-10 23:43:26'),(9,11,10,'2026-01-12 12:21:36'),(13,45,10,'2026-01-14 14:57:39');
/*!40000 ALTER TABLE `post_likes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `post_reports`
--

DROP TABLE IF EXISTS `post_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `post_reports` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `post_id` int unsigned NOT NULL,
  `usuario_id` int unsigned NOT NULL,
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_post_report` (`post_id`,`usuario_id`),
  KEY `fk_post_reports_usuario` (`usuario_id`),
  CONSTRAINT `fk_post_reports_post` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_post_reports_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `post_reports`
--

LOCK TABLES `post_reports` WRITE;
/*!40000 ALTER TABLE `post_reports` DISABLE KEYS */;
INSERT INTO `post_reports` VALUES (1,35,10,'2026-01-11 00:55:09'),(2,38,10,'2026-01-11 00:55:21');
/*!40000 ALTER TABLE `post_reports` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `posts`
--

DROP TABLE IF EXISTS `posts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `posts` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` int unsigned NOT NULL,
  `contenido` text NOT NULL,
  `imagen_url` varchar(255) DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` datetime DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `fk_posts_usuario` (`usuario_id`),
  CONSTRAINT `fk_posts_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci

;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `posts`
--

LOCK TABLES `posts` WRITE;
/*!40000 ALTER TABLE `posts` DISABLE KEYS */;
INSERT INTO `posts` VALUES (1,10,'Es un buen día para empezar el GYM',NULL,'2026-01-09 08:17:56','2026-01-09 08:32:53',0),(2,11,'hola pana',NULL,'2026-01-09 17:47:02',NULL,0),(3,10,'bien día para empezar',NULL,'2026-01-10 05:56:42',NULL,0),(4,10,'🥺🥺🥺🥺🥺',NULL,'2026-01-10 06:59:42',NULL,0),(5,10,'es un nuevo día para ser feliz 🥰',NULL,'2026-01-10 07:07:21',NULL,0),(6,10,'este día es maravilloso🦍🦍🦍🦍🦍',NULL,'2026-01-10 07:20:43',NULL,0),(7,10,'📸',NULL,'2026-01-10 07:20:56',NULL,0),(8,10,'¡Hoy completé mi primera rutina de piernas! 💪 Me siento increíble.',NULL,'2026-01-10 08:16:11',NULL,0),(9,10,'Compartiendo mi progreso: 3 meses de entrenamiento constante. ¡Vamos por más! 🔥',NULL,'2026-01-10 08:16:11',NULL,0),(10,10,'Nuevo récord personal en press de banca: 80kg. ¡A seguir mejorando! 🏋️',NULL,'2026-01-10 08:16:11',NULL,0),(11,10,'¡Hoy completé mi primera rutina de piernas! 💪 Me siento increíble.',NULL,'2026-01-10 08:16:38',NULL,1),(12,10,'Compartiendo mi progreso: 3 meses de entrenamiento constante. ¡Vamos por más! 🔥',NULL,'2026-01-10 08:16:38',NULL,0),(13,10,'Nuevo récord personal en press de banca: 80kg. ¡A seguir mejorando! 🏋️',NULL,'2026-01-10 08:16:38',NULL,0),(14,10,'¡Hoy completé mi primera rutina de piernas! 💪 Me siento increíble.',NULL,'2026-01-10 08:19:06',NULL,0),(15,10,'Compartiendo mi progreso: 3 meses de entrenamiento constante. ¡Vamos por más! 🔥',NULL,'2026-01-10 08:19:06',NULL,0),(16,10,'Nuevo récord personal en press de banca: 80kg. ¡A seguir mejorando! 🏋️',NULL,'2026-01-10 08:19:06',NULL,0),(17,10,'¡Hoy completé mi primera rutina de piernas! 💪 Me siento increíble.',NULL,'2026-01-10 08:19:59',NULL,0),(18,10,'Compartiendo mi progreso: 3 meses de entrenamiento constante. ¡Vamos por más! 🔥',NULL,'2026-01-10 08:19:59',NULL,0),(19,10,'Nuevo récord personal en press de banca: 80kg. ¡A seguir mejorando! 🏋️',NULL,'2026-01-10 08:19:59',NULL,0),(20,10,'¡Hoy completé mi primera rutina de piernas! 💪 Me siento increíble.',NULL,'2026-01-10 08:21:07',NULL,0),(21,10,'Compartiendo mi progreso: 3 meses de entrenamiento constante. ¡Vamos por más! 🔥',NULL,'2026-01-10 08:21:07',NULL,0),(22,10,'Nuevo récord personal en press de banca: 80kg. ¡A seguir mejorando! 🏋️',NULL,'2026-01-10 08:21:07',NULL,0),(23,10,'foto',NULL,'2026-01-10 08:35:42',NULL,0),(24,10,'prueba foto',NULL,'2026-01-10 08:39:54',NULL,0),(25,10,'uju',NULL,'2026-01-10 08:45:43',NULL,0),(26,10,'jjj',NULL,'2026-01-10 08:51:05',NULL,0),(27,10,'prueba',NULL,'2026-01-10 08:54:27',NULL,0),(28,10,'📸',NULL,'2026-01-10 08:59:02',NULL,0),(29,10,'hola','https://functionaltraining.site/uploads/posts/post_69621634b2ca73.63717739.jpg','2026-01-10 09:04:52',NULL,0),(30,10,'prueba post','https://functionaltraining.site/uploads/posts/post_6962164f5faff8.98131125.jpg','2026-01-10 09:05:19',NULL,0),(31,12,'hola 2',NULL,'2026-01-10 22:57:18','2026-01-12 11:16:18',0),(32,12,'hola otra vez 2',NULL,'2026-01-10 23:02:28','2026-01-12 11:11:20',0),(33,12,'hola',NULL,'2026-01-10 23:24:02',NULL,0),(34,12,'buen','https://functionaltraining.site/uploads/posts/post_69632725972436.48828542.jpg','2026-01-10 23:29:25',NULL,0),(35,12,'📸','https://functionaltraining.site/uploads/posts/post_696327cb1d92c3.95064159.jpg','2026-01-10 23:32:11',NULL,0),(36,12,'📸','https://functionaltraining.site/uploads/posts/post_69632899a6d960.37825537.jpg','2026-01-10 23:35:37',NULL,0),(37,12,'buena','https://functionaltraining.site/uploads/posts/post_6963293d941471.84085677.jpg','2026-01-10 23:38:21',NULL,0),(38,12,'📸','https://functionaltraining.site/uploads/posts/post_69632a49e5a858.14582592.jpg','2026-01-10 23:42:50',NULL,0),(39,12,'🥰🥰🥰 bien',NULL,'2026-01-12 11:16:29','2026-01-12 11:58:42',0),(40,10,'buen día para dormir',NULL,'2026-01-13 08:18:59',NULL,0),(41,10,'mk breinder',NULL,'2026-01-13 08:19:35',NULL,0),(42,10,'no funciona ahora',NULL,'2026-01-13 09:03:40',NULL,0),(43,10,'bobos todos',NULL,'2026-01-13 09:18:13',NULL,0),(44,10,'errrorrrr','https://functionaltraining.site/uploads/posts/post_69665c17b83593.20632541.jpg','2026-01-13 09:52:07',NULL,0),(45,10,'📸','https://functionaltraining.site/uploads/posts/post_6967f4404c7951.83012767.jpg','2026-01-14 14:53:36',NULL,0),(46,10,'📸','https://functionaltraining.site/uploads/posts/post_698221836ff1b6.42469515.jpg','2026-02-03 11:25:39',NULL,1),(47,13,'muy bacana',NULL,'2026-02-03 11:25:50',NULL,1);
/*!40000 ALTER TABLE `posts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `preferencias_usuario`
--

DROP TABLE IF EXISTS `preferencias_usuario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `preferencias_usuario` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` int unsigned NOT NULL COMMENT 'ID del usuario',
  `color_mode` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'light' COMMENT 'Modo de color: light, dark, auto',
  `dir_mode` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT 'ltr' COMMENT 'Dirección: ltr, rtl',
  `sidebar_color` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Color del sidebar',
  `sidebar_type` text COLLATE utf8mb4_unicode_ci COMMENT 'Tipos de sidebar (JSON array)',
  `sidebar_style` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Estilo del sidebar',
  `navbar_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Tipo de navbar',
  `color_custom` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Color personalizado del tema',
  `color_custom_info` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Información del color personalizado',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_preferencias_usuario` (`usuario_id`),
  CONSTRAINT `fk_preferencias_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Preferencias de tema y UI de usuarios';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `preferencias_usuario`
--

LOCK TABLES `preferencias_usuario` WRITE;
/*!40000 ALTER TABLE `preferencias_usuario` DISABLE KEYS */;
INSERT INTO `preferencias_usuario` VALUES (1,1,'light','ltr','sidebar-white','[]','navs-rounded',NULL,'theme-color-blue','#573BFF','2025-12-06 12:10:38','2026-02-04 20:48:59');
/*!40000 ALTER TABLE `preferencias_usuario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `productos`
--

DROP TABLE IF EXISTS `productos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `productos` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nombre del producto',
  `descripcion` text COLLATE utf8mb4_unicode_ci COMMENT 'Descripción del producto',
  `categoria` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Categoría (suplementos, accesorios, ropa)',
  `precio` decimal(10,2) NOT NULL COMMENT 'Precio del producto',
  `stock` int DEFAULT '0' COMMENT 'Cantidad en stock',
  `imagen` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Ruta de la imagen del producto',
  `activo` tinyint(1) DEFAULT '1' COMMENT '1=activo, 0=inactivo',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_productos_categoria` (`categoria`),
  KEY `idx_productos_activo` (`activo`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Productos de la tienda';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos`
--

LOCK TABLES `productos` WRITE;
/*!40000 ALTER TABLE `productos` DISABLE KEYS */;
INSERT INTO `productos` VALUES (8,'Creatina','creatina','Suplementos',50000.00,4,'producto_1767848149_695f38d558cd7.webp',1,'2026-01-08 04:55:49','2026-02-04 20:14:44');
/*!40000 ALTER TABLE `productos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `progreso_usuario`
--

DROP TABLE IF EXISTS `progreso_usuario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `progreso_usuario` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` int unsigned NOT NULL COMMENT 'ID del usuario',
  `fecha` date NOT NULL COMMENT 'Fecha del registro',
  `peso` decimal(5,2) DEFAULT NULL COMMENT 'Peso en kg',
  `altura` decimal(5,2) DEFAULT NULL COMMENT 'Altura en cm',
  `imc` decimal(5,2) DEFAULT NULL COMMENT 'Índice de masa corporal',
  `grasa_corporal` decimal(5,2) DEFAULT NULL COMMENT 'Porcentaje de grasa corporal',
  `musculo` decimal(5,2) DEFAULT NULL COMMENT 'Porcentaje de masa muscular',
  `medidas_brazo` decimal(5,2) DEFAULT NULL COMMENT 'Medida del brazo en cm',
  `medidas_pecho` decimal(5,2) DEFAULT NULL COMMENT 'Medida del pecho en cm',
  `medidas_cintura` decimal(5,2) DEFAULT NULL COMMENT 'Medida de la cintura en cm',
  `medidas_cadera` decimal(5,2) DEFAULT NULL COMMENT 'Medida de la cadera en cm',
  `medidas_pierna` decimal(5,2) DEFAULT NULL COMMENT 'Medida de la pierna en cm',
  `foto_progreso` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Ruta de la foto de progreso',
  `notas` text COLLATE utf8mb4_unicode_ci COMMENT 'Notas adicionales',
  `registrado_por` int unsigned DEFAULT NULL COMMENT 'ID del entrenador que registró el progreso',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_progreso_usuario` (`usuario_id`),
  KEY `idx_progreso_fecha` (`fecha`),
  KEY `fk_progreso_registrado_por` (`registrado_por`),
  CONSTRAINT `fk_progreso_registrado_por` FOREIGN KEY (`registrado_por`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_progreso_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Progreso físico de usuarios';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `progreso_usuario`
--

LOCK TABLES `progreso_usuario` WRITE;
/*!40000 ALTER TABLE `progreso_usuario` DISABLE KEYS */;
/*!40000 ALTER TABLE `progreso_usuario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `push_notifications_config`
--

DROP TABLE IF EXISTS `push_notifications_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `push_notifications_config` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `tipo` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Tipo de notificación (cumpleanos, membresia_vencimiento, inactividad)',
  `activa` tinyint(1) DEFAULT '1' COMMENT '1=activa, 0=inactiva',
  `titulo` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Título de la notificación',
  `mensaje` text COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Mensaje de la notificación (puede usar variables como {nombre}, {dias}, etc.)',
  `dias_antes` int DEFAULT '0' COMMENT 'Días antes del evento para enviar (0 = el mismo día)',
  `dias_inactividad` int DEFAULT '7' COMMENT 'Días de inactividad para notificar (solo para tipo inactividad)',
  `hora_envio` time DEFAULT '09:00:00' COMMENT 'Hora del día para enviar la notificación',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_push_notif_tipo` (`tipo`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Configuración de notificaciones push automáticas';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `push_notifications_config`
--

LOCK TABLES `push_notifications_config` WRITE;
/*!40000 ALTER TABLE `push_notifications_config` DISABLE KEYS */;
INSERT INTO `push_notifications_config` VALUES (1,'cumpleanos',1,'¡Feliz Cumpleaños! 🎉','¡Feliz cumpleaños {nombre}! Esperamos verte hoy en el gimnasio. Te deseamos un día lleno de energía y éxito. ¡Vamos a entrenar! 💪',0,NULL,'06:00:00','2025-12-06 09:43:23','2025-12-11 16:00:36'),(2,'membresia_vencimiento',1,'Tu membresía está por vencer ⏰','Hola {nombre}, tu membresía vence en {dias} día(s). Renueva ahora para no perder tus beneficios. ¡Te esperamos!',1,NULL,'10:00:00','2025-12-06 09:43:23','2025-12-11 16:02:26'),(3,'membresia_vencida',1,'Tu membresía ha vencido','Hola {nombre}, tu membresía ha vencido. Renueva ahora para continuar disfrutando de todos nuestros servicios.',0,NULL,'10:00:00','2025-12-06 09:43:23','2025-12-06 09:43:23'),(4,'inactividad',1,'Te extrañamos en el gimnasio 💪','Hola {nombre}, hace {dias} día(s) que no te vemos en el gimnasio. ¡Vuelve y continúa con tu rutina! Te esperamos.',0,7,'11:00:00','2025-12-06 09:43:23','2025-12-06 09:43:23');
/*!40000 ALTER TABLE `push_notifications_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nombre del rol (admin, entrenador, cliente)',
  `descripcion` text COLLATE utf8mb4_unicode_ci COMMENT 'Descripción del rol y sus permisos',
  `activo` tinyint(1) DEFAULT '1' COMMENT '1=activo, 0=inactivo',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_roles_nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Roles del sistema';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'admin','Administrador del sistema con acceso completo',1,'2025-11-04 19:34:42','2025-11-04 19:34:42'),(2,'entrenador','Entrenador que puede asignar rutinas y ver progreso de usuarios',1,'2025-11-04 19:34:42','2025-11-04 19:34:42'),(3,'cliente','Cliente del gimnasio con acceso a membresía y rutinas',1,'2025-11-04 19:34:42','2025-11-04 19:34:42'),(4,'empleado','Empleado que puede usar la caja y gestionar ventas',1,'2025-12-03 04:21:46','2025-12-03 04:21:46');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rutina_ejercicios`
--

DROP TABLE IF EXISTS `rutina_ejercicios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rutina_ejercicios` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `rutina_id` int unsigned NOT NULL COMMENT 'ID de la rutina',
  `ejercicio_id` int unsigned NOT NULL COMMENT 'ID del ejercicio',
  `dia` int NOT NULL COMMENT 'Día de la semana (1=lunes, 2=martes, etc.)',
  `orden` int DEFAULT '1' COMMENT 'Orden del ejercicio en el día',
  `series` int DEFAULT NULL COMMENT 'Número de series',
  `repeticiones` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Repeticiones (ej: "10-12", "15", "hasta fallo")',
  `peso` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Peso recomendado (ej: "20kg", "cuerpo", "progresivo")',
  `descanso` int DEFAULT NULL COMMENT 'Tiempo de descanso en segundos',
  `notas` text COLLATE utf8mb4_unicode_ci COMMENT 'Notas adicionales sobre el ejercicio',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_rutina_ejercicios_rutina` (`rutina_id`),
  KEY `idx_rutina_ejercicios_ejercicio` (`ejercicio_id`),
  KEY `idx_rutina_ejercicios_dia` (`dia`),
  CONSTRAINT `fk_rutina_ejercicios_ejercicio` FOREIGN KEY (`ejercicio_id`) REFERENCES `ejercicios` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_rutina_ejercicios_rutina` FOREIGN KEY (`rutina_id`) REFERENCES `rutinas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ejercicios de rutinas';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rutina_ejercicios`
--

LOCK TABLES `rutina_ejercicios` WRITE;
/*!40000 ALTER TABLE `rutina_ejercicios` DISABLE KEYS */;
/*!40000 ALTER TABLE `rutina_ejercicios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rutinas`
--

DROP TABLE IF EXISTS `rutinas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rutinas` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nombre de la rutina',
  `descripcion` text COLLATE utf8mb4_unicode_ci COMMENT 'Descripción de la rutina',
  `objetivo` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Objetivo (ganar masa, perder peso, fuerza, etc.)',
  `nivel` enum('principiante','intermedio','avanzado') COLLATE utf8mb4_unicode_ci DEFAULT 'principiante' COMMENT 'Nivel de dificultad',
  `duracion_semanas` int DEFAULT NULL COMMENT 'Duración recomendada en semanas',
  `dias_semana` int DEFAULT NULL COMMENT 'Días de entrenamiento por semana',
  `activo` tinyint(1) DEFAULT '1' COMMENT '1=activo, 0=inactivo',
  `created_by` int unsigned DEFAULT NULL COMMENT 'ID del entrenador que creó la rutina',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_rutinas_objetivo` (`objetivo`),
  KEY `idx_rutinas_activo` (`activo`),
  KEY `fk_rutinas_created_by` (`created_by`),
  CONSTRAINT `fk_rutinas_created_by` FOREIGN KEY (`created_by`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Rutinas de entrenamiento';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rutinas`
--

LOCK TABLES `rutinas` WRITE;
/*!40000 ALTER TABLE `rutinas` DISABLE KEYS */;
/*!40000 ALTER TABLE `rutinas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rutinas_usuario`
--

DROP TABLE IF EXISTS `rutinas_usuario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rutinas_usuario` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` int unsigned NOT NULL COMMENT 'ID del usuario',
  `rutina_id` int unsigned NOT NULL COMMENT 'ID de la rutina',
  `entrenador_id` int unsigned DEFAULT NULL COMMENT 'ID del entrenador que asignó la rutina',
  `fecha_inicio` date NOT NULL COMMENT 'Fecha de inicio de la rutina',
  `fecha_fin` date DEFAULT NULL COMMENT 'Fecha de finalización de la rutina',
  `estado` enum('activa','completada','pausada','cancelada') COLLATE utf8mb4_unicode_ci DEFAULT 'activa' COMMENT 'Estado de la rutina',
  `observaciones` text COLLATE utf8mb4_unicode_ci COMMENT 'Observaciones del entrenador',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_rutinas_usuario_usuario` (`usuario_id`),
  KEY `idx_rutinas_usuario_rutina` (`rutina_id`),
  KEY `idx_rutinas_usuario_entrenador` (`entrenador_id`),
  KEY `idx_rutinas_usuario_estado` (`estado`),
  CONSTRAINT `fk_rutinas_usuario_entrenador` FOREIGN KEY (`entrenador_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_rutinas_usuario_rutina` FOREIGN KEY (`rutina_id`) REFERENCES `rutinas` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_rutinas_usuario_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Rutinas asignadas a usuarios';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rutinas_usuario`
--

LOCK TABLES `rutinas_usuario` WRITE;
/*!40000 ALTER TABLE `rutinas_usuario` DISABLE KEYS */;
/*!40000 ALTER TABLE `rutinas_usuario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sesiones_caja`
--

DROP TABLE IF EXISTS `sesiones_caja`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sesiones_caja` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `fecha_apertura` datetime NOT NULL COMMENT 'Fecha y hora de apertura de caja',
  `fecha_cierre` datetime DEFAULT NULL COMMENT 'Fecha y hora de cierre de caja',
  `monto_apertura` decimal(10,2) NOT NULL COMMENT 'Monto con el que se abrió la caja',
  `monto_cierre` decimal(10,2) DEFAULT NULL COMMENT 'Monto con el que se cerró la caja',
  `monto_esperado` decimal(10,2) DEFAULT NULL COMMENT 'Monto esperado según transacciones',
  `diferencia` decimal(10,2) DEFAULT NULL COMMENT 'Diferencia entre monto_cierre y monto_esperado',
  `estado` enum('abierta','cerrada') COLLATE utf8mb4_unicode_ci DEFAULT 'abierta' COMMENT 'Estado de la sesión',
  `abierta_por` int unsigned NOT NULL COMMENT 'ID del usuario que abrió la caja',
  `cerrada_por` int unsigned DEFAULT NULL COMMENT 'ID del usuario que cerró la caja',
  `observaciones_apertura` text COLLATE utf8mb4_unicode_ci COMMENT 'Observaciones al abrir',
  `observaciones_cierre` text COLLATE utf8mb4_unicode_ci COMMENT 'Observaciones al cerrar',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_sesiones_estado` (`estado`),
  KEY `idx_sesiones_fecha_apertura` (`fecha_apertura`),
  KEY `idx_sesiones_abierta_por` (`abierta_por`),
  KEY `idx_sesiones_cerrada_por` (`cerrada_por`),
  CONSTRAINT `fk_sesiones_abierta_por` FOREIGN KEY (`abierta_por`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_sesiones_cerrada_por` FOREIGN KEY (`cerrada_por`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Sesiones de apertura y cierre de caja';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sesiones_caja`
--

LOCK TABLES `sesiones_caja` WRITE;
/*!40000 ALTER TABLE `sesiones_caja` DISABLE KEYS */;
INSERT INTO `sesiones_caja` VALUES (11,'2026-01-08 17:02:34','2026-02-04 15:33:15',0.00,250000.00,255000.00,-5000.00,'cerrada',1,1,NULL,NULL,'2026-01-08 17:02:34','2026-02-04 20:33:15'),(12,'2026-02-04 16:17:24',NULL,500.00,NULL,NULL,NULL,'abierta',1,NULL,NULL,NULL,'2026-02-04 21:17:24','2026-02-04 21:17:24');
/*!40000 ALTER TABLE `sesiones_caja` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `transacciones_financieras`
--

DROP TABLE IF EXISTS `transacciones_financieras`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `transacciones_financieras` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `tipo` enum('ingreso','egreso') COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Tipo de transacción: ingreso o egreso',
  `categoria` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Categoría: membresia, producto, gasto_operativo, gasto_equipamiento, salario, otro',
  `concepto` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Concepto o descripción de la transacción',
  `monto` decimal(10,2) NOT NULL COMMENT 'Monto de la transacción',
  `metodo_pago` enum('efectivo','tarjeta','transferencia','app','otro') COLLATE utf8mb4_unicode_ci DEFAULT 'efectivo' COMMENT 'Método de pago',
  `referencia` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Número de referencia o comprobante',
  `usuario_id` int unsigned DEFAULT NULL COMMENT 'ID del usuario relacionado (si aplica)',
  `membresia_id` int unsigned DEFAULT NULL COMMENT 'ID de la membresía relacionada (si aplica)',
  `producto_id` int unsigned DEFAULT NULL COMMENT 'ID del producto relacionado (si aplica)',
  `fecha` datetime NOT NULL COMMENT 'Fecha y hora de la transacción',
  `observaciones` text COLLATE utf8mb4_unicode_ci COMMENT 'Observaciones adicionales',
  `registrado_por` int unsigned NOT NULL COMMENT 'ID del usuario que registró la transacción',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_transacciones_tipo` (`tipo`),
  KEY `idx_transacciones_categoria` (`categoria`),
  KEY `idx_transacciones_fecha` (`fecha`),
  KEY `idx_transacciones_usuario` (`usuario_id`),
  KEY `idx_transacciones_membresia` (`membresia_id`),
  KEY `idx_transacciones_producto` (`producto_id`),
  KEY `idx_transacciones_registrado_por` (`registrado_por`),
  CONSTRAINT `fk_transacciones_membresia` FOREIGN KEY (`membresia_id`) REFERENCES `membresias` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_transacciones_producto` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_transacciones_registrado_por` FOREIGN KEY (`registrado_por`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_transacciones_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Transacciones financieras del gimnasio';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transacciones_financieras`
--

LOCK TABLES `transacciones_financieras` WRITE;
/*!40000 ALTER TABLE `transacciones_financieras` DISABLE KEYS */;
INSERT INTO `transacciones_financieras` VALUES (43,'ingreso','membresia','Venta de membresía - FAC-20260108-6317',25000.00,'efectivo','FAC-20260108-6317',10,4,NULL,'2026-01-08 17:02:51',NULL,1,'2026-01-08 17:02:51','2026-01-08 17:02:51'),(44,'ingreso','membresia','Venta de membresía - FAC-20260109-5462',7000.00,'efectivo','FAC-20260109-5462',11,5,NULL,'2026-01-09 17:45:31',NULL,1,'2026-01-09 17:45:31','2026-01-09 17:45:31'),(45,'ingreso','membresia','Venta de membresía - FAC-20260110-6614',7000.00,'efectivo','FAC-20260110-6614',11,6,NULL,'2026-01-10 11:59:19',NULL,1,'2026-01-10 11:59:19','2026-01-10 11:59:19'),(46,'ingreso','membresia','Venta de membresía - FAC-20260110-8788',7000.00,'efectivo','FAC-20260110-8788',12,7,NULL,'2026-01-10 22:47:45',NULL,1,'2026-01-11 03:47:45','2026-01-11 03:47:45'),(47,'ingreso','membresia','Venta de membresía - FAC-20260111-0835',7000.00,'efectivo','FAC-20260111-0835',12,8,NULL,'2026-01-11 00:49:27',NULL,1,'2026-01-11 05:49:27','2026-01-11 05:49:27'),(48,'ingreso','membresia','Venta de membresía - FAC-20260112-9250',7000.00,'efectivo','FAC-20260112-9250',12,9,NULL,'2026-01-12 06:52:10',NULL,1,'2026-01-12 11:52:10','2026-01-12 11:52:10'),(49,'ingreso','membresia','Venta de membresía - FAC-20260202-5289',25000.00,'efectivo','FAC-20260202-5289',10,10,NULL,'2026-02-02 17:36:22',NULL,1,'2026-02-02 22:36:22','2026-02-02 22:36:22'),(50,'ingreso','producto','Venta de productos - FAC-20260203-7977',50000.00,'efectivo','FAC-20260203-7977',NULL,NULL,NULL,'2026-02-03 11:01:33',NULL,1,'2026-02-03 16:01:33','2026-02-03 16:01:33'),(51,'ingreso','membresia','Venta de membresía - FAC-20260203-1077',70000.00,'efectivo','FAC-20260203-1077',13,11,NULL,'2026-02-03 11:05:57',NULL,1,'2026-02-03 16:05:57','2026-02-03 16:05:57'),(52,'ingreso','producto','Venta de productos - FAC-20260204-4603',50000.00,'efectivo','FAC-20260204-4603',NULL,NULL,NULL,'2026-02-04 15:14:44',NULL,1,'2026-02-04 20:14:44','2026-02-04 20:14:44'),(53,'ingreso','membresia','Venta de membresía - FAC-20260204-7768',7000.00,'efectivo','FAC-20260204-7768',13,12,NULL,'2026-02-04 16:17:37',NULL,1,'2026-02-04 21:17:37','2026-02-04 21:17:37'),(54,'ingreso','membresia','Venta de membresía - FAC-20260204-4875',7000.00,'efectivo','FAC-20260204-4875',14,13,NULL,'2026-02-04 16:18:55',NULL,1,'2026-02-04 21:18:55','2026-02-04 21:18:55');
/*!40000 ALTER TABLE `transacciones_financieras` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_progress`
--

DROP TABLE IF EXISTS `user_progress`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_progress` (
  `id` int NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `current_block` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT 'start',
  `last_interaction` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `phone_number` (`phone_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_progress`
--

LOCK TABLES `user_progress` WRITE;
/*!40000 ALTER TABLE `user_progress` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_progress` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuarios`
--

DROP TABLE IF EXISTS `usuarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuarios` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `rol_id` int unsigned NOT NULL COMMENT 'ID del rol del usuario',
  `documento` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Documento de identidad (cédula, pasaporte)',
  `tipo_documento` enum('CC','CE','PA','TI') COLLATE utf8mb4_unicode_ci DEFAULT 'CC' COMMENT 'Tipo de documento',
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nombre del usuario',
  `apellido` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Apellido del usuario',
  `email` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Correo electrónico',
  `telefono` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Teléfono de contacto',
  `fecha_nacimiento` date DEFAULT NULL COMMENT 'Fecha de nacimiento',
  `genero` enum('M','F','O') COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Género: M=Masculino, F=Femenino, O=Otro',
  `direccion` text COLLATE utf8mb4_unicode_ci COMMENT 'Dirección de residencia',
  `ciudad` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Ciudad de residencia',
  `foto` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Ruta de la foto de perfil',
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Contraseña hasheada',
  `codigo_qr` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Código QR único para acceso al gym',
  `estado` enum('activo','inactivo','suspendido') COLLATE utf8mb4_unicode_ci DEFAULT 'activo' COMMENT 'Estado del usuario',
  `email_verificado` tinyint(1) DEFAULT '0' COMMENT '1=email verificado, 0=no verificado',
  `token_verificacion` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Token para verificación de email',
  `ultimo_acceso` datetime DEFAULT NULL COMMENT 'Última vez que el usuario accedió al sistema',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_usuarios_email` (`email`),
  UNIQUE KEY `uk_usuarios_documento` (`documento`),
  UNIQUE KEY `uk_usuarios_codigo_qr` (`codigo_qr`),
  KEY `idx_usuarios_rol` (`rol_id`),
  KEY `idx_usuarios_estado` (`estado`),
  CONSTRAINT `fk_usuarios_rol` FOREIGN KEY (`rol_id`) REFERENCES `roles` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Usuarios del sistema';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

LOCK TABLES `usuarios` WRITE;
/*!40000 ALTER TABLE `usuarios` DISABLE KEYS */;
INSERT INTO `usuarios` VALUES (1,1,'123456789','CC','Admin','Sistema','admin@gmail.com','3185312833',NULL,NULL,NULL,'admin@gmail.com',NULL,'$2y$10$dZh1mFWRRsviZ41WOXAm1uTVKgLgHSn9xIDf3NZkXH61puiZmM3SK','QR-ADMIN-001','inactivo',1,NULL,'2026-02-04 15:07:34','2025-11-04 19:34:42','2026-02-04 20:07:34'),(10,2,'1004914530','CC','Joel','Lizarazo','endersonlizarazo3@gmail.com','3209939817','1999-01-13','M',NULL,NULL,'https://functionaltraining.site/uploads/posts/post_696db82824b6c6.62191956.jpg','$2y$10$2U7IvmYrIVzvYmLnW0McZe0yX0FVmfCVwjfvq5l/yvxkQounOstDS','QR-CC-1004914530','activo',0,'d10b360e5e2f25beb00a43330c955fc6eec56100a965b0512c6c9e574a6ee72b','2026-02-04 22:17:58','2026-01-07 23:53:11','2026-02-05 03:17:58'),(11,3,'1127053018','TI','Breinder','wladimir','breinderlizarazo@gmail.com','3142885359',NULL,'F','calle 8','villa del rosario',NULL,'$2y$10$ZrCdGPhIL81PnMaBcgY9W.qTO5MyQkIsKdrwfl1JXHq9Bs2QJUWJe','QR-TI-1127053018','inactivo',0,'cba134a66b4883f0a9e37153a5dabebcafb216071e01829b634b1b0c95ef2a45','2026-01-19 00:39:40','2026-01-08 03:50:35','2026-01-19 05:39:40'),(12,3,'1004914531','CC','Carlos','Mendoza','endersonlizarazo6@gmail.com','123456789',NULL,NULL,NULL,NULL,NULL,'$2y$10$TapWhU06oEWEiTytsXxEYuahu9CuK89Hv7gg41rsvnexWBQDwANa2','QR-CC-1004914531','inactivo',0,NULL,'2026-01-13 10:51:33','2026-01-11 03:47:08','2026-01-14 11:10:25'),(13,2,'5501927','CC','edison','puerto','edisonpuertocuadros@gmail.com','3185312833','1985-11-20',NULL,NULL,NULL,'https://functionaltraining.site/uploads/posts/post_6982230e9259d4.55529501.jpg','$2y$10$xgchwmXyKIxUGqpgRoUwLOxnWZx3bomuseDiNztXrfhQje69vdRr.','QR-CC-0005501927','activo',0,NULL,'2026-02-04 16:17:37','2026-02-03 16:03:59','2026-02-04 21:17:37'),(14,3,'101765215','CC','eduard','puerto','eduardpuerto@gmail.com','312665455',NULL,NULL,NULL,NULL,'https://functionaltraining.site/uploads/posts/post_6983b60f536db1.38466699.jpg','$2y$10$5NNAYLP.DrvykifNjIeRTOhSKGwgHxMimRmlcZ5nkXzYSx9UBMyRG','QR-CC-0101765215','activo',0,NULL,'2026-02-04 16:09:57','2026-02-04 20:29:41','2026-02-04 21:18:55');
/*!40000 ALTER TABLE `usuarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `venta_items`
--

DROP TABLE IF EXISTS `venta_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `venta_items` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `venta_id` int unsigned NOT NULL COMMENT 'ID de la venta',
  `producto_id` int unsigned NOT NULL COMMENT 'ID del producto',
  `cantidad` int NOT NULL COMMENT 'Cantidad vendida',
  `precio_unitario` decimal(10,2) NOT NULL COMMENT 'Precio unitario al momento de la venta',
  `subtotal` decimal(10,2) NOT NULL COMMENT 'Subtotal (cantidad * precio_unitario)',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_venta_items_venta` (`venta_id`),
  KEY `idx_venta_items_producto` (`producto_id`),
  CONSTRAINT `fk_venta_items_producto` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_venta_items_venta` FOREIGN KEY (`venta_id`) REFERENCES `ventas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Items de productos en ventas';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `venta_items`
--

LOCK TABLES `venta_items` WRITE;
/*!40000 ALTER TABLE `venta_items` DISABLE KEYS */;
INSERT INTO `venta_items` VALUES (43,50,8,1,50000.00,50000.00,'2026-02-03 16:01:33'),(44,52,8,1,50000.00,50000.00,'2026-02-04 20:14:44');
/*!40000 ALTER TABLE `venta_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ventas`
--

DROP TABLE IF EXISTS `ventas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ventas` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `sesion_caja_id` int unsigned NOT NULL COMMENT 'ID de la sesión de caja',
  `numero_factura` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Número único de factura',
  `usuario_id` int unsigned DEFAULT NULL COMMENT 'ID del usuario/cliente',
  `tipo` enum('productos','membresia','mixto') COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Tipo de venta',
  `subtotal` decimal(10,2) NOT NULL COMMENT 'Subtotal de la venta',
  `descuento` decimal(10,2) DEFAULT '0.00' COMMENT 'Descuento aplicado',
  `total` decimal(10,2) NOT NULL COMMENT 'Total de la venta',
  `metodo_pago` enum('efectivo','tarjeta','transferencia','app','mixto') COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Método de pago',
  `monto_efectivo` decimal(10,2) DEFAULT NULL COMMENT 'Monto pagado en efectivo (si aplica)',
  `monto_tarjeta` decimal(10,2) DEFAULT NULL COMMENT 'Monto pagado con tarjeta (si aplica)',
  `monto_transferencia` decimal(10,2) DEFAULT NULL COMMENT 'Monto pagado por transferencia (si aplica)',
  `monto_app` decimal(10,2) DEFAULT NULL COMMENT 'Monto pagado por app (si aplica)',
  `membresia_id` int unsigned DEFAULT NULL COMMENT 'ID de la membresía vendida (si aplica)',
  `fecha_venta` datetime NOT NULL COMMENT 'Fecha y hora de la venta',
  `vendedor_id` int unsigned NOT NULL COMMENT 'ID del usuario que realizó la venta',
  `observaciones` text COLLATE utf8mb4_unicode_ci COMMENT 'Observaciones de la venta',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ventas_numero_factura` (`numero_factura`),
  KEY `idx_ventas_sesion_caja` (`sesion_caja_id`),
  KEY `idx_ventas_usuario` (`usuario_id`),
  KEY `idx_ventas_membresia` (`membresia_id`),
  KEY `idx_ventas_fecha` (`fecha_venta`),
  KEY `idx_ventas_vendedor` (`vendedor_id`),
  CONSTRAINT `fk_ventas_membresia` FOREIGN KEY (`membresia_id`) REFERENCES `membresias` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_sesion_caja` FOREIGN KEY (`sesion_caja_id`) REFERENCES `sesiones_caja` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_vendedor` FOREIGN KEY (`vendedor_id`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ventas realizadas desde la caja';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ventas`
--

LOCK TABLES `ventas` WRITE;
/*!40000 ALTER TABLE `ventas` DISABLE KEYS */;
INSERT INTO `ventas` VALUES (43,11,'FAC-20260108-6317',10,'membresia',25000.00,0.00,25000.00,'efectivo',25000.00,NULL,NULL,NULL,4,'2026-01-08 17:02:51',1,NULL,'2026-01-08 17:02:51','2026-01-08 17:02:51'),(44,11,'FAC-20260109-5462',11,'membresia',7000.00,0.00,7000.00,'efectivo',7000.00,NULL,NULL,NULL,5,'2026-01-09 17:45:31',1,NULL,'2026-01-09 17:45:31','2026-01-09 17:45:31'),(45,11,'FAC-20260110-6614',11,'membresia',7000.00,0.00,7000.00,'efectivo',7000.00,NULL,NULL,NULL,6,'2026-01-10 11:59:19',1,NULL,'2026-01-10 11:59:19','2026-01-10 11:59:19'),(46,11,'FAC-20260110-8788',12,'membresia',7000.00,0.00,7000.00,'efectivo',7000.00,NULL,NULL,NULL,7,'2026-01-10 22:47:45',1,NULL,'2026-01-11 03:47:45','2026-01-11 03:47:45'),(47,11,'FAC-20260111-0835',12,'membresia',7000.00,0.00,7000.00,'efectivo',7000.00,NULL,NULL,NULL,8,'2026-01-11 00:49:27',1,NULL,'2026-01-11 05:49:27','2026-01-11 05:49:27'),(48,11,'FAC-20260112-9250',12,'membresia',7000.00,0.00,7000.00,'efectivo',7000.00,NULL,NULL,NULL,9,'2026-01-12 06:52:10',1,NULL,'2026-01-12 11:52:10','2026-01-12 11:52:10'),(49,11,'FAC-20260202-5289',10,'membresia',25000.00,0.00,25000.00,'efectivo',25000.00,NULL,NULL,NULL,10,'2026-02-02 17:36:22',1,NULL,'2026-02-02 22:36:22','2026-02-02 22:36:22'),(50,11,'FAC-20260203-7977',NULL,'productos',50000.00,0.00,50000.00,'efectivo',50000.00,NULL,NULL,NULL,NULL,'2026-02-03 11:01:33',1,NULL,'2026-02-03 16:01:33','2026-02-03 16:01:33'),(51,11,'FAC-20260203-1077',13,'membresia',70000.00,0.00,70000.00,'efectivo',70000.00,NULL,NULL,NULL,11,'2026-02-03 11:05:57',1,NULL,'2026-02-03 16:05:57','2026-02-03 16:05:57'),(52,11,'FAC-20260204-4603',NULL,'productos',50000.00,0.00,50000.00,'efectivo',50000.00,NULL,NULL,NULL,NULL,'2026-02-04 15:14:44',1,NULL,'2026-02-04 20:14:44','2026-02-04 20:14:44'),(53,12,'FAC-20260204-7768',13,'membresia',7000.00,0.00,7000.00,'efectivo',7000.00,NULL,NULL,NULL,12,'2026-02-04 16:17:37',1,NULL,'2026-02-04 21:17:37','2026-02-04 21:17:37'),(54,12,'FAC-20260204-4875',14,'membresia',7000.00,0.00,7000.00,'efectivo',7000.00,NULL,NULL,NULL,13,'2026-02-04 16:18:55',1,NULL,'2026-02-04 21:18:55','2026-02-04 21:18:55');
/*!40000 ALTER TABLE `ventas` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-06 18:25:48
