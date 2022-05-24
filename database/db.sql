--Creación del esquema
CREATE SCHEMA divisas;

--CREACIÓN DE LOS ROLES Y USUARIOS DE LA BASE DE DATOS

CREATE USER yofer WITH PASSWORD 'yofer123';
CREATE USER valentina WITH PASSWORD 'valentina123';
GRANT ALL ON ALL TABLES IN SCHEMA divisas TO yofer;
GRANT ALL ON ALL TABLES IN SCHEMA divisas TO valentina;


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
        name VARCHAR(40) NOT NULL UNIQUE,
        value FLOAT NOT NULL
);
CREATE TABLE divisas.priorities(
        id SERIAL PRIMARY KEY,
        stk_code CHAR(3) REFERENCES divisas.stocks(code),
        id_user INT REFERENCES divisas.users(id)
);

CREATE TABLE divisas.transactions(
        id SERIAL PRIMARY KEY,
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
  	INSERT INTO divisas.users(name, pass, email, user_name) VALUES (name, pass, email, user_name);
  END;
  $$;
  
CREATE OR REPLACE PROCEDURE insertStock(codigo CHAR(3), nombre VARCHAR(15), valor FLOAT)
  LANGUAGE 'plpgsql'
  AS $$
  BEGIN
  	INSERT INTO divisas.stocks(code, name, value) VALUES(codigo, nombre, valor);
  END;
  $$;
  
CREATE OR REPLACE PROCEDURE insertPriority(moneda CHAR(3), id_usuario INT)
  LANGUAGE 'plpgsql'
  AS $$
  BEGIN
  	INSERT INTO divisas.priorities(stk_code, id_user) VALUES(moneda, id_usuario);
  END;
  $$;
  
 
CREATE OR REPLACE PROCEDURE insertTransaction( id_usuario INT, id_tipo INT, moneda_i CHAR(3), moneda_f CHAR(3), cantidad amount)
  LANGUAGE 'plpgsql'
  AS $$
  BEGIN
  	IF moneda_f IS NOT NULL THEN
		IF moneda_i IS NOT NULL THEN
			INSERT INTO divisas.transactions( id_user, id_type, stk_from, stk_to, amount, date) VALUES( id_usuario, id_tipo, moneda_i, moneda_f, cantidad, NOW());
			IF EXISTS (SELECT amount FROM capitals WHERE id_user = id_usuario AND stk_code = moneda_i AND amount > cantidad*1.03) THEN
				COMMIT;
			ELSE
				ROLLBACK;
			END IF;
		ELSE
			INSERT INTO divisas.transactions( id_user, id_type, stk_to, amount, date) VALUES( id_usuario, id_tipo, moneda_f, cantidad, NOW());
		END IF;
	ELSE
		INSERT INTO divisas.transactions( id_user, id_type, stk_from, amount, date) VALUES( id_usuario, id_tipo, moneda_i, cantidad, NOW());
	END IF;
  END;
  $$;
  

--#ACTUALIZACIONES!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

CREATE OR REPLACE PROCEDURE borrarPrioridad(moneda amount, id_usuario INT)
        LANGUAGE 'plpgsql'
        AS
        $$
	BEGIN
        DELETE FROM divisas.priorities WHERE stk_code = moneda AND id_user = id_usuario;
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
	$$;

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
	$$;
--##Calcular la conversión de una a otra moneda
CREATE OR REPLACE FUNCTION stk_to_stk(stk_from CHAR(3), stk_to CHAR(3), amount amount)
	RETURNS amount
	LANGUAGE 'plpgsql'
        AS
	$$
	BEGIN
		RETURN eur_to_stk(stk_to , stk_to_eur(stk_from, amount));
	END;
	$$;



CREATE OR REPLACE FUNCTION actualizarCapitales()
        RETURNS TRIGGER
	LANGUAGE 'plpgsql'
        AS
        $$
	BEGIN
		
	
		IF (NEW.id_type = 2) AND NOT EXISTS (SELECT * FROM divisas.capitals c WHERE c.id_user = NEW.id_user AND stk_code = NEW.stk_to) THEN
			
			INSERT INTO divisas.capitals( stk_code, id_user, amount) VALUES( NEW.stk_to, NEW.id_user, NEW.amount);
			
		ELSE	
			
			IF NEW.id_type = 1 THEN
				UPDATE divisas.capitals SET amount = amount - NEW.amount*1.03 WHERE stk_code = NEW.stk_from AND id_user = NEW.id_user;
			END IF;
			IF NEW.id_type = 2 THEN
				UPDATE divisas.capitals SET amount = amount + NEW.amount WHERE stk_code = NEW.stk_to AND id_user = NEW.id_user;
			END IF;
			IF NEW.id_type = 3 THEN
				UPDATE divisas.capitals SET amount = amount - NEW.amount*1.03 WHERE stk_code = NEW.stk_from AND id_user = NEW.id_user;
				UPDATE divisas.capitals SET amount = amount + stk_to_stk(NEW.stk_from, NEW.stk_to,NEW.amount) WHERE stk_code = NEW.stk_to AND id_user = NEW.id_user;
			END IF;
			
		END IF;
		RETURN NEW;
	END;
        $$;

--#TRIGGERS
CREATE TRIGGER actualizar_capitales AFTER INSERT 
ON divisas.transactions
FOR EACH ROW
EXECUTE PROCEDURE actualizarCapitales();


--VISTAS
--#Ganancias
CREATE OR REPLACE VIEW ganancias AS
(SELECT SUM(amount*0.03) AS ganancias
FROM divisas.transactions);

--#transacciones por usuario
CREATE OR REPLACE VIEW txu AS(
SELECT COUNT(user_name) AS total_transacciones, user_name FROM (SELECT u.user_name FROM divisas.users u INNER JOIN divisas.transactions t ON u.id =  t.id_user) AS ut
GROUP BY user_name
);


