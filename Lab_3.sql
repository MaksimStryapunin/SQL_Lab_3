-- Задание №3. Хранимые процедуры и функции
-- Написать хранимую процедуру или функцию (ХП), которая возвращает следующее целое число в столбце. Для этого
-- используется отдельная спец. Таблица, в которой есть столбцы `id`, `имя таблицы`, `имя столбца` и `текущее
-- максимальное значение`. Пользователь (программист) передаёт в функцию аргументами имя таблицы и имя столбца.
-- ХП ищет есть ли такая запись в спец. Таблице. Если запись есть, то значение инкрементируется, после чего возвращается
-- пользователю. Если такой записи нет – ХП сперва ищет максимальное число в столбце в запрашиваемой таблице, записывает
-- новую строку, содержащую следующее за найденным число, в спец. Таблицу и возвращает это значение пользователю.
-- При отсутствии значений в запрашиваемой таблице, пользователю возвращается 1, и этот же результат записывается в
-- спец. Таблицу. Следующий идентификатор для новой строки в спец. Таблице формируется рекурсивным вызовом разработанной
-- ХП.
-- Провести тестирование корректности работы программы.
-- P.S. Способ сдачи работы на занятии - выполнение одного SQL-скрипта, в котором происходит
-- 1.	Создание спец. Таблицы.
CREATE TABLE spec_table (
                            id serial primary key,
                            name text,
                            column_name text,
                            max_value integer
);
-- 2.	Добавление в спец. таблицу записи (1, spec, id, 1). // информация о том, что максимальное число в столбце id спец. таблицы равно 1
INSERT INTO spec_table (name, column_name, max_value)
VALUES ('spec', 'id', 1);
-- 3.	Создание хранимой процедуры (ХП).
CREATE OR REPLACE FUNCTION return_next_value(
    p_table_name text,
    p_column_name text
) RETURNS integer AS $$
DECLARE
    rec record;
    cur_max integer;
    next_val integer;
    new_id integer;
BEGIN
    SELECT id, max_value INTO rec FROM spec_table WHERE name = p_table_name AND column_name = p_column_name FOR UPDATE;
    IF FOUND THEN next_val := rec.max_value + 1;
        UPDATE spec_table SET max_value = next_val WHERE id = rec.id;
        RETURN next_val;
    ELSE
        BEGIN
            EXECUTE format('SELECT max(%I) FROM %I', p_column_name, p_table_name) INTO cur_max;
        EXCEPTION
            WHEN undefined_table THEN
                RAISE EXCEPTION 'Table % does not exist', p_table_name;
            WHEN undefined_column THEN
                RAISE EXCEPTION 'Column % does not exist in table %', p_column_name, p_table_name;
        END;

        IF cur_max IS NULL THEN
            cur_max := 0;
        END IF;

        next_val := cur_max + 1;

        new_id := return_next_value('spec', 'id');

        -- Вставляем новую запись
        INSERT INTO spec_table (id, name, column_name, max_value)
        VALUES (new_id, p_table_name, p_column_name, next_val);

        RETURN next_val;
    END IF;
END;
$$ LANGUAGE plpgsql;
-- 4.	Вызов вашей ХП с параметрами 'spec', 'id'. Функция должна вернуть `2`.
SELECT return_next_value('spec', 'id') AS next_value;
-- 5.	Распечатка содержимого спец. таблицы. Должна быть 1 строка "(1, spec, id, 2)".
SELECT * FROM spec_table;
-- 6.	Вызов вашей ХП с параметрами 'spec', 'id'. Функция должна вернуть `3`.
SELECT return_next_value('spec', 'id') AS next_value;
-- 7.	Распечатка содержимого спец. таблицы. Должна быть 1 строка "(1, spec, id, 3)".
SELECT * FROM spec_table;
-- 8.	Создание новой таблицы с одним столбцом 'id'. Назовём её test.
CREATE TABLE test (id integer);
-- 9.	Добавление в таблицу test записи (10).
INSERT INTO test VALUES (10);
-- 10.	Вызов вашей ХП с параметрами 'test', 'id'. Функция должна вернуть `11`. // место для рекурсии
SELECT return_next_value('test', 'id') AS next_value;
-- 11.	Распечатка содержимого спец. таблицы. Должно быть 2 строки "(1, spec, id, 4)" "(4, test, id, 11)".
SELECT * FROM spec_table;
-- 12.	Вызов вашей ХП с параметрами 'test', 'id'. Функция должна вернуть `12`.
SELECT return_next_value('test', 'id') AS next_value;
-- 13.	Распечатка содержимого спец. таблицы. Должно быть 2 строки "(1, spec, id, 4)" "(4, test, id, 12)".
SELECT * FROM spec_table;
-- 14.	Создание таблицы 'test2' со столбцами 'num_value1', 'num_value2'.
CREATE TABLE test2 (num_value1 integer, num_value2 integer);
-- 15.	Вызов вашей ХП с параметрами 'test2', 'num_value1'. Функция должна вернуть `1`.
SELECT return_next_value('test2', 'num_value1') AS next_value;
-- 16.	Распечатка содержимого спец. таблицы. Должно быть 3 строки "(1, spec, id, 5)" "(4, test, id, 12), (5, test2, num_value1, 1)".
SELECT * FROM spec_table;
-- 17.	Вызов вашей ХП с параметрами 'test2', 'num_value1'. Функция должна вернуть `2`.
SELECT return_next_value('test2', 'num_value1') AS next_value;
-- 18.	Распечатка содержимого спец. таблицы. Должно быть 3 строки "(1, spec, id, 5)" "(4, test, id, 12), (5, test2, num_value1, 2)".
SELECT * FROM spec_table;
-- 19.	Добавление в таблицу 'test2'(num_value1, num_value2) записи (2, 13).
INSERT INTO test2 (num_value1, num_value2) VALUES (2, 13);
-- 20.	Вызов вашей ХП с параметрами 'test2', 'num_value2'. Функция должна вернуть `14`.
SELECT return_next_value('test2', 'num_value2') AS next_value;
-- 21.	Распечатка содержимого спец. таблицы. Должно быть 4 строки "(1, spec, id, 6)" "(4, test, id, 12), (5, test2, num_value1, 2), (6, test2, num_value2, 14)".
SELECT * FROM spec_table;
-- 22.	Вызов вашей ХП с параметрами 'test2', 'num_value1' 5 раз.
SELECT return_next_value('test2', 'num_value1') AS next_value;
SELECT return_next_value('test2', 'num_value1') AS next_value;
SELECT return_next_value('test2', 'num_value1') AS next_value;
SELECT return_next_value('test2', 'num_value1') AS next_value;
SELECT return_next_value('test2', 'num_value1') AS next_value;
-- 23.	Распечатка содержимого спец. таблицы. Должно быть 4 строки "(1, spec, id, 6)" "(4, test, id, 12), (5, test2, num_value1, 7), (6, test2, num_value2, 14)".
SELECT * FROM spec_table;
-- 24.	Удаление ХП.
DROP FUNCTION return_next_value(text, text);
-- 25.	Удаление таблиц.
DROP TABLE test2;
DROP TABLE test;
DROP TABLE spec_table;
