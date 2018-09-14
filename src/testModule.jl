module testModule

using Distributed

export testfun, mygemv!, mygemv_minus!, myger!

myid2() = myid()

function testfun()
    x = @distributed (+) for i in 1:100
        myid2()
    end
    return x
end

function mygemv!(y::AbstractVector, A::AbstractMatrix, x::AbstractVector)
    y .+= A*x
end

function mygemv!(y::AbstractVector, alpha::Number, A::AbstractMatrix, x::AbstractVector)
    y .+= alpha .* A*x
end

function mygemv_minus!(y::AbstractVector, A::AbstractMatrix, x::AbstractVector)
    y .-= A*x
end


function myger!(A::AbstractMatrix, x::AbstractVector, y::AbstractVector)
    size(A,1) == size(A,2) == length(x) == length(y) || throw(DimensionMismatch())
    A .+= x .* transpose(y)
end

function myger!(A::AbstractMatrix, alpha::Number, x::AbstractVector, y::AbstractVector)
    size(A,1) == size(A,2) == length(x) == length(y) || throw(DimensionMismatch())
    A .+= alpha .* x .* transpose(y)
end

end # module end
