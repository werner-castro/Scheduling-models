#  problema de sequenciamento em máquina única com minimização do lateness máximo.
#  Modelagem: Carlos Werner Ribeiro de Castro
#  Modelo e instância do problema retirado do livro: Pesquisa operacional para os cursos de engenharia. Arenales 2007, pág: 217.
#
# Considere I tarefas a serem processadas em uma única máquina. Todas as tarefas estão disponíveis
# no intante zero e não se adimite a interrupção do processamento (preemption).
#
# Indices:
# i = 0,........,I número de tarefas
#
# Parâmetros:
# p(i) = tempo d procesamento da tarefa i
# d(i) = data de entrega da tarefa i
# M = número grande
#
# variáveis:
# x(i,j) = 1 se a atividade i precede imediatamente a tarefa j e 0 para o contrário
# y(i) = 1 se a tarefa está atrasada e 0 para caso contrário.
# C(i) = instante de término de processamento da tarefa i
# onde Lmax;
#
# |        I
# |Lmax = max L(i)
# |       i=1
#
# onde L(i) = L⁺(i) - L⁻(i)
#
# Seja zero (0) uma tarefa fictícia que precede imediatamente a primeira tarefa e sucede imedia-
# tamente a última tarefa de uma seqüência de tarefas. A partir desses parâmetros e variáveis, é pos-
# sível formular problemas com critérios distintos de otimização.
#
# Modelo matemático 6
#
# |função objetivo = minimização do lateness máximo.
# |
# |
# | Min z =  L(i)
# |
# |
# |
# |sujeito a:
# |
# |  Lmax >= L⁺(i) - L⁻(i)                           ∀ i = 1.......I
# |
# |  L⁺(i) - L⁻(i) = C(i) - d(i)                     ∀ i = 1.......I
# |
# |    I
# |    ∑   x(i,j) = 1                                ∀ i = 0.......I
# | i=0,i≠j
# |
# |    I
# |    ∑   x(i,j) = 1                                ∀ i = 0.......I
# | j=0,j≠i
# |
# |
# | C(j) >= C(i) - M + (p(j) + M) * x(i,j)           ∀ i = 0.......I, j = 0.......I
# |
# | C(i) >= 0                                        ∀ i = 0.......I
# | C(0) = 0
# |
# #---------------------------------------------------------------------------------
# | Dados da instância:
# | I = 0....8
# | N = 1....8
# | p(i) =  64 53  63  99 189  44  50  22
# | d(i) = 100 70 150 601 118 590 107 180
# #---------------------------------------------------------------------------------
# |
# | Resultado:
# | lateness máximo                =  269
# | Sequência ótima                =
# | Instante de término            =
# | Atraso                         =
# #---------------------------------------------------------------------------------

using JuMP, Cbc, VegaLite, DataFrames
# sequenciamento em máquina única no modelo 6
# smu6 = Model(with_optimizer(CPLEX.Optimizer))
smu6 = Model(with_optimizer(Cbc.Optimizer, threads = 5, seconds = 3600.0))

# Parâmetros:
p = [ 64 53  63  99 189  44  50  22] # tempo de processamento
d = [100 70 150 601 118 590 107 180] # data de entrega
M = 2000                             # número suficientemente grande

# Indices:
I = collect(0:length(p)) # número total de atividades (jobs)
N = collect(1:length(p))

# variáveis:
@variable(smu6, x[i in I,j in I], Bin)
@variable(smu6, C[i in I] >= 0)
@variable(smu6, L[i in N])
@variable(smu6, Lmax >= 0)

# função objetivo:
@objective(smu6, Min, Lmax)

# restrições:
@constraint(smu6, [i in N], Lmax >= maximum(L[i] - (-L[i])))
@constraint(smu6, [i in N], L[i] - (-L[i]) == C[i] - d[i])
@constraint(smu6, [j in I], sum(x[i,j] for i in I if i != j) == 1)
@constraint(smu6, [i in I], sum(x[i,j] for j in I if j != i) == 1)
@constraint(smu6, [i in I, j in N], C[j] >= C[i] - M + (p[j] + M) * x[i,j])
@constraint(smu6, C[0] == 0)

# resolvendo o modelo
optimize!(smu6)

# validando o status da solução e gerando o relatório de saida
if termination_status(smu6) == MOI.OPTIMAL
    α = fill(0.0,length(I),1)
    for i in N
        α[i] = value.(C[i])
    end
    la = zeros(length(N))
    for i in N
        la[i] = round.(Int,value.(L[i]))
    end
    S = collect(1:length(p))
    resposta = sortslices([α[1:end-1] S], dims = 1)
    resposta = [0 0; resposta]
    resultado = round(Int,objective_value(smu6))
    sequencia = round.(Int,resposta[2:end,2])

    println(" ")
    println("Solução ótima encontrada !")
    println(" ")
    println("Lateness máximo = ",resultado," unidades de tempo")
    println(" ")
    println("=================================================")
    println("Sequência ótima obtida = $(sequencia) ")
    println("=================================================")

    seq = resposta[:,1]
    seqI = seq[1:end-1] # instante de início das atividades
    seqF = seq[2:end]   # instante de término das atividades

    df = DataFrame(atividade = sequencia, start = seqI, stop = seqF, Recursos = "Máquina 1") # dataframe com a sequencia das atividades
    atv_la = DataFrame(lateness = la, Atividades = N) # dataframe das atividades adiantadas

    # gráfico
    [df |> @vlplot(:bar,
        title = " Resultado da função objetivo = $(resultado) unidades de tempo",
        y = "Recursos:o",
        x={"start:q", axis = {title = "tempo em minutos"}},
        x2="stop:q",
        width = 600,
        height = 100,
        color = {"atividade:n", axis = {title = "Tarefas"}})

        atv_la |> @vlplot(:bar,
        x=:Atividades,
        y={:lateness, axis = {title = "Lateness (min)"}},
        width = 600,
        height = 100,
        title = "Lateness",
        color = {"Atividades:n", axis = {title = " "}})
    ]
else
    println(" ")
    println(" Solução ótima não encontrada !")
end
