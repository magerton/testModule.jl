"""
    @GenGlobal

Declare expression `VARNAME` to be a global variable, export it, and generate an exported functions
`set_VARNAME!()` that sets the global and `get_VARNAME()` that gets the variable

# Example
```julia-repl
@GenGlobal myglob1 myglob2
#errors out myglob1
#errors out myglob2
set_myglob1(1.0)
set_myglob2(Matrix(1.0I,3,3))
myglob1
myglob2
```

See <https://stackoverflow.com/questions/31313040/julia-automatically-generate-functions-and-export-them>


TODO: do type annotation

"""
macro GenGlobal(globalnames::Symbol...)
    e = quote end  # start out with a blank quoted expression
    for varname in globalnames
        setname = Symbol("set_$(varname)!") # create function name
        getname = Symbol("get_$(varname)") # create function name

        # this next part creates another quoted expression, which are just the 2 statements
        # we want to add for this function... the export call and the function definition
        # note: wrap the variable in "esc" when you want to use a value from macro scope.
        #       If you forget the esc, it will look for a variable named "maximumfilter" in the
        #       calling scope, which will probably give an error (or worse, will be totally wrong
        #       and reference the wrong thing)
        blk = quote
            # declare variable to be global w/in module
            global $(esc(varname))

            # export set_ and get_
            export $(esc(setname)), $(esc(getname))

            # set
            function $(esc(setname))(x)
                global $(esc(varname))
                $(esc(varname)) = x
                return nothing
            end

            # get
            function $(esc(getname))()
                return $(esc(varname))
            end
        end

        # an "Expr" object is just a tree... do "dump(e)" or "dump(blk)" to see it
        # the "args" of the blk expression are the export and method definition... we can
        # just append the vector to the end of the "e" args
        append!(e.args, blk.args)
        # append!(e.args, blk2.args)
    end

    # macros return expression objects that get evaluated in the caller's scope
    e
end
