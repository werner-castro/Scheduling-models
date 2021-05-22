
# Modelo matemático: job shop
# Implementação: Carlos Werner Ribeiro de Castro

# Descrição do modelo:

# O modelo de jb (job shop) é definido por um conjunto J de n trabalhos e um finito conjunto M de m maquinas.
# Nesse modelo por conveniência no referimos como sendo um problema n-trabalhos x m-máquinas. Para cada trabalho j ∈ J nos é dada uma
# lista (α(1,j)......, α(h,j)......., α(m,j)) das máquinas que representam a ordem de processamento de j através das máquinas.

# Parâmetros do modelo:

# n = 1:J       # número de trabalhos
# m = 1:M       # Número de maquinas
# α(m,j)        # matriz de sequenciamento dos j trabalhos nas m máquinas
# P(i,j)        # tempo de processamento do trabalho j na máquina i
# V             # somatório de todas as tarefas

# Variáveis:
# x(i,j)       # instante de inicio do trabalho j na maquina i
# z(i,j,k) = 1 se o trabalho j precede o trabalho k na máquina i
# Cmax         instante de término do n-esimo trabalho na m-ésima máquina (makespan)

#  Modelo matemático:

# Min z = Cmax                                                                                    (1)

# S.t:

# x(i,j) >= 0,                                                       ∀ j = 1:J, i = 1:M           (2)

# x(α[h,j], j) >= x(α[h-1,j], j) + p(α[h-1,j], j),                   ∀ j = 1:J, h = 2:M           (3)

# x(i,j) ≥ x(i,k) + p(i,k) − V · z(i,j,k),                           ∀ j e k 1:J, j < k, i ∈ M    (4)

# x(i,k) ≥ x(i,j) + p(i,j) − V · (1 − z(i,j,k)),                     ∀ j, k ∈ J, j < k, i ∈ M     (5)

# Cmax ≥ x(α[m,j], j) + P(α[m,j], j)                                 ∀ j ∈ J                      (6)

using JuMP, Cbc, Plots, PlotThemes; theme(:juno)

include("src.jl")

DJSM = Model(optimizer_with_attributes(Cbc.Optimizer, "threads" => 5, "seconds" => 3600))

# P = [
#     2 1 2
#     1 2 2
#     1 2 1
# ]
#
# α = [
#     3 1 2
#     2 3 1
#     3 2 1
# ]

# Matriz de processamentos
#   m1 m2 m3
P = [5  7  10  # job 1
     9  5  3   # job 2
     5  8  2   # job 3
     2  7  4   # job 4
     8  8  8]  # job 5
#
# # Matriz de roteiros
#   maquinas
α = [2  1  3   # job 1
     1  2  3   # job 2
     3  2  1   # job 3
     2  1  3   # job 4
     3  1  2]  # job 5

J,M = size(P)

V = sum(P)

@variable(DJSM, x[j = 1:J, i = 1:M] ≥ 0)
@variable(DJSM, z[k = 1:J, j = 1:J, i = 1:M], Bin)
@variable(DJSM, Cmax ≥ 0)

@objective(DJSM, Min, Cmax)

@constraint(DJSM, [i = 1:M-1, j = 1:J], x[j,α[j,i+1]] ≥ x[j,α[j,i]] + P[j,α[j,i]])
@constraint(DJSM, [i = 1:M, j = 1:J, k = 1:J; j ≠ k], x[j,i] ≥ x[k,i] + P[k,i] - V * z[k,j,i])
@constraint(DJSM, [i = 1:M, j = 1:J, k = 1:J; j ≠ k], x[k,i] ≥ x[j,i] + P[j,i] - V * (1 - z[k,j,i]))
@constraint(DJSM, [j = 1:J], Cmax ≥ x[j,α[j,M]] + P[j,α[j,M]])

optimize!(DJSM)

if termination_status(DJSM) == MOI.OPTIMAL
    seq = fill(0,J,M)
    obj = round.(Int, objective_value(DJSM))
    # clearconsole()
    println(" ")
    println("Modelo de programação: [job shop]")
    println(" ")
    println("Valor da função objetivo (makespan) = ", obj)
    println(" ")
    for i = M:-1:1
        # ordenando os j trabalhos pelo menor tempo de processamento na máquina i
        seq[:,i] = sortperm(value.(x[:,i]))
        println("A maquina $i opera a programação: $(seq[:,i])")
    end
    tp = P'              # tempos de processamento
    it = value.(x)' + tp # instante de término = instante de inicio + tempos de processamento
    seq = seq'           # sequencia das tarefas
    objetivo = round.(Int, maximum(value.(x) .+ P))
    gantt(tp, it, seq, objetivo)
else
    println("Solução não encontrada !")
end
