# frozen_string_literal: true

class GraphqlController < ApplicationController
  def execute
    result = Schema.execute(params[:query],
                            variables: ensure_hash(params[:variables]),
                            context: {},
                            operation_name: params[:operationName])
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development e
  end

  private

  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String then ambiguous_param.present? ? ensure_hash(JSON.parse(ambiguous_param)) : {}
    when Hash, ActionController::Parameters then ambiguous_param
    when nil then {}
    else raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end

  def handle_error_in_development(error)
    logger.error error.message
    logger.error error.backtrace.join("\n")

    render json: { error: { message: error.message, backtrace: error.backtrace }, data: {} }, status: 500
  end
end
