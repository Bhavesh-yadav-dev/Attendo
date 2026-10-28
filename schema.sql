-- Attendo – database schema
-- Run once to set up (or re-create) all tables.
-- Safe to re-run: uses IF NOT EXISTS / IF NOT EXISTS.

CREATE DATABASE IF NOT EXISTS attendance_system
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE attendance_system;

-- ------------------------------------------------------------------
-- students
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS students (
  id        INT          NOT NULL AUTO_INCREMENT,
  name      VARCHAR(255) NOT NULL,
  roll_no   VARCHAR(50)  NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_roll_no (roll_no)          -- prevents duplicate registrations
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------
-- face_embeddings
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS face_embeddings (
  id           INT  NOT NULL AUTO_INCREMENT,
  student_id   INT  NOT NULL,
  photo_number TINYINT NOT NULL,           -- 1, 2 or 3
  embedding    MEDIUMTEXT NOT NULL,        -- JSON array of 512 floats (~6 KB)
  PRIMARY KEY (id),
  UNIQUE KEY uq_student_photo (student_id, photo_number),
  CONSTRAINT fk_fe_student
    FOREIGN KEY (student_id) REFERENCES students (id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------
-- attendance
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS attendance (
  id              INT         NOT NULL AUTO_INCREMENT,
  student_id      INT         NOT NULL,
  attendance_date DATE        NOT NULL,
  status          ENUM('Present','Absent') NOT NULL DEFAULT 'Absent',
  PRIMARY KEY (id),
  UNIQUE KEY uq_student_date (student_id, attendance_date),  -- required for ON DUPLICATE KEY UPDATE
  CONSTRAINT fk_att_student
    FOREIGN KEY (student_id) REFERENCES students (id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
