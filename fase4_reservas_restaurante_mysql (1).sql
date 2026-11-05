-- =====================================================================
-- Sistema de Reservas de Restaurante - Fase 4: Base de datos
-- Motor: MySQL 8.0.16 o superior   |   Proyecto Integrador SENA 2026
-- Uso:   mysql -u root -p < fase4_reservas_restaurante_mysql.sql
-- =====================================================================

DROP DATABASE IF EXISTS reservas_restaurante;
CREATE DATABASE reservas_restaurante CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE reservas_restaurante;

-- =====================================================================
-- 1. TABLAS
--    EstadoMesa y EstadoReserva (diagrama de clases) son columnas ENUM.
-- =====================================================================

-- Seguridad: roles, permisos y usuarios (HU-08, HU-09, RF-13, RF-15)
CREATE TABLE rol (
    id_rol  INT          NOT NULL AUTO_INCREMENT,
    nombre  VARCHAR(30)  NOT NULL,
    CONSTRAINT pk_rol        PRIMARY KEY (id_rol),
    CONSTRAINT uq_rol_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE permiso (
    id_permiso   INT          NOT NULL AUTO_INCREMENT,
    nombre       VARCHAR(60)  NOT NULL,
    descripcion  VARCHAR(200),
    CONSTRAINT pk_permiso        PRIMARY KEY (id_permiso),
    CONSTRAINT uq_permiso_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE rol_permiso (
    id_rol      INT NOT NULL,
    id_permiso  INT NOT NULL,
    CONSTRAINT pk_rol_permiso PRIMARY KEY (id_rol, id_permiso),
    CONSTRAINT fk_rolperm_rol     FOREIGN KEY (id_rol)     REFERENCES rol(id_rol)         ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_rolperm_permiso FOREIGN KEY (id_permiso) REFERENCES permiso(id_permiso) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE usuario (
    id_usuario        INT          NOT NULL AUTO_INCREMENT,
    nombre            VARCHAR(100) NOT NULL,
    correo            VARCHAR(120) NOT NULL,
    telefono          VARCHAR(20)  NOT NULL,
    contrasena_hash   VARCHAR(255) NOT NULL,
    intentos_fallidos SMALLINT     NOT NULL DEFAULT 0,
    bloqueado_hasta   DATETIME     NULL,
    activo            BOOLEAN      NOT NULL DEFAULT TRUE,
    fecha_registro    DATE         NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT pk_usuario          PRIMARY KEY (id_usuario),
    CONSTRAINT uq_usuario_correo   UNIQUE (correo),                          -- RN-04, RN-14
    CONSTRAINT uq_usuario_telefono UNIQUE (telefono),                        -- RN-04, RN-14
    CONSTRAINT ck_usuario_nombre   CHECK (CHAR_LENGTH(TRIM(nombre)) > 0),
    CONSTRAINT ck_usuario_correo   CHECK (correo REGEXP '^[^@ ]+@[^@ ]+[.][^@ ]+$'),
    CONSTRAINT ck_usuario_telefono CHECK (telefono REGEXP '^[0-9+() -]{7,20}$'),
    CONSTRAINT ck_usuario_intentos CHECK (intentos_fallidos >= 0)
) ENGINE=InnoDB;

CREATE TABLE usuario_rol (
    id_usuario  INT NOT NULL,
    id_rol      INT NOT NULL,
    CONSTRAINT pk_usuario_rol PRIMARY KEY (id_usuario, id_rol),
    CONSTRAINT fk_urol_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_urol_rol     FOREIGN KEY (id_rol)     REFERENCES rol(id_rol)         ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Auditoria de cambios de rol/permiso (RN-12, RF-14)
CREATE TABLE registro_cambio (
    id_registro             INT          NOT NULL AUTO_INCREMENT,
    id_usuario_responsable  INT          NOT NULL,
    id_usuario_afectado     INT          NULL,
    descripcion             VARCHAR(300) NOT NULL,
    fecha_hora              DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_registro_cambio PRIMARY KEY (id_registro),
    CONSTRAINT fk_regcambio_resp  FOREIGN KEY (id_usuario_responsable) REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_regcambio_afect FOREIGN KEY (id_usuario_afectado)    REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- Parametros del restaurante (RN-05, RN-06). Una sola fila (id = 1).
CREATE TABLE configuracion_restaurante (
    id_configuracion          SMALLINT NOT NULL DEFAULT 1,
    anticipacion_minima_min   INT      NOT NULL DEFAULT 60,
    estado_inicial_reserva    ENUM('PENDIENTE', 'CONFIRMADA') NOT NULL DEFAULT 'PENDIENTE',
    horario_apertura          TIME     NOT NULL DEFAULT '11:00:00',
    horario_cierre            TIME     NOT NULL DEFAULT '22:00:00',
    CONSTRAINT pk_configuracion      PRIMARY KEY (id_configuracion),
    CONSTRAINT ck_config_unica       CHECK (id_configuracion = 1),
    CONSTRAINT ck_config_anticip     CHECK (anticipacion_minima_min >= 0),
    CONSTRAINT ck_config_horario     CHECK (horario_cierre > horario_apertura)
) ENGINE=InnoDB;

-- Mesas (HU-02, RF-02, RN-03)
CREATE TABLE mesa (
    id_mesa    INT          NOT NULL AUTO_INCREMENT,
    numero     INT          NOT NULL,
    capacidad  INT          NOT NULL,
    ubicacion  VARCHAR(50)  NOT NULL,
    estado     ENUM('LIBRE', 'RESERVADA', 'OCUPADA') NOT NULL DEFAULT 'LIBRE',
    CONSTRAINT pk_mesa           PRIMARY KEY (id_mesa),
    CONSTRAINT uq_mesa_numero    UNIQUE (numero),                            -- RN-03
    CONSTRAINT ck_mesa_numero    CHECK (numero > 0),
    CONSTRAINT ck_mesa_capacidad CHECK (capacidad > 0)                       -- HU-02
) ENGINE=InnoDB;

-- Contador para el codigo unico de reserva (MySQL no tiene SEQUENCE)
CREATE TABLE secuencia_reserva (
    id_secuencia  TINYINT NOT NULL DEFAULT 1,
    ultimo        INT     NOT NULL DEFAULT 0,
    CONSTRAINT pk_secuencia_reserva PRIMARY KEY (id_secuencia),
    CONSTRAINT ck_secuencia_unica   CHECK (id_secuencia = 1)
) ENGINE=InnoDB;

-- Reservas (HU-04, HU-06, HU-07, RF-04 a RF-12)
-- El cruce de horarios (RN-01 / RF-09 / RF-10 / RNF-04) lo controla el trigger
-- trg_reserva_bi / trg_reserva_bu, que bloquea la mesa antes de validar.
CREATE TABLE reserva (
    id_reserva       INT          NOT NULL AUTO_INCREMENT,
    codigo_unico     VARCHAR(25)  NOT NULL,
    id_cliente       INT          NOT NULL,
    id_mesa          INT          NOT NULL,
    fecha            DATE         NOT NULL,
    hora_inicio      TIME         NOT NULL,
    hora_fin         TIME         NOT NULL,
    numero_personas  INT          NOT NULL,
    estado           ENUM('PENDIENTE', 'CONFIRMADA', 'CANCELADA', 'FINALIZADA') NOT NULL DEFAULT 'PENDIENTE',
    fecha_creacion   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_reserva           PRIMARY KEY (id_reserva),
    CONSTRAINT uq_reserva_codigo    UNIQUE (codigo_unico),                   -- RF-05
    CONSTRAINT fk_reserva_cliente   FOREIGN KEY (id_cliente) REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_reserva_mesa      FOREIGN KEY (id_mesa)    REFERENCES mesa(id_mesa)       ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_reserva_horas     CHECK (hora_fin > hora_inicio),
    CONSTRAINT ck_reserva_personas  CHECK (numero_personas > 0)
) ENGINE=InnoDB;

-- Notificaciones (RF-06). Composicion 1 a 0..1 con Reserva.
CREATE TABLE notificacion (
    id_notificacion  INT          NOT NULL AUTO_INCREMENT,
    id_reserva       INT          NOT NULL,
    tipo             VARCHAR(30)  NOT NULL,
    mensaje          VARCHAR(300) NOT NULL,
    fecha_envio      DATETIME     NULL,
    estado_envio     VARCHAR(15)  NOT NULL DEFAULT 'PENDIENTE',
    CONSTRAINT pk_notificacion         PRIMARY KEY (id_notificacion),
    CONSTRAINT uq_notificacion_reserva UNIQUE (id_reserva),
    CONSTRAINT fk_notif_reserva        FOREIGN KEY (id_reserva) REFERENCES reserva(id_reserva) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_notificacion_estado  CHECK (estado_envio IN ('PENDIENTE', 'ENVIADA', 'FALLIDA'))
) ENGINE=InnoDB;

-- Indices de apoyo a las consultas frecuentes
CREATE INDEX ix_reserva_mesa_fecha   ON reserva (id_mesa, fecha, estado);    -- validacion de cruces
CREATE INDEX ix_reserva_cliente      ON reserva (id_cliente, fecha);         -- HU-11
CREATE INDEX ix_reserva_fecha_estado ON reserva (fecha, estado);             -- HU-05
CREATE INDEX ix_usuario_nombre       ON usuario (nombre);                    -- HU-12
CREATE INDEX ix_registro_cambio_fecha ON registro_cambio (fecha_hora);

-- =====================================================================
-- 2. REGLAS DE NEGOCIO EN PROCEDIMIENTOS Y TRIGGERS
-- =====================================================================
DELIMITER $$

-- 2.1 Validacion comun de una reserva: RN-01, RN-02, RN-05, RN-10, horario.
--     Primero bloquea la fila de la mesa (FOR UPDATE): si dos solicitudes llegan
--     al mismo tiempo por la misma mesa, la segunda espera a que la primera
--     termine y entonces ve su reserva (RF-10, RNF-04).
CREATE PROCEDURE sp_validar_reserva(
    IN p_id_reserva INT, IN p_id_cliente INT, IN p_id_mesa INT, IN p_fecha DATE,
    IN p_hora_inicio TIME, IN p_hora_fin TIME, IN p_personas INT,
    IN p_estado VARCHAR(12), IN p_revisar_horario BOOLEAN)
BEGIN
    DECLARE v_cap     INT;
    DECLARE v_es_cli  INT;
    DECLARE v_ant     INT;
    DECLARE v_ap      TIME;
    DECLARE v_ci      TIME;
    DECLARE v_cruces  INT;

    SELECT capacidad INTO v_cap FROM mesa WHERE id_mesa = p_id_mesa FOR UPDATE;
    IF v_cap IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La mesa indicada no existe';
    END IF;

    SELECT COUNT(*) INTO v_es_cli
      FROM usuario_rol ur JOIN rol r ON r.id_rol = ur.id_rol
     WHERE ur.id_usuario = p_id_cliente AND r.nombre = 'CLIENTE';
    IF v_es_cli = 0 THEN                                                     -- RN-10
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario no tiene rol CLIENTE (RN-10)';
    END IF;

    IF p_personas > v_cap THEN                                               -- RN-02
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'La capacidad de la mesa es menor al numero de personas (RN-02)';
    END IF;

    IF p_estado IN ('PENDIENTE', 'CONFIRMADA') AND p_revisar_horario THEN
        SELECT horario_apertura, horario_cierre, anticipacion_minima_min
          INTO v_ap, v_ci, v_ant
          FROM configuracion_restaurante WHERE id_configuracion = 1;

        IF p_hora_inicio < v_ap OR p_hora_fin > v_ci THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La reserva esta fuera del horario del restaurante';
        END IF;
        IF TIMESTAMP(p_fecha, p_hora_inicio) < NOW() + INTERVAL v_ant MINUTE THEN   -- RN-05
            SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = 'La reserva no respeta la anticipacion minima configurada (RN-05)';
        END IF;

        -- RN-01: cruce con otra reserva activa de la misma mesa.
        -- FOR SHARE = lectura del dato mas reciente (no de una foto anterior).
        -- (FOR UPDATE no se permite sobre la tabla del propio trigger, error 1442.)
        SELECT COUNT(*) INTO v_cruces
          FROM reserva
         WHERE id_mesa = p_id_mesa AND fecha = p_fecha
           AND estado IN ('PENDIENTE', 'CONFIRMADA')
           AND id_reserva <> p_id_reserva
           AND hora_inicio < p_hora_fin AND hora_fin > p_hora_inicio
           FOR SHARE;
        IF v_cruces > 0 THEN
            SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = 'La mesa ya tiene una reserva activa que se cruza en ese horario (RN-01)';
        END IF;
    END IF;
END$$

-- 2.2 Antes de insertar: estado inicial (RN-06), codigo unico (RF-05) y validacion
CREATE TRIGGER trg_reserva_bi BEFORE INSERT ON reserva
FOR EACH ROW
BEGIN
    DECLARE v_n INT;
    DECLARE v_ini VARCHAR(12);

    IF NEW.estado IS NULL THEN
        SELECT estado_inicial_reserva INTO v_ini
          FROM configuracion_restaurante WHERE id_configuracion = 1;
        SET NEW.estado = v_ini;
    END IF;
    IF NEW.estado NOT IN ('PENDIENTE', 'CONFIRMADA') THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'Una reserva nueva solo puede iniciar PENDIENTE o CONFIRMADA (RN-06)';
    END IF;

    IF NEW.codigo_unico IS NULL OR NEW.codigo_unico = '' THEN
        UPDATE secuencia_reserva SET ultimo = ultimo + 1 WHERE id_secuencia = 1;
        SELECT ultimo INTO v_n FROM secuencia_reserva WHERE id_secuencia = 1;
        SET NEW.codigo_unico = CONCAT('RES-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(v_n, 5, '0'));
    END IF;

    CALL sp_validar_reserva(0, NEW.id_cliente, NEW.id_mesa, NEW.fecha, NEW.hora_inicio,
                            NEW.hora_fin, NEW.numero_personas, NEW.estado, TRUE);
END$$

-- 2.3 Antes de modificar: codigo inmodificable (RF-05), transiciones (RN-08), revalidacion (RN-09)
CREATE TRIGGER trg_reserva_bu BEFORE UPDATE ON reserva
FOR EACH ROW
BEGIN
    DECLARE v_cambio_horario BOOLEAN;

    IF NOT (NEW.codigo_unico <=> OLD.codigo_unico) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El codigo unico de la reserva no se puede modificar (RF-05)';
    END IF;

    IF NEW.estado <> OLD.estado AND NOT (
           (OLD.estado = 'PENDIENTE'  AND NEW.estado IN ('CONFIRMADA', 'CANCELADA')) OR
           (OLD.estado = 'CONFIRMADA' AND NEW.estado IN ('CANCELADA', 'FINALIZADA'))) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'Transicion de estado no permitida; una reserva cancelada no se reactiva (RN-08)';
    END IF;

    SET v_cambio_horario = NOT (NEW.fecha = OLD.fecha AND NEW.hora_inicio = OLD.hora_inicio
                                AND NEW.hora_fin = OLD.hora_fin AND NEW.id_mesa = OLD.id_mesa);

    CALL sp_validar_reserva(OLD.id_reserva, NEW.id_cliente, NEW.id_mesa, NEW.fecha, NEW.hora_inicio,
                            NEW.hora_fin, NEW.numero_personas, NEW.estado, v_cambio_horario);
END$$

-- 2.4 Despues de cambiar una reserva: estado de la mesa (HU-02) y liberacion (RN-07)
CREATE PROCEDURE sp_actualizar_estado_mesa(
    IN p_id_reserva INT, IN p_id_mesa INT, IN p_estado VARCHAR(12), IN p_fecha DATE)
BEGIN
    IF p_estado = 'CONFIRMADA' AND p_fecha = CURRENT_DATE THEN
        UPDATE mesa SET estado = 'RESERVADA' WHERE id_mesa = p_id_mesa AND estado = 'LIBRE';
    ELSEIF p_estado IN ('CANCELADA', 'FINALIZADA') THEN
        UPDATE mesa SET estado = 'LIBRE'
         WHERE id_mesa = p_id_mesa AND estado = 'RESERVADA'
           AND NOT EXISTS (SELECT 1 FROM reserva r
                            WHERE r.id_mesa = p_id_mesa AND r.estado = 'CONFIRMADA'
                              AND r.fecha = CURRENT_DATE AND r.id_reserva <> p_id_reserva);
    END IF;
END$$

CREATE TRIGGER trg_reserva_ai AFTER INSERT ON reserva
FOR EACH ROW
BEGIN
    CALL sp_actualizar_estado_mesa(NEW.id_reserva, NEW.id_mesa, NEW.estado, NEW.fecha);
END$$

CREATE TRIGGER trg_reserva_au AFTER UPDATE ON reserva
FOR EACH ROW
BEGIN
    IF NEW.estado <> OLD.estado THEN
        CALL sp_actualizar_estado_mesa(NEW.id_reserva, NEW.id_mesa, NEW.estado, NEW.fecha);
    END IF;
END$$

-- 2.5 Auditoria automatica de cambios de rol (RN-12). El responsable se informa con:
--     SET @usuario_actual = <id_usuario>;   (si no se define, no se registra)
CREATE TRIGGER trg_usuario_rol_ai AFTER INSERT ON usuario_rol
FOR EACH ROW
BEGIN
    IF @usuario_actual IS NOT NULL THEN
        INSERT INTO registro_cambio (id_usuario_responsable, id_usuario_afectado, descripcion)
        VALUES (@usuario_actual, NEW.id_usuario, CONCAT('Rol asignado, id_rol ', NEW.id_rol));
    END IF;
END$$

CREATE TRIGGER trg_usuario_rol_ad AFTER DELETE ON usuario_rol
FOR EACH ROW
BEGIN
    IF @usuario_actual IS NOT NULL THEN
        INSERT INTO registro_cambio (id_usuario_responsable, id_usuario_afectado, descripcion)
        VALUES (@usuario_actual, OLD.id_usuario, CONCAT('Rol retirado, id_rol ', OLD.id_rol));
    END IF;
END$$

-- =====================================================================
-- 3. PROCEDIMIENTO Y VISTAS DE CONSULTA
-- =====================================================================

-- HU-03 / RF-03: mesas disponibles por fecha, horario y numero de personas
--   CALL sp_mesas_disponibles('2026-10-20', '13:00', '15:00', 2);
CREATE PROCEDURE sp_mesas_disponibles(
    IN p_fecha DATE, IN p_hora_inicio TIME, IN p_hora_fin TIME, IN p_personas INT)
BEGIN
    SELECT m.id_mesa, m.numero, m.capacidad, m.ubicacion
      FROM mesa m
     WHERE m.capacidad >= p_personas                                         -- RN-02
       AND NOT EXISTS (
            SELECT 1 FROM reserva r
             WHERE r.id_mesa = m.id_mesa AND r.fecha = p_fecha
               AND r.estado IN ('PENDIENTE', 'CONFIRMADA')
               AND r.hora_inicio < p_hora_fin AND r.hora_fin > p_hora_inicio)
     ORDER BY m.capacidad, m.numero;
END$$

DELIMITER ;

-- HU-05 / RF-07 / RF-08: panel de reservas (filtrar por fecha y estado)
CREATE VIEW v_panel_reservas AS
SELECT r.fecha, r.hora_inicio, r.hora_fin, r.codigo_unico, m.numero AS mesa,
       u.nombre AS cliente, u.telefono, r.numero_personas, r.estado
  FROM reserva r
  JOIN mesa    m ON m.id_mesa    = r.id_mesa
  JOIN usuario u ON u.id_usuario = r.id_cliente;

-- HU-11 / RF-18: historial de reservas por cliente (filtrar por id_cliente)
CREATE VIEW v_historial_cliente AS
SELECT r.id_cliente, r.codigo_unico, r.fecha, r.hora_inicio, m.numero AS mesa,
       r.numero_personas, r.estado
  FROM reserva r
  JOIN mesa m ON m.id_mesa = r.id_mesa;

-- =====================================================================
-- 4. DATOS DE PRUEBA (ficticios)
-- =====================================================================

INSERT INTO rol (nombre) VALUES ('CLIENTE'), ('RECEPCIONISTA'), ('ADMINISTRADOR');

INSERT INTO permiso (nombre, descripcion) VALUES
 ('CONSULTAR_DISPONIBILIDAD', 'Consultar mesas disponibles'),
 ('GESTIONAR_RESERVAS_PROPIAS', 'Crear, modificar, cancelar y ver reservas propias'),
 ('EDITAR_PERFIL_PROPIO', 'Actualizar los datos del propio perfil'),
 ('GESTIONAR_MESAS', 'Registrar y editar mesas'),
 ('VER_PANEL_RESERVAS', 'Ver el panel de reservas del dia'),
 ('GESTIONAR_RESERVAS_TODAS', 'Confirmar y reubicar cualquier reserva'),
 ('BUSCAR_CLIENTES', 'Buscar clientes por nombre, telefono o correo'),
 ('GESTIONAR_USUARIOS_ROLES', 'Administrar usuarios, roles y permisos'),
 ('CONFIGURAR_RESTAURANTE', 'Configurar parametros generales');

INSERT INTO rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM rol r JOIN permiso p ON
   (r.nombre = 'CLIENTE' AND p.nombre IN
        ('CONSULTAR_DISPONIBILIDAD', 'GESTIONAR_RESERVAS_PROPIAS', 'EDITAR_PERFIL_PROPIO'))
OR (r.nombre = 'RECEPCIONISTA' AND p.nombre IN
        ('CONSULTAR_DISPONIBILIDAD', 'GESTIONAR_MESAS', 'VER_PANEL_RESERVAS',
         'GESTIONAR_RESERVAS_TODAS', 'BUSCAR_CLIENTES'))
OR (r.nombre = 'ADMINISTRADOR');          -- el administrador recibe todos los permisos

INSERT INTO configuracion_restaurante (id_configuracion) VALUES (1);   -- valores por defecto
INSERT INTO secuencia_reserva (id_secuencia, ultimo) VALUES (1, 0);

-- Los hashes son marcadores ficticios; la aplicacion debe generar hashes reales (bcrypt/argon2)
INSERT INTO usuario (nombre, correo, telefono, contrasena_hash) VALUES
 ('Laura Admin',        'admin@restaurante.test',      '3001000001', '$2b$10$HASH_FICTICIO_ADMIN'),
 ('Camilo Recepcion',   'recepcion@restaurante.test',  '3001000002', '$2b$10$HASH_FICTICIO_RECEP'),
 ('Ana Torres',         'ana.torres@correo.test',      '3102000001', '$2b$10$HASH_FICTICIO_C1'),
 ('Carlos Rojas',       'carlos.rojas@correo.test',    '3102000002', '$2b$10$HASH_FICTICIO_C2'),
 ('Marta Perdomo',      'marta.perdomo@correo.test',   '3102000003', '$2b$10$HASH_FICTICIO_C3'),
 ('Julian Cabrera',     'julian.cabrera@correo.test',  '3102000004', '$2b$10$HASH_FICTICIO_C4'),
 ('Sofia Ramirez',      'sofia.ramirez@correo.test',   '3102000005', '$2b$10$HASH_FICTICIO_C5');

INSERT INTO usuario_rol (id_usuario, id_rol)
SELECT u.id_usuario, r.id_rol FROM usuario u JOIN rol r ON
   (u.correo = 'admin@restaurante.test'     AND r.nombre = 'ADMINISTRADOR')
OR (u.correo = 'recepcion@restaurante.test' AND r.nombre = 'RECEPCIONISTA')
OR (u.correo LIKE '%@correo.test'           AND r.nombre = 'CLIENTE');

INSERT INTO mesa (numero, capacidad, ubicacion) VALUES
 (1, 2, 'Ventana'), (2, 2, 'Ventana'), (3, 4, 'Salon principal'), (4, 4, 'Salon principal'),
 (5, 4, 'Terraza'), (6, 6, 'Terraza'), (7, 8, 'Salon privado'), (8, 10, 'Salon privado');

-- Ids que se reutilizan abajo. Nota de MySQL: un INSERT/UPDATE de reserva NO puede
-- consultar la tabla mesa en una subconsulta, porque sus triggers modifican mesa
-- (error 1442). Por eso aqui se guardan los ids en variables y se usan directamente.
SELECT id_mesa INTO @m1 FROM mesa WHERE numero = 1;
SELECT id_mesa INTO @m2 FROM mesa WHERE numero = 2;
SELECT id_mesa INTO @m3 FROM mesa WHERE numero = 3;
SELECT id_mesa INTO @m4 FROM mesa WHERE numero = 4;
SELECT id_mesa INTO @m5 FROM mesa WHERE numero = 5;
SELECT id_mesa INTO @m6 FROM mesa WHERE numero = 6;
SELECT id_mesa INTO @m8 FROM mesa WHERE numero = 8;
SELECT id_usuario INTO @u_ana    FROM usuario WHERE correo = 'ana.torres@correo.test';
SELECT id_usuario INTO @u_carlos FROM usuario WHERE correo = 'carlos.rojas@correo.test';
SELECT id_usuario INTO @u_marta  FROM usuario WHERE correo = 'marta.perdomo@correo.test';
SELECT id_usuario INTO @u_julian FROM usuario WHERE correo = 'julian.cabrera@correo.test';
SELECT id_usuario INTO @u_sofia  FROM usuario WHERE correo = 'sofia.ramirez@correo.test';

-- Reservas: fechas relativas a hoy para respetar la anticipacion minima (RN-05).
-- No se indica codigo_unico: lo genera el trigger (RF-05).
INSERT INTO reserva (id_cliente, id_mesa, fecha, hora_inicio, hora_fin, numero_personas, estado) VALUES
 (@u_ana,    @m3, CURRENT_DATE + INTERVAL 1 DAY, '13:00:00', '15:00:00', 4, 'CONFIRMADA'),
 (@u_carlos, @m1, CURRENT_DATE + INTERVAL 1 DAY, '13:00:00', '14:30:00', 2, 'PENDIENTE'),
 (@u_marta,  @m6, CURRENT_DATE + INTERVAL 1 DAY, '19:00:00', '21:00:00', 6, 'CONFIRMADA'),
 (@u_julian, @m3, CURRENT_DATE + INTERVAL 1 DAY, '15:00:00', '17:00:00', 3, 'PENDIENTE'),   -- contigua a la 1ra (permitido)
 (@u_sofia,  @m8, CURRENT_DATE + INTERVAL 2 DAY, '20:00:00', '22:00:00', 9, 'CONFIRMADA'),
 (@u_ana,    @m5, CURRENT_DATE + INTERVAL 3 DAY, '12:00:00', '13:30:00', 4, 'PENDIENTE'),
 (@u_carlos, @m2, CURRENT_DATE + INTERVAL 3 DAY, '19:00:00', '20:30:00', 2, 'CONFIRMADA'),
 (@u_marta,  @m4, CURRENT_DATE + INTERVAL 4 DAY, '18:00:00', '20:00:00', 4, 'CONFIRMADA');

-- Una cancelada (libera la mesa; la misma mesa/horario puede reservarse de nuevo, RN-07)
UPDATE reserva SET estado = 'CANCELADA'
 WHERE id_cliente = @u_carlos AND id_mesa = @m1;
INSERT INTO reserva (id_cliente, id_mesa, fecha, hora_inicio, hora_fin, numero_personas, estado)
VALUES (@u_julian, @m1, CURRENT_DATE + INTERVAL 1 DAY, '13:00:00', '14:00:00', 2, 'CONFIRMADA');

-- Una finalizada (ejemplo del ciclo de vida completo)
UPDATE reserva SET estado = 'FINALIZADA' WHERE id_mesa = @m4;

-- Notificaciones de las reservas confirmadas o finalizadas
INSERT INTO notificacion (id_reserva, tipo, mensaje, fecha_envio, estado_envio)
SELECT id_reserva, 'CONFIRMACION',
       CONCAT('Su reserva ', codigo_unico, ' fue registrada correctamente.'), NOW(), 'ENVIADA'
  FROM reserva WHERE estado IN ('CONFIRMADA', 'FINALIZADA');

-- Auditoria de ejemplo (RN-12): el administrador asigna un rol
SET @usuario_actual = 1;
INSERT INTO usuario_rol (id_usuario, id_rol)
SELECT u.id_usuario, r.id_rol FROM usuario u, rol r
 WHERE u.correo = 'recepcion@restaurante.test' AND r.nombre = 'CLIENTE';   -- la recepcionista tambien puede reservar
SET @usuario_actual = NULL;

-- =====================================================================
-- 5. CONSULTAS DE VERIFICACION (ejecutar despues de cargar)
-- =====================================================================
-- Mesas libres manana de 13:00 a 15:00 para 2 personas:
--   CALL sp_mesas_disponibles(CURRENT_DATE + INTERVAL 1 DAY, '13:00', '15:00', 2);
-- Panel de reservas de manana, solo confirmadas:
--   SELECT * FROM v_panel_reservas WHERE fecha = CURRENT_DATE + INTERVAL 1 DAY AND estado = 'CONFIRMADA' ORDER BY hora_inicio;
-- Historial de un cliente:
--   SELECT * FROM v_historial_cliente WHERE id_cliente = 3 ORDER BY fecha DESC;
-- Debe FALLAR (cruce en mesa 3, RN-01):
--   INSERT INTO reserva (id_cliente,id_mesa,fecha,hora_inicio,hora_fin,numero_personas,estado)
--   VALUES (3,3,CURRENT_DATE + INTERVAL 1 DAY,'14:00','16:00',4,'CONFIRMADA');
-- Debe FALLAR (capacidad insuficiente, RN-02):
--   INSERT INTO reserva (id_cliente,id_mesa,fecha,hora_inicio,hora_fin,numero_personas,estado)
--   VALUES (3,1,CURRENT_DATE + INTERVAL 5 DAY,'13:00','14:00',5,'PENDIENTE');
-- Debe FALLAR (reactivar cancelada, RN-08):
--   UPDATE reserva SET estado='CONFIRMADA' WHERE estado='CANCELADA';
