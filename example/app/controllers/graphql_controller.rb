class GraphqlController < ApplicationController
  def execute
    render json: Schema.execute(query, variables: variables, context: context)
  end

  private

  def query
    params[:query]
  end

  def variables
    ensure_hash(params[:variables])
  end

  def context
    {}
  end

  # Handle form data, JSON body, or a blank value
  def ensure_hash(params)
    case params
    when String then params.present? ? ensure_hash(JSON.parse(params)) : {}
    when Hash, ActionController::Parameters then params
    when nil then {}
    else raise ArgumentError, "Unexpected parameter: #{params}"
    end
  end
end
