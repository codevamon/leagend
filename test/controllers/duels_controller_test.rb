require "test_helper"

class DuelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @captain = users(:captain)
    @arena = arenas(:main)
    @home_team = teams(:home)
    @away_team = teams(:away)
    sign_in @captain
  end

  test "should get index" do
    get duels_url
    assert_response :success
  end

  test "should get new" do
    get new_duel_url
    assert_response :success
  end

  test "should create duel" do
    assert_difference("Duel.count") do
      post duels_url, params: {
        duel: {
          home_team_id: @home_team.id,
          duel_type: :friendly,
          starts_at: 1.day.from_now,
          ends_at: 1.day.from_now + 2.hours,
          arena_id: @arena.id
        }
      }
    end

    assert_redirected_to duel_url(Duel.last)
  end

  test "should show duel" do
    duel = duels(:one)
    get duel_url(duel)
    assert_response :success
  end

  test "should get edit" do
    duel = duels(:one)
    get edit_duel_url(duel)
    assert_response :success
  end

  test "should update duel" do
    duel = duels(:one)
    patch duel_url(duel), params: {
      duel: {
        starts_at: 2.days.from_now,
        ends_at: 2.days.from_now + 2.hours
      }
    }
    assert_redirected_to duel_url(duel)
  end

  test "should destroy duel" do
    duel = duels(:one)
    assert_difference("Duel.count", -1) do
      delete duel_url(duel)
    end

    assert_redirected_to duels_url
  end

  test "should start duel" do
    duel = duels(:one)
    post start_duel_url(duel)
    assert_redirected_to duel_url(duel)
    duel.reload
    assert_equal "ongoing", duel.status
  end

  test "should finish duel" do
    duel = duels(:one)
    duel.update!(status: :ongoing)
    post finish_duel_url(duel)
    assert_redirected_to duel_url(duel)
    duel.reload
    assert_equal "finished", duel.status
  end

  test "should cancel duel" do
    duel = duels(:one)
    post cancel_duel_url(duel)
    assert_redirected_to duel_url(duel)
    duel.reload
    assert_equal "cancelled", duel.status
  end

  test "should postpone duel" do
    duel = duels(:one)
    post postpone_duel_url(duel)
    assert_redirected_to duel_url(duel)
    duel.reload
    assert_equal "postponed", duel.status
  end
end
