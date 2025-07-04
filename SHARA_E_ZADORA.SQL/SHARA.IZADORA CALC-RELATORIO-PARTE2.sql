-- TRIGGER PARA CALCULAR TOTAL DO PEDIDO AUTOMATICAMENTE

DROP TRIGGER IF EXISTS TRG_CALCULAR_TOTAL_PEDIDO ON ITEM_PEDIDO;
DROP FUNCTION IF EXISTS CALCULAR_TOTAL_PEDIDO();
DROP FUNCTION IF EXISTS PRODUTOS_BAIXO_ESTOQUE(INTEGER);
DROP FUNCTION IF EXISTS VENDAS_POR_FUNCIONARIO();

CREATE OR REPLACE FUNCTION CALCULAR_TOTAL_PEDIDO()
RETURNS TRIGGER AS $$
DECLARE
    V_TOTAL DECIMAL(10,2);
BEGIN
    -- Calcula o total somando 
    SELECT SUM(IP.QUANT * P.PRECO)
    INTO V_TOTAL
    FROM ITEM_PEDIDO IP
    JOIN PRODUTO P ON IP.ID_PRODUTO = P.ID_PRODUTO
    WHERE IP.ID_PEDIDO = NEW.ID_PEDIDO;

    UPDATE PEDIDO
    SET TOTAL = COALESCE(V_TOTAL, 0)
    WHERE ID_PEDIDO = NEW.ID_PEDIDO;

    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

-- Trigger para calcular total após inserção/atualização/exclusão de itens
CREATE TRIGGER TRG_CALCULAR_TOTAL_PEDIDO
AFTER INSERT OR UPDATE OR DELETE ON ITEM_PEDIDO
FOR EACH ROW
EXECUTE FUNCTION CALCULAR_TOTAL_PEDIDO();

-- TRIGGER PARA CALCULAR TOTAL DA COMPRA AUTOMATICAMENTE
CREATE OR REPLACE FUNCTION CALCULAR_TOTAL_COMPRA()
RETURNS TRIGGER AS $$
DECLARE
    V_TOTAL DECIMAL(10,2);
BEGIN
    SELECT SUM(QUANT * VALOR_UNITARIO)
    INTO V_TOTAL
    FROM ITEM_COMPRA
    WHERE ID_COMPRA = NEW.ID_COMPRA;

    UPDATE COMPRA
    SET TOTAL = COALESCE(V_TOTAL, 0)
    WHERE ID_COMPRA = NEW.ID_COMPRA;

    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER TRG_CALCULAR_TOTAL_COMPRA
AFTER INSERT OR UPDATE OR DELETE ON ITEM_COMPRA
FOR EACH ROW
EXECUTE FUNCTION CALCULAR_TOTAL_COMPRA();


-- TRIGGER PARA DEFINIR VALOR UNITÁRIO AO INSERIR ITEM NO PEDIDO
CREATE OR REPLACE FUNCTION DEFINIR_VALOR_UNITARIO()
RETURNS TRIGGER AS $$
BEGIN
    -- Busca o preço atual do produto 
    SELECT PRECO INTO NEW.VALOR_UNITARIO
    FROM PRODUTO
    WHERE ID_PRODUTO = NEW.ID_PRODUTO;
    
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER TRG_DEFINIR_VALOR_UNITARIO
BEFORE INSERT ON ITEM_PEDIDO
FOR EACH ROW
EXECUTE FUNCTION DEFINIR_VALOR_UNITARIO();

