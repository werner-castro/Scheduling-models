
using Plots, Logging, PlotThemes; theme(:juno)

# gráfico de gantt para problemas de scheduling (agendamento) em máquina única e flowshop usando heuristicas

# Modelagem: Carlos Werner Ribeiro de Castro

# parâmetros da função:

# a = matriz de tempos de processamento, onde as linhas representam as maquinas e as colunas representam as tarefas
# ordem = Sequencia gerada (vetor de inteiros)
# anime = passe a string "s" para o gráfico ser animado e qualquer outra para o gráfico estático
# v = numero de frames p/ segundo na animação (número inteiro)

function gantt(a::AbstractMatrix, ordem::Vector{Int64}; v::Int64 = 10, anime::String = "n")
    ENV["GKSwstype"] = "100"
    plt = []
    m,n = size(a)
    b = fill(0,m,n)
    γ = fill(0,m,n)
    for j in 1:n
        γ[1:end,j] = a[1:end,ordem[j]]
    end
    b[1,1] = γ[1,1]
    for i in 2:m, j in 2:n
        b[1,j] = b[1,j-1] + γ[1,j]
        b[i,1] = b[i-1,1] + γ[i,1]
    end
    for i in 2:m, j in 2:n
        if b[i,j-1] > b[i-1,j]
            b[i,j] = b[i,j-1] + γ[i,j]
        else
            b[i,j] = b[i-1,j] + γ[i,j]
        end
    end
    rectangle(w, h, x, y) = Plots.Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])
    Plots.plot(rectangle(b[end,end],m+1,0,0), opacity=.4, color = "black", size = (750, 500))
    xlabel!("Tempo de processamento (min)")
    # xaxis!([1:b[end,end]...])
    maq = ["Máquina $(i)" for i in 1:m]
    yticks!([1:m...], maq)
    title!("Modelo: Flow shop \n Makespan = $(b[end,end]) min")
    a = a[1:end,ordem]
    # gráfico animado
    if anime == "s"
        anim = @animate for j = 1:n, i = 1:m
            Plots.plot!(rectangle(a[i,j], 0.75, (b[i,j] - a[i,j]), [i-0.35]), opacity=.5, color = [ordem[j]], legend = false)
            annotate!([(b[i,j] - (a[i,j]/2))], [i], text("$(ordem[j])", 8, color = "white"))
            # display(plt)
        end
        return gif(anim, "/tmp/anim_fps30.gif", fps = v)
    else # gráfico estático
        for j = 1:n, i = 1:m
            plt = Plots.plot!(rectangle(a[i,j], 0.75, (b[i,j] - a[i,j]), [i-0.35]), opacity=.5, color = [ordem[j]], legend = false)
            plt = annotate!([(b[i,j] - (a[i,j])/2)], [i], text("$(ordem[j])", 8, color = "white"))
        end
        return plt
    end
end

# Função para coleta do vetor com a ordem de sequenciamento
function sequence(tempos::Matrix{Float64})
    order = [i for i = 1:N, j = 1:N if tempos[i,j] > 0.99]
    return order
end
