/* Проект выполняется в интерактивном тренажере на платформе Яндекс.Практикума.

Состоит из двух частей на 20 задач на составление запросов к базе данных (PostgreSQL) StackOverFlow за 2008 год. */

/* 1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки». */

SELECT COUNT(po.post_type_id)
FROM stackoverflow.posts AS po
JOIN stackoverflow.post_types AS pt ON po.post_type_id = pt.id
WHERE pt.type = 'Question' AND (po.score > 300 OR po.favorites_count >=100);

/* 2. Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа. */

SELECT ROUND(COUNT(po.id) / EXTRACT(DAY FROM AGE('2008-11-19', '2008-11-01'))) AS avg_questions_per_day
FROM stackoverflow.posts po
JOIN stackoverflow.post_types pt ON po.post_type_id = pt.id
WHERE po.creation_date::date BETWEEN '2008-11-01' AND '2008-11-18'
      AND pt.type = 'Question';

/* 3. Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей. */

SELECT COUNT(DISTINCT us.id)
FROM stackoverflow.users AS us
JOIN stackoverflow.badges ba ON ba.user_id=us.id
WHERE us.creation_date::date=ba.creation_date::date;

/* 4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос? */

SELECT COUNT(DISTINCT po.id)
FROM stackoverflow.users us
JOIN stackoverflow.posts po ON us.id = po.user_id
JOIN stackoverflow.votes v ON po.id = v.post_id
WHERE us.display_name = 'Joel Coehoorn';

/* 5. 
Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке.
Таблица должна быть отсортирована по полю id. */

SELECT *,
        ROW_NUMBER() OVER (ORDER BY vt.id DESC)
FROM stackoverflow.vote_types AS vt 
ORDER BY id;

/* 6. Отберите 10 пользователей, которые поставили больше всего голосов типа Close. 
Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. 
Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя. */

SELECT v.user_id, COUNT(v.id)
FROM stackoverflow.votes AS v
JOIN stackoverflow.vote_types AS vt ON vt.id=v.vote_type_id
WHERE vt.name = 'Close'
GROUP BY v.user_id
ORDER BY COUNT(v.id) DESC, v.user_id DESC
LIMIT 10;
      
/* 7. 
Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
Отобразите несколько полей:
- идентификатор пользователя;
- число значков;
- место в рейтинге — чем больше значков, тем выше рейтинг.
Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя. */

SELECT user_id, COUNT(id),
        DENSE_RANK() OVER (ORDER BY COUNT(id) DESC) 
FROM stackoverflow.badges ba 
WHERE ba.creation_date::date BETWEEN '15-11-2008' AND '15-12-2008'
GROUP BY user_id
ORDER BY COUNT(id) DESC, user_id
LIMIT 10

/* 8. Сколько в среднем очков получает пост каждого пользователя?
Сформируйте таблицу из следующих полей:
- заголовок поста;
- идентификатор пользователя;
- число очков поста;
- среднее число очков пользователя за пост, округлённое до целого числа.
Не учитывайте посты без заголовка, а также те, что набрали ноль очков. */

SELECT title, user_id, score,
ROUND(AVG(score) OVER (PARTITION BY user_id))
FROM stackoverflow.posts
      WHERE title IS NOT NULL AND score != 0

/* 9. Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. 
Посты без заголовков не должны попасть в список. */

SELECT p.title
FROM stackoverflow.posts p
WHERE title IS NOT NULL AND user_id IN (SELECT user_id 
              FROM stackoverflow.badges
              GROUP BY user_id
              HAVING COUNT(id) > 1000)

/* 10. 
Напишите запрос, который выгрузит данные о пользователях из Канады (англ. Canada). 
Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. 
Пользователи с количеством просмотров меньше либо равным нулю не должны войти в итоговую таблицу. */

SELECT id, views,
    CASE 
    WHEN views >= 350 THEN 1
    WHEN views < 100 THEN 3
    ELSE 2
    END
FROM stackoverflow.users
WHERE location LIKE '%Canada%' AND views > 0

/* 11. Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. 
Выведите поля с идентификатором пользователя, группой и количеством просмотров. 
Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора. */

WITH a AS (SELECT id, views,
CASE 
WHEN views >= 350 THEN 1
WHEN views < 100 THEN 3
ELSE 2
END AS group
FROM stackoverflow.users
           WHERE location LIKE '%Canada%' AND views > 0),
           b AS (SELECT id, views, a.group AS groups, (MAX(views) OVER (PARTITION BY a.group ORDER BY views DESC)) AS maxi
FROM a) 
SELECT id, b.groups, b.views
FROM b
WHERE b.views=maxi
ORDER BY b.views DESC, id

/* 12. Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
- номер дня;
- число пользователей, зарегистрированных в этот день;
- сумму пользователей с накоплением. */

WITH a AS (
SELECT EXTRACT(DAY FROM CAST(creation_date AS date)) AS dt,
COUNT(id) AS idd
FROM stackoverflow.users
    WHERE EXTRACT(MONTH FROM creation_date) = 11 AND 
EXTRACT(YEAR FROM creation_date) = 2008
GROUP BY dt
    ORDER BY dt)
    SELECT *,
    SUM(idd) OVER (ORDER BY dt)
    FROM a;

