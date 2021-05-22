# Modelo matemático: flow shop simples.
# Modelagem: Carlos Werner Ribeiro de Castro
# modelo e instância retirados do livro: Pesquisa Operacional para os cursos de engenharia, Arenales 2007, pág = 224 e 225

# índices
# k = 1,......N número de tarefas / linhas da matriz
# i = 1,......M número de máquinas / colunas da matriz
#
# Parâmetros
# p(i,k) = tempo de processamento da tarefa i na máquina k
#
# Variáveis
# S(k,j) = instante de início da tarefa j na máquina k
# Z(i,j) = 1 se a tarefa i é designada a posição j e 0 para caso contrário
#
#
# Modelo matemático:
#
# Função objetivo = Minimizar o makespan.
# |            I          I
# | Min Cmax = ∑ S(i,k) + ∑ p(i,I) * z(i,k)                                                             (1)
# |           i=1        i=1
# |
#
# Restrições
# |  I
# |  ∑  Z(i,j) = 1                                                        ∀ j = 1.........I             (2)
# | i=1
# |
# |  I
# |  ∑  Z(i,j) = 1                                                        ∀ i = 1.........I             (3)
# | j=1
# |
# |          I
# | S(1,j) + ∑ p(i,1) * Z(i,j) = S(i,j+1)                                 ∀ j = 1.........I-1           (4)
# |         i=1
# |
# | S(1,1) = 0                                                                                          (5)
# |
# |          I
# | S(k,1) + ∑ p(i,k) * Z(i,1) = S(k+1,i)                                 ∀ k                           (6)
# |         i=1
# |
# |          I
# | S(k,j) + ∑ p(i,k) * Z(i,j) <= S(k+1,j)                                ∀ j                           (7)
# |         i=1
# |

using JuMP, Cbc

include("graph.jl")

# construção do modelo:

sfs = Model(optimizer_with_attributes(Cbc.Optimizer, "threads" => 5, "seconds" => 1000))
# sfs = Model(optimizer_with_attributes(CPLEX.Optimizer, "CPX_PARAM_TILIM" => 300, "CPX_PARAM_TRELIM" => 2024, "CPX_PARAM_THREADS" => 4))

#     m1 m2 m3
# P = [5  7  10   # t1
#      9  5  3    # t2
#      5  8  2    # t3
#      2  7  4    # t4
#      8  8  8]   # t5

maquinas = 4

tarefas = 10

P = rand(2:10, tarefas, maquinas)

# Parâmetros:
N,M = size(P)

# variáveis:
@variable(sfs, s[k = 1:M, j = 1:N] >= 0)
@variable(sfs, z[i in 1:N, j in 1:N], Bin)
@variable(sfs, Cmax >= 0)

# função objetivo = minimizar o makespan
@objective(sfs, Min, Cmax)                                                                            # (1) minimiza o makespan

# restrições:
@constraint(sfs, Cmax == s[M,N] + sum(P[i,M] * z[i,N] for i in 1:N))                                  # (1)
@constraint(sfs, [j in 1:N], sum(z[i,j] for i in 1:N) == 1)                                           # (2)
@constraint(sfs, [i in 1:N], sum(z[i,j] for j in 1:N) == 1)                                           # (3)
@constraint(sfs, [j in 1:N-1], s[1,j] + sum(P[i,1] * z[i,j] for i in 1:N) == s[1,j+1])                # (4)
@constraint(sfs, s[1,1] == 0)                                                                         # (5)
@constraint(sfs, [k = 1:M-1], s[k,1] + sum(P[i,k] * z[i,1] for i in 1:N) == s[k+1,1])                 # (6)
@constraint(sfs, [j = 2:N, k = 1:M-1], s[k,j] + sum(P[i,k] * z[i,j] for i in 1:N) <= s[k+1,j])        # (7)
@constraint(sfs, [j = 1:N-1, k = 2:M], s[k,j] + sum(P[i,k] * z[i,j] for i in 1:N) <= s[k,j+1])        # (8)

# otimizando o modelo:
optimize!(sfs)

# validando o status da solução e gerando o relatório de saída.
if termination_status(sfs) == MOI.OPTIMAL

    # pegando o valor da função objetivo
    obj = round.(Int, objective_value(sfs))

    # gerando o vetor com a sequência ótima
    s = sequence(value.(z))

    # gerando o relatório de saída
    println(" ")
    println("Modelo de programação: [flow shop]")
    println(" ")
    println("Solução ótima encontrada !")
    println(" ")
    println("Makespan = $(obj) unidades de tempo")
    println(" ")
    println("Sequencia ótima obtida = $(s)")
    println(" ")

    tempos = P'

    # plotando o gráfico de gantt
    gantt(tempos, s)
else
    println("Solução não encontrada !")
end
