-- Create Tables

CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE levels (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL, -- In production, store hashes!
    full_name VARCHAR(100),
    role_id INTEGER REFERENCES roles(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    student_code VARCHAR(20) UNIQUE NOT NULL,
    department_id INTEGER REFERENCES departments(id),
    level_id INTEGER REFERENCES levels(id)
);

-- Insert Initial Data

-- Roles
INSERT INTO roles (name) VALUES ('admin'), ('teacher'), ('student');

-- Departments
INSERT INTO departments (code, name) VALUES 
('t', 'تكنولوجيا التعليم'),
('c', 'الحاسب الآلي'),
('e', 'إعلام تربوي'),
('a', 'تربية فنية'),
('m', 'تربية موسيقية'),
('h', 'اقتصاد منزلي');

-- Levels
INSERT INTO levels (name) VALUES ('الفرقة الأولى'), ('الفرقة الرابعة');

-- Users (Admin & Teacher)
INSERT INTO users (username, password, full_name, role_id) VALUES 
('admin', 'admin', 'المدير العام', 1),
('doctor', 'password', 'د. عضو هيئة تدريس', 2);

-- Students (Level 1)
-- Code format: {dept_code}1
INSERT INTO users (username, password, full_name, role_id) VALUES 
('t1_student', 'pass', 'طالب تكنولوجيا تعليم 1', 3),
('c1_student', 'pass', 'طالب حاسب آلي 1', 3),
('e1_student', 'pass', 'طالب إعلام تربوي 1', 3),
('a1_student', 'pass', 'طالب تربية فنية 1', 3),
('m1_student', 'pass', 'طالب تربية موسيقية 1', 3),
('h1_student', 'pass', 'طالب اقتصاد منزلي 1', 3);

INSERT INTO students (user_id, student_code, department_id, level_id) VALUES
((SELECT id FROM users WHERE username='t1_student'), 't1', 1, 1),
((SELECT id FROM users WHERE username='c1_student'), 'c1', 2, 1),
((SELECT id FROM users WHERE username='e1_student'), 'e1', 3, 1),
((SELECT id FROM users WHERE username='a1_student'), 'a1', 4, 1),
((SELECT id FROM users WHERE username='m1_student'), 'm1', 5, 1),
((SELECT id FROM users WHERE username='h1_student'), 'h1', 6, 1);

-- Students (Level 4)
-- Code format: {dept_code}4
INSERT INTO users (username, password, full_name, role_id) VALUES 
('t4_student', 'pass', 'طالب تكنولوجيا تعليم 4', 3),
('c4_student', 'pass', 'طالب حاسب آلي 4', 3),
('e4_student', 'pass', 'طالب إعلام تربوي 4', 3),
('a4_student', 'pass', 'طالب تربية فنية 4', 3),
('m4_student', 'pass', 'طالب تربية موسيقية 4', 3),
('h4_student', 'pass', 'طالب اقتصاد منزلي 4', 3);

INSERT INTO students (user_id, student_code, department_id, level_id) VALUES
((SELECT id FROM users WHERE username='t4_student'), 't4', 1, 2),
((SELECT id FROM users WHERE username='c4_student'), 'c4', 2, 2),
((SELECT id FROM users WHERE username='e4_student'), 'e4', 3, 2),
((SELECT id FROM users WHERE username='a4_student'), 'a4', 4, 2),
((SELECT id FROM users WHERE username='m4_student'), 'm4', 5, 2),
((SELECT id FROM users WHERE username='h4_student'), 'h4', 6, 2);
