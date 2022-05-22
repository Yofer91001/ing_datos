CREATE DATABASE exval;

--\c exval


CREATE SCHEMA divisas;

--CREACIÓN DE LOS ROLES Y USUARIOS DE LA BASE DE DATOS
CREATE ROLE developer WITH PASSWORD 'developerteam';
CREATE USER yofer;
CREATE USER valentina;
GRANT ALL ON ALL TABLES IN SCHEMA divisas TO developer;
REVOKE DELETE ON ALL TABLES IN SCHEMA divisas FROM developer;
GRANT developer TO yofer;
GRANT developer TO valentina;

--CREACION DE DOMINIO PARA AMOUNT
CREATE DOMAIN amount AS
	FLOAT NOT NULL CHECK (value >= 0);

CREATE ROLE administrator WITH PASSWORD 'admin123';
CREATE USER nelson;
GRANT ALL ON ALL TABLES IN SCHEMA divisas TO administrator WITH GRANT OPTION;
GRANT administrator TO nelson;


CREATE ROLE data_analytics WITH PASSWORD 'analytics';
CREATE USER analitico;
GRANT SELECT ON ALL TABLES IN SCHEMA divisas TO data_analytics;


 
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


CREATE TABLE divisas.interests(
        id SMALLINT PRIMARY KEY,
        type INT REFERENCES divisas.types(id),
        stk_code CHAR(3) REFERENCES divisas.stocks(code),
        percentage DECIMAL(5,2) NOT NULL
);
CREATE TABLE divisas.transactions(
        id INT PRIMARY KEY,
        id_user INT REFERENCES divisas.users(id),
        id_type INT REFERENCES divisas.types(id),
        stk_from CHAR(3) REFERENCES divisas.stocks(code),
        stk_to CHAR(3) REFERENCES divisas.stocks(code),
        amount FLOAT NOT NULL,
        date TIMESTAMP NOT NULL,
        interest_id INT REFERENCES divisas.interest(id) 
);

CREATE TABLE divisas.capitals(
        id INT PRIMARY KEY,
        stk_code CHAR(3) REFERENCES divisas.stocks(code),
        id_user INT REFERENCES divisas.users(id),
        amount INT  NOT NULL CHECK (amount >= 0)
);


--CREACION DE INDICE TABLA TRANSACCIONES
CREATE INDEX id_transaccion ON divisas.transactions(id);


--INSERCIONES GENERALES
INSERT INTO types(name) VALUES('Retiro');
INSERT INTO types(name) VALUES('Consignacion');
INSERT INTO types(name) VALUES('Cambio');

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
	BEGIN
        UPDATE capitals SET amount = amount - cantidad - interest WHERE id_user = id_usuario AND id_type = id_tipo AND stk_code = moneda;
	END;
        $$;


CREATE OR REPLACE PROCEDURE actualizarInteresTransaccion(transaccion_id INT)
        LANGUAGE 'plpgsql'
        AS
        $$
        DECLARE myinsterest INT;
	BEGIN
	SELECT * INTO myinsterest FROM calcularInteres(transaccion_id);
        UPDATE transactions SET interest = myinterest WHERE transactions.id = transaccion_id;
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
--##CALCULAR INTERES POR TRANSACCION
CREATE OR REPLACE FUNCTION calcularInteres(transaccion_id INT)
                RETURNS INT
        $$
                DECLARE porcentaje INT, cantidad INT
        BEGIN
                WITH transaccion AS (SELECT * FROM transactions WHERE id = transaccion_id);
                SELECT i.percentage INTO porcentaje FROM interest i INNER JOIN transaccion t ON t.stk_from = i.stk_code AND t.id_type = i.type;
                SELECT t.amount INTO cantidad FROM interest i INNER JOIN transaccion t ON t.stk_from = i.stk_code AND t.id_type = i.type)
                RETURN porcentaje * cantidad;
        END;
        $$

--##Calcular la conversión de una a otra moneda

--#TRIGGERS
CREATE OR REPLACE TRIGGER insertar_interes AFTER INSERT 
ON transactions
REFERENCING NEW ROW AS nr
FOR EACH ROW
IF EXISTS (SELECT * FROM capitals WHERE id_user = nr.id_user AND stk_code = nr.stk_from AND amount > calcularInteres(nr.id))
BEGIN
        actualizarInteresTransaccion(nr.id);
        IF 
ELSE


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



