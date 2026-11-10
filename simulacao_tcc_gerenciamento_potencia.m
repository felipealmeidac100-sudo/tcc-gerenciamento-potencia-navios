function simulacao_tcc_gerenciamento_potencia
% SIMULACAO_TCC_GERENCIAMENTO_POTENCIA
% Implementa o modelo estático por condição operativa utilizado no TCC:
% - 3 grupos geradores idênticos de 650 kW;
% - enumeração de 1, 2 e 3 GG em serviço;
% - limite mínimo e máximo de carregamento;
% - reserva girante;
% - contingência N-1;
% - comparação entre as políticas A, A', B e C;
% - cálculo do consumo anual;
% - geração de figuras para uso no TCC.
%
% Os valores foram organizados a partir das Tabelas 5 a 8 e da comparação
% anual apresentada no trabalho. O código usa a função quadrática adotada
% no Capítulo 4 para reproduzir o cenário-base.

clc; close all;

%% 1. Pasta de saída
pastaSaida = fullfile(pwd,'resultados_matlab');
if ~exist(pastaSaida,'dir')
    mkdir(pastaSaida);
end

%% 2. Dados dos grupos geradores
Pnom = 650; % potência nominal adotada no cenário-base [kW]
fracMin = 0.30;          % carregamento mínimo adotado
Pmin = fracMin*Pnom;     % [kW]
Pmax = Pnom;             % [kW]
reservaFrac = 0.10;      % reserva girante = 10% da demanda

% Função de consumo do GG [kg/h]
% C(P) = c0 + c1*P + c2*P^2
c0 = 23.2594;
c1 = 0.134597;
c2 = 8.674e-5;
C = @(P) c0 + c1.*P + c2.*P.^2;

%% 3. Dados da Tabela 5 - referência Caterpillar
fracao = [1.00 0.90 0.80 0.70 0.60 0.50 0.40 0.30];
P_elet_ref = [565 509 452 396 339 283 226 170];       % [kW]
P_eixo_ref = [599 539 479 419 360 300 240 180];       % [kW]
ce_eixo = [212.7 213.5 216.7 207.7 211.8 221.1 240.5 250.6]; % [g/kWh]
ce_elet = [225.5 226.1 229.6 219.8 224.9 234.4 255.4 265.3]; % [g/kWh]

% Escalonamento para o GG de 650 kW empregado no modelo
P_modelo = fracao*Pnom;
consumo_h_dados = ce_elet.*P_modelo/1000;  % [kg/h]

%% 4. Condições operativas - Tabelas 6, 7 e 8
condicao = {'Fundeado','Manobra','Cruzeiro','Patrulha','Máxima'};
PD = [335 890 435 940 460];       % demanda total [kW]
PV = [110 600 195 690 220];       % carga vital [kW]
horas = [4380 613 1314 2190 263]; % horas/ano

% Na política C, admite-se respaldo do GG de emergência nas condições
% indicadas no texto do trabalho. Em Manobra, a solução já exige 2 GG pela
% própria demanda; em Patrulha, PV = 690 kW excede 650 kW.
respaldoEmerg = [true false true false true];

%% 5. Enumeração das políticas
politicas = {'A','A''','B','C'};
nPol = numel(politicas);
nCond = numel(condicao);

nEscolhido = nan(nPol,nCond);
consumoHorario = nan(nPol,nCond);
consumoAnual_t = nan(nPol,nCond);

linhas = {};
linha = 0;

for ip = 1:nPol
    pol = politicas{ip};

    for j = 1:nCond
        melhorConsumo = inf;
        melhorN = NaN;

        for n = 1:3
            PG = PD(j)/n;
            [ok, motivo] = verificaConfiguracao(n,PD(j),PV(j),Pnom,Pmin,Pmax,...
                reservaFrac,pol,respaldoEmerg(j));

            Ch = n*C(PG);

            linha = linha + 1;
            linhas(linha,:) = {pol,condicao{j},n,PG,ok,motivo,Ch}; %#ok<AGROW>

            if ok && Ch < melhorConsumo
                melhorConsumo = Ch;
                melhorN = n;
            end
        end

        if ~isnan(melhorN)
            nEscolhido(ip,j) = melhorN;
            consumoHorario(ip,j) = melhorConsumo;
            consumoAnual_t(ip,j) = melhorConsumo*horas(j)/1000;
        end
    end
end

%% 6. Tabela completa de enumeração
Tenum = cell2table(linhas,'VariableNames',...
    {'Politica','Condicao','Numero_GG','Carga_por_GG_kW','Viavel','Restricao_ou_status','Consumo_kg_h'});
