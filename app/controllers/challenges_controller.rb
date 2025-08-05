class ChallengesController < ApplicationController
    before_action :set_challenge, only: [:show, :accept, :reject]
  
    # POST /challenges
    # Crea el challenge (el "desafiante" reta al "desafiable")
    def create
      challenger_duel = Duel.find(params[:challenger_duel_id])
      challengee_duel = Duel.find(params[:challengee_duel_id])
    
      # Verificar si ya existe challenge con esos dos duelos
      existing = Challenge.find_by(
        challenger_duel_id: challenger_duel.id,
        challengee_duel_id: challengee_duel.id
      )
    
      if existing
        redirect_to duel_path(challenger_duel), alert: "Ya enviaste un reto a este duelo."
        return
      end
    
      @challenge = Challenge.new(
        challenger_duel_id: challenger_duel.id,
        challengee_duel_id: challengee_duel.id
      )
    
      if @challenge.save
        challengee_admin = find_admin_for_duel(challengee_duel)
    
        home_team = challenger_duel.home_team
        challenger_name = home_team&.club&.name || home_team&.clan&.name || "Un equipo"
        duel_type = challenger_duel.duel_type.capitalize
        starts_at = I18n.l(challenger_duel.starts_at, format: :short)
        
        Notification.create!(
          recipient: challengee_admin,
          sender: current_user,
          message: "#{challenger_name} te ha desafiado a un duelo #{duel_type} que inicia #{starts_at} - #{challenger_duel.id}",
          category: :challenge,
          notifiable: @challenge
        )
    
        redirect_to duel_path(@challenge.challenger_duel), notice: "Se envió el reto al duelo."
      else
        flash.now[:alert] = @challenge.errors.full_messages.to_sentence
        render :new
      end
    end
    
  
    # GET /challenges/:id
    def show
      # Vista opcional para mostrar info del Challenge
    end
  
      # PATCH /challenges/:id/accept
  def accept
    if @challenge.update(status: :accepted)
      if DuelMerger.call(@challenge)
        redirect_to @challenge.challenger_duel,
                    notice: "Reto aceptado. Los duelos se han fusionado."
      else
        @challenge.update!(status: :pending) # Revertir si falla
        redirect_to @challenge.challenger_duel,
                    alert: "Error al fusionar los duelos. Intenta nuevamente."
      end
    else
      redirect_to @challenge.challenger_duel,
                  alert: "No se pudo aceptar el reto."
    end
  end
  
    # PATCH /challenges/:id/reject
    def reject
      if @challenge.update(status: :rejected)
        # Siguen independientes
        # Podrías notificar al desafiante aquí
        redirect_to @challenge.challengee_duel,
                    notice: "Reto rechazado. Cada duelo permanece independiente."
      else
        redirect_to @challenge.challengee_duel,
                    alert: "No se pudo rechazar el reto."
      end
    end
  
    private
    
        def set_challenge
        @challenge = Challenge.find(params[:id])  # params[:id] es el UUID/string del Challenge
        end
    
            # Fusión de duelos si el challenge es aceptado
    def merge_duels(challenge)
      # DEPRECATED: Usar DuelMerger.call(challenge) en su lugar
      DuelMerger.call(challenge)
    end
        def find_admin_for_duel(duel)
            team = duel.home_team
            return nil unless team
            User.find_by(id: team.captain_id) # o tu lógica real de admin
        end
  end
  