-- FUNÇÃO PARA REMOVER DADOS
CREATE OR REPLACE FUNCTION REMOVER_DADO(
    NOME_TABELA VARCHAR,
    COLUNA_ID VARCHAR,
    VALOR_ID VARCHAR
) RETURNS TEXT AS $$
DECLARE
    COMANDO_SQL TEXT;
    REGISTRO_EXISTE BOOLEAN; 
BEGIN
    -- Verifica se o registro existe
    EXECUTE 'SELECT EXISTS (SELECT 1 FROM ' || NOME_TABELA || ' WHERE ' || COLUNA_ID || ' = ''' || VALOR_ID || ''')' INTO REGISTRO_EXISTE;
    
    IF NOT REGISTRO_EXISTE THEN 
        RETURN 'Erro: Registro não encontrado.';
    END IF;
    
    COMANDO_SQL := 'DELETE FROM ' || NOME_TABELA || ' WHERE ' || COLUNA_ID || ' = ''' || VALOR_ID || '''';
    
    BEGIN
        EXECUTE COMANDO_SQL;
        RETURN 'Sucesso: Registro removido de ' || NOME_TABELA;
    EXCEPTION WHEN OTHERS THEN
        RETURN 'Erro ao remover: Registro pode estar em uso ou outro problema ocorreu. Detalhes: ' || SQLERRM; -- Adicionei SQLERRM para mais detalhes
    END;
END;
$$ LANGUAGE PLPGSQL;

--Teste
SELECT REMOVER_DADO(
    'CLIENTE',
    'ID_CLIENTE',
    '25' -- '25' é uma string, mesmo que ID_CLIENTE seja um INT.
);

---Funcao para alterar dados
CREATE OR REPLACE FUNCTION ALTERAR_DADO(
    NOME_TABELA VARCHAR,
    COLUNA_ID VARCHAR,
    VALOR_ID VARCHAR,
    DADOS_ALTERAR VARCHAR
) RETURNS TEXT AS $$
DECLARE
    COMANDO_SQL TEXT;
    REGISTRO_EXISTE BOOLEAN;
BEGIN
    -- Verifica se o registro existe
    EXECUTE 'SELECT EXISTS (SELECT 1 FROM ' || NOME_TABELA || ' WHERE ' || COLUNA_ID || ' = ''' || VALOR_ID || ''')' INTO REGISTRO_EXISTE;
    
    IF NOT REGISTRO_EXISTE THEN 
        RETURN 'Erro: Registro não encontrado.';
    END IF;
    
    COMANDO_SQL := 'UPDATE ' || NOME_TABELA || ' SET ' || DADOS_ALTERAR || ' WHERE ' || COLUNA_ID || ' = ''' || VALOR_ID || '''';
    
    BEGIN
        EXECUTE COMANDO_SQL;
        RETURN 'Sucesso: Registro atualizado em ' || NOME_TABELA;
    EXCEPTION WHEN OTHERS THEN
        RETURN 'Erro ao alterar: Verifique os valores ou o registro pode estar em uso. Detalhes: ' || SQLERRM; -- Adicionado SQLERRM
    END;
END;
$$ LANGUAGE PLPGSQL;

SELECT ALTERAR_DADO(
    'CLIENTE',
    'ID_CLIENTE',
    '24',
    'ENDERECO = ''Nova Rua, 789'', TELEFONE = ''9999-1111'''
);