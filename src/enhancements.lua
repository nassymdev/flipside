--testing the flip mechanic + needs a resprite
SMODS.Enhancement {
    key = "flip_card",
    pools = { Card = true },
    atlas="enhancementsseif",
    loc_txt = {
        name = "flipside",
        text={ "this card {X:tarot}perceives","what lies beyond your","{X:tarot}vision"}
    },
    pos={x=0,y=0},
    set_badges = function(self, card, badges)
        badges[#badges+1] = create_badge("Flip", G.C.BLUE, G.C.WHITE, 0.9)
    end,
    update = function(self, card, dt)
        if not card.FlipTag then
            card._absolute_deck = true 
            card.FlipTag = { added = true }
        end
    end
}