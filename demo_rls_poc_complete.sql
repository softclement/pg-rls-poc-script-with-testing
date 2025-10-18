-- ============================================
-- PostgreSQL Row-Level Security (RLS) PoC Setup
-- Safe for repeated execution
-- Ver-001
-- Author: Clement
-- Date: 2024-06-10
-- ============================================

-- CONNECT TO postgres TO DROP demo DATABASE
\c postgres

-- DROP DATABASE IF EXISTS
DROP DATABASE IF EXISTS demo;

-- DROP ROLES IF THEY EXIST AND NOT IN USE
DO $$
BEGIN
   IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'clement') THEN
      REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM clement;
      REVOKE ALL PRIVILEGES ON SCHEMA public FROM clement;
      REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM clement;
      DROP ROLE clement;
   END IF;

   IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'deepak') THEN
      REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM deepak;
      REVOKE ALL PRIVILEGES ON SCHEMA public FROM deepak;
      REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM deepak;
      DROP ROLE deepak;
   END IF;

   IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'shruti') THEN
      REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM shruti;
      REVOKE ALL PRIVILEGES ON SCHEMA public FROM shruti;
      REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM shruti;
      DROP ROLE shruti;
   END IF;

   IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'demo') THEN
      DROP ROLE demo;
   END IF;
END
$$;

-- CREATE USERS
DO $$
BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'demo') THEN
      CREATE ROLE demo LOGIN PASSWORD '123';
   END IF;
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'clement') THEN
      CREATE ROLE clement LOGIN PASSWORD '123';
   END IF;
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'deepak') THEN
      CREATE ROLE deepak LOGIN PASSWORD '123';
   END IF;
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'shruti') THEN
      CREATE ROLE shruti LOGIN PASSWORD '123';
   END IF;
END
$$;

-- CREATE DATABASE
CREATE DATABASE demo OWNER demo;

-- CONNECT TO demo DATABASE AS postgres
\c demo

-- CREATE TABLE IF NOT EXISTS
DO $$
BEGIN
   IF NOT EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'employees'
   ) THEN
      CREATE TABLE public.employees (
         id SERIAL PRIMARY KEY,
         name TEXT,
         department TEXT,
         username TEXT
      );
   END IF;
END
$$;

-- ENABLE ROW LEVEL SECURITY
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

-- CREATE POLICY IF NOT EXISTS
DO $$
BEGIN
   IF NOT EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE schemaname = 'public' AND tablename = 'employees' AND policyname = 'emp_rls_policy'
   ) THEN
      CREATE POLICY emp_rls_policy
         ON public.employees
         FOR ALL
         USING (username = current_user);
   END IF;
END
$$;


-- CHANGE OWNER TO demo
ALTER TABLE public.employees OWNER TO demo;

-- ENFORCE RLS
ALTER TABLE public.employees FORCE ROW LEVEL SECURITY;

-- GRANT PRIVILEGES TO USERS
GRANT SELECT, INSERT, UPDATE, DELETE ON public.employees TO clement, deepak, shruti;
GRANT USAGE, CREATE ON SCHEMA public TO clement, deepak, shruti;
GRANT USAGE, SELECT, UPDATE ON SEQUENCE employees_id_seq TO clement, deepak, shruti;

-- TEMPORARILY DISABLE RLS TO INSERT TEST DATA
ALTER TABLE public.employees DISABLE ROW LEVEL SECURITY;

-- INSERT TEST DATA IF NOT EXISTS
DO $$
BEGIN
   IF NOT EXISTS (SELECT 1 FROM public.employees WHERE username = 'demo') THEN
      INSERT INTO public.employees (name, department, username) VALUES
      ('Demo Admin', 'Admin', 'demo'),
      ('Clement User', 'IT', 'clement'),
      ('Deepak User', 'HR', 'deepak'),
      ('Shruti User', 'Finance', 'shruti');
   END IF;
END
$$;

-- RE-ENABLE RLS
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees FORCE ROW LEVEL SECURITY;
-- 



-- ============================================
-- Manual RLS Testing Steps for Individual Users
-- ============================================

-- Clement Login Test
-- Connect: psql -U clement -d demo
-- Run:
-- SELECT current_user, current_database();
-- SELECT * FROM public.employees;
-- INSERT INTO public.employees (name, department, username) VALUES ('Clement Test', 'IT', current_user);
-- UPDATE public.employees SET department = 'Updated IT' WHERE username = current_user AND name = 'Clement Test';
-- DELETE FROM public.employees WHERE username = current_user AND name = 'Clement Test';

-- Deepak Login Test
-- Connect: psql -U deepak -d demo
-- Run:
-- SELECT current_user, current_database();
-- SELECT * FROM public.employees;
-- INSERT INTO public.employees (name, department, username) VALUES ('Deepak Test', 'HR', current_user);
-- UPDATE public.employees SET department = 'Updated HR' WHERE username = current_user AND name = 'Deepak Test';
-- DELETE FROM public.employees WHERE username = current_user AND name = 'Deepak Test';

-- Shruti Login Test
-- Connect: psql -U shruti -d demo
-- Run:
-- SELECT current_user, current_database();
-- SELECT * FROM public.employees;
-- INSERT INTO public.employees (name, department, username) VALUES ('Shruti Test', 'Finance', current_user);
-- UPDATE public.employees SET department = 'Updated Finance' WHERE username = current_user AND name = 'Shruti Test';
-- DELETE FROM public.employees WHERE username = current_user AND name = 'Shruti Test';