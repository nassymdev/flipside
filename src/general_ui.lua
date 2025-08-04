-- cardarea
sxeif.create_UIBox_extra_deck = function()
    local t = {
        n = G.UIT.ROOT,
        config = { 
            align = 'cm', 
            r = 0.1, 
            colour = G.C.CLEAR, 
            padding = 0.2 
        },
        nodes = {
            {
                n = G.UIT.O,
                config = {
                    object = sxeif.extra_deck_area,
                    draw_layer = 1
                }
            },
        }
    }
    return t
end
local game_start_run_ref = Game.start_run
function Game:start_run(args)
    self.abyss_field_spell_area = CardArea(
        0, 0,
        self.CARD_W * 1.9,
        self.CARD_H * 0.95,
        {
            card_limit = 1,
            type = 'extra_deck',
            highlight_limit = 1,
        }
    )
    sxeif.field_spell_area = self.abyss_field_spell_area
    
    self.abyss_extra_deck_area = CardArea(
        0, 0,
        self.CARD_W * 4.95,
        self.CARD_H * 0.95,
        {
            card_limit = 5,
            type = 'extra_deck',
            highlight_limit = 1,
        }
    )
    sxeif.extra_deck_area = self.abyss_extra_deck_area


    game_start_run_ref(self, args)

    sxeif.extra_deck_area.config.card_limit = (self.GAME and self.GAME.modifiers and self.GAME.modifiers["abyss_extra_deck_slots"]) or 5


    self.abyss_extra_deck = UIBox {
        definition = sxeif.create_UIBox_extra_deck(),
        config = {
            align = 'cmi', 
            offset = { x = 2.4, y = -5 }, 
            major = self.jokers, 
            bond = 'Weak'
        }
    }
    self.abyss_extra_deck.states.visible = false
    G.GAME.abyss_show_extra_deck = G.GAME.abyss_show_extra_deck or false


    sxeif.extra_deck_open = false
    sxeif.extra_deck_forced = false


    if G.consumeables and sxeif.field_spell_area then
        sxeif.field_spell_area.T.x = (G.consumeables.T.x or 0) + 2.3
        sxeif.field_spell_area.T.y = (G.consumeables.T.y or 0) + 3
    end


    if sxeif.hide_ui and sxeif.field_spell_area then 
        sxeif.field_spell_area.states.visible = false 
    end
end

-- flip mechanic
function sxeif.flip(target)
    if target.flip then
        target:flip()
    end
    if target.facing=="back" then
        ease_background_colour({ new_colour = G.C.PURPLE, special_colour = G.C.BLACK})
    else
        ease_background_colour({ new_colour = G.C.RED, special_colour = G.C.BLACK})
    end
    target:juice_up(0.3, 0.3)
    play_sound(target.flip and 'generic1' or 'tarot1')

    if G.FUNCS.create_floating_text then
        local name = target.ability and target.ability.name or 
                    (target.config and target.config.key) or 
                    (target.ability and "Joker") or 
                    "Card"
        G.FUNCS.create_floating_text({
            text = "Flipped " .. name,
            x = target.T.x or 0,
            y = target.T.y or 0,
            colour = G.C.L_RED
        })
    end
end

