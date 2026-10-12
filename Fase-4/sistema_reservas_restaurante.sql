-- ============================================================================
-- Sistema de Reservas de un Restaurante
-- Fase 4 — Implementación: Tablas SQL + restricciones + script + datos de prueba
-- Motor: MySQL 8.0+ / MariaDB 10.2.1+ (CHECK constraints soportados)
-- Basado en el modelo lógico de la sección 5.3 del documento de Fase 4
-- ============================================================================

DROP DATABASE IF EXISTS sistema_reservas_restaurante;
CREATE DATABASE sistema_reservas_restaurante
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE sistema_reservas_restaurante;

-- ----------------------------------------------------------------------------
-- 1. rol
-- ----------------------------------------------------------------------------
CREATE TABLE rol (
    id_rol  INT AUTO_INCREMENT PRIMARY KEY,
    nombre  VARCHAR(30) NOT NULL,
    CONSTRAINT uk_rol_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 2. permiso
-- ----------------------------------------------------------------------------
CREATE TABLE permiso (
    id_permiso   INT AUTO_INCREMENT PRIMARY KEY,
    nombre       VARCHAR(60) NOT NULL,
    descripcion  VARCHAR(200) NULL,
    CONSTRAINT uk_permiso_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 3. configuracion_restaurante (opcional, decisión D-6)
-- ----------------------------------------------------------------------------
CREATE TABLE configuracion_restaurante (
    id_configuracion            INT AUTO_INCREMENT PRIMARY KEY,
    anticipacion_minima_minutos INT NOT NULL,
    estado_inicial_reserva      VARCHAR(12) NOT NULL,
    horario_apertura            TIME NOT NULL,
    horario_cierre              TIME NOT NULL,
    CONSTRAINT ck_config_anticipacion CHECK (anticipacion_minima_minutos >= 0),           -- RN-05 (propuesta)
    CONSTRAINT ck_config_estado_inicial CHECK (estado_inicial_reserva IN ('PENDIENTE','CONFIRMADA')),  -- RN-06
    CONSTRAINT ck_config_horario CHECK (horario_cierre > horario_apertura)                -- propuesta
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 4. usuario (estrategia: tabla única, sección 5.2)
-- ----------------------------------------------------------------------------
CREATE TABLE usuario (
    id_usuario       INT AUTO_INCREMENT PRIMARY KEY,
    nombre           VARCHAR(100) NOT NULL,                       -- HU-01
    correo           VARCHAR(100) NOT NULL,                       -- RN-04
    telefono         VARCHAR(20) NOT NULL,                        -- RN-04
    contrasena_hash  VARCHAR(255) NOT NULL,                       -- se guarda solo el hash
    fecha_registro   DATE NOT NULL,
    id_rol           INT NOT NULL,
    CONSTRAINT uk_usuario_correo UNIQUE (correo),
    CONSTRAINT uk_usuario_telefono UNIQUE (telefono),
    CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol)
        REFERENCES rol (id_rol)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 5. mesa
-- ----------------------------------------------------------------------------
CREATE TABLE mesa (
    id_mesa    INT AUTO_INCREMENT PRIMARY KEY,
    numero     INT NOT NULL,                                      -- RN-03, HU-02
    capacidad  INT NOT NULL,
    ubicacion  VARCHAR(50) NOT NULL,
    estado     VARCHAR(10) NOT NULL DEFAULT 'LIBRE',
    CONSTRAINT uk_mesa_numero UNIQUE (numero),
    CONSTRAINT ck_mesa_capacidad CHECK (capacidad > 0),            -- HU-02
    CONSTRAINT ck_mesa_estado CHECK (estado IN ('LIBRE','RESERVADA','OCUPADA'))
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 6. rol_permiso (tabla intermedia N:M, sección 5.5)
-- ----------------------------------------------------------------------------
CREATE TABLE rol_permiso (
    id_rol     INT NOT NULL,
    id_permiso INT NOT NULL,
    PRIMARY KEY (id_rol, id_permiso),
    CONSTRAINT fk_rolpermiso_rol FOREIGN KEY (id_rol)
        REFERENCES rol (id_rol)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_rolpermiso_permiso FOREIGN KEY (id_permiso)
        REFERENCES permiso (id_permiso)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 7. reserva
-- ----------------------------------------------------------------------------
CREATE TABLE reserva (
    id_reserva        INT AUTO_INCREMENT PRIMARY KEY,
    codigo_unico      VARCHAR(20) NOT NULL,                       -- RF-05, HU-04
    fecha             DATE NOT NULL,
    hora_inicio       TIME NOT NULL,
    hora_fin          TIME NOT NULL,
    numero_personas   INT NOT NULL,
    estado            VARCHAR(12) NOT NULL DEFAULT 'PENDIENTE',
    fecha_creacion    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_cliente        INT NOT NULL,
    id_mesa           INT NOT NULL,
    id_configuracion  INT NOT NULL,                                -- tabla opcional, D-6
    CONSTRAINT uk_reserva_codigo UNIQUE (codigo_unico),
    CONSTRAINT ck_reserva_horario CHECK (hora_fin > hora_inicio),   -- propuesta
    CONSTRAINT ck_reserva_personas CHECK (numero_personas > 0),     -- propuesta
    CONSTRAINT ck_reserva_estado CHECK (estado IN ('PENDIENTE','CONFIRMADA','CANCELADA','FINALIZADA')),
    CONSTRAINT fk_reserva_cliente FOREIGN KEY (id_cliente)
        REFERENCES usuario (id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE,                       -- HU-11, RN-08: no se elimina historial
    CONSTRAINT fk_reserva_mesa FOREIGN KEY (id_mesa)
        REFERENCES mesa (id_mesa)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reserva_configuracion FOREIGN KEY (id_configuracion)
        REFERENCES configuracion_restaurante (id_configuracion)
        ON DELETE RESTRICT ON UPDATE CASCADE
    -- Nota: que id_cliente tenga rol "Cliente" NO lo garantiza una FK;
    -- queda como validación de la aplicación (sección 5.6 del documento).
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 8. notificacion (composición 1 a 0..1 con reserva)
-- ----------------------------------------------------------------------------
CREATE TABLE notificacion (
    id_notificacion  INT AUTO_INCREMENT PRIMARY KEY,
    tipo             VARCHAR(30) NOT NULL,
    mensaje          VARCHAR(255) NOT NULL,
    fecha_envio      TIMESTAMP NULL,                                -- opcional hasta que se concrete el envío (H-6)
    estado_envio     VARCHAR(20) NOT NULL,
    id_reserva       INT NOT NULL,
    CONSTRAINT uk_notificacion_reserva UNIQUE (id_reserva),          -- máximo una notificación por reserva
    CONSTRAINT fk_notificacion_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva)
        ON DELETE CASCADE ON UPDATE CASCADE                         -- composición: muere con la reserva
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 9. registro_cambio
-- ----------------------------------------------------------------------------
CREATE TABLE registro_cambio (
    id_registro             INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario_responsable  INT NOT NULL,                           -- RN-12
    fecha                   TIMESTAMP NOT NULL,                     -- RF-14
    descripcion             VARCHAR(255) NOT NULL,
    CONSTRAINT fk_registro_usuario FOREIGN KEY (id_usuario_responsable)
        REFERENCES usuario (id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Índices adicionales de apoyo a las consultas más frecuentes
-- (no sustituyen las restricciones; aceleran las búsquedas de HU-03/HU-05/HU-06)
-- ----------------------------------------------------------------------------
CREATE INDEX idx_reserva_mesa_fecha  ON reserva (id_mesa, fecha, estado);  -- apoya la validación de cruces (RN-01)
CREATE INDEX idx_reserva_cliente     ON reserva (id_cliente);              -- apoya historial (HU-11)
CREATE INDEX idx_usuario_rol         ON usuario (id_rol);


-- ============================================================================
-- DATOS DE PRUEBA
-- ============================================================================

-- ----------------------------------------------------------------------------
-- rol
-- ----------------------------------------------------------------------------
INSERT INTO rol (nombre) VALUES
    ('Cliente'),
    ('Recepcionista'),
    ('Administrador');

-- ----------------------------------------------------------------------------
-- permiso  (criterio de HU-08: mesas y panel del día para recepcionista y administrador)
-- ----------------------------------------------------------------------------
INSERT INTO permiso (nombre, descripcion) VALUES
    ('gestionar_mesas',          'Registrar y editar mesas del restaurante'),
    ('ver_panel_reservas_dia',   'Consultar y filtrar el panel de reservas del día'),
    ('gestionar_roles_permisos', 'Asignar y retirar roles y permisos a usuarios'),
    ('gestionar_usuarios',       'Crear, editar o desactivar cuentas de usuario');

-- ----------------------------------------------------------------------------
-- rol_permiso
--   Recepcionista: gestionar_mesas, ver_panel_reservas_dia
--   Administrador: los cuatro permisos
-- ----------------------------------------------------------------------------
INSERT INTO rol_permiso (id_rol, id_permiso) VALUES
    (2, 1), (2, 2),                 -- Recepcionista
    (3, 1), (3, 2), (3, 3), (3, 4); -- Administrador

-- ----------------------------------------------------------------------------
-- configuracion_restaurante
-- ----------------------------------------------------------------------------
INSERT INTO configuracion_restaurante
    (anticipacion_minima_minutos, estado_inicial_reserva, horario_apertura, horario_cierre)
VALUES
    (30, 'PENDIENTE', '12:00:00', '22:00:00');

-- ----------------------------------------------------------------------------
-- usuario  (contrasena_hash son valores ficticios de ejemplo, no hashes reales)
-- ----------------------------------------------------------------------------
INSERT INTO usuario (nombre, correo, telefono, contrasena_hash, fecha_registro, id_rol) VALUES
    ('Ana Gómez',          'ana.gomez@correo.com',      '3101234567', '$2y$10$ejemploHashAna000000000000000000000000000000', '2026-09-01', 1), -- Cliente
    ('Luis Rojas',         'luis.rojas@correo.com',     '3207654321', '$2y$10$ejemploHashLuis00000000000000000000000000000', '2026-09-03', 1), -- Cliente
    ('Marta Díaz',         'marta.diaz@correo.com',     '3159876543', '$2y$10$ejemploHashMarta0000000000000000000000000000', '2026-09-05', 1), -- Cliente
    ('Carlos Ibáñez',      'carlos.ibanez@restaurante.com', '3001112233', '$2y$10$ejemploHashCarlos000000000000000000000000000', '2026-08-15', 2), -- Recepcionista
    ('Daniela Suárez',     'daniela.suarez@restaurante.com', '3002223344', '$2y$10$ejemploHashDaniela00000000000000000000000000', '2026-08-01', 3); -- Administrador

-- ----------------------------------------------------------------------------
-- mesa
-- ----------------------------------------------------------------------------
INSERT INTO mesa (numero, capacidad, ubicacion, estado) VALUES
    (1, 2, 'Ventana',       'LIBRE'),
    (2, 2, 'Terraza',       'LIBRE'),
    (3, 4, 'Salón principal','LIBRE'),
    (4, 4, 'Salón principal','LIBRE'),
    (5, 6, 'Salón privado',  'LIBRE');

-- ----------------------------------------------------------------------------
-- reserva
--   Códigos únicos RES-001.. ; se evita cualquier cruce entre reservas activas
--   (PENDIENTE/CONFIRMADA) de la misma mesa, fecha y horario (RN-01).
-- ----------------------------------------------------------------------------
INSERT INTO reserva
    (codigo_unico, fecha, hora_inicio, hora_fin, numero_personas, estado, id_cliente, id_mesa, id_configuracion)
VALUES
    ('RES-001', '2026-10-20', '19:00:00', '21:00:00', 4, 'CONFIRMADA', 1, 5, 1),  -- Ana, mesa 5
    ('RES-002', '2026-10-22', '20:00:00', '22:00:00', 4, 'CONFIRMADA', 1, 5, 1),  -- Ana, mesa 5, otro horario: no se cruza
    ('RES-003', '2026-10-22', '13:00:00', '14:30:00', 2, 'PENDIENTE',  2, 2, 1),  -- Luis, mesa 2
    ('RES-004', '2026-10-18', '19:00:00', '20:30:00', 2, 'CANCELADA',  3, 1, 1),  -- Marta, cancelada: libera la mesa (RN-07)
    ('RES-005', '2026-10-18', '19:00:00', '20:30:00', 2, 'CONFIRMADA', 2, 1, 1),  -- Luis, misma mesa/horario que la cancelada: válido (RN-08)
    ('RES-006', '2026-09-30', '13:00:00', '15:00:00', 4, 'FINALIZADA', 1, 3, 1);  -- Ana, reserva ya concluida

-- ----------------------------------------------------------------------------
-- notificacion  (0..1 por reserva, RF-06; se genera al confirmar/crear)
-- ----------------------------------------------------------------------------
INSERT INTO notificacion (tipo, mensaje, fecha_envio, estado_envio, id_reserva) VALUES
    ('CONFIRMACION', 'Su reserva RES-001 para el 2026-10-20 a las 19:00 ha sido confirmada.', '2026-10-10 10:00:00', 'ENVIADA', 1),
    ('CONFIRMACION', 'Su reserva RES-002 para el 2026-10-22 a las 20:00 ha sido confirmada.', '2026-10-10 10:05:00', 'ENVIADA', 2),
    ('PENDIENTE',    'Su reserva RES-003 quedó pendiente de confirmación.',                   NULL,                  'PENDIENTE', 3),
    ('CANCELACION',  'Su reserva RES-004 fue cancelada.',                                      '2026-10-12 09:00:00', 'ENVIADA', 4);

-- ----------------------------------------------------------------------------
-- registro_cambio  (RN-12, RF-14: trazabilidad de cambios de roles/permisos)
-- ----------------------------------------------------------------------------
INSERT INTO registro_cambio (id_usuario_responsable, fecha, descripcion) VALUES
    (5, '2026-08-20 09:00:00', 'Se asignó el permiso ver_panel_reservas_dia al rol Recepcionista.'),
    (5, '2026-09-01 11:30:00', 'Se creó la cuenta de usuario Carlos Ibáñez con rol Recepcionista.');
