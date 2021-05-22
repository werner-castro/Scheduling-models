# gráfico de gantt para máquinas paralelas

using Plots, JuMP, PlotThemes; theme(:juno)
ENV["GKSwstype"] = "100"
function gantt(s::AbstractArray, T::Int64, obj, g::String)
    if typeof(obj) == Model
        sol = objective_value(obj)
        J = size(s,2)
    else
        sol = obj
        J = size(s,1)
    end
    rectangle(w, h, x, y) = Plots.Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])
    Plots.plot(rectangle(T,J+1,0,0), opacity=.5, color = "black")
    Maq = ["Máquina $(i)" for i in 1:J]
    Plots.vline!([sol], color = "red")
    xlabel!("Tempo de processamento (min)")
    yticks!([1:J...], Maq)
    # xaxis!([1:T...])
    title!("Gráfico de gantt \n Makespan = $(sol) min \n Tempo total disponível p/ máquina = $(T) min \n")
    if typeof(obj) == Model
        s = transpose(s)
    end
    m,n = size(s)
    if g == "s"
        let plt = []
            Plots.plot(rectangle(T,J+1,0,0), opacity=.5, color = "black", size = (800, 600))
            anim = @animate for j = 1:n
                for i = 1:m
                    if j == 1 && s[i,j] > 0
                        plt = Plots.plot!(rectangle(s[i,j], 0.75, 0, [i-0.35]), opacity=.5, color = [i], legend = false)
                        plt = annotate!([s[i,j]/2], [i], text("$(j)", 6, color = "white"))
                    elseif j > 1 && s[i,j] > 0
                        plt = Plots.plot!(rectangle(s[i,j], 0.75, sum(s[i,1:j-1]), [i-0.35]), opacity=.5, color = [j], legend = false)
                        plt = annotate!([sum(s[i,1:j-1]) + s[i,j]/2], [i], text("$(j)", 6, color = "white"))
                    else
                        continue
                    end
                end
            end
            gif(anim, "/tmp/anim_fps15.gif", fps = 5)
        end
    else
        let plt = []
            for j = 1:n
                for i = 1:m
                    if j == 1 && s[i,j] > 0
                        plt = Plots.plot!(rectangle(s[i,j], 0.75, 0, [i-0.35]), opacity=.5, color = [i], legend = false, size = (800, 600))
                        plt = annotate!([s[i,j]/2], [i], text("$(j)", 8, color = "white"))
                    elseif j > 1 && s[i,j] > 0
                        plt = Plots.plot!(rectangle(s[i,j], 0.75, sum(s[i,1:j-1]), [i-0.35]), opacity=.5, color = [j], legend = false)
                        plt = annotate!([sum(s[i,1:j-1]) + s[i,j]/2], [i], text("$(j)", 8, color = "white"))
                    else
                        continue
                    end
                end
            end
            plt = vline!([sol], color = "grey")
            return plt
        end
    end
end
