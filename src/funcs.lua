-- simple function for factorial mult


function sxeif.fact(x)
    if x==0 or x==1 then 
        return 1
    else
        return x*sxeif.fact(x-1)
    end

end

function sxeif.increase_object_value(object, operation, val, include, exclude)
    include = include or {}
    exclude = exclude or {}
    local function can_pass(i)
        if exclude["all"] and include[i] then
            return true
        end
        if exclude[i] or exclude["all"] then
            return false
        end
        return true
    end
    local extra = object.ability.extra
    local allowed = {}
    local extra_is_nil = false
    if extra == nil or type(extra) == "number" then
        extra_is_nil = true
        local key = object.config.center_key
        local center = G.P_CENTERS[key]
        if center.config.extra and type(center.config.extra) == "table" then
            for i,v in pairs(center.config.extra) do
                allowed[i] = true
            end
        else
            for i,v in pairs(center.config) do
                allowed[i] = true
            end
        end
    end
    local function multiply(i)
    extra[i]=extra[i]*val
    end
    local function sub(i)
    extra[i]=extra[i]-val
    end
    local function add(i)
    extra[i]=extra[i]+val
    end
    local function pow(i)
    extra[i]=extra[i]^val
    end
    local function rad(i)
    extra[i]=math.rad(val)
    end
    local function div(i)
        extra[i]=extra[i]/val
    end
    local function custom(i)
        extra[i]=operation(object,extra,i)
    end
    if extra_is_nil then extra = object.ability end
    for i,v in pairs(extra) do
        if type(v) == "number" or is_number(v) then
            if extra_is_nil == true and allowed[i] == true or not extra_is_nil then
            if can_pass(i) then
            if type(operation) == "function" then custom(i) end
            if operation == "*" then multiply(i) end
            if operation == "-" then sub(i) end
            if operation == "+" then add(i) end
            if operation == "^" then pow(i) end
            if operation == "rad" then rad(i) end
            if operation == "div" then div(i) end

                end
            end
        end
    end
end