writetable(Tenum,fullfile(pastaSaida,'Resultados_Enumeracao.csv'));

%% 7. Resumo das políticas
Tpol = table(condicao',PD',PV',horas',...
    nEscolhido(1,:)',nEscolhido(2,:)',nEscolhido(3,:)',nEscolhido(4,:)',...
    'VariableNames',{'Condicao','Demanda_kW','Carga_vital_kW','Horas_ano',...
    'GG_Politica_A','GG_Politica_A_linha','GG_Politica_B','GG_Politica_C'});
writetable(Tpol,fullfile(pastaSaida,'Resultados_Politicas.csv'));

%% 8. Comparação anual A' x C
idxAprime = 2;
idxC = 4;
consA = consumoAnual_t(idxAprime,:);
consC = consumoAnual_t(idxC,:);
dif = consA-consC;

Tresumo = table(condicao',horas',nEscolhido(idxAprime,:)',consA',...
    nEscolhido(idxC,:)',consC',dif',...
    'VariableNames',{'Condicao','Horas','GG_A_linha','Consumo_A_linha_t',...
    'GG_C','Consumo_C_t','Economia_t'});
writetable(Tresumo,fullfile(pastaSaida,'Resumo_Anual_A_linha_vs_C.csv'));

TotalA = sum(consA,'omitnan');
TotalC = sum(consC,'omitnan');
Economia_t = TotalA-TotalC;
Economia_pct = 100*Economia_t/TotalA;

fprintf('\n================ RESULTADO BASE ================\n');
fprintf('Consumo anual - Política A'' : %.1f t/ano\n',TotalA);
fprintf('Consumo anual - Política C  : %.1f t/ano\n',TotalC);
fprintf('Economia anual              : %.1f t/ano\n',Economia_t);
fprintf('Economia relativa           : %.2f %%\n',Economia_pct);
fprintf('================================================\n\n');

disp(Tresumo)

%% 9. FIGURA 1 - ajuste da função de consumo
P = linspace(0.30*Pnom,Pnom,300);
fig1 = figure('Color','w');
plot(P,C(P),'LineWidth',1.6); hold on;
scatter(P_modelo,consumo_h_dados,55,'filled');
grid on;
xlabel('Potência por grupo gerador (kW)');
ylabel('Consumo de combustível (kg/h)');
% título omitido: a legenda da figura fica no texto do TCC
legend('Função quadrática adotada','Pontos de referência','Location','northwest');
set(gca,'FontName','Times New Roman','FontSize',11);
exportgraphics(fig1,fullfile(pastaSaida,'Figura_MATLAB_1_ajuste_consumo_TCC.png'),'Resolution',300);
savefig(fig1,fullfile(pastaSaida,'Figura_MATLAB_1_ajuste_consumo_TCC.fig'));

%% 10. FIGURA 2 - consumo específico
fig2 = figure('Color','w');
ceModelo = 1000*C(P)./P;
plot(P,ceModelo,'LineWidth',1.6); hold on;
scatter(P_modelo,ce_elet,55,'filled');
grid on;
xlabel('Potência por grupo gerador (kW)');
ylabel('Consumo específico elétrico (g/kWh)');
% título omitido: a legenda da figura fica no texto do TCC
legend('Modelo quadrático','Pontos de referência','Location','northeast');
set(gca,'FontName','Times New Roman','FontSize',11);
exportgraphics(fig2,fullfile(pastaSaida,'Figura_MATLAB_2_consumo_especifico.png'),'Resolution',300);

%% 11. FIGURA 3 - consumo para 1, 2 e 3 GG
D = linspace(100,1900,500);
fig3 = figure('Color','w','Position',[100 100 900 520]); hold on;
for n = 1:3
    PG = D/n;
    Ch = n*C(PG);
    valido = (PG >= Pmin) & (PG <= Pmax);
    Ch(~valido) = NaN;
    plot(D,Ch,'LineWidth',1.6,'DisplayName',sprintf('%d GG em serviço',n));
end
grid on;
xlabel('Demanda elétrica total (kW)');
ylabel('Consumo total (kg/h)');
% título omitido: a legenda da figura fica no texto do TCC
legend('Location','northwest');
set(gca,'FontName','Times New Roman','FontSize',11);
exportgraphics(fig3,fullfile(pastaSaida,'Figura_MATLAB_3_consumo_configuracoes_TCC.png'),'Resolution',300);
savefig(fig3,fullfile(pastaSaida,'Figura_MATLAB_3_consumo_configuracoes_TCC.fig'));

