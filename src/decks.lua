-- needs recoding



SMODS.Back{
    name = "delta Deck",
    key = "deltadeck",
    pos = {x = 0, y = 0},
    config = {polyglass = true},
    atlas="deltad",
    loc_txt = {
        name = "delta Deck",
        text ={
            "{X:purple,C:white}vision"
        }
    },
    apply = function()
        G.E_MANAGER:add_event(Event({
            func = function()
                for i = #G.playing_cards, 1, -1 do
                    G.playing_cards[i]:set_edition("e_aao_p_delta")
                end
                return true
            end
        }))
    end
}


-- also for testing just the buttons 

SMODS.Back {
    name = "Omega",
    key = "Omega",
    pos = { x = 0, y = 3 },
    config = { },
    loc_txt = {
        name = "Omega Deck",
        text = {
            "Adds flip enhancement to all cards."
        },
    },
    apply = function()
        G.E_MANAGER:add_event(Event({
            func = function()
                for _, card in ipairs(G.playing_cards) do
                    card._absolute_deck = true
                    card.enhancement = card.enhancement or {}
                    table.insert(card.enhancement, "m_aao_p_flip_card")
                end
                return true
            end
        }))
    end
}