# 🍽️ Sistema de Reservas de Restaurante

Sistema de software desarrollado para gestionar de manera centralizada las **reservas, clientes, mesas y disponibilidad** de un restaurante.

El proyecto busca solucionar los problemas que se presentan cuando las reservas se manejan manualmente mediante cuadernos, hojas de cálculo o llamadas telefónicas, evitando principalmente las **reservas duplicadas, sobre-reservas y asignaciones incorrectas de mesas**.

---

## 📌 Descripción del proyecto

Actualmente, el restaurante presenta dificultades para llevar un control organizado de sus clientes, mesas y reservas. La información se encuentra distribuida en diferentes medios, lo que puede generar errores y afectar la atención al cliente.

Este sistema tiene como propósito centralizar la información y permitir la gestión de las reservas en tiempo real, garantizando que la disponibilidad de las mesas sea confiable y evitando que se crucen reservas para una misma mesa, fecha y hora.

---

## 🎯 Objetivo general

Desarrollar un sistema de software que permita manejar de forma centralizada y en tiempo real:

* Registro de clientes.
* Gestión de mesas.
* Creación de reservas.
* Modificación de reservas.
* Cancelación de reservas.
* Consulta de disponibilidad.

El sistema debe evitar que se dupliquen o se crucen reservas para una misma mesa, fecha y hora.

---

## 🔎 Problema identificado

El manejo manual de las reservas puede ocasionar:

* ❌ Sobre-reservas de una misma mesa.
* ❌ Reservas duplicadas.
* ❌ Asignación incorrecta de mesas.
* ❌ Falta de información actualizada.
* ❌ Dificultad para consultar las reservas del día.
* ❌ Mala experiencia para los clientes.

Por esta razón, se plantea la implementación de un sistema que centralice y automatice la gestión de clientes, mesas, reservas y disponibilidad.

---

## 👥 Actores del sistema

El sistema contempla tres tipos principales de usuarios:

| Actor                                                   | Responsabilidades                                                                                                             |
| ------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| 👤 **Cliente**                                          | Registrarse, consultar disponibilidad, crear, modificar y cancelar sus propias reservas.                                      |
| 🧑‍💼 **Recepcionista / Administrador del restaurante** | Gestionar mesas, confirmar o reubicar reservas, atender reservas presenciales o telefónicas y consultar las reservas del día. |
| 🔐 **Administrador del sistema**                        | Gestionar usuarios, roles y permisos, además de configurar y mantener la información del restaurante.                         |

---

## 🧩 Épicas

### EP-01 — Gestión de Clientes

Permite registrar, consultar y actualizar la información de los clientes que realizan reservas.

**Historia asociada:** HU-01

### EP-02 — Gestión de Mesas

Permite mantener actualizado el inventario de mesas, incluyendo capacidad, ubicación y estado.

**Historia asociada:** HU-02

### EP-03 — Gestión de Reservas

Permite crear, modificar, cancelar y consultar reservas, evitando duplicaciones y cruces de horarios.

**Historias asociadas:** HU-04, HU-05, HU-06, HU-07

### EP-04 — Consulta de Disponibilidad

Permite consultar las mesas disponibles teniendo en cuenta la fecha, hora y número de personas.

**Historia asociada:** HU-03

### EP-05 — Administración y Seguridad

Permite gestionar los roles y permisos de los usuarios para proteger la información y controlar el acceso a las funciones del sistema.

**Historia asociada:** HU-08

---

## 📖 Historias de usuario

| Código    | Historia                                  | Prioridad | MVP  |
| --------- | ----------------------------------------- | --------- | ---- |
| **HU-01** | Registro de clientes                      | 🔴 Alta   | ✅ Sí |
| **HU-02** | Registro y edición de mesas               | 🔴 Alta   | ✅ Sí |
| **HU-03** | Consulta de disponibilidad                | 🔴 Alta   | ✅ Sí |
| **HU-04** | Creación de reservas                      | 🔴 Alta   | ✅ Sí |
| **HU-05** | Panel de reservas del día                 | 🟡 Media  | ✅ Sí |
| **HU-06** | Prevención de duplicados y sobre-reservas | 🔴 Alta   | ✅ Sí |
| **HU-07** | Cancelación y modificación de reservas    | 🟡 Media  | ✅ Sí |
| **HU-08** | Gestión de roles y permisos               | 🔴 Alta   | ✅ Sí |

---

## 🚀 Alcance del MVP

La primera versión del sistema contempla las funcionalidades necesarias para que el restaurante pueda gestionar sus reservas de forma organizada.

### Funcionalidades principales

* 👤 Registro de clientes.
* 🪑 Registro y edición de mesas.
* 🔎 Consulta de disponibilidad.
* 📅 Creación de reservas.
* 📋 Visualización de las reservas del día.
* 🛡️ Prevención de reservas duplicadas.
* 🔄 Cancelación y modificación de reservas.
* 🔐 Gestión de roles y permisos.

Una de las reglas principales del sistema es impedir que dos reservas activas ocupen la misma mesa durante horarios que se crucen.

---

## 🛡️ Reglas importantes del sistema

### Disponibilidad de mesas

Una mesa solamente puede aparecer como disponible cuando:

* Su capacidad es suficiente para el número de personas solicitado.
* No tiene una reserva confirmada que se cruce con la fecha y horario consultados.
* Su información corresponde al estado actual del sistema.

### Prevención de reservas duplicadas

Antes de crear o confirmar una reserva, el sistema debe verificar que no exista otra reserva activa para la misma mesa en un horario que se cruce.

Si existe un conflicto:

> La reserva debe ser rechazada y el sistema debe informar al usuario del problema.

Esta validación debe realizarse de forma segura en la base de datos para evitar conflictos cuando dos solicitudes lleguen prácticamente al mismo tiempo.

### Seguridad

Los permisos dependen del rol del usuario:

* **Cliente:** solamente puede consultar y gestionar sus propias reservas.
* **Recepcionista:** puede gestionar mesas y consultar las reservas del día.
* **Administrador:** puede gestionar usuarios, roles y permisos.

---

## 📊 Priorización del MVP

Las historias se priorizaron teniendo en cuenta qué tan necesarias son para resolver el problema principal del proyecto: **evitar sobre-reservas y reservas duplicadas**.

Las historias de prioridad alta conforman la base funcional del sistema, mientras que las historias de prioridad media complementan la operación diaria del restaurante.

---

## 🏫 Información académica

**Servicio Nacional de Aprendizaje — SENA**

**Programa:** Análisis y Desarrollo de Software
**Ficha:** 3239137
**Centro:** Centro de la Industria, la Empresa y los Servicios
**Ciudad:** Neiva
**Año:** 2026

### 👨‍💻 Integrantes

* **Luis Eduardo Buitrago Pascuas**
* **Laura Daniela Aviles Perdomo**
* **Andres Camilo Perez Mendoza**

### 👨‍🏫 Instructor

**Carlos Julio Cadena**
Ingeniero de Sistemas

---

## 📁 Estado del proyecto

🚧 **En desarrollo — Fase 1**

Esta fase corresponde a la identificación del problema, definición de objetivos, actores, épicas, historias de usuario, criterios de aceptación y alcance del MVP.

---

## 📌 Próximas fases

Las siguientes etapas dependerán del desarrollo del proyecto y de los requerimientos definidos posteriormente.

> **Nota:** La Fase 1 no especifica en detalle las tecnologías, arquitectura o estructura final del proyecto, por lo que estas secciones deberán definirse cuando avance el desarrollo.

---

⭐ **Sistema de Reservas de Restaurante — Proyecto Integrador SENA 2026**
