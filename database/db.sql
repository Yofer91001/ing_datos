--Creación de la base de datos
CREATE DATABASE exval;

--\c exval

--Creación del esquema
CREATE SCHEMA divisas;

--CREACIÓN DE LOS ROLES Y USUARIOS DE LA BASE DE DATOS

CREATE USER yofer WITH PASSWORD 'yofer123';
CREATE USER valentina WITH PASSWORD 'valentina123';
GRANT ALL ON DATABASE exval TO yofer;
GRANT ALL ON DATABASE exval TO valentina;
REVOKE DROP ON DATABASE exval TO yofer;
REVOKE DROP ON DATABASE exval TO valentina;


CREATE USER nelson WITH PASSWORD 'admin123';
GRANT ALL ON DATABASE exval TO nelson;


CREATE USER analitico WITH PASSWORD 'analytics';
GRANT SELECT ON DATABASE exval TO analitico;

--CREACION DE DOMINIO PARA AMOUNT
CREATE DOMAIN amount AS
	FLOAT NOT NULL CHECK (value >= 0);

 
DROP TABLE IF EXISTS divisas.users;
DROP TABLE IF EXISTS divisas.types;
DROP TABLE IF EXISTS divisas.stocks;
DROP TABLE IF EXISTS divisas.priorities;
DROP TABLE IF EXISTS divisas.interests;
DROP TABLE IF EXISTS divisas.transactions;
DROP TABLE IF EXISTS divisas.capitals;


CREATE TABLE divisas.users(
        id SERIAL PRIMARY KEY,
        name VARCHAR(30) NOT NULL,
        pass VARCHAR(30) NOT NULL,
        email VARCHAR(50) NOT  NULL,
        user_name VARCHAR(10) NOT NULL UNIQUE
);

CREATE TABLE divisas.types(
        id SERIAL PRIMARY KEY,
        name VARCHAR(15) NOT NULL
);
CREATE TABLE divisas.stocks(
        code CHAR(3) PRIMARY KEY,
        name VARCHAR(15) NOT NULL UNIQUE,
        value FLOAT NOT NULL
);
CREATE TABLE divisas.priorities(
        id SERIAL PRIMARY KEY,
        stk_code CHAR(3) REFERENCES divisas.stocks(code),
        id_user INT REFERENCES divisas.users(id)
);

/*
CREATE TABLE divisas.interests(
        id SMALLINT PRIMARY KEY,
        type INT REFERENCES divisas.types(id),
        stk_code CHAR(3) REFERENCES divisas.stocks(code),
        percentage DECIMAL(5,2) NOT NULL
);
*/
CREATE TABLE divisas.transactions(
        id INT PRIMARY KEY,
        id_user INT REFERENCES divisas.users(id),
        id_type INT REFERENCES divisas.types(id),
        stk_from CHAR(3) REFERENCES divisas.stocks(code),
        stk_to CHAR(3) REFERENCES divisas.stocks(code),
        amount amount NOT NULL,
        date TIMESTAMP NOT NULL
);

CREATE TABLE divisas.capitals(
        id SERIAL PRIMARY KEY,
        stk_code CHAR(3) REFERENCES divisas.stocks(code),
        id_user INT REFERENCES divisas.users(id),
        amount amount  NOT NULL CHECK (amount >= 0)
);


--CREACION DE INDICE TABLA TRANSACCIONES
CREATE INDEX id_transaccion ON divisas.transactions(id);


--INSERCIONES GENERALES
INSERT INTO divisas.types(name) VALUES('Retiro');
INSERT INTO divisas.types(name) VALUES('Consignacion');
INSERT INTO divisas.types(name) VALUES('Cambio');

