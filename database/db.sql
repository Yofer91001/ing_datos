CREATE DATABASE exval;

DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS types;
DROP TABLE IF EXISTS stocks;
DROP TABLE IF EXISTS priorities;
DROP TABLE IF EXISTS interests;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS capitals;

--CREACION DE DOMINIO PARA AMOUNT
CREATE DOMAIN amount_dom as
	float NOT NULL CHECK (value >= 0);

CREATE TABLE users(
        id SERIAL PRIMARY KEY,
        name VARCHAR(30) NOT NULL,
        pass VARCHAR(30) NOT NULL,
        email VARCHAR(50) NOT  NULL,
        user_name VARCHAR(10) NOT NULL UNIQUE
);

CREATE TABLE types(
        id SERIAL PRIMARY KEY,
        name VARCHAR(15) NOT NULL
);
CREATE TABLE stocks(
        code CHAR(3) PRIMARY KEY,
        name VARCHAR(15) NOT NULL UNIQUE,
        value FLOAT NOT NULL
);
CREATE TABLE priorities(
        id SERIAL PRIMARY KEY,
        stk_code CHAR(3) REFERENCES stocks(code),
        id_user INT REFERENCES users(id)
);


CREATE TABLE interests(
        type INT REFERENCES types(id),
        stk_code CHAR(3) REFERENCES stocks(code),
        percentage DECIMAL(5,2) NOT NULL,
        PRIMARY KEY(type, stk_code)
);
CREATE TABLE transactions(
        id INT PRIMARY KEY,
        id_user INT REFERENCES users(id),
        id_type INT REFERENCES types(id),
        stk_from CHAR(3) REFERENCES stocks(code),
        stk_to CHAR(3) REFERENCES stocks(code),
        amount amount_dom,
        date DATETIME NOT NULL,
        interest INT 
);

CREATE TABLE capitals(
        id INT PRIMARY KEY,
        stk_code CHAR(3) REFERENCES stocks(code),
        id_user INT REFERENCES users(id),
        amount amount_dom
);

--CREACION DE TABLA GANANCIAS
SELECT SUM(amount*intest) AS ganancias
FROM transactions

--CREACION DE INDICE TABLA TRANSACCIONES
CREATE INDEX id_transaccion ON transactions(id);

--#PROCEDURES
--##INSERCIONES
CREATE OR REPLACE PROCEDURE insertUsers(name VARCHAR(30), pass VARCHAR(30), email VARCHAR(50), user_name VARCHAR(10))
  LANGUAGE 'plpgsql'
  as $$
  BEGIN
  	INSERT INTO users(name, pass, email, user_name) VALUES (name, pass, email, user_name);
  end;
  $$
  
CREATE OR REPLACE PROCEDURE insertTypes(name VARCHAR(15))
  LANGUAGE 'plpgsql'
  as $$
  BEGIN
  	INSERT INTO types(name) VALUES(name);
  end;
  $$
  
CREATE OR REPLACE PROCEDURE insertStocks(code CHAR(3), name VARCHAR(15), value FLOAT)
  LANGUAGE 'plpgsql'
  as $$
  BEGIN
  	INSERT INTO stocks(code, name, value) VALUES(code, name, value);
  end;
  $$ 
  
CREATE OR REPLACE PROCEDURE insertPriorities(stk_code CHAR(3), id_user int)
  LANGUAGE 'plpgsql'
  as $$
  BEGIN
  	INSERT INTO priorities(stk_code, id_user) VALUES(stk_code, id_user);
  end;
  $$
  
CREATE OR REPLACE PROCEDURE insertInterests(types int, stk_code char(3), percentage DECIMAL)
  LANGUAGE 'plpgsql'
  as $$
  BEGIN
  	INSERT INTO interests(types, stk_code, percentage) VALUES(types, stk_code, percentage);
  end;
  $$
  
CREATE OR REPLACE PROCEDURE insertTransactions(id int, id_user int, id_type int, stk_from char(3), stk_to char(3), amount int, date date, interests int)
  LANGUAGE 'plpgsql'
  as $$
  BEGIN
  	INSERT INTO transactions(id, id_user, id_type, stk_from, stk_to, amount, date, interests) VALUES(id, id_user, id_type, stk_from, stk_to, amount, date, interests);
  end;
  $$
  
CREATE OR REPLACE PROCEDURE insertCapitals(id int, stk_code char(3), id_user int, amount int)
  LANGUAGE 'plpgsql'
  as $$
  BEGIN
  	INSERT INTO capitals(id, stk_code, id_user, amount) VALUES(id, stk_code, id_user, amount);
  end;
  $$

--#ACTUALIZACIONES
CREATE OR REPLACE PROCEDURE actualizar_capital(id_usuario INT, id_tipo INT, moneda CHAR(3), cantidad FLOAT)
        LANGUAGE 'plpgsql'
        AS
        $$
        UPDATE capitalas SET amount = amount - cantidad WHERE user_id = id_usuario AND type_id = id_tipo AND stk_code = moneda
        $$;


CREATE OR REPLACE PROCEDURE actualizar_interes_transaccion(transaccion_id INT, cantidad FLOAT)
        LANGUAGE 'plpgsql'
        AS
        $$
        UPDATE capitalas SET amoount = amount - cantidad WHERE user_id = id_usuario AND type_id = id_tipo AND stk_code )
        $$;



--#FUNCIONES
--##CALCULAR INTERES POR TRANSACCION
CREATE OR REPLACE FUNCTION calcular_interes(id_tipo INT, moneda CHAR(3), cantidad FLOAT)
RETURNS INT
DECLARE
@porcentaje INT
BEGIN
	SET @porcentaje = SELECT percentage FROM interests WHERE type_id = id_tipo AND stk_code = moneda
	RETURN @porcentaje * cantidad
END;


--#TRIGGERS
CREATE OR REPLACE TRIGGER insertar_interes AFTER INSERT 
ON transactions
REFEREENCING NEW ROW AS nr
FOR EACH ROW






--CONSULTAS GENERALES:
SELECT * FROM transactions;
SELECT * FROM capitals;
SELECT * FROM users;
SELECT * FROM stocks;


