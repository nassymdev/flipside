
-- the effect is just a placeholder for now

SMODS.Edition{
    key = "sword_params",
    shader = "aao_p_sword_params",
    loc_txt={
        name = "{X:black}Delta",
        text = {
            "{C:white,X:green}X#1#{} Mult if {X:tarot,C:white}blinded",
            "i'll change the effect later "
        }
    },
    config = {
        extra ={
            x_mult = 6,
        },
    },
    calculate =  function (self, card, context)
        card._absolute_deck=false
        if context.main_scoring and (context.cardarea == G.hand or context.cardarea == G.play) and card.facing=="back" then
            return {
                Xmult = card.edition.extra.x_mult
            }
        end
        if context.pre_joker and (context.cardarea == G.jokers)  and card.facing=="back" then
            return {
                Xmult = card.edition.extra.x_mult
            }
        end
    end,
    loc_vars = function (self, info_queue, card)
        return {
            vars = {
                self.config.extra.x_mult,
            }
        }
    end,
    in_shop = true,
    weight = 3,
}



SMODS.Edition{
    key = "delta",
    shader = "aao_p_delta",
    loc_txt={
        name = "{X:black}Delta",
        text = {
            "{C:white,X:green}X#1#{} Mult if {X:tarot,C:white}blinded",
            "i'll change the effect later "
        }
    },
    config = {
        extra ={
            x_mult = 6,
        },
    },
    calculate =  function (self, card, context)
        card._absolute_deck=true
        if context.main_scoring and (context.cardarea == G.hand or context.cardarea == G.play) and card.facing=="back" then
            return {
                Xmult = card.edition.extra.x_mult
            }
        end
        if context.pre_joker and (context.cardarea == G.jokers)  and card.facing=="back" then
            return {
                Xmult = card.edition.extra.x_mult
            }
        end
    end,
    loc_vars = function (self, info_queue, card)
        return {
            vars = {
                self.config.extra.x_mult,
            }
        }
    end,
    in_shop = true,
    weight = 3,
}