--CARGA MASIVA DE DATOS
--COPY divisas.users(names, pass, email, user_name) FROM './usuarios.csv' DELIMITER ',' CSV HEADER;
--COPY divisas.stocks FROM './divisas.csv' DELIMITER ',' CSV HEADER; 

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
  
 
CREATE OR REPLACE PROCEDURE insertTransaction(identificador INT, id_usuario INT, id_tipo INT, moneda_i CHAR(3), moneda_f CHAR(3), cantidad amount)
  LANGUAGE 'plpgsql'
  AS $$
  BEGIN
  	IF moneda_f IS NOT NULL THEN
		IF moneda_i IS NOT NULL THEN
			INSERT INTO transactions(id, id_user, id_type, stk_from, stk_to, amount) VALUES(identificador, id_usuario, id_tipo, moneda_i, moneda_f, cantidad);
			IF EXISTS (SELECT amount FROM capitals WHERE id_user = id_usuario AND stk_code = moneda_i AND amount > cantidad*1.03) THEN
				COMMIT;
			ELSE
				ROLLBACK;
			END IF;
		ELSE
			INSERT INTO transactions(id, id_user, id_type, stk_to, amount) VALUES(identificador, id_usuario, id_tipo, moneda_f, cantidad);
		END IF;
	ELSE
		INSERT INTO transactions(id, id_user, id_type, stk_from, amount) VALUES(identificador, id_usuario, id_tipo, moneda_i, cantidad);
	END IF;
  END;
  $$
  
CREATE OR REPLACE PROCEDURE insertCapital(identificador INT, moneda CHAR(3), id_usuario INT, cantidad amount)
  LANGUAGE 'plpgsql'
  AS $$
  BEGIN
  	INSERT INTO capitals( stk_code, id_user, amount) VALUES( moneda, id_usuario, cantidad);
  END;
  $$

--#ACTUALIZACIONES!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
CREATE OR REPLACE PROCEDURE actualizarCapital(id_usuario INT, id_tipo INT, moneda_i CHAR(3), moneda_f CHAR(3), cantidad amount)
        LANGUAGE 'plpgsql'
        AS
        $$
	BEGIN
		IF id_tipo = 1 OR id_tipo = 3 THEN
			UPDATE capitals c SET c.amount = c.amount - cantidad*1.03 WHERE stk_code = moneda_i AND c.id_user = id_usuario;
		END IF;
		IF nr.id_type = 3 OR nr.id_type = 2 THEN
			UPDATE capitals c SET c.amount = c.amount - cantidad*1.03 WHERE stk_code = moneda_f AND c.id_user = id_usuario;
		END IF;

	END;
        $$;


CREATE OR REPLACE PROCEDURE borrarPrioridad(moneda amount, id_usuario INT)
        LANGUAGE 'plpgsql'
        AS
        $$
	BEGIN
        DELETE FROM priorities WHERE stk_code = moneda AND id_user = id_usuario;
	END;
        $$;

--#FUNCIONES

--##Calcular modena a euro
CREATE OR REPLACE FUNCTION stk_to_eur(stk CHAR(3), amount amount)
	RETURNS amount
	LANGUAGE 'plpgsql'
        AS
	$$
	DECLARE 
		total amount;
	BEGIN
		SELECT SUM(tota) INTO total FROM (SELECT amount*valor FROM (SELECT value AS total FROM divisas.stocks WHERE code = stk_code) AS val) AS tot;
		RETURN total;
	END;
	$$

--##Calcular euro a moneda
CREATE OR REPLACE FUNCTION eur_to_stk(stk CHAR(3), amount amount)
	RETURNS amount
	LANGUAGE 'plpgsql'
        AS
	$$
	DECLARE 
		total amount;
	BEGIN
		SELECT SUM(tota) INTO total FROM (SELECT amount/valor AS tota FROM (SELECT value AS total FROM divisas.stocks WHERE code = stk_code) AS val) AS tot;
		RETURN total;
	END;
	$$
--##Calcular la conversión de una a otra moneda
CREATE OR REPLACE FUNCTION stk_to_stk(stk_from CHAR(3), stk_to CHAR(3), amount amount)
	RETURNS amount
	LANGUAGE 'plpgsql'
        AS
	$$
	BEGIN
		RETURN eur_to_stk(stk_to , stk_to_eur(stk_from, amount));
	END;
	$$




