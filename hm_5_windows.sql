--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--Пронумеруйте все платежи от 1 до N по дате платежа
--Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате платежа
--Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна 
--быть сперва по дате платежа, а затем по размеру платежа от наименьшей к большей
--Пронумеруйте платежи для каждого покупателя по размеру платежа от наибольшего к
--меньшему так, чтобы платежи с одинаковым значением имели одинаковое значение номера.
--Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.

select payment_id, payment_date, customer_id, 
	row_number() over (order by payment_date) as column_1,
	row_number() over (partition by customer_id order by payment_date) as column_2,
	sum(amount) over (partition by customer_id order by payment_date, amount) as column_3,
	rank() over (partition by customer_id order by amount desc) as column_4
from payment p


--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате платежа.

select payment_id, payment_date, customer_id, amount,
	lag(amount, 1, 0.0) over (partition by customer_id order by payment_date) as last_amount
from payment p
order by payment_date 


--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.

select payment_id, payment_date, customer_id, amount,
	lead(amount, 1, 0.0) over (partition by customer_id order by payment_date) - amount  as difference
from payment p



--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.

select payment_id, payment_date, customer_id, amount
from (
	select payment_id, payment_date, customer_id, amount, 
		last_value(payment_id) over (partition by customer_id order by payment_date
			rows between unbounded preceding and unbounded following)
	from payment p) t 
where payment_id = last_value 

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.

select staff_id , payment_date, 
	sum(amount) over (partition by staff_id order by payment_date) as sum_amount,
	sum(amount) over (order by payment_date)
from payment p  
where date_trunc('month', payment_date) = '2005-08-01'::date

--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку

select *
from ( 
	select customer_id, payment_date, 
		row_number() over (order by payment_date)
	from payment p  
	where date_trunc('day', payment_date) = '2005-08-20'::date)
where row_number % 100 = 0

--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм

select distinct c1.country,
	first_value(concat(c3.last_name, ' ', c3.first_name)) over (partition by c1.country_id order by count(r.rental_id) desc) as "Покупатель арендовавший наибольшее количество фильмов",
	first_value(concat(c3.last_name, ' ', c3.first_name)) over (partition by c1.country_id order by sum(p.amount) desc) as "Покупатель арендовавший на наибольшую сумму",
	first_value(concat(c3.last_name, ' ', c3.first_name)) over (partition by c1.country_id order by max(r.rental_date) desc) as "Покупатель, который последний арендовавал фильм"
from country c1 
left join city c2 on c1.country_id = c2.country_id 
left join address a on a.city_id  = c2.city_id 
left join customer c3 on c3.address_id = a.address_id 
left join rental r on r.customer_id = c3.customer_id 
left join payment p on p.rental_id = r.rental_id 
group by c1.country_id, c3.customer_id 


