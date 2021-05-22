# problema de sequenciamento em máquina única com minimização da quantidade de atividades atrasadas.
# Modelo e instância do problema retirado do livro: Pesquisa operacional para os cursos de engenharia. Arenales 2007, pág: 217.
#=
Considere I tarefas a serem processadas em uma única máquina. Todas as tarefas estão disponíveis
no intante zero e não se adimite a interrupção do processamento (preemption).

Indices:
i = 0,........,I número de tarefas

Parâmetros:
p(i) = tempo d procesamento da tarefa i
d(i) = data de entrega da tarefa i
M = número grande

variáveis:
x(i,j) = 1 se a atividade i precede imediatamente a tarefa j e 0 para o contrário
y(i) = 1 se a tarefa está atrasada e 0 para caso contrário.
C(i) = instante de término de processamento da tarefa i
T(i) = max{C(i) - d(i),0}

Seja zero (0) uma tarefa fictícia que precede imediatamente a primeira tarefa e sucede imedia-
tamente a última tarefa de uma seqüência de tarefas. A partir desses parâmetros e variáveis, é pos-
sível formular problemas com critérios distintos de otimização. As seguintes restrições são comuns
a todos problemas:

Modelo 5 = minimização da quantidade de atividades atrasadas.

|função objetivo.
|
|          I
| Min z =  ∑ y(i)
|         i=1
|
|
|
|sujeito a:
|
|  T(i) >= C(i) - d(i)                             ∀ i = 1.......I
|
|  T(i) <= M * y(i)                                ∀ i = 1.......I
|
|    I
|    ∑    x(i,j) = 1                               ∀ i = 0.......I
| i=0,i≠j
|
|    I
|    ∑    x(i,j) = 1                               ∀ i = 0.......I
| j=0,j≠i
|
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
| Qtd. atividades atrasadas   =  3
| Sequência ótima             =
| Instante de término         =
| Atraso                      =
#---------------------------------------------------------------------------------
=#

using JuMP,Cbc,VegaLite,DataFrames
# sequenciamento em máquina única no modelo 5
smu5 = Model(with_optimizer(Cbc.Optimizer, threads = 5, seconds = 3600.0))

# Parâmetros:
p = [ 64 53  63  99 189  44  50  22] # tempo de procesamento
d = [100 70 150 601 118 590 107 180] # data de entrega
M = 2000 # número suficientemente grande

# Indices:
I = collect(0:length(p)) # número total de atividades (jobs)
N = collect(1:length(p))

# variáveis:
@variable(smu5, x[i in I,j in I], Bin)
@variable(smu5, C[i in I] >= 0)
@variable(smu5, T[i in N] >= 0)
@variable(smu5, y[i in N], Bin)

# função objetivo:
@objective(smu5, Min, sum(y[i] for i in N))

# restrições:
@constraint(smu5, [i in N], T[i] >= C[i] - d[i])
@constraint(smu5, [i in N], T[i] <= M * y[i])
@constraint(smu5, [j in I], sum(x[i,j] for i in I if i != j) == 1)
@constraint(smu5, [i in I], sum(x[i,j] for j in I if j != i) == 1)
@constraint(smu5, [i in I, j in N], C[j] >= C[i] - M + (p[j] + M) * x[i,j])
@constraint(smu5, C[0] == 0)

# relatório de saída:
optimize!(smu5)
if termination_status(smu5) == MOI.OPTIMAL
    α = fill(0.0,length(I),1)
    for i in N
        α[i] = value.(C[i])
    end
    at = zeros(length(N))
    for i in N
        at[i] = round.(Int,value.(T[i]))
    end
    S = collect(1:length(p))
    resposta = sortslices([α[1:end-1] S], dims = 1)
    resposta = [0 0; resposta]
    resultado = round.(Int,objective_value(smu5))
    sequencia = round.(Int, resposta[:,2])

    println(" ")
    println("Solução ótima encontrada !")
    println(" ")
    println("Total de atividades atrasadas = ",resultado)
    println(" ")
    println("=================================================")
    println("Sequência ótima obtida = $(round.(Int,sequencia[2:end])) ")
    println("=================================================")

    df = DataFrame(atividade = sequencia[2:end], start = seqI, stop = seqF, Recursos = "Máquina 1") # dataframe com a sequencia das atividades
    atv_at = DataFrame(atrasos = at, Atividades = N) # dataframe das atividades atrasadas

    # gráfico
    [df |> @vlplot(:bar,
            title = " Resultado da função objetivo = $(resultado) atividades",
            y={"Recursos:o"},
            x={"start:q", axis = {title = "Tempo de processamento"}},
            x2="stop:q",
            width = 630,
            height = 120,
            color = "atividade:n"
        )

        atv_at |> @vlplot(:bar,
            x={:Atividades, axis = {title = "Atividades"}},
            y={:atrasos, axis = {title = "valor de M"}},
            width = 630,
            height = 120,
            title = "Atividades atrasadas",
            color = "Atividades:n"
        )
    ]
else
    println(" ")
    println("Solução ótima não encontrada !")
end
