/* MotorPH Payroll System Database Implementation */

-- EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- SECTION: EMPLOYEE MASTER DATA
CREATE TABLE employees (
    employee_id VARCHAR(36) PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    birthday DATE NOT NULL,
    tin_number VARCHAR(16) NOT NULL UNIQUE,
    sss_number VARCHAR(16) NOT NULL UNIQUE,
    pagibig_number VARCHAR(16) NOT NULL UNIQUE,
    philhealth_number VARCHAR(16) NOT NULL UNIQUE,
    position VARCHAR(50) NOT NULL,
    employment_status VARCHAR(20) NOT NULL,
    CONSTRAINT chk_birthday CHECK (birthday <= CURRENT_DATE - INTERVAL '18 years'),
    CONSTRAINT chk_status CHECK (employment_status IN ('Regular', 'Probationary', 'Contractual')),
    CONSTRAINT chk_tin_format CHECK (tin_number ~ '^[0-9]+$'),
    CONSTRAINT chk_sss_format CHECK (sss_number ~ '^[0-9]+$'),
    CONSTRAINT chk_pagibig_format CHECK (pagibig_number ~ '^[0-9]+$'),
    CONSTRAINT chk_philhealth_format CHECK (philhealth_number ~ '^[0-9]+$')
);

-- SECTION: USER AUTHENTICATION AND ACCESS CONTROL
CREATE TABLE users (
    user_id VARCHAR(36) PRIMARY KEY,
    employee_id VARCHAR(36) NOT NULL UNIQUE,
    user_name VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    CONSTRAINT fk_employee_user FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

CREATE TABLE system_roles (
    system_role_id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL UNIQUE,
    role_name VARCHAR(60) NOT NULL UNIQUE,
    CONSTRAINT fk_user_role FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE login_sessions (
    login_session_id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_session FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- SECTION: ATTENDANCE AND LEAVE MANAGEMENT
CREATE TABLE attendance (
    attendance_id VARCHAR(36) PRIMARY KEY,
    employee_id VARCHAR(36) NOT NULL,
    date DATE NOT NULL,
    time_in TIMESTAMP NOT NULL,
    time_out TIMESTAMP DEFAULT NULL,
    total_overtime_count DECIMAL(4,2) DEFAULT 0,
    total_undertime_count DECIMAL(4,2) DEFAULT 0,
    total_late_minutes DECIMAL(4,2) DEFAULT 0,
    total_working_hours DECIMAL(4,2) DEFAULT 0,
    CONSTRAINT fk_employee_attendance FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    CONSTRAINT chk_attendance_hours CHECK (total_overtime_count >= 0 AND total_undertime_count >= 0 AND total_late_minutes >= 0 AND total_working_hours >= 0)
);

CREATE TABLE leave (
    leave_id VARCHAR(36) PRIMARY KEY,
    employee_id VARCHAR(36) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_employee_leave FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- SECTION: COMPENSATION AND PAYROLL PROCESSING
CREATE TABLE salary (
    salary_id VARCHAR(36) PRIMARY KEY,
    employee_id VARCHAR(36) NOT NULL,
    salary_amount DECIMAL(8,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE DEFAULT NULL,
    CONSTRAINT fk_employee_salary FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    CONSTRAINT chk_salary_amt CHECK (salary_amount > 0)
);

CREATE TABLE payroll (
    payroll_id VARCHAR(36) PRIMARY KEY,
    start_date DATE NOT NULL UNIQUE,
    end_date DATE NOT NULL UNIQUE,
    status BOOLEAN DEFAULT FALSE
);

CREATE TABLE payslips (
    payslip_id VARCHAR(36) PRIMARY KEY,
    payroll_id VARCHAR(36) NOT NULL,
    employee_id VARCHAR(36) NOT NULL,
    gross_pay DECIMAL(8,2) NOT NULL,
    net_pay DECIMAL(8,2) NOT NULL,
    CONSTRAINT fk_payroll_run FOREIGN KEY (payroll_id) REFERENCES payroll(payroll_id),
    CONSTRAINT fk_employee_payslip FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    CONSTRAINT chk_payslip_amt CHECK (gross_pay > 0 AND net_pay > 0)
);

-- SECTION: DEDUCTIONS MANAGEMENT
CREATE TABLE deduction_type (
    deduction_type_id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(160) NOT NULL
);

CREATE TABLE payslip_deduction (
    payslip_deduction_id VARCHAR(36) PRIMARY KEY,
    payslip_id VARCHAR(36) NOT NULL,
    deduction_type_id VARCHAR(36) NOT NULL,
    amount DECIMAL(7,2) NOT NULL,
    CONSTRAINT fk_payslip_ref FOREIGN KEY (payslip_id) REFERENCES payslips(payslip_id) ON DELETE CASCADE,
    CONSTRAINT fk_deduction_ref FOREIGN KEY (deduction_type_id) REFERENCES deduction_type(deduction_type_id),
    CONSTRAINT chk_deduction_amt CHECK (amount > 0)
);