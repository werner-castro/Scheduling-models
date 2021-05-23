
using Plots, PlotThemes; theme(:juno)

# gráfico de gantt para problemas de scheduling (agendamento) em máquina única

function gantt(a::AbstractMatrix, ordem::Vector{Int64}, obj::Model, anime::String)
    obj = objective_value(obj)
    plt = []
    m,n = size(a)
    rectangle(w, h, x, y) = Plots.Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])
    Plots.plot(rectangle(sum(a[1:end]),m+1,0,0), opacity=.5, color = "black", size = (800, 650))
    # tarefas = ["Job $(i)" for i in 1:4]
    xlabel!("Tempo de processamento (min)")
    yaxis!([1:m...])
    title!("Gráfico de gantt \n Makespan = $(obj) min")
    a = a[1:end,ordem]
    
    # gráfico animado
    if anime == "s"
        anim = @animate for j = 1:n, i = 1
            if j == 1
                Plots.plot!(rectangle(a[i,j], 0.75, 0, [i-0.35]), opacity=.5, color = [seq[j]], legend = false)
                annotate!([a[i,j]/2], [i], text("$(ordem[j])", color = "white"))
            else
                Plots.plot!(rectangle(a[i,j], 0.75, sum(a[1,1:j-1]), [i-0.35]), opacity=.5, color = [ordem[j]], legend = false)
                annotate!([sum(a[1,1:j-1]) + a[i,j]/2], [i], text("j $(ordem[j])", 8, color = "white"))
                Plots.plot!(yticks!([1], ["Máquina 1"]))
                # Plots.plot!(legend=:outerright)
            end
            # display(plt)
        end
        gif(anim, "/tmp/anim_fps30.gif", fps = 2)
    # gráfico estático
    else
        for j = 1:n, i = 1:m
            plt = Plots.plot!(rectangle(a[i,j], 0.75, sum(a[1,1:j-1]), [i-0.35]), opacity=.5, color = [ordem[j]], legend = false)
            plt = annotate!([sum(a[1,1:j-1]) + a[i,j]/2], [i], text("j $(ordem[j])", 8, color = "white"))
            plt = Plots.plot!(yticks!([1], ["Máquina 1"]))
            # Plots.plot!(legend=:outerright)
        end
        return plt
    end
end
