class ClansController < ApplicationController
  before_action :set_clan, only: [:show, :edit, :update, :destroy, :join]
  before_action :authenticate_user!, except: [:index, :show]

  def index
    @clans = Clan.all
  end

  def show
    @members = @clan.memberships.includes(:user).where(status: :approved).map(&:user)
    @membership = @clan.memberships.find_by(user: current_user) if user_signed_in?
    @is_admin = @clan.admins.exists?(user_id: current_user.id)
  end

  def new
    @clan = Clan.new
  end

  def create
    @clan = Clan.new(clan_params.except(:avatar))
    @clan.king = current_user

    if @clan.save
      @clan.avatar.attach(params[:clan][:avatar]) if params[:clan][:avatar].present?

      Admin.create!(
        user_id: current_user.id,
        clan_id: @clan.id,
        level: 2 # king
      )

      redirect_to @clan, notice: 'Clan creado exitosamente.'
    else
      flash.now[:alert] = @clan.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit; end

  def update
    if @clan.update(clan_params.except(:avatar))
      if params[:clan][:avatar].present?
        @clan.avatar.purge_later if @clan.avatar.attached?
        @clan.avatar.attach(params[:clan][:avatar])
      end
      redirect_to @clan, notice: 'Clan actualizado correctamente.'
    else
      render :edit
    end
  end

  def destroy
    @clan.destroy
    redirect_to clans_url, notice: 'Clan eliminado correctamente.'
  end

  def join
    if @clan.memberships.where(user: current_user).exists?
      redirect_to @clan, alert: 'Ya eres miembro de este clan.'
    else
      Membership.create!(user: current_user, joinable: @clan, status: :approved, role: :member)
      redirect_to @clan, notice: 'Te uniste al clan exitosamente.'
    end
  end

  private

  def set_clan
    @clan = Clan.friendly.find_by(slug: params[:id])
    redirect_to clans_path, alert: "No se encontró el clan." unless @clan
  end

  def clan_params
    params.require(:clan).permit(:name, :description, :address, :avatar)
  end
end