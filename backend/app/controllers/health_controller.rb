$PROCESS_START_TIME = Time.current

class HealthController < ApplicationController
  def show
    db_status = database_ok? ? "ok" : "error"
    sidekiq_status = sidekiq_ok? ? "ok" : "error"

    render json: {
      status: "ok",
      database: db_status,
      sidekiq: sidekiq_status,
      uptime: (Time.current - $PROCESS_START_TIME).to_i
    }
  end

  private

  def database_ok?
    ActiveRecord::Base.connection.execute("SELECT 1")
    true
  rescue StandardError
    false
  end

  def sidekiq_ok?
    Sidekiq.redis(&:ping)
    true
  rescue StandardError
    false
  end
end
