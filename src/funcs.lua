-- simple function for factorial mult


function sxeif.fact(x)
    if x==0 or x==1 then 
        return 1
    else
        return x*sxeif.fact(x-1)
    end
end