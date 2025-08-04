-- this one for adding the flip button to 1 joker or , card 
-- this will probably be scrapped since i coded it into the edition
SMODS.Consumable {
    key = 'lovers',
    set = 'Spectral',
    pos = { x = 6, y = 0 },
    config = { max_highlighted = 1 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('tarot1')
                card:juice_up(0.3, 0.5)
                return true
            end
        }))

        local target = nil
        local is_joker = false

        if G.hand and #G.hand.highlighted == 1 then
            target = G.hand.highlighted[1]
        elseif G.jokers and G.jokers.highlighted and #G.jokers.highlighted == 1 then
            target = G.jokers.highlighted[1]
            is_joker = true
        end

        if target then
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.15,
                func = function()
                    if not is_joker then target:flip() end
                    play_sound(is_joker and 'tarot1' or 'card1', 1.0)
                    target:juice_up(0.3, 0.3)
                    return true
                end
            }))

            delay(0.2)

            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.1,
                func = function()
                    target._absolute_deck = true
                    return true
                end
            }))
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.2,
                func = function()
                    if G.hand then G.hand:unhighlight_all() end
                    if G.jokers then 
                        for _, j in ipairs(G.jokers.cards) do
                            if j.stop_highlight then j:stop_highlight() end
                        end
                    end
                    sxeif.update_flip_buttons()
                    return true
                end
            }))
        end

        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.2,
            func = function()
                if G.hand then G.hand:unhighlight_all() end
                return true
            end
        }))
        
        delay(0.5)
    end,
    can_use = function(self, card)
        local hand_highlighted = G.hand and #G.hand.highlighted > 0
        local jokers_highlighted = G.jokers and G.jokers.highlighted and #G.jokers.highlighted > 0
        
        -- Only allow use when exactly 1 card OR 1 joker is highlighted
        return ((hand_highlighted and #G.hand.highlighted == 1) or 
                (jokers_highlighted and #G.jokers.highlighted == 1)) and
               not (hand_highlighted and jokers_highlighted)
    end
}