-- Updated UI and highlight handling
if not G._absolute_highlight_hooked then
    G._absolute_highlight_hooked = true
    
    local original_card_highlight = Card.highlight
    
    function Card:highlight(is_highlighted)
        original_card_highlight(self, is_highlighted)
        if not is_highlighted and self._absolute_deck then
            if self.children.abs_button then
                self.children.abs_button:remove()
                self.children.abs_button = nil
            end
            if self.children.abs_flip_all_button then
                self.children.abs_flip_all_button:remove()
                self.children.abs_flip_all_button = nil
            end
        end
        if self._absolute_deck then
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.01,
                func = function()
                    sxeif.update_flip_buttons()
                    return true
                end
            }))
        end
    end

    if G.jokers then
        for _, joker in ipairs(G.jokers.cards) do
            local original_joker_highlight = joker.highlight
            
            function joker:highlight(is_highlighted)
                if original_joker_highlight then
                    original_joker_highlight(self, is_highlighted)
                end
                if self._absolute_deck then
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        delay = 0.01,
                        func = function()
                            sxeif.update_flip_buttons()
                            return true
                        end
                    }))
                end
            end
        end
    end

    function sxeif.update_flip_buttons()
    -- Clear ALL buttons first (both flip and flip all)
        for _, card in ipairs(G.playing_cards) do
            if card.children.abs_button then 
                card.children.abs_button:remove()
                card.children.abs_button = nil
            end
            if card.children.abs_flip_all_button then
                card.children.abs_flip_all_button:remove()
                card.children.abs_flip_all_button = nil
            end
        end
        
        if G.jokers then
            for _, joker in ipairs(G.jokers.cards) do
                if joker.children.abs_button then
                    joker.children.abs_button:remove()
                    joker.children.abs_button = nil
                end
            end
        end

        -- Only proceed if we have highlighted flip-enabled cards
        local highlighted = {}
        
        -- Check cards
        for _, card in ipairs(G.playing_cards) do
            if card.highlighted and card._absolute_deck then
                table.insert(highlighted, {item = card, is_joker = false})
            end
        end
        
        -- Check jokers
        if G.jokers then
            for _, joker in ipairs(G.jokers.cards) do
                if joker.highlighted and joker._absolute_deck then
                    table.insert(highlighted, {item = joker, is_joker = true})
                end
            end
        end

        -- Only add buttons if we have exactly what we want
        if #highlighted > 0 then
            table.sort(highlighted, function(a, b) return a.item.T.x > b.item.T.x end)
            local rightmost = highlighted[1].item
            
            -- Only show Flip All if we have multiple flip-enabled cards (not jokers)
            if #highlighted > 1 and not highlighted[1].is_joker then
                rightmost.children.abs_flip_all_button = sxeif.create_flip_button(
                    "Flip All", 'abs_flip_all', rightmost, false)
            else
                rightmost.children.abs_button = sxeif.create_flip_button(
                    "Flip", 'abs_flip', rightmost, highlighted[1].is_joker)
            end
        end
    end

    function sxeif.create_flip_button(text, func, target, is_joker)
        return UIBox {
            definition = {
                n = G.UIT.ROOT,
                config = {
                    r = 0.1,
                    padding = 0.3,
                    align = "cm",
                    hover = true,
                    shadow = true,
                    colour = is_joker and G.C.PURPLE or G.C.RED,
                    button = func,
                    ref_table = target
                },
                nodes = {
                    {
                        n = G.UIT.T,
                        config = {
                            text = text,
                            scale = 0.5,
                            colour = G.C.UI.TEXT_LIGHT
                        }
                    }
                }
            },
            config = {
                align = "r",
                offset = {x = 0.5, y = 0},
                parent = target
            }
        }
    end
end

-- Flip functions
G.FUNCS.abs_flip = function(ref)
    local target = ref.config.ref_table
    if not target then return end

    G.E_MANAGER:add_event(Event({
        func = function()
            sxeif.flip(target)
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
                    return true
                end
            }))
            return true
        end
    }))
end

G.FUNCS.abs_flip_all = function(ref)
    local rightmost = ref.config.ref_table
    if not rightmost then return end

    G.E_MANAGER:add_event(Event({
        func = function()
            local cards_to_flip = {}
            for _, card in ipairs(G.playing_cards) do
                if card.highlighted and card._absolute_deck then
                    table.insert(cards_to_flip, card)
                end
            end

            for i, card in ipairs(cards_to_flip) do
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.1 * i,
                    func = function()
                        sxeif.flip(card)
                        return true
                    end
                }))
            end

            if G.FUNCS.create_floating_text and #cards_to_flip > 0 then
                G.FUNCS.create_floating_text({
                    text = "Flipped " .. #cards_to_flip .. " Cards",
                    x = rightmost.T.x or 0,
                    y = rightmost.T.y or 0,
                    colour = G.C.L_RED
                })
            end

            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.2 + (0.1 * #cards_to_flip),
                func = function()
                    if G.hand then G.hand:unhighlight_all() end
                    if G.jokers then 
                        for _, j in ipairs(G.jokers.cards) do
                            if j.stop_highlight then j:stop_highlight() end
                        end
                    end
                    return true
                end
            }))
            return true
        end
    }))
end

-- Floating text handler
function G.FUNCS.create_floating_text(params)
    if not G.OVERLAY or not FloatingText then return end
    G.OVERLAY:add_child(FloatingText({
        text = params.text or "",
        x = params.x or 0,
        y = params.y or 0,
        colour = params.colour or G.C.WHITE,
        duration = 1.0,
        size = 14
    }))
end

