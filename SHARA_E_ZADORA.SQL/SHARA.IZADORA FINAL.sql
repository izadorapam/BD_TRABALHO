DROP FUNCTION IF EXISTS CADASTRAR_DADO(VARCHAR, VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS REMOVER_DADO(VARCHAR, VARCHAR, INT);
DROP FUNCTION IF EXISTS ALTERAR_DADO(VARCHAR, VARCHAR, INT, VARCHAR);

-- FUNÇÃO PARA CADASTRAR DADOS
CREATE OR REPLACE FUNCTION CADASTRAR_DADO(
    NOME_TABELA VARCHAR,
    COLUNAS VARCHAR,  
    VALORES VARCHAR  
) RETURNS TEXT AS $$
DECLARE
    COMANDO_SQL TEXT;
BEGIN
    -- Verifica se a tabela existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = LOWER(NOME_TABELA)) THEN
        RETURN 'Erro: Tabela ' || NOME_TABELA || ' não existe.';
    END IF;
	
    COMANDO_SQL := 'INSERT INTO ' || NOME_TABELA || ' (' || COLUNAS || ') VALUES (' || VALORES || ')';
    
    BEGIN
        EXECUTE COMANDO_SQL;
        RETURN 'Sucesso: Dados cadastrados em ' || NOME_TABELA;
    EXCEPTION WHEN OTHERS THEN
        RETURN 'Erro ao cadastrar: Verifique os valores.';
    END;
END;
$$ LANGUAGE PLPGSQL;

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
