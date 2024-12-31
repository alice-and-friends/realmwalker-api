# frozen_string_literal: true

class ErrorResponse
  attr_reader :error, :message, :meta

  def initialize(message:, meta: {})
    @error = true
    @message = message
    @meta = meta
  end

  def to_h
    {
      error: error,
      message: message,
      meta: meta.presence,
    }.compact
  end

  def to_json(*_args)
    to_h.to_json
  end
end