%% 12. FIGURA 4 - consumo anual A' x C (versão pronta para o TCC)
x = 1:nCond;
fig4 = figure('Color','w','Position',[100 100 900 520]);
b4 = bar(x,[consA(:) consC(:)],'grouped');
grid on;
box on;
xticks(x);
xticklabels(condicao);
xlabel('Condição operativa');
ylabel('Consumo anual de combustível (t)');
% título omitido: a legenda da figura fica no texto do TCC
legend('Política A''','Política C','Location','northwest');
set(gca,'FontName','Times New Roman','FontSize',11);
ylim([0 max([consA consC])*1.15]);

% Valores sobre as barras
for k = 1:numel(b4)
    text(b4(k).XEndPoints,b4(k).YEndPoints+8,compose('%.1f',b4(k).YData), ...
        'HorizontalAlignment','center','VerticalAlignment','bottom', ...
        'FontName','Times New Roman','FontSize',10);
end
exportgraphics(fig4,fullfile(pastaSaida,'Figura_MATLAB_4_consumo_anual_politicas_TCC.png'),'Resolution',300);
savefig(fig4,fullfile(pastaSaida,'Figura_MATLAB_4_consumo_anual_politicas_TCC.fig'));

%% 13. FIGURA 5 - número de GG por condição (versão pronta para o TCC)
fig5 = figure('Color','w','Position',[100 100 900 520]);
b5 = bar(x,[nEscolhido(idxAprime,:)' nEscolhido(idxC,:)'],'grouped');
grid on;
box on;
xticks(x);
xticklabels(condicao);
xlabel('Condição operativa');
ylabel('Número de grupos geradores em serviço');
yticks(0:1:3);
ylim([0 3.6]);
% título omitido: a legenda da figura fica no texto do TCC
legend('Política A''','Política C','Location','northwest');
set(gca,'FontName','Times New Roman','FontSize',11);

% Valores sobre as barras
for k = 1:numel(b5)
    text(b5(k).XEndPoints,b5(k).YEndPoints+0.08,compose('%d',round(b5(k).YData)), ...
        'HorizontalAlignment','center','VerticalAlignment','bottom', ...
        'FontName','Times New Roman','FontSize',10);
end
exportgraphics(fig5,fullfile(pastaSaida,'Figura_MATLAB_5_numero_GG_TCC.png'),'Resolution',300);
savefig(fig5,fullfile(pastaSaida,'Figura_MATLAB_5_numero_GG_TCC.fig'));

fprintf('Arquivos gerados em:\n%s\n',pastaSaida);

end

function [ok,motivo] = verificaConfiguracao(n,PD,PV,Pnom,Pmin,Pmax,reservaFrac,politica,respaldoEmerg)
% Verifica uma configuração de n grupos geradores para uma condição.

PG = PD/n;

% Capacidade máxima
if PG > Pmax
    ok = false;
    motivo = 'Limite máximo de carregamento';
    return
end

% Limite mínimo: a política A' representa o caso conservador que admite
% operação abaixo do mínimo para permitir comparação com a prática descrita.
if ~strcmp(politica,'A''') && PG < Pmin
    ok = false;
    motivo = 'Limite mínimo de carregamento';
    return
end

% Reserva girante
reservaDisp = n*Pnom-PD;
reservaReq = reservaFrac*PD;
if reservaDisp < reservaReq
    ok = false;
    motivo = 'Reserva girante';
    return
end

% Contingência N-1
switch politica
    case {'A','A'''}
        % Após a perda de um GG, toda a demanda deve permanecer atendida.
        contingenciaOK = (n-1)*Pnom >= PD;

    case 'B'
        % Após a perda de um GG, os GG de serviço remanescentes devem
        % sustentar a carga vital.
        contingenciaOK = (n-1)*Pnom >= PV;

    case 'C'
        % Nas condições em que o respaldo pelo GG de emergência é admitido
        % e PV não excede 650 kW, a carga não vital pode ser aliviada e a
        % contingência pode ser suprida pelo gerador de emergência.
        if respaldoEmerg && PV <= Pnom
            contingenciaOK = true;
        else
            contingenciaOK = (n-1)*Pnom >= PV;
        end

    otherwise
        error('Política desconhecida: %s',politica)
end

if ~contingenciaOK
    ok = false;
    motivo = 'Critério N-1';
    return
end

ok = true;
motivo = 'Viável';
end
