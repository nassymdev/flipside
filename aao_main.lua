SMODS.Atlas{
    key="enhancementsseif",
    path="flipside.png",
    px=71,
    py=95,
}

-- Omega Deck definition (UNCHANGED)
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

-- Enhancement (UNCHANGED)
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

-- Updated flip logic
sxeif = sxeif or {}
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

        -- Only proceed if we have highlighted flip-enabled items
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

-- Floating text handler (UNCHANGED)
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

-- Factorial function (UNCHANGED)
function sxeif.fact(x)
    if x==0 or x==1 then 
        return 1
    else
        return x*sxeif.fact(x-1)
    end
end

-- Test Subject Joker (UNCHANGED)
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

-- Updated Lovers Consumable
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
                    sxeif.update_flip_buttons() -- Force button cleanup
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

SMODS.Shader{
    key = "delta",
    path = "delta.fs"
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
SMODS.DrawStep {
    key        = 'back',
    order      = 0,
    func       = function(self)
        -- base white background for decks
        if self.area and self.area.config.type == 'deck' then
            self.children.back:draw(G.C.WHITE)
            return
        end

        -- determine if we should use the “delta” styling
        local use_delta = false
        if self.config
           and self.config.edition
           and self.config.edition.key == 'delta'
        then
            use_delta = true
        elseif rawget(self, '_absolute_deck') then
            use_delta = true
        end

        if use_delta then
            -- 1) dissolve shader pass
            self.children.back:draw_shader('aao_p_delta')

            -- 2) overlay sprite pass (cached)
            if not sxeif.delta_overlay_sprite then
                sxeif.delta_overlay_sprite = Sprite(
                    0, 0,
                    G.CARD_W, G.CARD_H,
                    G.ASSET_ATLAS['aao_p_soul'],
                    { x = 0, y = 0 }
                )
            end

            -- bind it to this card’s draw order, then draw with dissolve
            sxeif.delta_overlay_sprite.role.draw_major = self
            sxeif.delta_overlay_sprite:draw_shader(
                'dissolve',
                nil, nil, nil,
                self.children.back
            )
        else
            -- fallback: normal back‑facing dissolve
            self.children.back:draw_shader('dissolve')
        end
    end,
    conditions = {
        vortex = false,
        facing = 'back',
    },
}
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
                    object = sxeif.extra_deck_area,  -- Changed from JoyousSpring
                    draw_layer = 1
                }
            },
        }
    }
    return t
end
local game_start_run_ref = Game.start_run
function Game:start_run(args)
    -- Initialize field spell area
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
    
    -- Initialize extra deck area
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

    -- Call original function
    game_start_run_ref(self, args)

    -- Set up extra deck limit from modifiers
    sxeif.extra_deck_area.config.card_limit = (self.GAME and self.GAME.modifiers and self.GAME.modifiers["abyss_extra_deck_slots"]) or 5

    -- Create UI box for extra deck
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

    -- Initialize state variables
    sxeif.extra_deck_open = false
    sxeif.extra_deck_forced = false

    -- Position field spell area safely
    if G.consumeables and sxeif.field_spell_area then
        sxeif.field_spell_area.T.x = (G.consumeables.T.x or 0) + 2.3
        sxeif.field_spell_area.T.y = (G.consumeables.T.y or 0) + 3
    end

    -- Handle UI visibility
    if sxeif.hide_ui and sxeif.field_spell_area then 
        sxeif.field_spell_area.states.visible = false 
    end
end


SMODS.Atlas {
    key = "soul",
    path = "heart.png",
    px = 71,
    py = 95
}
SMODS.Atlas {
    key = "deltad",
    path = "deltadeck.png",
    px = 71,
    py = 95
}
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