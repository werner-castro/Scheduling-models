# # Titulo: Problema de sequenciamento em máquina única com minimização do tempo de fluxo total.
# # Autor da modelagem: Carlos Werner Ribeiro de Castro
# # Modelo e instância retirados do livro: Pesquisa operacional para os cursos de engenharia. Arenales 2007, pág: 215 e 216.
#
# Descrição do modelo:
#
# Considere I tarefas a serem processadas em uma única máquina. Todas as tarefas estão disponíveis
# no intante zero e não se adimite a interrupção do processamento (preemption).
#
# Indices:
# i = 0,........,I número de tarefas
#
# Parâmetros:
# p(i) = tempo de procesamento da tarefa i
# d(i) = data de entrega da tarefa i
# M = número grande
#
# variáveis:
# x(i,j) = 1 se a atividade i precede imediatamente a tarefa j e 0 para o contrário
# C(i) = instante de término de processamento da tarefa i
#
# Seja zero (0) uma tarefa fictícia que precede imediatamente a primeira tarefa e sucede imediatamente
# a última tarefa de uma seqüência de tarefas. A partir desses parâmetros e variáveis, é possível
# formular problemas com critérios distintos de otimização.
#
# Modelo 1 = minimização do fluxo total
#
# |função objetivo.
# |
# |         I
# | Min z = ∑ C(i)
# |        i=1
# |
# |sujeito a:
# |
# |    I
# |    ∑    x(i,j) = 1                               ∀ j = 0......I
# | i=0,i≠j
# |
# |    I
# |    ∑    x(i,j) = 1                               ∀ i = 0......I
# | j=0,j≠i
# |
# | C(j) >= C(i) - M + (p(j) + M) * x(i,j)           ∀ i = 0.......I, j = 1.......N
# |
# | C(i) >= 0                                        ∀ i = 0.......I
# | C(0) = 0
# |
# #---------------------------------------------------------------------------------
# | Dados da instância:
# |
# | I = 0....8
# | N = 1....8
# | p(i) =  64 53  63  99 189  44  50  22
# | d(i) = 100 70 150 601 118 590 107 180
# #---------------------------------------------------------------------------------
# | Resultado:
# |
# | tempo total de processamento = 1880 u.t
# | Sequência ótima     =   8   6   7    2    3    1    4     5
# | Instante de término =  22  66  116  169  232  296  395   584
# #---------------------------------------------------------------------------------

using JuMP, Cbc
# sequenciamento em máquina única no modelo 1

include("graph.jl")

# construção do modelo
smu1 = Model(optimizer_with_attributes(Cbc.Optimizer, "threads" => 5, "seconds" => 3600.0))

# Parâmetros
p = [64 53 63 99 189 44 50 22]       # tempo de procesamento
d = [100 70 150 601 118 590 107 180] # data de entrega
M = 2000                             # número suficientemente grande

# Indices
I = collect(0:length(p))             # número total de atividades (jobs)
N = collect(1:length(p))

# variáveis
@variable(smu1, x[i in I,j in I], Bin)
@variable(smu1, C[i in I] >= 0)

# função objetivo
@objective(smu1, Min, sum(C[i] for i in N))

# restrições
@constraint(smu1, [j in I], sum(x[i,j] for i in I if i != j) == 1)
@constraint(smu1, [i in I], sum(x[i,j] for j in I if j != i) == 1)
@constraint(smu1, [i in I, j in N], C[j] >= C[i] - M + (p[j] + M) * x[i,j])
@constraint(smu1, C[0] == 0)

# resolvendo o modelo
optimize!(smu1)

# validando o status da solução e gerando o relatório de saída
if termination_status(smu1) == MOI.OPTIMAL
    α = fill(0.0,length(p)+1,1)
    for i in 1:length(p)
        α[i] = value.(C[i])
    end
    α = transpose(round.(Int,α))
    S = collect(1:length(p))
    resposta = sortslices([α[1:end-1] S], dims = 1)
    resposta = [0 0;resposta]
    resultado = round.(Int,objective_value(smu1))
    sequencia = round.(Int,resposta[2:end,2])
    p = p[1:end,sequencia]

    println(" ")
    println("Solução ótima encontrada !")
    println(" ")
    println("Tempo total de processamento = $(resultado) min")
    println(" ")
    println("=================================================")
    println("Sequência ótima obtida = $(round.(sequencia)) ")
    println("=================================================")

    # parâmetros da função:
    # gantt(matriz de tempos, sequência, modelo, "s" para o gráfico animado)
    # gantt(matriz de tempos, sequência, modelo, "n" para gráfico estático)

    # gráfico de gantt
    gantt(p,sequencia,smu1,"n")
else
    println("Solução ótima não encontrada !")
end
