--TESTES
SELECT CADASTRAR_CLIENTE(100, 'Ana Silva', 'Rua das Flores, 123', '11999990001', 'ana@email.com'); 
-- TESTE REALIZADO COM SUCESSO, FOI VALIDO!

SELECT CADASTRAR_CLIENTE(100, 'João Santos', 'Av. Paulista, 456', '11999990002', 'joao@email.com');
--COM SUCESSO ID JA EXISTE!

SELECT CADASTRAR_CLIENTE(101, 'Maria Oliveira', 'Rua das Acácias, 789', '11999990003', 'email-invalido');
--COM SUCESSO, EMAIL INVALIDO!