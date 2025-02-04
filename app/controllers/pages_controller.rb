class PagesController < ApplicationController
    def home
      @clubs = Club.all
    #   @duels = Duel.where('duels.active = true AND duels.rival_id IS NOT ?', nil)
      # @rivals = club.joins(:rivals).where("'id' = #{@rivals.map {|key, value| [ key.rival_id]} }")
    end
  
end
