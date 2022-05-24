--CONSULTAS GENERALES:
--Ordenar por fechas todas las transacciones
SELECT * FROM divisas.transactions ORDER BY date;

--Mostrar las monedas que más tienen los usuarios en sus capitales
SELECT SUM(amount) AS total_amount, stk_code FROM divisas.capitals GROUP BY stk_code ORDER BY total_amount DESC;

--Seleccionar las divisas más valiosas respecto al euro
SELECT RANK() OVER(ORDER BY valor), name FROM (SELECT name, stk_to_eur(code, value) AS valor FROM divisas.stocks) AS stk;

--TRANSACCIONES REALIZADAS POR UN USUARIO
SELECT * FROM txu;

--Los usuarios con más transacciones
SELECT RANK() OVER(ORDER BY total_transacciones), txu.* FROM txu;


--Monedas con más transacciones:
--A las que más se mueve dinero
SELECT s.name, r.total_amount, r.rank
FROM divisas.stocks s
INNER JOIN (SELECT RANK() OVER(ORDER BY total_amount DESC) AS rank, stk_to AS stock, total_amount FROM (SELECT SUM(amount) AS total_amount, stk_to FROM divisas.transactions GROUP BY stk_to) AS t) AS r
ON r.stock = s.code;

--De las que más sale dinero
SELECT s.name, r.rank
FROM divisas.stocks s
INNER JOIN (SELECT RANK() OVER(ORDER BY total_amount DESC) AS rank, stk_from AS stock, total_amount FROM (SELECT SUM(amount) AS total_amount, stk_from FROM divisas.transactions GROUP BY stk_from) AS t) AS r
ON r.stock = s.code;

--A la que más se mueve dinero
SELECT s.name, total_amount
FROM divisas.stocks s
INNER JOIN (SELECT SUM(amount) AS total_amount, stk_to FROM divisas.transactions WHERE stk_to IS NOT NULL GROUP BY stk_to) AS t
ON s.code = t.stk_to
ORDER BY total_amount DESC
LIMIT 1;

--De la que más sale dinero
SELECT s.name, total_amount
FROM divisas.stocks s
INNER JOIN (SELECT SUM(amount) AS total_amount, stk_from FROM divisas.transactions WHERE stk_from IS NOT NULL GROUP BY stk_from) AS t
ON s.code = t.stk_from
ORDER BY total_amount DESC
LIMIT 1;

--A la que menos se mueve dinero
SELECT s.name, total_amount
FROM divisas.stocks s
INNER JOIN (SELECT SUM(amount) AS total_amount, stk_to FROM divisas.transactions WHERE stk_to IS NOT NULL GROUP BY stk_to) AS t
ON s.code = t.stk_to
ORDER BY total_amount
LIMIT 1;

--De la que menos sale dinero
SELECT s.name, total_amount
FROM divisas.stocks s
INNER JOIN (SELECT SUM(amount) AS total_amount, stk_from FROM divisas.transactions WHERE stk_from IS NOT NULL GROUP BY stk_from) AS t
ON s.code = t.stk_from
ORDER BY total_amount
LIMIT 1;

--Numero de usuarios registrados
SELECT COUNT(*) FROM divisas.users;

--Usuarios con más dinero en
SELECT u.user_name, final.rank FROM divisas.users u
INNER JOIN (SELECT RANK() OVER(ORDER BY total DESC) AS rank, id_user FROM 
	(SELECT SUM(eur) AS total, id_user FROM 
	 (SELECT id_user, stk_to_eur(stk_code, c.amount) AS eur FROM divisas.capitals) AS stocks GROUP BY id_user) AS TEUR) AS final
ON final.id_user = u.id_user;
