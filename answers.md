# Answers — Bonus Task 2

1. What is the difference between a function and a procedure in PostgreSQL?

A function always returns a value and can be used directly inside a SELECT query.
A procedure does not return a value - it is called with CALL and is used to perform actions like inserting or updating data.

2. Can a trigger be executed manually? Why or why not?

No, a trigger cannot be executed manually.
A trigger is always attached to a specific event on a table - INSERT, UPDATE, or DELETE.
It fires automatically when that event happens, so there is no way to call it directly like a function or procedure.

3. What are the advantages and disadvantages of storing business logic inside the database?

Advantages: the logic runs close to the data, which is faster and reduces the amount of data transferred between the database and the application.
Disadvantages: it is harder to test and debug SQL logic compared to application code.
It also makes the codebase harder to maintain when logic is split between the database and the application.

