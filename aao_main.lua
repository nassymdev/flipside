SMODS.Atlas{
    key="enhancementsseif",
    path="flipside.png",
    px=71,
    py=95,
}



-- Omega Deck definition
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

-- Enhancement: Adds flip ability with a badge and on-draw flipping
SMODS.Enhancement {
    key = "flip_card",
    pools = { Card = true },
    atlas="enhancementsseif",
    -- ill make a localization file later
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
            -- this adds the flip mechanic
            card._absolute_deck = true 
            card.FlipTag = { added = true }

        end
    end
}


-- Shared flip logic 
-- yes i felt like it 
sxeif = sxeif or {}

function sxeif.flip(card)
    card:flip()
    card:juice_up(0.3, 0.3)
    play_sound('generic1')

    if G.FUNCS.create_floating_text then
        G.FUNCS.create_floating_text({
            text = "Flipped " .. (card.ability and card.ability.name or "Card"),
            x = card.T.x or 0,
            y = card.T.y or 0,
            colour = G.C.L_RED
        })
    end
end

-- ui logic
if not G._absolute_highlight_hooked then
    G._absolute_highlight_hooked = true
    local original_card_highlight = Card.highlight

    function Card:highlight(is_highlighted)
        original_card_highlight(self, is_highlighted)

        if self._absolute_deck then
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.01,
                func = function()
                    self:update_flip_buttons()
                    return true
                end
            }))
        end
    end
    -- dynamic button logic
    function Card:update_flip_buttons()
        for _, card in ipairs(G.playing_cards) do
            if card._absolute_deck then
                if card.children.abs_button then
                    card.children.abs_button:remove()
                    card.children.abs_button = nil
                end
                if card.children.abs_flip_all_button then
                    card.children.abs_flip_all_button:remove()
                    card.children.abs_flip_all_button = nil
                end
            end
        end

        local highlighted = {}
        for _, card in ipairs(G.playing_cards) do
            if card.highlighted and card._absolute_deck then
                table.insert(highlighted, card)
            end
        end

        if #highlighted > 0 then
            table.sort(highlighted, function(a, b) return a.T.x > b.T.x end)
            local rightmost = highlighted[1]

            if #highlighted > 1 then
                rightmost.children.abs_flip_all_button = self:create_flip_button("Flip All", 'abs_flip_all', rightmost)
            else
                rightmost.children.abs_button = self:create_flip_button("Flip", 'abs_flip', rightmost)
            end
        end
    end

    function Card:create_flip_button(text, func, target_card)
        return UIBox {
            definition = {
                n = G.UIT.ROOT,
                config = {
                    r = 0.1,
                    padding = 0.3,
                    align = "cm",
                    hover = true,
                    shadow = true,
                    colour = G.C.RED,
                    button = func,
                    ref_table = target_card
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
                offset = {
                    x = 0.5,
                    y = 0
                },
                parent = target_card
            }
        }
    end
end

-- Flip 
G.FUNCS.abs_flip = function(ref)
    local card = ref.config.ref_table
    if not card then return end

    G.E_MANAGER:add_event(Event({
        func = function()
            sxeif.flip(card)

            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.2,
                func = function()
                    if G.hand then G.hand:unhighlight_all() end
                    return true
                end
            }))
            return true
        end
    }))
end

-- Flip all
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
                    return true
                end
            }))

            return true
        end
    }))
end

-- text handler
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


function sxeif.fact(x)

    if x==0 or x==1 then 
        return 1
    else
        return x*sxeif.fact(x-1)
    end
end


SMODS.Joker {
    key = "test_subject",
    atlas = "enhancementsseif",
    pos = { x = 0, y = 0},
    rarity = 1,
    blueprint_compat = true,
    cost = 5,
    loc_txt = {
        name = "",
        text = {

            ""
        }
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
--   loc_vars = function(self, info_queue, card)
--        return { vars = { card.ability.extra.bul } }
--    end,
}