-- FUNÇÕES DE VALIDAÇÃO
CREATE OR REPLACE FUNCTION VALIDAR_EMAIL(EMAIL_PARAM VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EMAIL_PARAM ~* '^[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]+$';
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION VALIDAR_TELEFONE(TELEFONE_PARAM VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN TELEFONE_PARAM ~ '^[0-9]{10,11}$';
END;
$$ LANGUAGE PLPGSQL;

-- TRIGGER PARA VALIDAR EMAIL DO CLIENTE
CREATE OR REPLACE FUNCTION VALIDA_EMAIL_CLIENTE()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT VALIDAR_EMAIL(NEW.EMAIL) THEN
        RAISE EXCEPTION 'EMAIL INVÁLIDO: %', NEW.EMAIL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER TRG_EMAIL_CLIENTE
BEFORE INSERT OR UPDATE ON CLIENTE
FOR EACH ROW
EXECUTE FUNCTION VALIDA_EMAIL_CLIENTE();

-- TRIGGER PARA VALIDAR TELEFONE DO FUNCIONÁRIO
CREATE OR REPLACE FUNCTION VALIDA_TELEFONE_FUNCIONARIO()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT VALIDAR_TELEFONE(NEW.TELEFONE) THEN
        RAISE EXCEPTION 'TELEFONE INVÁLIDO: %', NEW.TELEFONE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER TRG_TELEFONE_FUNCIONARIO
BEFORE INSERT OR UPDATE ON FUNCIONARIO
FOR EACH ROW
EXECUTE FUNCTION VALIDA_TELEFONE_FUNCIONARIO();

-- FUNÇÃO PARA ADICIONAR COMPOSIÇÃO
CREATE OR REPLACE FUNCTION ADICIONAR_COMPOSICAO_PRODUTO(
    PROD1 INT,
    PROD2 INT,
    QUANTIDADE INT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO COMPOSICAO_PRONTA(ID_PROD_COMP1, ID_PROD_COMP2, QUANT)
    VALUES (PROD1, PROD2, QUANTIDADE);
END;
$$ LANGUAGE PLPGSQL;

-- FUNÇÃO PARA VERIFICAR ESTOQUE DE COMPONENTES
CREATE OR REPLACE FUNCTION VERIFICAR_ESTOQUE_COMPOSICAO(P_ID_PRODUTO INT)
RETURNS BOOLEAN AS $$
DECLARE
    R RECORD;
BEGIN
    FOR R IN SELECT * FROM COMPOSICAO_PRONTA WHERE ID_PROD_COMP1 = P_ID_PRODUTO
    LOOP
        IF (SELECT ESTOQUE FROM PRODUTO WHERE ID_PRODUTO = R.ID_PROD_COMP2) < R.QUANT THEN
            RETURN FALSE;
        END IF;
    END LOOP;
    RETURN TRUE;
END;
$$ LANGUAGE PLPGSQL;

-- FUNÇÃO PARA MONTAR PRODUTO COMPOSTO
CREATE OR REPLACE FUNCTION MONTAR_PRODUTO_COMPOSTO(P_ID_PRODUTO INT, P_QUANTIDADE INT)
RETURNS VOID AS $$
DECLARE
    R RECORD;
BEGIN
    FOR R IN SELECT * FROM COMPOSICAO_PRONTA WHERE ID_PROD_COMP1 = P_ID_PRODUTO
    LOOP
        IF (SELECT ESTOQUE FROM PRODUTO WHERE ID_PRODUTO = R.ID_PROD_COMP2) < R.QUANT * P_QUANTIDADE THEN
            RAISE EXCEPTION 'ESTOQUE INSUFICIENTE DO COMPONENTE %', R.ID_PROD_COMP2;
        END IF;
    END LOOP;

    FOR R IN SELECT * FROM COMPOSICAO_PRONTA WHERE ID_PROD_COMP1 = P_ID_PRODUTO
    LOOP
        UPDATE PRODUTO SET ESTOQUE = ESTOQUE - (R.QUANT * P_QUANTIDADE)
        WHERE ID_PRODUTO = R.ID_PROD_COMP2;
    END LOOP;

    UPDATE PRODUTO SET ESTOQUE = ESTOQUE + P_QUANTIDADE
    WHERE ID_PRODUTO = P_ID_PRODUTO;
END;
$$ LANGUAGE PLPGSQL;

-- RELATÓRIO DE PRODUTOS COM BAIXO ESTOQUE
CREATE OR REPLACE FUNCTION PRODUTOS_BAIXO_ESTOQUE(LIMITE INT)
RETURNS TABLE(ID_PRODUTO INT, NOME VARCHAR, ESTOQUE INT, PRECO DECIMAL) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        P.ID_PRODUTO, 
        P.NOME, 
        P.ESTOQUE, 
        P.PRECO
    FROM 
        PRODUTO P
    WHERE 
        P.ESTOQUE < LIMITE
    ORDER BY 
        P.ESTOQUE;
END;
$$ LANGUAGE PLPGSQL;

-- RELATÓRIO DE PRODUTOS MAIS VENDIDOS
CREATE OR REPLACE FUNCTION PRODUTOS_MAIS_VENDIDOS(LIMITE INT)
RETURNS TABLE(ID_PRODUTO INT, NOME VARCHAR, QUANTIDADE BIGINT, TOTAL DECIMAL) AS $$
BEGIN
    RETURN QUERY
    SELECT P.ID_PRODUTO, P.NOME, SUM(I.QUANT), SUM(I.QUANT * I.VALOR_UNITARIO)
    FROM PRODUTO P
    JOIN ITEM_PEDIDO I ON P.ID_PRODUTO = I.ID_PRODUTO
    GROUP BY P.ID_PRODUTO, P.NOME
    ORDER BY SUM(I.QUANT) DESC
    LIMIT LIMITE;
END;
$$ LANGUAGE PLPGSQL;

-- RELATÓRIO DE VENDAS POR FUNCIONÁRIO
CREATE OR REPLACE FUNCTION VENDAS_POR_FUNCIONARIO()
RETURNS TABLE(
    ID_FUNCIONARIO INT, 
    NOME VARCHAR, 
    CARGO VARCHAR, 
    TOTAL_VENDAS DECIMAL, 
    QTD_PEDIDOS BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        F.ID_FUNCIONARIO, 
        F.NOME, 
        F.CARGO, 
        COALESCE(SUM(P.TOTAL), 0)::DECIMAL AS TOTAL_VENDAS,
        COUNT(P.ID_PEDIDO)::BIGINT AS QTD_PEDIDOS
    FROM 
        FUNCIONARIO F
    LEFT JOIN 
        PEDIDO P ON F.ID_FUNCIONARIO = P.ID_FUNCIONARIO
    GROUP BY 
        F.ID_FUNCIONARIO, F.NOME, F.CARGO
    ORDER BY 
        TOTAL_VENDAS DESC;
END;
$$ LANGUAGE PLPGSQL;
