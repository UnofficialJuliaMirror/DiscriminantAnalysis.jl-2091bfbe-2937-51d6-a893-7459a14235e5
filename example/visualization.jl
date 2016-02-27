using DiscriminantAnalysis, Gadfly


### Helper functions ###

function rotationmatrix2D{T<:AbstractFloat}(θ::T)
    T[cos(θ) -sin(θ);
      sin(θ)  cos(θ)]
end

function boxmuller(n::Integer)  # Generates two normally distributed variables
    u1 = rand(n)
    u2 = rand(n)
    Z = Float64[(√(-2log(u1)) .* cos(2π*u2)) (√(-2log(u1)) .* sin(2π*u2))]
end

function boundary(model, xrange, yrange, is_quad::Bool = false)  # Create the decision boundary using Contour.jl 
    Z = hcat(vec(Float64[x for x in xrange, y in yrange]), 
             vec(Float64[y for x in xrange, y in yrange]))
    δ = DiscriminantAnalysis.discriminants(model, is_quad ? hcat(Z, Z.^2, Z[:,1] .* Z[:,2]) : Z)
    Z = reshape(δ[:,1] - δ[:,2], length(xrange), length(yrange))
    Contour.coordinates(Contour.contours(xrange, yrange, Z, 0.0)[1].lines[1])
end


### Sample Data ###

n = 250

Z1 = boxmuller(n)
σ1 = [0.5 2.0]
X1 = ((Z1 .* σ1) .- [0.0 4.25]) * rotationmatrix2D(π/4) 

Z2 = boxmuller(n)
σ2 = [3.0 1.5]
X2 = ((Z2 .* σ2) .+ [0.0 2.25]) * rotationmatrix2D(π/4)

X = vcat(X1,X2)
y = repeat([1,2], inner=[n])

xmin = minimum(X[:,1])
xmax = maximum(X[:,1])
ymin = minimum(X[:,2])
ymax = maximum(X[:,2])
aspect = (ymax-ymin)/(xmax-xmin)

m = 250  # Used for interpolating the decision boundary
xrange = linspace(xmin,xmax,m)
yrange = linspace(ymin,ymax,m)


### LDA & QDA Plots ###
for (obj, desc, is_quad) in ((:lda, "Linear Discriminant Analysis", false), 
                             (:qda, "Quadratic Discriminant Analyisis", false),
                             (:lda, "Quadratic Linear Discriminant Analysis", true))
    @eval begin
        model = ($obj)($is_quad ? hcat(X, X.^2, X[:,1] .* X[:,2]) : X, y)
        cx, cy = boundary(model, xrange, yrange, $is_quad)

        P = plot(
                x = vec(X[:,1]), 
                y = vec(X[:,2]),
                color = map(class -> "Class $class", y), 
                Geom.point,
                Scale.color_discrete_manual(colorant"red",colorant"blue"),
                Guide.XLabel("X Variable"),
                Guide.YLabel("Y Variable"),
                Guide.title($desc),
                Guide.colorkey(""),
                Coord.Cartesian(xmin=xmin, ymin=ymin, xmax=xmax, ymax=ymax)
            )
        L = layer(x=cx, y=cy, Geom.line(preserve_order=true),
                  Theme(default_color=colorant"black", line_width=.4mm))
        unshift!(P.layers,L[1])

        draw(PNG(($is_quad ? "q" : "") * $(string(obj)) * ".png", 6inch, (6*aspect)inch), P)
    end
end


### CDA Plot ###

model = cda(X, y)
C = vec(X * model.W)

P = plot(
    x = C, 
    color = map(class -> "Class $class", y), 
    Geom.histogram(bincount=100),
    Scale.color_discrete_manual(colorant"red",colorant"blue"),
    Guide.XLabel("Canonical Coordinate"),
    Guide.YLabel("Count"),
    Guide.title("Canonical Discriminant Analysis"),
    Guide.colorkey(""),
    Coord.Cartesian(xmin=minimum(C), xmax=maximum(C))
)

draw(PNG("cda.png", 6inch, 4inch), P)


### Using LDA to do QDA ###

#model = lda(hcat(X, X.^2), y)

