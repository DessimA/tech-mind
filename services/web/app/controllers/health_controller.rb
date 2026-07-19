$PROCESS_START_TIME = Time.current

class HealthController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :show ]

  def show
    db_status = database_ok? ? "ok" : "error"
    cache_status = cache_ok? ? "ok" : "degradado"

    respond_to do |format|
      format.json do
        render json: {
          status: "ok",
          database: db_status,
          cache: cache_status,
          uptime: (Time.current - $PROCESS_START_TIME).to_i
        }
      end
      format.html { render plain: "OK", status: :ok }
    end
  end

  private

  def database_ok?
    ActiveRecord::Base.connection.execute("SELECT 1")
    true
  rescue StandardError
    false
  end

  def cache_ok?
    Rails.cache.read("health_check")
    true
  rescue StandardError
    false
  end
end
