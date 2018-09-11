module testModule

using Distributed

myid2 = myid()

function testfun()
    x = @distributed (+) for i in 1:1
        myid2()
    end
    return x
end

end # module end
