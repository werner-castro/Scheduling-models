# Título do modelo: problema de sequenciamento em máquina única com minimização da soma dos avanços e atrasos.
# Autor da modelagem: Carlos Werner Ribeiro de Castro
# Modelo e instância do problema retirado do livro: Pesquisa operacional para os cursos de engenharia. Arenales 2007, pág: 217.
#=

Descrição do modelo
| Considere I tarefas a serem processadas em uma única máquina. Todas as tarefas estão disponíveis
| no intante zero e não se adimite a interrupção do processamento (preemption).

Indices
| i = 0,........,I número de tarefas

Parâmetros
| p(i) = tempo d procesamento da tarefa i
| d(i) = data de entrega da tarefa i
| M = número grande

Variáveis
| x(i,j) = 1 se a atividade i precede imediatamente a tarefa j e 0 para o contrário
| C(i) = instante de término de processamento da tarefa i
| T(i) = max{C(i) - d(i),0}
| E(i) = max{d(i) - C(i),0}

Seja zero (0) uma tarefa fictícia que precede imediatamente a primeira tarefa e sucede imedia-
tamente a última tarefa de uma seqüência de tarefas. A partir desses parâmetros e variáveis, é
possível formular problemas com critérios distintos de otimização. As seguintes restrições
são comuns a todos problemas:

Modelo 4 = minimização da soma dos atrasos e avanços. (conceito de produção just in time)

Função objetivo
|
|          I
| Min z =  ∑ T(i) + E(i)
|         i=1
|
|

Restrições
|
|  T(i) >= C(i) - d(i)                             ∀ i = 1.......I
|
|  E(i) >= d(i) - C(i)                             ∀ i = 1.......I
|
|    I
|    ∑    x(i,j) = 1                               ∀ i = 0.......I
| i=0,i≠j
|
|    I
|    ∑    x(i,j) = 1                               ∀ i = 0.......I
| j=0,j≠i
|
| C(j) >= C(i) - M + (p(j) + M) * x(i,j)           ∀ i = 0.......I, j = 0.......I
|
| C(i) >= 0                                        ∀ i = 0.......I
| C(0) = 0
|
#---------------------------------------------------------------------------------
| Dados da instância:
| I = 0....8
| N = 1....8
| p(i) =  64 53  63  99 189  44  50  22
| d(i) = 100 70 150 601 118 590 107 180
#---------------------------------------------------------------------------------
|
| Resultado:
| Soma dos atrasos    =
| Sequência ótima     =
| Instante de término =
| Atraso              =
| Avanço              =
#---------------------------------------------------------------------------------
=#

using JuMP, Cbc, VegaLite, DataFrames

smu4 = Model(with_optimizer(Cbc.Optimizer, threads = 5, seconds = 3600.0))

# Parâmetros
p = [64 53 63 99 189 44 50 22]        # tempo de procesamento
d = [100 70 150 601 118 590 107 180]  # data de entrega
M = 2000                              # número suficientemente grande

# Indices
I = collect(0:length(p)) # número total de atividades (jobs)
N = collect(1:length(p))

# Variáveis
@variable(smu4, x[i in I,j in I], Bin)
@variable(smu4, C[i in I] >= 0)
@variable(smu4, E[i in N] >= 0)
@variable(smu4, T[i in N] >= 0)

# Função objetivo
@objective(smu4, Min, sum(T[i] + E[i] for i in N))

# Restrições
@constraint(smu4, [i in N], T[i] >= C[i] - d[i])
@constraint(smu4, [i in N], E[i] >= d[i] - C[i])
@constraint(smu4, [j in I], sum(x[i,j] for i in I if i != j) == 1)
@constraint(smu4, [i in I], sum(x[i,j] for j in I if j != i) == 1)
@constraint(smu4, [i in I, j in N], C[j] >= C[i] - M + (p[j] + M) * x[i,j])
@constraint(smu4, C[0] == 0)

# Relatório de saída
optimize!(smu4)

# Validando o status da solução e gerando o relatório de saída
if termination_status(smu4) == MOI.OPTIMAL
    α = fill(0.0,length(I),1)
    for i in N
        α[i] = value.(C[i])
    end
    at = zeros(length(N))
    av = zeros(length(N))
    for i in N
        at[i] = round.(Int,value.(T[i]))
        av[i] = round.(Int,value.(E[i]))
    end
    S = collect(1:length(p))
    resposta = sortslices([α[1:end-1] S], dims = 1)
    resposta = [0 0; resposta]
    resultado = round.(Int,objective_value(smu4))
    sequencia = resposta[:,2]

    println(" ")
    println("Solução ótima encontrada !")
    println(" ")
    println("Tempo total dos atrasos e antecipações = ",resultado," unidades de tempo")
    println(" ")
    println("=================================================")
    println("Sequência ótima obtida = $(round.(Int,sequencia[2:end])) ")
    println("=================================================")

    seq = resposta[:,1]
    seqI = seq[1:end-1] # instante de início das atividades
    seqF = seq[2:end]   # instante de término das atividades

    df = DataFrame(atividade = sequencia[2:end], start = seqI, stop = seqF, Recursos = "Máquina 1") # dataframe com a sequência das atividades
    atv_at = DataFrame(atrasos = at, Atividades = N) # dataframe das atividades atrasadas
    atv_ad = DataFrame(avanços = av, Atividades = N) # dataframe das atividades adiantadas

    # gráfico
    [df |> @vlplot(:bar,
        title = "Resultado da função objetivo = $(resultado) unidades de tempo",
        y ="Recursos:o", x="start:q", x2="stop:q", width = 600, height = 120, color = "atividade:n")

        atv_at |> @vlplot(:bar, x=:Atividades, y=:atrasos,width = 600, height = 120,
        title = "Atividades atrasadas", color = "Atividades:n")

        atv_ad |> @vlplot(:bar, x=:Atividades, y=:avanços,width = 600, height = 120,
        title = "Atividades adiantadas", color = "Atividades:n")
    ]
else
    println("  ")
    println("Solução ótima não encontrada !")
end
