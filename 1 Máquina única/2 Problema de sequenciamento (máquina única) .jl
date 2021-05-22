# problema de sequenciamento em máquina única com minimização do atraso máximo.
# Modelo e instância do problema retirados do livro: Pesquisa operacional para os cursos de engenharia. Arenales 2007, pág: 216 e 217.
#=
Considere I tarefas a serem processadas em uma única máquina. Todas as tarefas estão disponíveis
no intante zero e não se adimite a interrupção do processamento (preemption).

Indices:
i = 0,........,I número de tarefas

Parâmetros:
p(i) = tempo de procesamento da tarefa i
d(i) = data de entrega da tarefa i
M = número grande

variáveis:
x(i,j) = 1 se a atividade i precede imediatamente a tarefa j e 0 para o contrário
C(i) = instante de término de processamento da tarefa i
T(i) = max{C(i) - d(i),0}

|        N
|Tmax = max T(i)
|       i=1

Seja zero (0) uma tarefa fictícia que precede imediatamente a primeira tarefa e sucede imedia-
tamente a última tarefa de uma seqüência de tarefas. A partir desses parâmetros e variáveis, é pos-
sível formular problemas com critérios distintos de otimização.

Modelo 2 = minimização do atraso máximo

|função objetivo.
|
| Min z = Tmax
|
|
|sujeito a:
|
|
|  Tmax >= T(i)                                    ∀ i = 1.......I
|
|
|  T(i) >= C(i) - d(i)                             ∀ i = 1.......I
|
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
| Atraso máximo       =   269
| Sequência ótima     =   5   2   7    1    3    8    6     4
| Instante de término =  189 242 292  354  419  441  485   584
| Atraso              =   71 172 185  254  269  261  000   000
#---------------------------------------------------------------------------------
=#

using JuMP,Cbc,VegaLite,DataFrames
# sequenciamento em máquina única no modelo 2
smu2 = Model(with_optimizer(Cbc.Optimizer, threads = 5, seconds = 3600.0))

# Parâmetros:
p = [64 53 63 99 189 44 50 22] # tempo de procesamento
d = [100 70 150 601 118 590 107 180] # data de entrega
M = 2000 # número suficientemente grande

# Indices:
I = collect(0:length(p)) # número total de atividades (jobs)
N = collect(1:length(p))

# variáveis:
@variable(smu2, x[i in I,j in I], Bin)
@variable(smu2, C[i in I] >= 0)
@variable(smu2, T[i in N] >= 0)
@variable(smu2, Tmax >= 0)

# função objetivo:
@objective(smu2, Min, Tmax)

# restrições:
@constraint(smu2, [i in N], Tmax >= T[i])
@constraint(smu2, [i in N], T[i] == maximum(C[i] - d[i]))
@constraint(smu2, [j in I], sum(x[i,j] for i in I if i != j) == 1)
@constraint(smu2, [i in I], sum(x[i,j] for j in I if j != i) == 1)
@constraint(smu2, [i in I, j in N], C[j] >= C[i] - M + (p[j] + M) * x[i,j])
@constraint(smu2, C[0] == 0)

optimize!(smu2)

# relatório de saída:
if termination_status(smu2) == MOI.OPTIMAL
    a = fill(0.0,length(I),1) # tempos de processamento
    for i in N
        a[i] = value.(C[i])
    end
    at = zeros(length(N))
    for i in N
        at[i] = round.(Int,value.(T[i]))
    end
    S = collect(1:length(p))
    resposta = sortslices([a[1:end-1] S], dims = 1)
    resposta = [0 0; resposta]
    resultado = round.(Int,objective_value(smu2))
    sequencia = round.(Int,resposta[:,2])

    println(" ")
    println("Solução ótima encontrada !")
    println(" ")
    println("Atraso máximo / atividade com maior atraso = ",resultado," unidades de tempo")
    println(" ")
    println("=================================================")
    println("Sequência ótima obtida = $(sequencia[2:end]) \n")
    println("Atasos das atividades  = $(round.(Int,at))")
    println("=================================================")

    seq = resposta[:,1]
    seqI = seq[1:end-1] # instante de início das atividades
    seqF = seq[2:end]   # instante de término das atividades

    df = DataFrame(atividade=sequencia[2:end], start = seqI, stop = seqF, tarefas = sequencia[2:end], Recursos = " Máquina 1 ")
    atv_at = DataFrame(atrasos = at, Atividades = N) # dataframe das atividades atrasadas

    # gráfico
    [df |> @vlplot(:bar,
        title = "Resultado da função objetivo = $(resultado) unidades de tempo",
        y = "Recursos:o", x="start:q", x2="stop:q", width = 630, height = 120, color = "tarefas:n") # atividades

        atv_at |> @vlplot(:bar, x=:Atividades, y=:atrasos, width = 630, height = 120, # atividades com atraso
        title = "Atividades atrasadas", color = "Atividades:n")
    ]
else
    println(" ")
    println("Solução ótima não encontrada !")
end
