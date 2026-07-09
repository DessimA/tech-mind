class HealthController < ApplicationController
  def show
    db_status = database_ok? ? "ok" : "error"
    sidekiq_status = sidekiq_ok? ? "ok" : "error"

    render json: {
      status: "ok",
      database: db_status,
      sidekiq: sidekiq_status,
      uptime: (Time.current - Process.clock_gettime(Process::CLOCK_MONOTONIC)).to_i
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
