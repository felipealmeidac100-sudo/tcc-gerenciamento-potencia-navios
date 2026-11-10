# Gerenciamento de potência em navios com propulsão elétrica

Código-fonte em MATLAB do Trabalho de Conclusão de Curso **"Gerenciamento de potência em navios com propulsão elétrica: redução do consumo de combustível pela operação otimizada dos grupos geradores"**, apresentado ao Centro de Instrução Almirante Alexandrino (CIAA), no Curso de Aperfeiçoamento Avançado em Sistemas de Controle e Eletricidade de Navios (C-ApA-Of SCELN), em 2026.

- **Autor:** Primeiro-Tenente Felipe Nascimento de Almeida
- **Orientador técnico:** CT (EN) Victor Hugo Almeida Cruz
- **Orientador acadêmico:** Prof. Thiago Monteiro Tuxi, D.Sc.

## Sobre o código

O script implementa o modelo estático por condição operativa descrito no Capítulo 4 do trabalho. Para cada uma das cinco condições operativas (fundeado, manobra, cruzeiro, patrulha e velocidade máxima), a rotina avalia, por enumeração, as configurações com um, dois e três grupos geradores (GG) em serviço, descarta as que violam alguma restrição e seleciona a alternativa viável de menor consumo horário.

As restrições verificadas são:

- limites de carregamento mínimo (30%) e máximo (100%) da potência nominal;
- reserva girante de 10% da demanda;
- critério de contingência N-1, parametrizado conforme as políticas A, A', B e C.

O consumo anual é obtido pela ponderação das horas de cada regime.

## Parâmetros do cenário-base

| Parâmetro | Valor |
|---|---|
| Grupos geradores de serviço | 3 × 650 kW |
| Função de consumo [kg/h] | C(P) = 23,2594 + 0,134597·P + 8,674×10⁻⁵·P² |
| Demandas [kW] | 335, 890, 435, 940, 460 |
| Cargas vitais [kW] | 110, 600, 195, 690, 220 |
| Horas por ano | 4380, 613, 1314, 2190, 263 |

O perfil de carga é um cenário de estudo construído a partir de fontes abertas sobre a classe Dattilo e de estimativas de engenharia. Não corresponde a um balanço elétrico medido a bordo.

## Como executar

1. Baixe o arquivo `simulacao_tcc_gerenciamento_potencia.m`.
2. No MATLAB, defina como pasta de trabalho a pasta onde o arquivo foi salvo.
3. Na janela de comandos, execute:

```matlab
simulacao_tcc_gerenciamento_potencia
```

Requisito: MATLAB R2020a ou posterior (uso da função `exportgraphics`).

## Resultados gerados

O programa cria a pasta `resultados_matlab` com:

- `Resultados_Enumeracao.csv`: avaliação de todas as configurações candidatas;
- `Resultados_Politicas.csv`: número de GG escolhido por política e condição;
- `Resumo_Anual_A_linha_vs_C.csv`: comparação anual entre as políticas A' e C;
- cinco figuras (`.png`), correspondentes às Figuras 6 a 10 do trabalho.

Resultado esperado para o cenário-base (ver também `resultado_esperado_base.csv`):

| Política | Consumo anual |
|---|---|
| A' (referência conservadora) | ≈ 1.218,4 t/ano |
| C (proposta) | ≈ 1.107,1 t/ano |
| **Economia** | **≈ 111,3 t/ano (9,13%)** |

## Limitações

O modelo é estático. Não são simulados transitórios de frequência e tensão, reguladores de velocidade, sistemas de excitação, sincronismo, partidas ou paradas dos grupos geradores. Os resultados correspondem à planta modelada e não aos valores de placa de uma instalação real.
