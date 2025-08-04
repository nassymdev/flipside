-- for drawing shaders and sprites on the back of the cards



SMODS.DrawStep {
    key        = 'back',
    order      = 90,
    func       = function(self)
        if self.area and self.area.config.type == 'deck' then
            self.children.back:draw(G.C.WHITE)
            return
        end

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

            self.children.back:draw_shader('aao_p_delta')
            if not sxeif.delta_overlay_sprite then
                sxeif.delta_overlay_sprite = Sprite(
                    0, 0,
                    G.CARD_W, G.CARD_H,
                    G.ASSET_ATLAS['aao_p_soul'],
                    { x = 0, y = 0 }
                )
            end

            sxeif.delta_overlay_sprite.role.draw_major = self
            sxeif.delta_overlay_sprite:draw_shader(
                'dissolve',
                nil, nil, nil,
                self.children.back
            )
        else
            self.children.back:draw_shader('dissolve')
        end
    end,
    conditions = {
        vortex = false,
        facing = 'back',
    },
}