--#TRIGGERS
CREATE OR REPLACE TRIGGER actualizar_capitales AFTER INSERT 
ON transactions
REFERENCING NEW ROW AS nr
FOR EACH ROW
BEGIN
	IF (nr.id_type = 2) THEN
		IF EXIST (SELECT * FROM capitals c WHERE c.id_user = nr.id_user AND stk_code = nr.stk_to) THEN
			actualizarCapital(nr.id_user, nr.id_type, nr.stk_from, nr.stk_to , nr.amount);
		ELSE
			insertCapital( nr.stk_to, nr.id_user , nr.amount)
		END IF;
	END IF;
END;


--GANANCIAS
CREATE OR REPLACE VIEW ganancias AS
(SELECT SUM(amount*interest) AS ganancias
FROM transactions);


--CONSULTAS GENERALES:
--Ordenar por fechas todas las transacciones
SELECT * FROM transactions ORDER BY date;

--Mostrar las monedas que más tienen los usuarios en sus capitales
SELECT SUM(amount) AS total_amount, stk_code FROM capitals GROUP BY stk_code ORDER BY total_amount;

--Seleccionar las divisas más valiosas respecto al euro
SELECT RANK() OVER(ORDER BY value DESC) FROM stocks;

--TRANSACCIONES REALIZADAS POR UN USUARIO
CREATE OR REPLACE VIEW txu AS(
SELECT SUM() OVER(PARTITION BY user_name) AS total_transacciones, user_name FORM (SELECT u.user_name FROM users u INNER JOIN transaccions t ON u.user_name =  t.id_user) AS ut;
);

--Los usuarios con más transacciones
SELECT RANK() OVER(total_transacciones), u.* FROM txu;

--Monedas con más transacciones:
--A las que más se mueve dinero
SELECT s.name, r.total_maount
FROM stocks s
INNER JOIN (SELECT RANK() OVER(ORDER BY total_amount DESC), stk_to AS stock FROM (SELECT SUM(amount) AS total_amount, stk_to FROM transactions GROUP BY stk_to) AS t) AS r
ON t.stock = s.code;

--De las que más sale dinero
SELECT s.name, r.total_maount
FROM stocks s
INNER JOIN (SELECT RANK() OVER(ORDER BY total_amount DESC), stk_to AS stock FROM (SELECT SUM(amount) AS total_amount, stk_from FROM transactions GROUP BY stk_to) AS t) AS r
ON t.stock = s.code;

--A la que más se mueve dinero
SELECT s.name, MAX(r.total_maount)
FROM stocks s
INNER JOIN (SELECT RANK() OVER(ORDER BY total_amount DESC), stk_to AS stock FROM (SELECT SUM(amount) AS total_amount, stk_to FROM transactions GROUP BY stk_to) AS t) AS r
ON t.stock = s.code;

--De la que más sale dinero
SELECT s.name, MAX(r.total_maount)
FROM stocks s
INNER JOIN (SELECT RANK() OVER(ORDER BY total_amount DESC), stk_to AS stock FROM (SELECT SUM(amount) AS total_amount, stk_from FROM transactions GROUP BY stk_to) AS t) AS r
ON t.stock = s.code;

--A la que menos se mueve dinero
SELECT s.name, MIN(r.total_maount)
FROM stocks s
INNER JOIN (SELECT RANK() OVER(ORDER BY total_amount DESC), stk_to AS stock FROM (SELECT SUM(amount) AS total_amount, stk_to FROM transactions GROUP BY stk_to) AS t) AS r
ON t.stock = s.code;

--De la que menos sale dinero
SELECT s.name, MIN(r.total_maount)
FROM stocks s
INNER JOIN (SELECT RANK() OVER(ORDER BY total_amount DESC), stk_to AS stock FROM (SELECT SUM(amount) AS total_amount, stk_from FROM transactions GROUP BY stk_to) AS t) AS r
ON t.stock = s.code;



