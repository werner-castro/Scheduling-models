
using Plots, Logging, PlotThemes; theme(:juno)

# gráfico de gantt para problemas de scheduling (agendamento) em jobshop

# Modelagem: Carlos Werner Ribeiro de Castro

# parâmetros da função:

# a = matriz de tempos de processamento (duração das tarefas), onde as linhas representam as maquinas e as colunas representam as tarefas
# b = matriz com os tempos processados (instantes de término)
# obj = valor da função objetivo do modelo
# tempos = Sequencias geradas (matriz de inteiros)
# anime = passe a string "s" para o gráfico ser animado e qualquer outra para o gráfico estático
# v = numero de frames p/ segundo na animação (número inteiro)

function gantt(a::AbstractMatrix, b::AbstractMatrix, tempos::AbstractMatrix, obj::Number, v::Int64 = 10, anime::String = "n")
    plt = []
    m,n = size(a)
    rectangle(w, h, x, y) = Plots.Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])
    Plots.plot(rectangle(obj,m+1,0,0), opacity=.3, color = "black", size = (750, 500))
    xlabel!("Tempo de processamento (min)")
    # xaxis!([0:obj...])
    maq = ["Máquina $(i)" for i in 1:m]
    yticks!([1:m...], maq)
    title!("Modelo: Job shop \n Makespan = $(obj) min")
    # gráfico animado
    if anime == "s"
        anim = @animate for i = 1:m
            a[i,:] = a[i,tempos[i,:]]
            b[i,:] = b[i,tempos[i,:]]
            for j = 1:n
                plt = Plots.plot!(rectangle(a[i,j], 0.75, (b[i,j] - a[i,j]), [i-0.35]), opacity=.5, color = [tempos[i,j]], legend = false)
                plt = annotate!([(b[i,j] - (a[i,j]/2))], [i], text("J $(tempos[i,j])", 8, color = "white"))
                # display(plt)
            end
        end
        return gif(anim, "/tmp/anim_fps30.gif", fps = v)
    else # gráfico estático
        for i = 1:m
            a[i,:] = a[i,tempos[i,:]]
            b[i,:] = b[i,tempos[i,:]]
            for j = 1:n
                plt = Plots.plot!(rectangle(a[i,j], 0.75, (b[i,j] - a[i,j]), [i-0.35]), opacity=.5, color = [tempos[i,j]], legend = false)
                plt = annotate!([(b[i,j] - (a[i,j])/2)], [i], text("J $(tempos[i,j])", 8, color = "white"))
            end
        end
        return plt
    end
end
