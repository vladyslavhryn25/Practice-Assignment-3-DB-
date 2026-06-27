# Practical Assignment 3

База даних онлайн-магазину.

5 таблиць: customers, products, orders, order_items, order_log.

## Що зроблено

**Функція** `calculate_order_total(order_id)` - рахує загальну суму замовлення на основі order_items. Якщо товарів немає — повертає 0.

**Процедура** `create_order(customer_id)` - створює нове замовлення для клієнта. Якщо клієнта не існує - нічого не робить і виводить повідомлення.

**Процедура** `add_product_to_order(order_id, product_id, quantity)` - додає товар до замовлення. Бере поточну ціну з таблиці products, зменшує залишок на складі. Перевіряє що кількість більше 0 і що товару достатньо на складі.

**Тригер** `trg_order_items_total` - спрацьовує після будь-якої зміни в order_items (INSERT, UPDATE, DELETE) і автоматично перераховує total_amount в orders через функцію calculate_order_total.

**Тригер** `trg_orders_audit` - спрацьовує після створення нового замовлення і записує подію в order_log.

