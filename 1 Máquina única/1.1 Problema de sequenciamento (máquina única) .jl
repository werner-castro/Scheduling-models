# Autor: Carlos Werner Ribeiro de Castro
# problema de sequenciamento em máquina única com minimização do tempo de fluxo total com tempo de preparação independente.
# Modelo e instância do problema retirado do livro: Pesquisa operacional para os cursos de engenharia. Arenales 2007, pág: 219.
# Considere I tarefas a serem processadas em uma única máquina com um tempo de preparação. não se adimite a interrupção do processamento (preemption).

# Decrição do modelo:

# Seja zero (0) uma tarefa fictícia que precede imediatamente a primeira tarefa e sucede imediatamente a última tarefa
# de uma seqüência de tarefas. A partir desses parâmetros e variáveis,
# é possível formular problemas com critérios distintos de otimização.

# Indices
# i = 0,........,I número de tarefas

# Parâmetros:
# p(i) = tempo d procesamento da tarefa i
# d(i) = data de entrega da tarefa i
# s(i) = tempo de preparação para a tarefa i
# M = número grande

# variáveis:
# x(i,j) = 1 se a atividade i precede imediatamente a tarefa j e 0 para o contrário
# C(i) = instante de término de processamento da tarefa i



# Modelo 1.1 = minimização do fluxo total com tempo de preparação independente (setup)
#
# |função objetivo:
# |
# |         I
# | Min z = ∑ C(i)
# |        i=1
# |
# |sujeito a:
# |
# |    I
# |    ∑    x(i,j) = 1                                      ∀ j = 0......I
# | i=0,i≠j
# |
# |    I
# |    ∑    x(i,j) = 1                                      ∀ i = 0......I
# | j=0,j≠i
# |
# |
# | C(j) >= C(i) - M + (s(j) + p(j) + M) * x(i,j)           ∀ i = 0.......I, j = 1.......I
# |
# | C(i) >= 0                                               ∀ i = 0.......I
# | C(0)  = 0
# |
# #------------------------------------------------------------------------------------------
# | Dados da instância:
# | Sem instância para testes.
# #------------------------------------------------------------------------------------------

using JuMP, Cbc, VegaLite, DataFrames
# sequenciamento em máquina única no modelo 1.1
smu11 = Model(with_optimizer(Cbc.Optimizer))

# Parâmetros
p = [64 53 63 99 189 44 50 22] # tempo de procesamento
d = [100 70 150 601 118 590 107 180] # data de entrega
s = [2 2 2 2 1 1 1 2] # tempo de preparação
M = 2000 # número suficientemente grande

# Indices
I = collect(0:length(p)) # número total de atividades (jobs)
N = collect(1:length(p))

# variáveis
@variable(smu11, x[i in I,j in I], Bin)
@variable(smu11, C[i in I] >= 0)

# função objetivo
@objective(smu11, Min, sum(C[i] for i in N))

# restrições
@constraint(smu11, [j in I], sum(x[i,j] for i in I if i != j) == 1)
@constraint(smu11, [i in I], sum(x[i,j] for j in I if j != i) == 1)
@constraint(smu11, [i in I, j in N], C[j] >= C[i] - M + (s[j] + p[j] + M) * x[i,j])
@constraint(smu11, C[0] == 0)

# otimizando o modelo
optimize!(smu11)

# relatório de saída
if termination_status(smu11) == MOI.OPTIMAL
    a = fill(0.0,length(I),1)
    for i in N
        a[i] = value.(C[i])
    end
    resposta = sortslices([a I], dims = 1)
    resultado = round.(Int,objective_value(smu11))
    sequencia = resposta[:,2]
    println(" ")
    println("Solução ótima encontrada !")
    println(" ")
    println("Tempo do fluxo total de processamento = ",resultado," unidades de tempo")
    println(" ")
    println(" Sequência da programação = ", sequencia[2:end])
    seq = resposta[:,1]
    seqI = seq[1:end-1] # instante de início das atividades
    seqF = seq[2:end]   # instante de término das atividades

    df = DataFrame(atividade=sequencia[2:end], start = seqI, stop = seqF, tarefas = N, Recursos = "Máquina 1")

    # gráfico
    df |> @vlplot(
        :bar,
        title = "Resultado da função objetivo = $(resultado) unidades de tempo",
        y="Recursos:o", x="start:q", x2="stop:q", width = 630, height = 120, color = "tarefas:n"
    )
else
    println("Solução ótima não encontrada !")
end
