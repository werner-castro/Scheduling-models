# problema de sequenciamento em máquinas paralelas idênticas com minimização do makespan.
# Modelo do problema retirado do livro: Pesquisa operacional para os cursos de engenharia. Arenales 2007, pág: 220.

# Descrição do modelo:
#
# No modelo de máquinas paralelas idênticas o tempo de processamento e o tempo de preparação são os mesmos.
# O modelo a seguir refere-se a m máquinas paralelas e n tarefas disponíveis para o processamento no instante zero e sem interrupção
# de processamento de qualquer tarefa.

# Índices
# | i = 1,........,I número de tarefas
# | j = 1,........,J número de máquinas

# Parâmetros
# | p(i) = tempo da procesamento da tarefa i

# Variáveis
# | Cmax = makespan
# | x(i,j) = 1 se a atividade i é processada na máquina j e 0 caso não ocorra

# Modelo matemático 1 = minimização do makespan.
#
# Função objetivo
# |
# | Min z =  Cmax                                                     (1)  minimiza o makespan
#
# Restrições
# |
# |  J
# |  ∑  x(i,j) = 1                                   ∀ i = 1.......I  (2) assegura qua a tarefa i só vai para uma máquina j
# | j=1
# |
# |         I
# | Cmax >= ∑ p(i) * x(i,j)                          ∀ j = 1.......J  (3) assegura que o makespan é o o maior tempo de processamento em todas as j máquinas
# |        i=1
# |
# | Dados da instância
# | p(i) =  [2 5 8 3 4 4 6]
# |

using JuMP, Cbc

include("graph.jl")

# Parâmetros:
n = 50 # número de jobs

p = rand(1:10,n)      # tempos de processamento entre 1 e 10

J = 6                 # número de máquinas
T = 60                # capacidade das máquinas em minutos

smpi = Model(optimizer_with_attributes(Cbc.Optimizer, "threads" => 5, "seconds" => 300))

# Indices:
I = length(p)       # número de tarefas

# Variáveis:
@variable(smpi, x[i in 1:I, j in 1:J], Bin)
@variable(smpi, Cmax >= 0)

# Função objetivo:
@objective(smpi, Min, Cmax)

# Restrições:
@constraint(smpi, [i in 1:I], sum(x[i,j] for j = 1:J) == 1)
@constraint(smpi, [j in 1:J], Cmax >= sum(p[i] * x[i,j] for i = 1:I))
@constraint(smpi, Cmax <= T)

# Otimizando o problema
optimize!(smpi)

# clearconsole()

# Validando o status da solução e gerando o relatório de saída
if termination_status(smpi) == MOI.OPTIMAL
    clearconsole()
    s = value.(x) .* p
    sol = (round.(Int, objective_value(smpi)))
    print("=========== relatório de alocação =========== \n")
    println(" ")
    print("Máquinas não acionadas: ")
    for j = 1:J
        if sum(value.(x[1:end,j])) == 0
            print("$([j])")
        end
    end
    println(" ")
    println(" ")
    for j = 1:J
        if ((sum(value.(x[1:end,j]) .* p[1:end])) / T) >= 0.85
            print("Máquina $([j]) com [",round.(Int,((sum(value.(x[1:end,j]) .* p[1:end])) / T) * 100),"]% da capacidade utilizada")
        end
        if sum(value.(x[1:end,j])) > 0
            print("A máquina $([j]) recebeu as tarefas: ")
            for i = 1:I
                if value.(x[i,j]) > 0
                    print("$([i])")
                end
            end
        else
            continue
        end
        println(" ")
    end
    println(" ")
    println("===== relatório de capacidade utilizada =====")
    println(" ")
    for j = 1:J
        println("Máquina $([j]) com [",round.(Int,((sum(value.(x[1:end,j]) .* p[1:end])) / T) * 100),"]% da capacidade utilizada")
    end
    # gráfico de gantt
    gantt(s,T,smpi,"n")
else
    println("Solução não encontrada !")
end