/* 13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. 
Отобразите:
- идентификатор пользователя;
- разницу во времени между регистрацией и первым постом. */

WITH p AS 
(SELECT user_id, 
       creation_date,
       RANK() OVER (PARTITION BY user_id ORDER BY creation_date) AS rate
FROM stackoverflow.posts 
ORDER BY user_id)

SELECT user_id,
       p.creation_date - u.creation_date AS delta
FROM p
JOIN stackoverflow.users AS u 
ON p.user_id = u.id
WHERE rate = 1;


-- Вторая часть проекта --


/* 1. Выведите общую сумму просмотров у постов, опубликованных в каждый месяц 2008 года. 
Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. Результат отсортируйте по убыванию общего количества просмотров. */

SELECT DISTINCT DATE_TRUNC('month', creation_date)::date as dt,
       SUM(views_count) OVER (PARTITION BY DATE_TRUNC('month', creation_date)) AS summa
FROM stackoverflow.posts
WHERE EXTRACT(YEAR FROM creation_date) = 2008
ORDER BY summa DESC

/* 2. 
Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. 
Вопросы, которые задавали пользователи, не учитывайте. Для каждого имени пользователя выведите количество уникальных значений user_id. 
Отсортируйте результат по полю с именами в лексикографическом порядке. */

WITH a AS (SELECT p.creation_date::date AS pdt,
           u.creation_date::date AS udt,
           u.id AS uid,
           p.user_id AS pid,
           u.display_name as name,
p.id as b     
FROM stackoverflow.posts p
JOIN stackoverflow.post_types pt ON p.post_type_id=pt.id
JOIN stackoverflow.users u ON u.id = p.user_id
           WHERE pt.type LIKE 'Answer')
           SELECT DISTINCT name,
COUNT(DISTINCT pid)
           FROM a
           WHERE a.pdt BETWEEN a.udt AND (a.udt + INTERVAL '1 month')
           GROUP BY name
HAVING COUNT(b) > 100
ORDER BY name;

/* 3. 
Выведите количество постов за 2008 год по месяцам. Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года 
и сделали хотя бы один пост в декабре того же года. Отсортируйте таблицу по значению месяца по убыванию. */

WITH users AS
(SELECT u.id
FROM stackoverflow.posts AS p
JOIN stackoverflow.users AS u ON p.user_id=u.id
WHERE (u.creation_date::date BETWEEN '2008-09-01' AND '2008-09-30')
AND (p.creation_date::date BETWEEN '2008-12-01' AND '2008-12-31')
GROUP BY u.id)

SELECT DATE_TRUNC('month', p.creation_date)::date AS month,
       COUNT(p.id)
FROM stackoverflow.posts AS p
WHERE p.user_id IN 
(SELECT *
FROM users)
      AND DATE_TRUNC('year', p.creation_date)::date = '2008-01-01'
GROUP BY DATE_TRUNC('month', p.creation_date)::date
ORDER BY DATE_TRUNC('month', p.creation_date)::date DESC;


/* 4. Используя данные о постах, выведите несколько полей:
идентификатор пользователя, который написал пост;
дата создания поста;
количество просмотров у текущего поста;
сумма просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста. */

SELECT p.user_id,
       p.creation_date,
       p.views_count,
       SUM(views_count) OVER (PARTITION BY p.user_id ORDER BY creation_date)
FROM stackoverflow.posts p
ORDER BY user_id, p.creation_date::date;

/* 5. Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? 
Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. 
Нужно получить одно целое число — не забудьте округлить результат. */

SELECT ROUND(AVG(b))
FROM (SELECT user_id,
COUNT(DISTINCT DATE_TRUNC('day', creation_date)::date) AS b
FROM stackoverflow.posts
      WHERE creation_date::date BETWEEN '2008-12-01' AND '2008-12-07'
GROUP BY user_id) AS a;

/* 6. На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? Отобразите таблицу со следующими полями:
Номер месяца.
Количество постов за месяц.
Процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. 
Округлите значение процента до двух знаков после запятой. */

WITH a AS (SELECT EXTRACT(MONTH FROM creation_date::date) AS dt,
           COUNT(id) AS cc
           FROM stackoverflow.posts
           WHERE creation_date::date BETWEEN '2008-09-01' AND '2008-12-31'
           GROUP BY dt), 
b AS (SELECT *,
      LAG(cc) OVER () AS prev
      FROM a)
      SELECT dt, cc,
     ROUND(((cc-prev)::numeric/prev::numeric)*100, 2)
FROM b;


/* 7.Найдите пользователя, который опубликовал больше всего постов за всё время с момента регистрации. 
Выведите данные его активности за октябрь 2008 года в таком виде:
- номер недели;
- дата и время последнего поста, опубликованного на этой неделе. */

WITH a AS (SELECT user_id, COUNT(id)
FROM stackoverflow.posts
GROUP BY user_id
ORDER BY COUNT(id) DESC
           LIMIT 1)
           SELECT EXTRACT(WEEK FROM creation_date),
MAX(creation_date)
           FROM a 
           LEFT JOIN stackoverflow.posts p ON a.user_id=p.user_id
           WHERE creation_date::date BETWEEN '2008-10-01' AND '2008-10-31'
GROUP BY EXTRACT(WEEK FROM creation_date);
