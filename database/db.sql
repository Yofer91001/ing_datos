CREATE DATABASE exval;

DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS types;
DROP TABLE IF EXISTS stocks;
DROP TABLE IF EXISTS priorities;
DROP TABLE IF EXISTS interests;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS capitals;

--CREACION DE DOMINIO PARA AMOUNT
CREATE DOMAIN amount as
	FLOAT NOT NULL CHECK (value >= 0);

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
        amount amount,
        date TIMESTAMP NOT NULL,
        interest INT 
);

CREATE TABLE capitals(
        id INT PRIMARY KEY,
        stk_code CHAR(3) REFERENCES stocks(code),
        id_user INT REFERENCES users(id),
        amount amount
);

--CREACION DE INDICE TABLA TRANSACCIONES
CREATE INDEX id_transaccion ON transactions(id);

--INSERCIONES GENERALES
INSERT INTO types(name) VALUES('Retiro');
INSERT INTO types(name) VALUES('Consignacion');
INSERT INTO types(name) VALUES('Cambio');

--#PROCEDURES
--##INSERCIONES
CREATE OR REPLACE PROCEDURE insertUser(name VARCHAR(30), pass VARCHAR(30), email VARCHAR(50), user_name VARCHAR(10))
  LANGUAGE 'plpgsql'
  AS $$
  BEGIN
  	INSERT INTO users(name, pass, email, user_name) VALUES (name, pass, email, user_name);
  END;
  $$
  
CREATE OR REPLACE PROCEDURE insertStock(codigo CHAR(3), nombre VARCHAR(15), valor FLOAT)
  LANGUAGE 'plpgsql'
  AS $$
  BEGIN
  	INSERT INTO stocks(code, name, value) VALUES(codigo, nombre, valor);
  END;
  $$ 
  
CREATE OR REPLACE PROCEDURE insertPriority(moneda CHAR(3), id_usuario INT)
  LANGUAGE 'plpgsql'
  AS $$
  BEGIN
  	INSERT INTO priorities(stk_code, id_user) VALUES(moneda, id_usuario);
  END;
  $$
  
CREATE OR REPLACE PROCEDURE insertInterest(tipo INT, moneda CHAR(3), porcentaje DECIMAL)
  LANGUAGE 'plpgsql'
  AS $$
  BEGIN
  	INSERT INTO interests(type, stk_code, percentage) VALUES(tipo, moneda, porcentaje);
  END;
  $$
  
CREATE OR REPLACE PROCEDURE insertTransaction(identificador INT, id_usuario INT, id_tipo INT, moneda_i CHAR(3), moneda_f CHAR(3), cantidad amount)
  LANGUAGE 'plpgsql'
  AS $$
  BEGIN
  	
  	INSERT INTO transactions(id, id_user, id_type, stk_from, stk_to, amount) VALUES(identificador, id_usuario, id_tipo, moneda_i, moneda_f, cantidad);
  END;
  $$
  
CREATE OR REPLACE PROCEDURE insertCapital(identificador INT, moneda CHAR(3), id_usuario INT, cantidad amount)
  LANGUAGE 'plpgsql'
  AS $$
  BEGIN
  	INSERT INTO capitals(id, stk_code, id_user, amount) VALUES(identificador, moneda, id_usuario, cantidad);
  END;
  $$

--#ACTUALIZACIONES
CREATE OR REPLACE PROCEDURE actualizarCapital(id_usuario INT, id_tipo INT, moneda CHAR(3), cantidad amount, interest amount)
        LANGUAGE 'plpgsql'
        AS
        $$
        UPDATE capitalas SET amount = amount - cantidad - interest WHERE id_user = id_usuario AND id_type = id_tipo AND stk_code = moneda
        $$;


CREATE OR REPLACE PROCEDURE actualizarInteresTransaccion(transaccion_id INT)
        LANGUAGE 'plpgsql'
	DECLARE
	@interes amount
        AS
        $$ 
	SET @interest = calcularInteres(transaccion_id)
        UPDATE transactions SET interest = @interest WHERE transactions.id = transaccion_id)
        $$;

CREATE OR REPLACE PROCEDURE borrarPrioridad(moneda amount, id_usuario INT)
 LANGUAGE 'plpgsql'
        AS
        $$
        DELETE FROM priorities WHERE stk_code = moneda AND id_user = id_usuario
        $$;

--#FUNCIONES
--##CALCULAR INTERES POR TRANSACCION
CREATE OR REPLACE FUNCTION calcularInteres(transaccion_id INT)
RETURNS INT
DECLARE
@porcentaje INT
BEGIN
WITH transaccion AS (SELECT * FROM transactions WHERE id = transaccion_id)
	SET @porcentaje = SELECT i.percentage FROM interest i INNER JOIN transaccion t ON t.stk_from = i.stk_code AND t.id_type = i.type
	RETURN @porcentaje * cantidad
END;


--#TRIGGERS
CREATE OR REPLACE TRIGGER insertar_interes AFTER INSERT 
ON transactions
REFEREENCING NEW ROW AS nr
FOR EACH ROW

--VISTAS
CREATE OR REPLACE VIEW ganancias AS
(SELECT SUM(amount*interest) AS ganancias
FROM transactions);


--CONSULTAS GENERALES:
SELECT * FROM transactions;
SELECT * FROM capitals;
SELECT * FROM users;
SELECT * FROM stocks;


