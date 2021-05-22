
# cálculo makespan em maquinas paralelas

# m = número de maquinas
# n = número de tarefas

# p = 1:n, tempo de processamento das n tarefas
# s = 1:n, vetor de tarefas / sequência de processamento

using Random, Plots

include("graph.jl")

function parallel_mp(s::AbstractArray, p::Array{Int64}, m::Int64)
    matriz_tempos = fill(0,m,length(seq))
    tempos = fill(0,m,1)
    for i = 1:length(s)
        j = argmin(tempos)[1]
        tempos[j] += p[s[i]]
        matriz_tempos[j,s[i]] = p[s[i]]
    end
    # clearconsole()
    println(" ")
    println("Cálculo do makespan: $(maximum(tempos)) u.t")
    println(" ")
    for i in 1:m
        println("A máquina [$(i)] com tempo total de [$(tempos[i])] u.t, tarefas alocadas: $([j for j = 1:length(seq) if matriz_tempos[i,j] > 0])")
    end
    obj = maximum(tempos)
    return gantt(matriz_tempos, obj, obj, "n")
end

# # número de maquinas
# m = 3

# # número de tarefas
# n = 20

# # sequência das tarefas (gerando de forma aleatória)
# seq = shuffle([1:n...])

# # tempos de processamento das tarefas
# p = rand(3:15,n,1)

# parallel_mp(seq,p,m)
