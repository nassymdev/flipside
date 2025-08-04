-- this joker just for testing the factorial mult function
SMODS.Joker {
    key = "test_subject",
    atlas = "enhancementsseif",
    pos = { x = 0, y = 0},
    rarity = 1,
    blueprint_compat = true,
    cost = 5,
    loc_txt = {
        name = "",
        text = { "" }
    },
    config = { extra = { mult=15 } }, 
    unlocked = true,
    discovered = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea==G.play and SMODS.has_enhancement(context.other_card,"m_aao_p_flip_card") == true then
            return { 
                xmult_message = { message = tostring(card.ability.extra.mult).."!", colour = G.C.GREEN },
                xmult = sxeif.fact(card.ability.extra.mult),
                message_card=card,
            }    
        end
    end,
}
