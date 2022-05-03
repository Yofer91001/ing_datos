CREATE DATABASE exval;

DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS types;
DROP TABLE IF EXISTS stocks;
DROP TABLE IF EXISTS priorities;
DROP TABLE IF EXISTS interests;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS capitals;


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
        amount FLOAT NOT NULL,
        date DATETIME NOT NULL,
        interest INT 
);

CREATE TABLE capitals(
        id INT PRIMARY KEY,
        stk_code CHAR(3) REFERENCES stocks(code),
        id_user INT REFERENCES users(id),
        amount INT  NOT NULL CHECK (amount >= 0)
);


--CREACION DE INDICE TABLA TRANSACCIONES
CREATE INDEX id_transaccion ON transactions(id);

--#PROCEDURES
--##INSERCIONES
CREATE OR REPLACE PROCEDURE insertar_transaccion(id_usuario INT, id_tipo INT, moneda_i CHAR(3), moneda_f CHAR(3), cantidad INT)
	LANGUAGE 'plpgsql'
	AS
	$$
	INSERT INTO transactions(user_id, type_id, stk_from, stk_to, amount) VALUES(id_usuario, id_tipo, moneda_i, moneda_f, cantidad);
	$$;



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


